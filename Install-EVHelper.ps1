##########################################################################
#                                                                        #
#                 Endpoint Verification Helper Installer                 #
#                                                                        #
##########################################################################

$ErrorActionPreference = 'Stop'
$LogFilePath = "C:\Windows\Temp\Install-EVHelper.log"
$EVHelperPath = "C:\Windows\Temp\EndpointVerification_admin.msi"
$EVHelperApp = Get-Package | Where-Object { $_.Name -like "*Google Endpoint Verification*" }
$EVHelperURL = 'https://dl.google.com/dl/secureconnect/install/win/EndpointVerification_admin.msi' 
Add-Type -AssemblyName System.Windows.Forms

function Write-Log {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Level,    
        [string]$Message
    )
    $Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $LogEntry = "$Timestamp - [$Level] $Message"
    $LogEntry | Out-File -FilePath $LogFilePath -Append -Encoding Unicode
}

function Show-MessageBox {
    param (
        [string]$Message,
        [string]$Title = "Notice",
        [ValidateSet("Information", "Warning", "Error")]
        [string]$Icon = "Information"
    )
    $ButtonType = [System.Windows.Forms.MessageBoxButtons]::OK
    $IconType = [System.Windows.Forms.MessageBoxIcon]::$Icon
    [System.Windows.Forms.MessageBox]::Show($Message, $Title, $ButtonType, $IconType)
}

Set-Content -Path $LogFilePath -Encoding Unicode -Value "
##########################################################################
#                                                                        #
#                 Endpoint Verification Helper Installer                 #
#                                                                        #
##########################################################################
"

Write-Log INFO "Checking if Endpoint Verification Helper is installed..."

if ($null -eq $EVHelperApp) {
    Write-Log NOTICE "Endpoint Verification Helper is not installed"

    # Downloads the file into the Temp directory
    Write-Log INFO "Checking if Endpoint Verification Helper MSI file is present..."
    if (!(Test-Path $EVHelperPath)) {
        Write-Log INFO "MSI file is missing. Downloading the file..."
        try {
            Invoke-WebRequest $EVHelperURL -outfile $EVHelperPath
            Write-Log NOTICE 'Endpoint Verification Helper file downloaded'
        }
        catch {
            Write-Log ERROR "Failed to download EV Helper file: $($_.Exception.Message)"
            Show-MessageBox "Failed to download Google Endpoint Verification.`n`n$($_.Exception.Message)" "Error" "Error"
            exit 1
        }
    }
    else {
        Write-Log INFO "EV Helper MSI file has already been downloaded"
    }
    

    # Enable Admin account
    Write-Log INFO "Prompting for builtin administrator credentials..." 
    $AdminCred = Get-Credential -UserName "administrator" -Message "Enter or set the local admin credentials."
    
    if ($null -eq $AdminCred) {
        Write-Log ERROR "Username or Password cannot be empty.`n`nPlease enter the admin credentials to continue."
        Show-MessageBox "Username or Password cannot be empty.`n`nPlease enter the admin credentials to continue." "Error" "Error"
        exit 1
    }

    Write-Log INFO "Checking if builtin administrator account is enabled..."
    $BuiltinAdmin = Get-LocalUser -Name "Administrator"

    if (!$BuiltinAdmin.Enabled) {
        Write-Log INFO "Account is disabled. Enabling..."
        try {
            Enable-LocalUser -Name "Administrator"
            Write-Log NOTICE "Builtin administrator account enabled"

            Set-LocalUser -Name "Administrator" -Password $AdminCred.Password
            Write-Log NOTICE "Administrator password updated"

            $SetByScript = 1
        }
        catch {
            Write-Log ERROR "Failed to activate builtin administrator account: $($_.Exception.Message)" 
            Show-MessageBox "Failed to activate the builtin administrator account.`n`n$($_.Exception.Message)" "Error" "Error"
        }
    }
    else {
        Write-Log INFO "Account is already enabled" 
    }

    # Install and clean up files
    Write-Log INFO "Installing Endpoint Verification Helper..."
    try {
        Start-Process -FilePath "msiexec.exe" -ArgumentList "/i `"$EVHelperPath`"" -Credential $AdminCred -Wait
        Write-Log NOTICE 'Endpoint Verification Helper installed'
    }
    catch {
        Write-Log ERROR "Installation failed: $($_.Exception.Message)"
        Show-MessageBox "Failed to install Google Endpoint Verification.`n`n$($_.Exception.Message)" "Error" "Error"
        exit 1
    }   
    
    try {
        Write-Log INFO 'Deleting .msi file...'
        Remove-Item $EVHelperPath -Force
        Write-Log NOTICE 'MSI file deleted'
        Remove-Variable AdminCred
    }
    catch {
        Write-Log ERROR "Cleanup failed: $($_.Exception.Message)"
        continue
    }

    # Disable Administrator account if enabled by the script
    if ($SetByScript -eq 1) {
        Write-Log INFO "Disabling builtin administrator account..."
        Disable-LocalUser -Name "Administrator"
        Write-Log NOTICE 'Builtin administrator account disabled'
    }

    Show-MessageBox "Google Endpoint Verification has been installed. Please open your Chrome work profile and run the Endpoint Verification sync." "Information" "Information"
}
else {
    Write-Log NOTICE "Google Endpoint Verification is already installed"
    Show-MessageBox "Google Endpoint Verification is already installed." "Notice" "Information"
}

Add-Content -Path $LogFilePath -Value "------------------------------ END OF SCRIPT -----------------------------" -Encoding Unicode