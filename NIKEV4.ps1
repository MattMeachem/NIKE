$Appversion = 4
$LogPath = "C:\Background_Files\setup_log.txt"
$Author - "MattMeachem"


# Auto-Elevation
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator"))
{
    Start-Process powershell "-ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# Logging function
function Log {
    param([string]$message)
    $timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    "$timestamp - $message" | Out-File -Append -FilePath $LogPath
    Write-Host $message
}

Log "`n===== Project Nike V4 Setup Started ====="

try {
    # === HARDCORE DEBLOAT SECTION ===
    Log "[*] Starting Windows debloat..."

    Try {
        Get-AppxPackage -AllUsers | Remove-AppxPackage -ErrorAction SilentlyContinue
        Get-AppxProvisionedPackage -Online | Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue

        $disableServices = @(
            "DiagTrack", "dmwappushsvc", "XblAuthManager", "XblGameSave",
            "XboxNetApiSvc", "WMPNetworkSvc", "Fax", "PrintNotify", "RemoteRegistry"
        )
        foreach ($svc in $disableServices) {
            Stop-Service -Name $svc -Force -ErrorAction SilentlyContinue
            Set-Service -Name $svc -StartupType Disabled
        }

        Get-ScheduledTask | Where-Object {
            $_.TaskPath -like "*CEIP*" -or $_.TaskName -like "*Telemetry*"
        } | ForEach-Object {
            Disable-ScheduledTask -TaskName $_.TaskName -TaskPath $_.TaskPath -ErrorAction SilentlyContinue
        }

        $featuresToRemove = @(
            "Printing-XPSServices-Features",
            "WorkFolders-Client",
            "Internet-Explorer-Optional-amd64",
            "MediaPlayback"
        )
        foreach ($feature in $featuresToRemove) {
            Disable-WindowsOptionalFeature -Online -FeatureName $feature -NoRestart -ErrorAction SilentlyContinue
        }

        New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Force | Out-Null
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Name "AllowCortana" -Type DWord -Value 0
        Stop-Service -Name "WSearch" -Force -ErrorAction SilentlyContinue
        Set-Service -Name "WSearch" -StartupType Disabled

        New-Item -Path "HKCU:\Software\Policies\Microsoft\Windows\CloudContent" -Force | Out-Null
        Set-ItemProperty -Path "HKCU:\Software\Policies\Microsoft\Windows\CloudContent" -Name "DisableWindowsConsumerFeatures" -Value 1
        Set-ItemProperty -Path "HKCU:\Software\Policies\Microsoft\Windows\CloudContent" -Name "DisableCloudOptimizedContent" -Value 1

        if (Test-Path "$env:SystemRoot\SysWOW64\OneDriveSetup.exe") {
            Start-Process "$env:SystemRoot\SysWOW64\OneDriveSetup.exe" "/uninstall" -NoNewWindow -Wait
        }

        Log "[+] Debloat complete."
    } Catch {
        Log "ERROR OCCURRED DURING DEBLOAT: $($_.Exception.Message)"
        Log "STACK TRACE: $($_.ScriptStackTrace)"
    }

    # === OPENHASHTAB SECTION ===

    $forensicToolPath = "C:\Background_files\OpenHashTab_Machine_x64.msi"
    if (-not (Test-Path -Path $forensicToolPath)) {
        Log "[!] OPENHASHTAB not found at path: $forensicToolPath"
    } else {
        Log "[*] Disabling all network adapters..."
        Get-NetAdapter | Disable-NetAdapter -Confirm:$false -ErrorAction SilentlyContinue

        Log "[*] Importing registry keys..."
        reg import C:\Background_Files\USB.reg | Out-Null

        Log "[*] Launching forensic tool setup..."
        Start-Process -FilePath $forensicToolPath -ArgumentList "/S", "/silent" -NoNewWindow
        Start-Sleep -Seconds 60

        Log "[*] Verifying registry key installation..."
        if ((Get-Item 'HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Scan').property -contains "DisableRemovableDriveScanning") {
            Log "[+] Registry key installed successfully"
        } else {
            Log "[!] Registry key failed to install"
        }

        Log "[*] Checking network adapter state..."
        if (Get-NetAdapter | Where-Object {$_.Status -ne 'Disabled' -and $_.Status -ne 'Not Present'}) {
            Log "[!] Some adapters are still active"
        } else {
            Log "[+] All network adapters are disabled"
        }

        Log "[*] Configuring Defender scan settings..."
        Set-MpPreference -ScanParameters FullScan -ScanScheduleDay Everyday -ScanScheduleTime 23:00:00

        Log "[*] Scheduling weekly Defender offline scan (SYSTEM context)..."
        $Action   = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "Start-MpWDOScan"
        $Trigger  = New-ScheduledTaskTrigger -Weekly -At 23:00 -DaysOfWeek Sunday
        $Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
        $Principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -RunLevel Highest

        $Task = New-ScheduledTask -Action $Action -Trigger $Trigger -Settings $Settings -Principal $Principal
        Register-ScheduledTask -TaskName "Weekly Defender Offline Scan" -InputObject $Task -Force

        Log "[+] Scheduled Defender offline scan"
    }

    # Optional cleanup
    Set-ExecutionPolicy Undefined -Force
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\PowerShell\1\ShellIds\Microsoft.PowerShell" -Name "ExecutionPolicy" -Value "Undefined" -Force

    Log "[✓] Setup complete. System is ready for forensic use."

} catch {
    Log "ERROR OCCURRED: $($_.Exception.Message)"
    Log "STACK TRACE: $($_.ScriptStackTrace)"
}
