# CAA Compliance Tool for Google Workspace

This PowerShell-based utility checks, and optionally fixes, your Windows device for compliance with Google Context-Aware Access (CAA) policies

## Prerequisites

- The script must be run with **administrator privileges** (unless you use the -ScanOnly switch) to enable the built-in Administrator account on your system.
- The `ps1` file is compatible with Powershell 5 (Powershell 7+ is not supported due to `Get-Package` limitations).

## Usage

### **Option 1: Run Prebuilt Executable (Recommended)**

1. Download the latest `CAA-Tool.exe` file from the [Releases Page](https://github.com/2mmkolibri/Endpoint_Verification/releases/tag/v3.0.0)
2. Double-click to run the file. You will be prompted for the administrator credentials.
3. If prompted with a security warning:
   - Click `More info`
   - Then click `Run anyway`

```fix
NOTE: If you are running a 3rd party Antivirus, disable it and run the script again. The AV will incorrectly identify the exe as malware
```

### **Option 2: Run Script Manually**

### Step 1: Open PowerShell with Administrator Privileges

To run this script, you'll need to launch `PowerShell` or `Terminal` as an Administrator. Here are two ways to do that:

**Method 1: Start Menu**

1. Right-click on the `Start Menu` (Windows icon).
2. Select **`Windows PowerShell (Admin)`** (for Windows 10) or **`Terminal (Admin)`** (for Windows 11).

**Method 2: Search and Launch**

1. Press the `Windows key`.
2. Type `PowerShell` (for Windows 10 or 11) or `Terminal` (for Windows 11).
3. Press `Ctrl + Shift + Enter` or right-click the app and choose **`Run as administrator`** to launch it with administrator privileges.

### Step 2: Download and Run Script

Once you have PowerShell or Terminal open with administrator privileges, copy and paste the following command into the window (Choose **one**):

**Full Tool**
```powershell
iex "(irm 'https://raw.githubusercontent.com/2mmkolibri/Endpoint_Verification/main/CAA-Tool.ps1')
```

Alternatively, if you just want to run the scan, pass the `-ScanOnly` switch

**Scan Only**
```powershell
iex "(irm 'https://raw.githubusercontent.com/2mmkolibri/Endpoint_Verification/main/CAA-Tool.ps1') -ScanOnly"
```

Hit `Enter` to run the command

###  Step 3: Fix Compliance Issues

- If Windows is not compliant, you will need to download the latest Windows ISO and upgrade your version. You can use [this YouTube guide](https://youtu.be/dofyWO7msDA?t=689).
- If Chrome is not compliant, open a new tab and go to [chrome://settings/help](chrome://settings/help). Chrome will check for updates and will prompt you to relaunch the browser to apply them.
- If the Endpoint Verification extension is missing, install it from [here](https://chromewebstore.google.com/detail/endpoint-verification/callobklhcbilhphinckomhgkigmfocg).

Run the `ps1` or `exe` file again to check that everything is compliant.

### Step 4: Sync Device Details

1. Open `Google Chrome` and choose your work profile.
2. Locate and click `Extensions` (puzzle piece icon in the top right corner of Chrome).
3. Click the `Endpoint Verification` extension.
4. Click the `SYNC NOW` button.
5. Refresh your Gmail page and access should be granted.

## Troubleshooting

### Access Denied
If it throws an `Access Denied` error, while installing the MSI file, then it's likely you ran the `ps1` file in a non-admin powershell session.

Even if an error appears, the Helper app usually installs successfully. If you run the script again, it will tell you that the app is already installed. Proceed with the remaining steps listed above.

### Unknown Errors
If the script encounters any unexpected errors, check `C:\Windows\Temp\CAA-Tool.log` for a  

## Attribution

Icons provided by [FlatIcon](https://www.flaticon.com/)

<a href="https://www.flaticon.com/free-icons/computer" title="computer icons">Computer icons created by Maxim Basinski Premium - Flaticon</a>

<a href="https://www.flaticon.com/free-icons/magnifying-glass" title="magnifying glass icons">Magnifying glass icons created by Freepik - Flaticon</a>

<a href="https://www.flaticon.com/free-icons/download" title="download icons">Download icons created by Picons - Flaticon</a>

<a href="https://www.flaticon.com/free-icons/success" title="success icons">Success icons created by hqrloveq - Flaticon</a>