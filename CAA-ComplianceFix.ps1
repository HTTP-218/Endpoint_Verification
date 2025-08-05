######################################################################################################
#                                                                                                    #
#                                       CAA-ComplianceFix.ps1                                        #
#                                                                                                    #
######################################################################################################

#====================================================================================================#
#                                           [ Functions ]                                            #
#====================================================================================================#
#region Functions
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
        [ValidateSet("Information", "Warning", "Error", "Question")]
        [string]$Icon = "Information",
        [System.Windows.Forms.MessageBoxButtons]$Buttons = [System.Windows.Forms.MessageBoxButtons]::OK
    )

    # Create a hidden "topmost" window to own the message box
    $Form = New-Object System.Windows.Forms.Form
    $Form.TopMost = $true
    $Form.StartPosition = "Manual"
    $Form.Size = '1,1'
    $Form.Location = '0,0'
    $Form.Show()
    $Form.Hide()

    $Result =  [System.Windows.Forms.MessageBox]::Show($Form, $Message, $Title, $Buttons, [System.Windows.Forms.MessageBoxIcon]::$Icon)

    $Form.Dispose()
    return $Result
}

# Wrapper for different log message types
function Write-Message {
    param (
        [string]$Message,
        [ValidateSet("INFO", "NOTICE", "WARN", "ERROR")] 
        [string]$Level = "INFO",
        [bool]$Console = $true,
        [bool]$Log = $true,
        [bool]$Dialogue = $false,
        [string]$DialogueTitle = "CAA Compliance Fix"
    )

    if ($Console) { Write-Host "[$Level] $Message" }
    if ($Log) { Write-Log -Level $Level -Message $Message }
    if ($Dialogue) {
        $icon = switch ($Level) {
            "INFO"   { "Information" }
            "NOTICE" { "Information" }
            "WARN"   { "Warning" }
            "ERROR"  { "Error" }
        }
        Show-MessageBox -Message $Message -Title $DialogueTitle -Icon $icon
    }
}

#endregion

#====================================================================================================#
#                                           [ Variables ]                                            #
#====================================================================================================#
$ErrorActionPreference = "Stop"
$ProgressPreference = 'SilentlyContinue'
$LogFilePath = "C:\Windows\Temp\CAA-ComplianceFix.log"
$Summary = @()

Add-Type -AssemblyName System.Windows.Forms

Set-Content -Path $LogFilePath -Encoding Unicode -Value "
##########################################################################
#                                                                        #
#                          CAA-ComplianceFix.ps1                         #
#                                                                        #
##########################################################################
"

try {
    $JSONPath = "C:\Windows\Temp\caa.json"
    Invoke-WebRequest -Uri "https://raw.githubusercontent.com/2mmkolibri/Endpoint_Verification/feature/caa-compliance/caa.json" -OutFile $JSONPath
    $Variables = Get-Content -Raw -Path $JSONPath | ConvertFrom-Json
}
catch {
    Write-Message -Message "Failed to initialise JSON config file`n`n$($_.Exception.Message)" -Level "ERROR" -Dialogue $true
}

#====================================================================================================#
#                                      [ Windows Build Check ]                                       #
#====================================================================================================#
Write-Message -Message "Starting Windows Build check..." -Level "INFO"

$WindowsBuild = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion").CurrentBuildNumber
$DisplayVersion = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion").DisplayVersion

$MatchingRequirement = $Variables.BuildRequirements |
Where-Object { $WindowsBuild -ge $_.MinBuild -and ($_.MaxBuild -eq $null -or $WindowsBuild -le $_.MaxBuild) } |
Sort-Object MinBuild -Descending |
Select-Object -First 1

if ($null -eq $MatchingRequirement) {
    Write-Message -Message "Windows build $($DisplayVersion) is not compliant" -Level "WARN"
    $Summary += "Windows build $($DisplayVersion) is not supported"
} 
else {
    Write-Message -Message "Windows is compliant with $($MatchingRequirement.Label) (Build $WindowsBuild)" -Level "INFO"
}

#====================================================================================================#
#                                          [ Chrome Check ]                                          #
#====================================================================================================#
Write-Message -Message "Starting Chrome check..." -Level "INFO"

