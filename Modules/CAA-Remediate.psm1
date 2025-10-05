function Install-GoogleChrome {

    $ChromeURL = "https://dl.google.com/tag/s/dl/chrome/install/googlechromestandaloneenterprise64.msi"
    $ChromePath = "C:\Windows\Temp\googlechromestandaloneenterprise64.msi"
    
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
        Write-Message -Message "Google Chrome has been installed" -Level "NOTICE" -Dialogue $true
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

function Enable-FirewallProfiles {
    param (
        [Parameter(Mandatory = $true)]
        [string[]]$Profiles
    )

    foreach ($ProfileName in $Profiles) {
        try {
            Set-NetFirewallProfile -Name $ProfileName -Enabled True
            Write-Message -Message "$ProfileName firewall profile has been enabled" -Level "NOTICE" -Dialogue $true
        }
        catch {
            Write-Message -Message "Failed to enable the $ProfileName firewall profile`n`n$($_.Exception.Message)" -Level "ERROR" -Dialogue $true
            throw
        }
    }
}


function Install-EVHelperApp {

    $EVHelperPath = "C:\Windows\Temp\EndpointVerification_admin.msi"
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

    Write-Message -Message "Google Endpoint Verification has been installed" -Level "NOTICE" -Dialogue $true 
}