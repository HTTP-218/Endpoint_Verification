function Install-GoogleChrome {
    <#
    .SYNOPSIS
    Installs latest version of Google Chrome
    
    .DESCRIPTION
    Downloads and installs the latest stable version of Google Chrome
    #>

    $ChromeURL = "https://dl.google.com/tag/s/dl/chrome/install/googlechromestandaloneenterprise64.msi"
    $ChromePath = Join-Path $env:TEMP "googlechromestandaloneenterprise64.msi"
    
    Write-Message -Message "Checking if Chrome MSI file is present..." -Level "INFO"

    if (!(Test-Path $ChromePath)) {

        Write-Message -Message "MSI file is missing, downloading Google Chrome MSI file. This may take a few minutes..." -Level "INFO"
        try {
            Invoke-WebRequest $ChromeURL -outfile $ChromePath
            Write-Message -Message "Downloaded Google Chrome MSI file" -Level "NOTICE"
        }
        catch {
            Write-Message -Message "Failed to download Google Chrome MSI file`n`n$($_.Exception.Message)" -Level "ERROR" -Dialogue $true
            exit 1
        }    
    }
    else {
        Write-Message -Message "Chrome MSI file has already been downloaded" -Level "INFO"
    }

    Write-Message -Message "Installing Google Chrome..." -Level "INFO"
    try {
        Start-Process -FilePath "msiexec.exe" -ArgumentList "/i `"$ChromePath`"" -wait
        Write-Message -Message "Google Chrome has been installed" -Level "NOTICE" -Dialogue $true -ForegroundColor Green
    }
    catch {
        Write-Message -Message "Failed to install Google Chrome`n`n$($_.Exception.Message)" -Level "ERROR" -Dialogue $true
        exit 1
    }

    # Fresh install doesn't have User Data directory until Chrome is opened. This will prevent EV extension check from failing.
    Write-Message -Message "Launching Google Chrome to create User Data directory..." -Level "INFO"
    try {    
        Start-Process -FilePath "C:\Program Files\Google\Chrome\Application\chrome.exe" --silent-launch
    }
    catch {
        Write-Message -Message "Failed to launch Google Chrome`n`n$($_.Exception.Message)" -Level "ERROR" -Dialogue $true
        exit 1
    }

    Write-Message -Message  "Deleting Chrome MSI file..." -Level "INFO"
    try {    
        Remove-Item $ChromePath -Force
        Write-Message -Message  "Chrome MSI file deleted" -Level "NOTICE"
    }
    catch {
        Write-Message -Message  "Failed to delete Chrome MSI file: $($_.Exception.Message)" -Level "WARN"
    }    
}

function Update-GoogleChrome {
    <#
    .SYNOPSIS
    Updates Google Chrome to the latest version
    
    .DESCRIPTION
    Updates Google Chrome using Winget. It will test if Winget works before attempting to update Chrome.
    
    .NOTES
    Winget test is not perfect and is likely to fail on older Windows builds that shipped with an older Winget package. 
    Users are instructed to update chrome manually via settings.
    #>

    # Check if Winget is working
    try {
        $null = & winget --version 2>$null
        $WingetInstalled = $true
    }
    catch {
        $WingetInstalled = $false
    }
    
    if ($WingetInstalled -eq $true) { 
        Write-Message -Message "Updating Chrome to the latest version..." -Level INFO

        try {
            & winget upgrade --id Google.Chrome --silent --accept-source-agreements --accept-package-agreements
            Write-Message -Message "Google Chrome successfully updated" -Level "NOTICE" -Dialogue $true
        }
        catch {
            Write-Message -Message "Failed to update Chrome`n`n$($_.Exception.Message)" -Level "ERROR" -Dialogue $true
        }
    }
    else {
        Write-Message -Message "Winget is unavailable on this system. Chrome upgrade skipped." -Level "WARN" -Dialogue $true
    }
}

function Enable-FirewallProfiles {
    <#
    .SYNOPSIS
    Enables Windows Firewall profiles
    
    .DESCRIPTION
    Enables all Windows Firewalll profiles on the system. 
    For Home editions this is limited to Public and Private, while Pro/Ent editions include Domain as well.
    
    .PARAMETER Profiles
    This value should be 'Public' 'Private', and or 'Domain'. This is currently pulled from CAA-Scan using the Get-NetFirewallProfile cmdlet
    #>

    param (
        [Parameter(Mandatory = $true)]
        [string[]]$Profiles
    )

    foreach ($ProfileName in $Profiles) {
        try {
            Set-NetFirewallProfile -Name $ProfileName -Enabled True
            Write-Message -Message "$ProfileName firewall profile has been enabled" -Level "NOTICE" -Dialogue $true -ForegroundColor Green
        }
        catch {
            Write-Message -Message "Failed to enable the $ProfileName firewall profile`n`n$($_.Exception.Message)" -Level "ERROR" -Dialogue $true
            throw
        }
    }
}


function Install-EVHelperApp {
    <#
    .SYNOPSIS
    Installs the Endpoint Verification Helper app
    
    .DESCRIPTION
    Installs Google's Endpoint Verification app, which is used to collect and push device information to the endpoint Verification extension. 
    This includes installed hotfixes, firewall status, antivirus status.
    The app can only be installed using Windows' built-in Administrator account
    
    .NOTES
    This function will NOT work on corporate devices with locked down permissions. MSIExec will return status code 1619.
    #>

    $EVHelperPath = Join-Path $env:TEMP "EndpointVerification_admin.msi"
    $EVHelperURL = 'https://dl.google.com/dl/secureconnect/install/win/EndpointVerification_admin.msi'

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
    Write-Message -Message "Checking if builtin administrator account is enabled..." -Level "INFO"
    $BuiltinAdmin = Get-LocalUser -Name "Administrator"   

    $AdminCred = $null

    if ($BuiltinAdmin.Enabled) {
        Write-Message -Message "Built-in Administrator account is already enabled." -Level "INFO"
    
        # Prompt for credentials to use existing password
        Write-Message -Message "Prompting for builtin administrator credentials..." -Level "INFO"
        $AdminCred = Get-Credential -UserName "Administrator" -Message "Enter the existing local Administrator credentials."
    
        if ($null -eq $AdminCred) {
            Write-Message -Message "Username or Password cannot be empty.`n`nPlease enter the admin credentials to continue." -Level "ERROR" -Dialogue $true
            exit 1
         }

         Write-Message -Message "Using provided Administrator credentials." -Level "NOTICE"
    }
    else {
        Write-Message -Message "Built-in Administrator account is disabled." -Level "WARN"

        $UserResponse = Show-MessageBox -Message "The built-in Administrator account is disabled.`n`nTo continue, it must be enabled and a new password set.`n`n Would you like to proceed?" `
        -Title "Enable Administrator Account" -Icon "Question" -Buttons ([System.Windows.Forms.MessageBoxButtons]::YesNo)

        if ($UserResponse -ne [System.Windows.Forms.DialogResult]::Yes) {
            Write-Message -Message "User cancelled enabling Administrator account." -Level "NOTICE"
            exit 1
        }
        else {
            $AdminCred = Get-Credential -UserName "Administrator" -Message "Enter a new password for the account."
        }

        try {
            Enable-LocalUser -Name "Administrator"
            Write-Message -Message "Builtin administrator account enabled" -Level "NOTICE"

            if ($null -eq $AdminCred) {
                Write-Message -Message "Password not provided. Aborting." -Level "ERROR" -Dialogue $true
                Disable-LocalUser -Name "Administrator"
                exit 1
            }
            else {
                Set-LocalUser -Name "Administrator" -Password $AdminCred.Password
                Write-Message -Message "Administrator password updated" -Level "NOTICE"
            }

            $SetByScript = 1
        }
        catch {
            Write-Message -Message "Failed to activate builtin administrator account`n`n$($_.Exception.Message)" -Level "ERROR" -Dialogue $true
            exit 1
        }
    }

    Write-Message -Message  "Installing Endpoint Verification Helper..." -Level "INFO"

    try {
        $Process = Start-Process -FilePath "msiexec.exe" -ArgumentList "/i", "`"$EVHelperPath`"", "/qn", "/norestart" -Credential $AdminCred -Wait -PassThru

        if ($Process.ExitCode -eq 0) {
            Write-Message -Message "Endpoint Verification Helper installed successfully." -Level "NOTICE" -ForegroundColor Green
        }
        else {
            Write-Message -Message "Installation failed!`n`n`MSI exit code: $($Process.ExitCode)`n`nThis is likely due to security policies enforced on this device." -Level "ERROR" -Dialogue $true
            Write-Message -Message "Please visit this page for troubleshooting steps:`n`nhttps://github.com/HTTP-218/Endpoint_Verification?tab=readme-ov-file#troubleshooting" -Level "ERROR" -Dialogue $true
            exit 1
        }
    }
    catch {
        Write-Message -Message  "Failed to start MSI installation process:`n`n$($_.Exception.Message)" -Level "ERROR" -Dialogue $true
        exit 1
    }

    Write-Message -Message  "Deleting MSI file..." -Level "INFO"
    try {                       
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

    Write-Message -Message "Google Endpoint Verification has been installed" -Level "NOTICE" -Dialogue $true -ForegroundColor Green
}