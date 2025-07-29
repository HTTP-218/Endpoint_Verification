# Google CAA Compliance Tool

This script will check if a device is compliant with the `Context-Aware Access` rules and will fix certain non-compliant parts

## Prerequisites

- The script must be run with **administrator privileges** to enable the built-in Administrator account on your system.
- The `ps1` file can only be run in Powershell 5 (Powershell 7 does not support the Get-Package cmdlet).

## Usage

### Option 1

Download the [.exe](https://github.com/2mmkolibri/Endpoint_Verification/releases/tag/v1.0.0) file and run it. This requires admin privileges to run.

You may see a warning from windows that the file was blocked. Click `More info` and then hit `Run Anyways`.

### Option 2

#### Step 1: Open PowerShell with Administrator Privileges

To run this script, you'll need to launch `PowerShell` or `Terminal` as an Administrator. Here are two ways to do that:

##### Method 1: Start Menu

1. Right-click on the `Start Menu` (Windows icon).
2. Select **`Windows PowerShell (Admin)`** (for Windows 10) or **`Terminal (Admin)`** (for Windows 11).

##### Method 2: Search and Launch

1. Press the `Windows key`.
2. Type `PowerShell` (for Windows 10) or `Terminal` (for Windows 11).
3. Press `Ctrl + Shift + Enter` or right-click the app and choose **`Run as administrator`** to launch it with administrator privileges.

#### Step 2: Run the Command

Once you have PowerShell or Terminal open with administrator privileges, copy and paste the following command into the window:

```powershell
 irm "https://raw.githubusercontent.com/2mmkolibri/Endpoint_Verification/feature/caa-compliance/CAA-ComplianceTool.ps1" | iex
```
Hit `Enter`

####  Step 3: Remediate

If Windows is not compliant, you will need to download the latest Windows ISO and upgrade your version. You can use [this](https://youtu.be/dofyWO7msDA?t=689) guide.

If Chrome is not compliant

1. Open `Google Chrome` and choose your work profile.
2. Locate and click `Extensions` (puzzle piece icon in the top right corner of Chrome).
3. Click the `Endpoint Verification` extension.
4. Click the `SYNC NOW` button.
5. Refresh your Gmail page and access should be granted.

## Troubleshooting

### Access Denied
If it throws an `Access Denied` error, after entering the admin credentials, then it's likely you ran the `ps1` file in a non-admin powershell session.

The app will still install, despite the error message. If you run the script again, it will tell you that the app is already installed. Proceed with the remaining steps listed above.
