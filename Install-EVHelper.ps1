##########################################################################
#                                                                        #
#                 Endpoint Verification Helper Installer                 #
#                                                                        #
##########################################################################

$ErrorActionPreference = 'Stop'
$LogFilePath = ($env:USERPROFILE) + '\Downloads\evhelperinstall.log'
$EVHelperPath = ($env:USERPROFILE) + '\Downloads\EndpointVerification_admin.msi'
$AlreadyInstalled = Get-Package | Where-Object { $_.Name -like "*Google Endpoint Verification*" }
$EVHelperURL = 'https://dl.google.com/dl/secureconnect/install/win/EndpointVerification_admin.msi' 
$BuiltinAdmin = Get-LocalUser -Name "Administrator"
$WordList = ((Invoke-WebRequest -Uri "https://raw.githubusercontent.com/2mmkolibri/Endpoint_Verification/main/wordlist.txt").Content -replace "`r", "") -split "`n"

function New-Passphrase {
    param (
        [int]$WordCount = 4
    )

    if ($WordCount -lt 1 -or $WordCount -gt $WordList.Count) {
        throw "Word count must be between 1 and $($WordList.Count)."
    }

    $SelectedWords = Get-Random -InputObject $WordList -Count $WordCount
    $passphrase = $SelectedWords -join "$"
    return $passphrase
}

function Write-Log {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Level,    
        [string]$Message
    )
    $Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $LogEntry = "$Timestamp - [$Level] $Message"
    $LogEntry | Out-File -FilePath $LogFilePath -Append
}

Set-Content -Path $LogFilePath -Encoding Unicode -Value "
##########################################################################
#                                                                        #
#                 Endpoint Verification Helper Installer                 #
#                                                                        #
##########################################################################
"

Write-Log INFO "Checking if Endpoint Verification Helper is installed..."

if ($null -eq $AlreadyInstalled) {
    Write-Log NOTICE "Endpoint Verification Helper is not installed"

    # Downloads the file into the current user's downloads folder
    Write-Log INFO "Downloading EV Helper File..."
    try {
        Invoke-WebRequest $EVHelperURL -outfile $EVHelperPath
        Write-Log NOTICE 'EV Helper file downloaded'
    }
    catch {
        Write-Log ERROR "Failed to download EV Helper file: $($_.Exception.Message)"
    }

    # Enable Admin account
    $AdminUser = ".\Administrator"
    $Password = New-Passphrase | ConvertTo-SecureString -AsPlainText -Force
    Write-Log INFO "Checking if builtin administrator account is enabled..."

    if (!$BuiltinAdmin.Enabled) {
        Write-Log INFO "Account is disabled. Enabling..."
        try {
            Enable-LocalUser -Name "Administrator"
            Write-Log NOTICE "Builtin administrator account enabled"

            Set-LocalUser -Name "Administrator" -Password $Password
            Write-Log NOTICE "Administrator password updated"

            $AdminCred = New-Object System.Management.Automation.PSCredential ($AdminUser, $Password)
            $SetByScript = 1
        }
        catch {
            Write-Log ERROR "Failed to activate builtin administrator account: $($_.Exception.Message)" 
        }
    }
    else {
        Write-Log INFO "Builtin administrator account is already enabled. Prompting for password..."
        $AdminCred = Get-Credential -Message "Enter the local admin credentials"
    }

    # Install and clean up files
    Write-Log INFO "Installing Endpoint Verification Helper..."
    try {
        Start-Process -FilePath "msiexec.exe" -ArgumentList "/i `"$EVHelperPath`"" -Credential $AdminCred -Wait
        Write-Log NOTICE 'Endpoint Verification Helper installed'
        Write-Log INFO 'Deleting .msi file...'
        Remove-Item $EVHelperPath -Force
        Write-Log NOTICE 'MSI file deleted'
    }
    catch {
        Write-Log ERROR "Installation and Cleanup failed: $($_.Exception.Message)"
    }

    # Disable Administrator account if enabled by the script
    if ($SetByScript -eq 1) {
        Write-Log INFO "Disabling builtin administrator account..."
        Disable-LocalUser -Name "Administrator"
        Write-Log NOTICE 'Builtin administrator account disabled'
    }

}
else {
    Write-Log NOTICE "Google Endpoint Verification Helper is already installed"
}

Add-Content -Path $LogFilePath -Value "------------------------------ END OF SCRIPT -----------------------------" -Encoding Unicode