$ChromeURL = "https://dl.google.com/tag/s/dl/chrome/install/googlechromestandaloneenterprise64.msi"
$ChromePath = "C:\Windows\Temp\googlechromestandaloneenterprise64.msi"
$Chrome = Get-Package | Where-Object { $_.Name -like "*Google Chrome*" }

if ($null -eq $Chrome) {
    Write-Message -Message "Google Chrome is not installed on this device" -Level "WARN"

    $InstallResponse = Show-MessageBox -Message "Google Chrome is missing.`n`nWould you like to install it now?" -Title "Install Google Chrome?" -Icon "Question" -Buttons ([System.Windows.Forms.MessageBoxButtons]::YesNo)
    
    if ($InstallResponse -eq [System.Windows.Forms.DialogResult]::Yes) {
        try {
            Write-Message -Message "Downloading Google Chrome MSI file. This may take a few minutes..." -Level "INFO"
            Invoke-WebRequest $ChromeURL -outfile $ChromePath
            Write-Message -Message "Downloaded Google Chrome MSI file" -Level "NOTICE"
        }
        catch {
            Write-Message -Message "Failed to download Google Chrome MSI file`n`n$($_.Exception.Message)" -Level "ERROR" -Dialogue $true
            exit 1
        }

        try {
            Write-Message -Message "Installing Google Chrome..." -Level "INFO"
            Start-Process -FilePath "msiexec.exe" -ArgumentList "/i `"$ChromePath`"" -wait
            Write-Message -Message "Google Chrome has been installed" -Level "NOTICE" -Dialogue $true
        }
        catch {
            Write-Message -Message "Failed to install Google Chrome`n`n$($_.Exception.Message)" -Level "ERROR" -Dialogue $true
            exit 1
        }

        # Fresh install doesn't have User Data directory until Chrome is opened. This will prevent EV extension check from failing.
        try {
            Write-Message -Message "Launching Google Chrome to create User Data directory..." -Level "INFO"
            Start-Process -FilePath "C:\Program Files\Google\Chrome\Application\chrome.exe" --silent-launch
        }
        catch {
            Write-Message -Message "Failed to launch Google Chrome`n`n$($_.Exception.Message)" -Level "ERROR" -Dialogue $true
            exit 1
        }

        try {
            Write-Message -Message  "Deleting Chrome msi file..." -Level "INFO"           
            Remove-Item $ChromePath -Force
            Write-Message -Message  "Chrome MSI file deleted" -Level "NOTICE"
        }
        catch {
            Write-Message -Message  "Failed to delete Chrome MSI file: $($_.Exception.Message)" -Level "WARN"
        }    
    }
    else {
        Write-Message -Message "User chose not to install Google Chrome." -Level "NOTICE"
        $Summary += "Google Chrome is not installed"
    }
}
else {
    Write-Message -Message "Google Chrome is already installed. Checking version..." -Level "INFO"
    if ($Chrome.Version -lt $Variables.ChromeVersion) {
        Write-Message -Message "Chrome is not compliant" -Level "WARN"
        $Summary += "Chrome version $($Chrome.Version) is below the minimum requirement"
    }   
    else {
        Write-Message -Message "Chrome is compliant with version $($Chrome.Version)" -Level "INFO"
    }
}

#====================================================================================================#
#                             [ Endpoint Verification Extension Check ]                              #
#====================================================================================================#
Write-Message -Message "Starting Endpoint Verification Extension check..." -Level "INFO"

$Chrome = Get-Package | Where-Object { $_.Name -like "*Google Chrome*" }
$Username = (Get-CimInstance Win32_ComputerSystem).UserName

if ($Chrome) {
    if (!$Username) {
        Write-Message -Message "Could not grab current user's name. You may be using this script over a remote session." -Level "ERROR"
        exit 1
    }
    else {
        $Username = $Username.Split('\')[-1]
        Write-Message -Message "Current console user is: $Username" -Level "INFO"
    }

    $ChromeProfiles = Get-ChildItem -Path "C:\Users\$Username\AppData\Local\Google\Chrome\User Data" -Directory | Where-Object { $_.Name -eq "Default" -or $_.Name -match "^Profile \d+$" }
    $EVExtension = @()

    foreach ($ChromeProfile in $ChromeProfiles) {
        $ExtensionsFolder = Get-ChildItem -Path $ChromeProfile.FullName | Where-Object { $_.Name -eq "Extensions" }
        if ($ExtensionsFolder) {
            $ExtensionsPath = Get-ChildItem -Path $ExtensionsFolder.FullName | Where-Object { $_.Name -eq $Variables.ExtensionID }
            if ($ExtensionsPath) {
                $EVExtension += $ExtensionsPath
            }
        }
    }

    if ($EVExtension) {
        Write-Message -Message "Endpoint Verification extension is installed in one or more profiles" -Level "INFO"
    }
    else {
        Write-Message -Message  "Endpoint Verification extension could not be found in any Chrome profile" -Level "WARN"
        $Summary += "Endpoint Verification extension is not installed"
    }
}
else {
    Write-Message -Message  "Chrome is not installed. Skipping Endpoint Verification extension check" -Level "WARN"
    $Summary += "Endpoint Verification extension is not installed"
}

#====================================================================================================#
#                                     [ Firewall Status Check ]                                      #
#====================================================================================================#
Write-Message -Message "Starting Firewall Status check..." -Level "INFO"

$FirewallStatus = Get-NetFirewallProfile | Select-Object Name, Enabled

foreach ($NetProfile in $FirewallStatus) {
    if ($NetProfile.Enabled -eq $false) {
       Write-Message -Message "The $($NetProfile.Name) firewall profile is disabled" -Level "WARN"

        $EnableResponse = Show-MessageBox -Message "The $($NetProfile.Name) firewall profile is disabled.`n`nWould you like to enable it?" -Title "Enable Firewall Profile?" -Icon "Question" -Buttons ([System.Windows.Forms.MessageBoxButtons]::YesNo)
        if ($EnableResponse -eq [System.Windows.Forms.DialogResult]::Yes) {
            try {
                Set-NetFirewallProfile -Name $NetProfile.Name -Enabled True
                Write-Message -Message "$($NetProfile.Name) firewall profile has been enabled" -Level "NOTICE" -Dialogue $true
            }
            catch {
                Write-Message -Message "Failed to enable the $($NetProfile.Name) firewall profile`n`n$($_.Exception.Message)" -Level "ERROR" -Dialogue $true
                exit 1
            }
        }
        else {
            Write-Message -Message "User chose not to enable the $($NetProfile.Name) firewall profile." -Level "NOTICE"
            $Summary += "$($NetProfile.Name) firewall profile."
        }
    }
    else {
        Write-Message -Message "Firewall $($NetProfile.Name) profile is enabled" -Level "INFO"
    }
}

#====================================================================================================#
#                               [ Endpoint Verification Helper Check ]                               #
#====================================================================================================#
Write-Message -Message "Starting Endpoint Verification Helper check..." -Level "INFO"

$EVHelperPath = "C:\Windows\Temp\EndpointVerification_admin.msi"
$EVHelperURL = 'https://dl.google.com/dl/secureconnect/install/win/EndpointVerification_admin.msi'
$EVHelperApp = Get-Package | Where-Object { $_.Name -like "*Google Endpoint Verification*" }

if ($null -eq $EVHelperApp) {
    Write-Message -Message "Endpoint Verification Helper is not installed" -Level "WARN"
    
    $InstallResponse = Show-MessageBox -Message "Endpoint Verification Helper is missing.`n`nWould you like to install it now?" -Title "Install EV Helper?" -Icon "Question" -Buttons ([System.Windows.Forms.MessageBoxButtons]::YesNo)
    
    if ($InstallResponse -eq [System.Windows.Forms.DialogResult]::Yes) {

        Write-Message -Message "Checking if Endpoint Verification Helper MSI file is present..." -Level "INFO"
        if (!(Test-Path $EVHelperPath)) {
            Write-Message -Message "MSI file is missing. Downloading the file..." -Level "INFO"

            try {
                Invoke-WebRequest $EVHelperURL -outfile $EVHelperPath
                Write-Message -Message "Endpoint Verification Helper file downloaded" -Level "NOTICE" 
            }
            catch {
                Write-Message -Message "Failed to download EV Helper file`n`n$($_.Exception.Message)" -Level "ERROR" -Dialogue $true
                exit 1
            }
        }
        else {
            Write-Message -Message "EV Helper MSI file has already been downloaded" -Level "INFO"
        }

        # Built-in admin account is needed to install the MSI package
        Write-Message -Message "Prompting for builtin administrator credentials..." -Level "INFO"
        $AdminCred = Get-Credential -UserName "administrator" -Message "Enter or set the local admin credentials."
        
        if ($null -eq $AdminCred) {
            Write-Message -Message "Username or Password cannot be empty.`n`nPlease enter the admin credentials to continue." -Level "ERROR" -Dialogue $true
            exit 1
        }

        Write-Message -Message "Checking if builtin administrator account is enabled..." -Level "INFO"
        $BuiltinAdmin = Get-LocalUser -Name "Administrator"

        if (!$BuiltinAdmin.Enabled) {
            Write-Message -Message "Account is disabled. Enabling..." -Level "INFO"
            try {
                Enable-LocalUser -Name "Administrator"
                Write-Message -Message "Builtin administrator account enabled" -Level "NOTICE"

                Set-LocalUser -Name "Administrator" -Password $AdminCred.Password
                Write-Message -Message "Administrator password updated" -Level "NOTICE"

                $SetByScript = 1
            }
            catch {
                Write-Message -Message "Failed to activate builtin administrator account`n`n$($_.Exception.Message)" -Level "ERROR" -Dialogue $true
                exit 1
            }
        }
        else {
            Write-Message -Message  "Account is already enabled" -Level "INFO"
        }

        Write-Message -Message  "Installing Endpoint Verification Helper..." -Level "INFO"
        try {
            Start-Process -FilePath "msiexec.exe" -ArgumentList "/i `"$EVHelperPath`"" -Credential $AdminCred -Wait
            Write-Message -Message  "Endpoint Verification Helper installed" -Level "NOTICE"
        }
        catch {
            Write-Message -Message  "Installation failed!`n`n$($_.Exception.Message)" -Level "ERROR" -Dialogue $true
            exit 1
        }
        
        try {
            Write-Message -Message  "Deleting .msi file..." -Level "INFO"           
            Remove-Item $EVHelperPath -Force
            Write-Message -Message  "MSI file deleted" -Level "NOTICE"           

            Remove-Variable AdminCred
        }
        catch {
            Write-Message -Message  "Failed to delete EV Helper MSI file: $($_.Exception.Message)" -Level "WARN"
        }

        if ($SetByScript -eq 1) {
            Write-Message -Message  "Disabling builtin administrator account..." -Level "INFO"
            Disable-LocalUser -Name "Administrator"
            Write-Message -Message  "Builtin administrator account disabled" -Level "NOTICE"
        }

        Write-Message -Message "Google Endpoint Verification has been installed" -Level "NOTICE" -Dialogue $true 
    }
    else {
        Write-Message -Message "User chose not to install Endpoint Verification Helper." -Level "NOTICE"
        $Summary += "Endpoint Verification Helper is not installed"
    }
}
else {
    Write-Message -Message  "Endpoint Verification Helper is installed" -Level "INFO"
}

