######################################################################################################
#                                                                                                    #
#                    		             CAA-ComplianceScan.ps1                    		             #
#                                                                                                    #
######################################################################################################

#====================================================================================================#
#                                           [ Variables ]                                            #
#====================================================================================================#

Add-Type -AssemblyName System.Windows.Forms
$ErrorActionPreference = "Stop"
$LogFilePath = "C:\Windows\Temp\CAA-ComplianceScan.log"
$JSONPath = "C:\Windows\Temp\caa.json"
Invoke-WebRequest -Uri "https://drive.google.com/uc?export=download&id=1D-LoZOFrcXmFEulDjfywONZ2O12d98ty" -OutFile $JSONPath
$Variables = Get-Content -Raw -Path $JSONPath | ConvertFrom-Json
$Summary = @()

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
    Add-Type -AssemblyName System.Windows.Forms
    $form = New-Object System.Windows.Forms.Form
    $form.TopMost = $true
    $form.StartPosition = "Manual"
    $form.Size = '1,1'
    $form.Location = '0,0'
    $form.Show()
    $form.Hide()

    $Result =  [System.Windows.Forms.MessageBox]::Show($Form, $Message, $Title, $Buttons, [System.Windows.Forms.MessageBoxIcon]::$Icon)

    $form.Dispose()
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
        [string]$DialogueTitle = "CAA Compliance Scan"
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

function Get-LoggedInUser {
    $SessionLine = (quser 2>$null | Where-Object { $_ -match ">" })
    if ($SessionLine) {
        # Remove leading '>' and extra spaces
        $SessionLine = $SessionLine -replace '^>\s*', ''       
        $Columns = $SessionLine -replace '\s{2,}', ',' -split ','

        return $columns[0]
    }
    return $null
}

#endregion

Set-Content -Path $LogFilePath -Encoding Unicode -Value "
##########################################################################
#                                                                        #
#                         CAA-ComplianceScan.ps1                         #
#                                                                        #
##########################################################################
"

#====================================================================================================#
#                                      [ Windows Build Check ]                                       #
#====================================================================================================#
$WindowsBuild = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion").CurrentBuildNumber
$DisplayVersion = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion").DisplayVersion

$MatchingRequirement = $Variables.BuildRequirements |
Where-Object { $WindowsBuild -ge $_.MinBuild -and ($_.MaxBuild -eq $null -or $WindowsBuild -le $_.MaxBuild) } |
Sort-Object MinBuild -Descending |
Select-Object -First 1

if ($null -eq $MatchingRequirement) {
    Write-Message -Message "Windows build $($DisplayVersion) is not compliant" -Level "WARN"
    $Summary += "Windows build $($DisplayVersion) is not compliant"
} 
else {
    Write-Message -Message "Windows is compliant with $($MatchingRequirement.Label) (Build $WindowsBuild)" -Level "INFO"
}

#====================================================================================================#
#                                      [ Chrome Version Check ]                                      #
#====================================================================================================#
$ChromeVersion = (Get-Package | Where-Object { $_.Name -like "*Google Chrome*" }).Version 

if ($ChromeVersion -lt $Variables.ChromeVersion) {
    Write-Message -Message "Chrome is not compliant" -Level "WARN"
    $Summary += "Chrome version $ChromeVersion is below the minimum requirement"
}
else {
    Write-Message -Message "Chrome is compliant with version $($ChromeVersion)" -Level "INFO"
}

#====================================================================================================#
#                             [ Endpoint Verification Extension Check ]                              #
#====================================================================================================#
$CurrentUser = Get-LoggedInUser
$ChromeProfiles = Get-ChildItem -Path "C:\Users\$CurrentUser\AppData\Local\Google\Chrome\User Data" -Directory | Where-Object { $_.Name -eq "Default" -or $_.Name -match "^Profile \d+$" }
$EVExtension = @()

foreach ($ChromeProfile in $ChromeProfiles) {
    $ExtensionsFolder = Get-ChildItem -Path $ChromeProfile.FullName | Where-Object { $_.Name -eq "Extensions" }
    if ($ExtensionsFolder) {
        $ExtensionsPath = Get-ChildItem -Path $ExtensionsFolder.FullName | Where-Object { $_.Name -eq $Variables.ExtensionID}
        if ($ExtensionsPath){
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

#====================================================================================================#
#                                     [ Firewall Status Check ]                                      #
#====================================================================================================#
$FirewallStatus = Get-NetFirewallProfile | Select-Object Name, Enabled

foreach ($NetProfile in $FirewallStatus) {
    if ($NetProfile.Enabled -eq $false) {
       Write-Message -Message "The $($NetProfile.Name) firewall profile is disabled" -Level "WARN"
       $Summary += "$($NetProfile.Name) firewall profile."
    }
    else {
        Write-Message -Message "Firewall $($NetProfile.Name) profile is enabled" -Level "INFO"
    }
}

#====================================================================================================#
#                               [ Endpoint Verification Helper Check ]                               #
#====================================================================================================#
$EVHelperApp = Get-Package | Where-Object { $_.Name -like "*Google Endpoint Verification*" }

if ($null -eq $EVHelperApp) {
    Write-Message -Message "Endpoint Verification Helper is not installed" -Level "WARN"
    $Summary += "Endpoint Verification Helper is not installed"
}
else {
    Write-Message -Message  "Endpoint Verification Helper is installed" -Level "INFO"
}

#====================================================================================================#
#                                       [ Compliance Summary ]                                       #
#====================================================================================================#
if ($Summary.Count -eq 0) {
    $Message = @"
    All checks passed. Your device is compliant.

    If you're still unable to access Gmail, try the following:

      1. Open Google Chrome and wait 2 minutes
      2. Open the Endpoint Verification extension
      3. Click 'SYNC NOW'
      4. Reload your Gmail tab
"@
    Show-MessageBox -Message $Message -Title "Information" -Icon "Information"
} 
else {
    $SummaryText = ($Summary | ForEach-Object { "    - $_" }) -join "`n"
    $Message = @"
    Your device is not compliant:

$SummaryText

Please address each issue and then run the Endpoint Verification sync to regain access.
"@
    Show-MessageBox -Message $Message -Title "Information" -Icon "Error"
}
