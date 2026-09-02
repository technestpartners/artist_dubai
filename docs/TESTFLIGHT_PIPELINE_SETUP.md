# TestFlight & App Store Deployment Pipeline Setup

This repository is configured with automated pipelines using **GitHub Actions** and **Fastlane** to build and upload the Flutter iOS app to **Apple TestFlight** and the **App Store**.

---

## 1. App Details
- **Bundle ID**: `com.imbu.Dubai-Artists`
- **Team ID**: `VDL4YWPJJ2`
- **Export Options**: `ios/ExportOptions.plist`
- **Fastlane Config**: `ios/fastlane/Fastfile` & `ios/fastlane/Appfile`
- **GitHub Workflow**: `.github/workflows/deploy_testflight.yml`

---

## 2. GitHub Secrets Configuration

To enable the GitHub Actions workflow, navigate to your repository on GitHub:
👉 **Settings** -> **Secrets and variables** -> **Actions** -> **New repository secret**

Add the following secrets:

| Secret Name | Description | Example / How to generate |
| :--- | :--- | :--- |
| `APP_STORE_CONNECT_KEY_ID` | Key ID of your App Store Connect API Key | e.g. `2X9R4HX436` |
| `APP_STORE_CONNECT_ISSUER_ID` | Issuer ID from App Store Connect Keys page | e.g. `69a6de70-xxxx-xxxx-xxxx-xxxxxxxxxxxx` |
| `APP_STORE_CONNECT_API_KEY_BASE64` | Base64-encoded content of your `AuthKey_XXXXXX.p8` file | `base64 -i AuthKey_XXXXXX.p8 \| pbcopy` |
| `APPLE_CERTIFICATE_BASE64` | Base64-encoded `.p12` Distribution Certificate | `base64 -i distribution.p12 \| pbcopy` |
| `APPLE_CERTIFICATE_PASSWORD` | Password used when exporting the `.p12` certificate | e.g. `YourSecretPassword123` |
| `APPLE_PROVISIONING_PROFILE_BASE64` | Base64-encoded `.mobileprovision` App Store profile | `base64 -i DubaiArtists_AppStore.mobileprovision \| pbcopy` |

---

## 3. How to Generate Required Apple Credentials

### A. App Store Connect API Key (Recommended)
1. Go to [App Store Connect -> Users and Access -> Integrations -> App Store Connect API](https://appstoreconnect.apple.com/access/integrations/api).
2. Click **+** (Generate API Key).
3. Name it (e.g., `GitHub Actions CI`) and set Access to **App Manager** or **Admin**.
4. Note down the **Key ID** and **Issuer ID**.
5. Download the `.p8` file (Note: Apple only lets you download it once).
6. Convert to base64:
   ```bash
   base64 -i AuthKey_<KEY_ID>.p8 | pbcopy
   ```
   Paste this value into the `APP_STORE_CONNECT_API_KEY_BASE64` secret.

### B. Distribution Certificate (.p12)
1. Open **Keychain Access** on your Mac.
2. In the "login" or "Local Items" keychain, find **Apple Distribution: ... (VDL4YWPJJ2)**.
3. Expand it to ensure the private key is included, right-click, and choose **Export "..."**.
4. Choose `.p12` format and set a strong password.
5. Convert to base64:
   ```bash
   base64 -i certificates.p12 | pbcopy
   ```
   Paste into `APPLE_CERTIFICATE_BASE64`, and save the password in `APPLE_CERTIFICATE_PASSWORD`.

### C. App Store Provisioning Profile
1. Go to [Apple Developer Portal -> Profiles](https://developer.apple.com/account/resources/profiles/list).
2. Create or download an **App Store Distribution Profile** for `com.imbu.Dubai-Artists`.
3. Convert to base64:
   ```bash
   base64 -i DubaiArtists.mobileprovision | pbcopy
   ```
   Paste into `APPLE_PROVISIONING_PROFILE_BASE64`.

---

## 4. Triggering Deployments

### Option A: Manual Trigger via GitHub Actions (On Demand)
1. Go to your repository on GitHub -> **Actions** tab.
2. Select **Deploy to TestFlight** in the left sidebar.
3. Click **Run workflow**, enter optional changelog notes, and click **Run workflow**.

### Option B: Automatic Deployment via Git Release Tag
Push any semantic version tag matching `v*.*.*`:
```bash
git tag v1.0.1
git push origin v1.0.1
```
The workflow will automatically build and deploy the version to TestFlight.

### Option C: Local Deployment from macOS Terminal
You can also run the deployment script directly from your Mac:
```bash
# Set your API Key in environment or let fastlane prompt
export APP_STORE_CONNECT_API_KEY_KEY_ID="YOUR_KEY_ID"
export APP_STORE_CONNECT_API_KEY_ISSUER_ID="YOUR_ISSUER_ID"
export APP_STORE_CONNECT_API_KEY_PATH="/path/to/AuthKey_XXXXXX.p8"

./scripts/deploy_testflight.sh
```
Or directly using fastlane:
```bash
cd ios
bundle exec fastlane beta
```