#====================================================================================================#
#                                             [ Cleanup ]                                            #
#====================================================================================================#
Write-Message -Message "Cleaning up temporary files..." -Level "INFO"

try {
    Write-Message -Message  "Deleting JSON file..." -Level "INFO"           
    Remove-Item $JSONPath -Force
    Write-Message -Message  "JSON file deleted" -Level "NOTICE"     
}
catch {
    Write-Message -Message  "Failed to delete JSON file: $($_.Exception.Message)" -Level "WARN"
}

#====================================================================================================#
#                                       [ Compliance Summary ]                                       #
#====================================================================================================#
Write-Message -Message  "Generating summary report..." -Level "INFO"        

if ($Summary.Count -eq 0) {
    $Message = @"
    All checks passed. Your device is compliant.

    If you're still unable to access Gmail, try the following:

      1. Open Google Chrome and wait 2 minutes
      2. Open the Endpoint Verification extension
      3. Click 'SYNC NOW'
      4. Reload your Gmail tab
"@
    Write-Message -Message $Message -Level "INFO" -Console $false -Log $false -Dialogue $true
} 
else {
    $SummaryText = ($Summary | ForEach-Object { "    - $_" }) -join "`n"
    $Message = @"
    Your device is not compliant:

$SummaryText

Please address each issue, then run the Endpoint Verification sync to regain access.
"@
    Write-Message -Message $Message -Level "ERROR" -Console $false -Log $false -Dialogue $true
}

exit 0
