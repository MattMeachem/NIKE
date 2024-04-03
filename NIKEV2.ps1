# Init PowerShell Gui
#Requires -RunAsAdministrator
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

C:\Background_Files\forensictools_setup.exe -o "C:\Forensics" -y

# Create a new form
$NIKE                    = New-Object system.Windows.Forms.Form

# Define the size, title and background color
$NIKE.ClientSize         = '200,320'
$NIKE.text               = "NIKEV2.0"
$NIKE.BackColor          = "#ffffff"

# Disable network adapters
$Network                   = New-Object system.Windows.Forms.Button
$Network.BackColor         = "#1a71eb"
$Network.text              = "Disable Network"
$Network.width             = 120
$Network.height            = 40
$Network.location          = New-Object System.Drawing.Point(10,10)
$Network.Font              = 'Microsoft Sans Serif,10'
$Network.ForeColor         = "#ffffff"
$Network.Visible           = $true
$Network.Add_Click({ Get-NetAdapter | Disable-NetAdapter -Confirm:$false })

# Add Reg Key for USB scanning with Defender button
$USBScan                   = New-Object system.Windows.Forms.Button
$USBScan.BackColor         = "#1a71eb"
$USBScan.text              = "USB Scan Enable"
$USBScan.width             = 120
$USBScan.height            = 40
$USBScan.location          = New-Object System.Drawing.Point(10,60)
$USBScan.Font              = 'Microsoft Sans Serif,10'
$USBScan.ForeColor         = "#ffffff"
$USBScan.Visible           = $true
$USBScan.Add_Click({  reg import C:\Background_Files\USB.reg}) 


# Add Forensics tools
$Forensicstools            = New-Object system.Windows.Forms.Button
$Forensicstools.BackColor  = "#1a71eb"
$Forensicstools.text       = "Forensics Tools"
$Forensicstools.width      = 120
$Forensicstools.height     = 40
$Forensicstools.location   = New-Object System.Drawing.Point(10,110)
$Forensicstools.Font       = 'Microsoft Sans Serif,10'
$Forensicstools.ForeColor  = "#ffffff"
$Forensicstools.Visible    = $true
$Forensicstools.Add_Click({  
    C:\Background_Files\forensictools_1.1_setup.exe /S /silent })

# Auto Deploy
$AutoDeploy                = New-Object system.Windows.Forms.Button
$AutoDeploy.BackColor      = "#1a71eb"
$AutoDeploy.text           = "Auto-Deploy"
$AutoDeploy.width          = 120
$AutoDeploy.height         = 40
$AutoDeploy.location       = New-Object System.Drawing.Point(10,160)
$AutoDeploy.Font           = 'Microsoft Sans Serif,10'
$AutoDeploy.ForeColor      = "#ffffff"
$AutoDeploy.Visible        = $true
$AutoDeploy.Add_Click({  
    Get-NetAdapter | Disable-NetAdapter -Confirm:$false
    reg import C:\Background_Files\USB.reg
    C:\Background_Files\forensictools_1.1_setup.exe /S /silent})


# Add Sanity Check - maybe add as a post to auto-deploy?
$InstallCheck                = New-Object system.Windows.Forms.Button
$InstallCheck.BackColor      = "#1a71eb"
$InstallCheck.text           = "Install Check"
$InstallCheck.width          = 120
$InstallCheck.height         = 40
$InstallCheck.location       = New-Object System.Drawing.Point(10,210)
$InstallCheck.Font           = 'Microsoft Sans Serif,10'
$InstallCheck.ForeColor      = "#ffffff"
$InstallCheck.Visible        = $true
$InstallCheck.Add_Click({ 
    #reg key check
    if ( (Get-Item 'HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Scan').property -contains "DisableRemovableDriveScanning" ){
        Write-Host "Reg Key Installed"
    }
    else{
        Write-Host "Reg key Failed"
    }
    
    #Check Net Adapters
    if (Get-NetAdapter | Where-Object{$_.Status -ne 'Disabled' -and $_.Status -ne 'Not Present'}){
        Write-Host "Network has not been disabled"
    }

    else {
        Write-Host "Network Adapters Disabled Correctly"
    }})

# Add Cancel Button
$cancelBtn                 = New-Object system.Windows.Forms.Button
$cancelBtn.BackColor       = "#ffffff"
$cancelBtn.text            = "Close"
$cancelBtn.width           = 120
$cancelBtn.height          = 40
$cancelBtn.location        = New-Object System.Drawing.Point(10,260)
$cancelBtn.Font            = 'Microsoft Sans Serif,10'
$cancelBtn.ForeColor       = "#000"
$cancelBtn.DialogResult    = [System.Windows.Forms.DialogResult]::Cancel
$NIKE.CancelButton         = $cancelBtn
$NIKE.Controls.Add($cancelBtn)



# Add buttons to GUI
$NIKE.controls.AddRange(@($Title,$Description,$Network,$Forensicstools,$AutoDeploy,$USBScan,$InstallCheck,$cancelBtn))



# Display the form
[void]$NIKE.ShowDialog()
