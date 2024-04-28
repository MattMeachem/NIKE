$Appversion = 3
#Requires -RunAsAdministrator
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

#re-compile 7zip archive
$archivePath = "C:\Background_Files\forensictools_1.1_setup.exe"

# Check if the archive already exists
if (-not (Test-Path -Path $archivePath)) {
    # If the archive doesn't exist, re-compile it
    C:\Background_Files\forensictools_setup.exe -o "C:\Forensics" -y
} else {
    Write-Host "Re-compiled archive already exists. Skipping re-compilation."
}

# Function to show username and password input window
function Show-CredentialsForm {
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "Enter Credentials"
    $form.Size = New-Object System.Drawing.Size(300,150)
    $form.StartPosition = "CenterScreen"
    $form.FormBorderStyle = 'FixedDialog'
    
    $usernameLabel = New-Object System.Windows.Forms.Label
    $usernameLabel.Location = New-Object System.Drawing.Point(10,20)
    $usernameLabel.Size = New-Object System.Drawing.Size(100,20)
    $usernameLabel.Text = "Username:"
    $form.Controls.Add($usernameLabel)
    
    $usernameTextBox = New-Object System.Windows.Forms.TextBox
    $usernameTextBox.Location = New-Object System.Drawing.Point(120,20)
    $usernameTextBox.Size = New-Object System.Drawing.Size(150,20)
    $form.Controls.Add($usernameTextBox)
    
    $passwordLabel = New-Object System.Windows.Forms.Label
    $passwordLabel.Location = New-Object System.Drawing.Point(10,50)
    $passwordLabel.Size = New-Object System.Drawing.Size(100,20)
    $passwordLabel.Text = "Password:"
    $form.Controls.Add($passwordLabel)
    
    $passwordTextBox = New-Object System.Windows.Forms.TextBox
    $passwordTextBox.Location = New-Object System.Drawing.Point(120,50)
    $passwordTextBox.Size = New-Object System.Drawing.Size(150,20)
    $passwordTextBox.PasswordChar = '*'
    $form.Controls.Add($passwordTextBox)
    
    $okButton = New-Object System.Windows.Forms.Button
    $okButton.Location = New-Object System.Drawing.Point(120,90)
    $okButton.Size = New-Object System.Drawing.Size(75,23)
    $okButton.Text = "OK"
    $okButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $form.Controls.Add($okButton)
    
    $cancelButton = New-Object System.Windows.Forms.Button
    $cancelButton.Location = New-Object System.Drawing.Point(200,90)
    $cancelButton.Size = New-Object System.Drawing.Size(75,23)
    $cancelButton.Text = "Cancel"
    $cancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
    $form.Controls.Add($cancelButton)
    
    $result = $form.ShowDialog()
    
    if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
        $username = $usernameTextBox.Text
        $password = $passwordTextBox.Text
        return $username, $password
    } else {
        return $null, $null
    }
}

# Function to show confirmation message
function Show-Confirmation {
    param (
        [string]$Message
    )
    [System.Windows.Forms.MessageBox]::Show($Message, "Confirmation", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
}

# Call function to get username and password
$username, $password = Show-CredentialsForm

# Check if credentials are provided
if ($username -ne $null -and $password -ne $null) {
    
    # Auto Deploy
    Get-NetAdapter | Disable-NetAdapter -Confirm:$false
    reg import C:\Background_Files\USB.reg
    Start-Process -FilePath "C:\Background_Files\forensictools_1.1_setup.exe" -ArgumentList "/S", "/silent" -NoNewWindow
    Start-Sleep -Seconds 60
    Show-Confirmation -Message "Auto-Deploy Complete, commencing post-install checks"

    # Post-Install Check
    if ((Get-Item 'HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Scan').property -contains "DisableRemovableDriveScanning") {
        Show-Confirmation -Message "Registry Key Installed"
    } else {
        Show-Confirmation -Message "Registry Key Failed to Install Correctly"
    }

    if (Get-NetAdapter | Where-Object {$_.Status -ne 'Disabled' -and $_.Status -ne 'Not Present'}) {
        Show-Confirmation -Message "Network has not been disabled"
    } else {
        Show-Confirmation -Message "Network Adapters Disabled Correctly"
    }

    
    Set-MpPreference -ScanParameters FullScan -ScanScheduleDay Everyday -ScanScheduleTime 23:00:00

    # Setup Weekly Offline scan, sundays at 2300
    $Action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "Start-MpWDOScan"
    $Trigger = New-ScheduledTaskTrigger -Weekly -At 23:00 -DaysOfWeek Sunday
    $ScheduledTask = New-ScheduledTask -Action $action -Trigger $trigger 

    Register-ScheduledTask -TaskName "Weekly Defender Offline Scan" -InputObject $ScheduledTask -User $username -Password $password
    $Taskname = "Weekly Defender Offline Scan"
    $taskExists = Get-ScheduledTask | Where-Object {$_.Taskname -like $Taskname}
    if ($taskExists) {
        Show-Confirmation -Message "Weekly Offline Scan Scheduled"
    } else {
        Show-Confirmation -Message "Failed to Schedule Offline Scan"
    }
    Show-Confirmation -Message "It is now safe to close the script"
} else {
    Show-Confirmation -Message "Username and password not provided. Exiting script."
    
}
Set-ExecutionPolicy Undefined -force
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\PowerShell\1\ShellIds\Microsoft.PowerShell" -Name "ExecutionPolicy" -Value "Undefined" -Force
