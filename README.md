# Google Endpoint Verification Helper Installation Script

This script installs the `Google Endpoint Verification Helper` app on Windows devices. The helper app collects system information, such as OS version and antivirus status, which is then used by the `Endpoint Verification` Chrome Extension.

## Prerequisites

- The script must be run with **administrator privileges** to enable the built-in Administrator account on your system.
- This script is designed for **Windows** operating systems.

## Usage

### Step 1: Open PowerShell with Administrator Privileges

To run this script, you'll need to launch `PowerShell` or `Terminal` as an Administrator. Here are two ways to do that:

#### Method 1: Start Menu

1. Right-click on the `Start Menu` (Windows icon).
2. Select **`Windows PowerShell (Admin)`** (for Windows 10) or **`Terminal (Admin)`** (for Windows 11).

#### Method 2: Search and Launch

1. Press the `Windows key`.
2. Type `PowerShell` (for Windows 10) or `Terminal` (for Windows 11).
3. Press `Ctrl + Shift + Enter` or right-click the app and choose **`Run as administrator`** to launch it with administrator privileges.

### Step 2: Run the Command

Once you have PowerShell or Terminal open with administrator privileges, copy and paste the following command into the window:

```powershell
irm "https://raw.githubusercontent.com/2mmkolibri/Endpoint_Verification/main/Install-EVHelper.ps1" | iex
```
Hit `Enter` and a download should start shortly. Once the download popup has disappeared, follow the steps below:

### Step 3: Verify the Installation

1. Press the `Windows key`.
2. Type `Add or Remove Programs` and click the first option. This should take you to the Apps settings page.
3. Scroll down or search for `Google Endpoint Verification` to check that it has been installed.

###  Step 4: Run the Endpoint Verification Sync

Once you have confirmed that the helper app is installed, you will need to run the Endpoint Verification sync, to update your device's details on Google Workspace.
1. Open `Google Chrome` and choose your work profile.
2. Locate and click `Extensions` (puzzle piece icon in the top right corner of Chrome).
3. Click the `Endpoint Verification` extension.
4. Click the `SYNC NOW` button.
5. Refresh your Gmail page and access should be granted.

## Troubleshooting

### Credentials Window
If you see a credentials window, asking for your local admin username and password, then that means you have previously enabled the built-in Administrator account.

1. Enter `administator` for the username.
2. Enter the password you set for the account.

The script should then continue to the install stage. Proceed with `Step 3`.

### Access Denied
If it throws an `Access Denied` error, then you will need to install the helper app manually.

1. Log out of your user account
2. If you see an 'Administrator' account, log in to that account. If you only see `Other User`, click on this and log in with the username `.\administrator` and your password.
3. Download the [Endpoint Verification Helper](https://dl.google.com/dl/secureconnect/install/win/EndpointVerification_admin.msi) app.
4. Run the `EndpointVerification_admin.msi` file.
