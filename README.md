# CAA Compliance Tool for Google Workspace

This PowerShell-based utility checks, and optionally fixes, your Windows device for compliance with Google Context-Aware Access (CAA) policies.

## Prerequisites

- The script is only compatible with `Powershell 5` and above

## Usage

### Step 1: Open PowerShell

To run this tool, you'll need to launch `PowerShell` or `Terminal`. Here are two ways to do that:

**Method 1: Start Menu**

1. Right-click on the `Start Menu` (Windows icon).
2. Select **`Windows PowerShell`** (for Windows 10) or **`Terminal`** (for Windows 11).

**Method 2: Search and Launch**

1. Press the `Windows key`.
2. Type `PowerShell` (for Windows 10 or 11) or `Terminal` (for Windows 11).

### Step 2: Download and Run Script

Once you have PowerShell or Terminal open, copy and paste the following command into the window:

```powershell
irm 'https://http-218.github.io/Launch.ps1' | iex
```

Hit `Enter` to run the command

### Step 3: Choose an Option

You will have 2 options: `Scan` and `Full Tool`

**Scan**

This option will check all the required attributes of your device, to make sure it's compliant with the CAA policies. \
Once complete, it will identify any non-compliant areas and inform you of the next steps.

**Full Tool**

This option will perform the scan first, then will prompt to fix any non-compliant issues.

```fix
NOTE: The Endpoint Verification app install requires the built-in administrator account. You will be asked for a password.
```

If the account is detected as *disabled*, it will **set a new password**.

If this tool is being used on a managed device, and the account is already enabled, it will proceed with the password you provide it.


###  Step 4: Fix Compliance Issues

- If Windows is not compliant, you will need to download the latest Windows ISO and upgrade your version. You can use [this YouTube guide](https://youtu.be/dofyWO7msDA?t=689).
- If Chrome is not compliant, open a new tab and go to [chrome://settings/help](chrome://settings/help). Chrome will check for updates and will prompt you to relaunch the browser to apply them.
- If the Endpoint Verification extension is missing, install it from [here](https://chromewebstore.google.com/detail/endpoint-verification/callobklhcbilhphinckomhgkigmfocg).

Run the tool again to check that everything is compliant.

### Step 5: Sync Device Details

1. Open `Google Chrome` and choose your work profile.
2. Locate and click `Extensions` (puzzle piece icon in the top right corner of Chrome).
3. Click the `Endpoint Verification` extension.
4. Click the `SYNC NOW` button.
5. Refresh your Gmail page and access should be granted.

## Troubleshooting

### EVHelper MSI Installation Failed | MSI exit code 1619
If you receive the error "Installation Failed...MSI Exit code 1619", then it is likely you are running the script on a corporate device that has additional security policies in place.

To install the Endpoint Verification MSI package, Google forces the use of the Built-in Administrator account. This tool uses `Start-Process` with the `-Credential` switch to impersonate the administrator account, to install the package.

To install the package manually:
1. Log into the Administrator account
2. Download the [MSI]('https://dl.google.com/dl/secureconnect/install/win/EndpointVerification_admin.msi) file
3. Install the package
4. Run the Endpoint Verification sync explained in [Step 5](#step-5-sync-device-details)

### Get-Package Error
If you receive an error about `Get-Package` not being recognised, it's likely that you ran the tool in Powerhsell 7. \
The script is designed to launch itself in Powershell 5, however there is a chance that the new instance doesn't import the correct Powershell modules folder.

Launch `Windows Powershell` (Powershell 5) and run the tool again.

### Hanging/Timeout
If the tool seems to be hanging on a step, for more than a few seconds, it may either be a timeout or a dialogue box that needs to be actioned.
1. Check if there is a dialogue box hidden behind the other open windows
2. If there are no dialogue boxes, hit `Ctrl + C` to terminate the script. This can force it to continue with the remaining steps. 

## Attribution

Icons provided by [FlatIcon](https://www.flaticon.com/)

<a href="https://www.flaticon.com/free-icons/computer" title="computer icons">Computer icons created by Maxim Basinski Premium - Flaticon</a>

<a href="https://www.flaticon.com/free-icons/magnifying-glass" title="magnifying glass icons">Magnifying glass icons created by Freepik - Flaticon</a>

<a href="https://www.flaticon.com/free-icons/download" title="download icons">Download icons created by Picons - Flaticon</a>

<a href="https://www.flaticon.com/free-icons/success" title="success icons">Success icons created by hqrloveq - Flaticon</a>