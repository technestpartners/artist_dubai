# Apple Xcode, TestFlight & App Store Deployment Pipeline Setup

This repository is configured with two complete automated pipelines to build and deploy the Flutter iOS app to **Apple Xcode**, **TestFlight**, and the **App Store**:

1. **Option A: Apple Xcode Cloud Native Pipeline** *(Integrated directly into Xcode IDE)*
2. **Option B: GitHub Actions + Fastlane Pipeline** *(Automated CI on GitHub)*
3. **Option C: Local macOS Terminal Deployment** *(Direct upload from Mac)*

---

## 1. App Identifiers & Project Configuration
- **App Name**: Dubai Artists
- **Bundle ID**: `com.imbu.Dubai-Artists`
- **Apple Developer Team ID**: `VDL4YWPJJ2`
- **Xcode Project**: `ios/Runner.xcworkspace`
- **Xcode Cloud Scripts**: `ios/ci_scripts/ci_post_clone.sh`
- **Export Options**: `ios/ExportOptions.plist`
- **Fastlane Config**: `ios/fastlane/Fastfile` & `ios/fastlane/Appfile`
- **GitHub Workflows**:
  - `.github/workflows/deploy_testflight.yml` (TestFlight Beta)
  - `.github/workflows/deploy_appstore.yml` (Production App Store)

---

## Option A: Apple Xcode Cloud Pipeline (Direct from Xcode IDE)

Apple's **Xcode Cloud** builds your app directly on Apple's cloud infrastructure and delivers builds straight into **Xcode Organizer**, **TestFlight**, and **App Store Connect**.

### Why Xcode Cloud?
- **Zero manual certificate or provisioning management**: Apple handles code signing automatically with your Developer account.
- **Direct Xcode Integration**: View build status, crash reports, and test results right inside Xcode's Report Navigator and Organizer.
- **Preconfigured in this repository**: The required `ios/ci_scripts/ci_post_clone.sh` script is already added and executable.

### Step-by-Step Activation in Xcode:
1. Open `ios/Runner.xcworkspace` in **Xcode** on your Mac.
2. In the top menu bar, click **Integrate** -> **Create Workflow...** (or click the Xcode Cloud tab in the Report Navigator `⌘ + 9`).
3. Select the **Runner** product and choose a workflow template (e.g., *TestFlight Internal Testing*).
4. Review the workflow settings:
   - **Branch**: Set to `main` (trigger on push or pull request).
   - **Environment**: macOS with latest Xcode 15/16.
   - **Action**: **Archive** (for iOS).
   - **Post-Action**: Add **TestFlight (Internal Testing)** to automatically distribute to your testers.
5. Click **Save** and click **Start Build**.
6. **How it executes**:
   - Xcode Cloud clones your repository.
   - It runs `ios/ci_scripts/ci_post_clone.sh` to install Flutter, pre-cache iOS tools, run `flutter pub get`, and run `pod install`.
   - Xcode Cloud builds the archive, signs it, and distributes it to TestFlight!
   - Builds appear in Xcode's **Organizer** (`Window -> Organizer -> Archives`).

---

## Option B: GitHub Actions CI/CD Pipeline

If your team prefers automated builds triggered on GitHub:

### 1. Required GitHub Secrets
In your GitHub repository, go to:
👉 **Settings** -> **Secrets and variables** -> **Actions** -> **New repository secret**

Add these 6 secrets:

| Secret Name | Description | How to generate |
| :--- | :--- | :--- |
| `APP_STORE_CONNECT_KEY_ID` | Key ID of App Store Connect API Key | e.g. `2X9R4HX436` |
| `APP_STORE_CONNECT_ISSUER_ID` | Issuer ID from App Store Connect | e.g. `69a6de70-xxxx-xxxx-xxxx-xxxxxxxxxxxx` |
| `APP_STORE_CONNECT_API_KEY_BASE64` | Base64 content of `AuthKey_XXXXXX.p8` | `base64 -i AuthKey_XXXXXX.p8 \| pbcopy` |
| `APPLE_CERTIFICATE_BASE64` | Base64-encoded `.p12` Distribution Certificate | `base64 -i distribution.p12 \| pbcopy` |
| `APPLE_CERTIFICATE_PASSWORD` | Password used when exporting `.p12` | e.g. `YourSecretPassword123` |
| `APPLE_PROVISIONING_PROFILE_BASE64` | Base64-encoded `.mobileprovision` App Store profile | `base64 -i DubaiArtists.mobileprovision \| pbcopy` |

### 2. How to Generate Required Apple Credentials

#### A. App Store Connect API Key
1. Go to [App Store Connect -> Users and Access -> Integrations -> App Store Connect API](https://appstoreconnect.apple.com/access/integrations/api).
2. Click **+** (Generate API Key).
3. Name it `GitHub Actions CI` and set role to **App Manager** or **Admin**.
4. Note down the **Key ID** and **Issuer ID**.
5. Download the `.p8` file.
6. Base64 encode:
   ```bash
   base64 -i AuthKey_<KEY_ID>.p8 | pbcopy
   ```
   Paste into `APP_STORE_CONNECT_API_KEY_BASE64`.

#### B. Distribution Certificate (.p12)
1. Open **Keychain Access** on your Mac.
2. Under "login" / "My Certificates", locate **Apple Distribution: ... (VDL4YWPJJ2)**.
3. Expand to ensure private key is attached, right-click, and select **Export "..."**.
4. Select `.p12` format and enter an export password.
5. Base64 encode:
   ```bash
   base64 -i certificates.p12 | pbcopy
   ```
   Paste into `APPLE_CERTIFICATE_BASE64`, and export password in `APPLE_CERTIFICATE_PASSWORD`.

#### C. Provisioning Profile (.mobileprovision)
1. Go to [Apple Developer Portal -> Profiles](https://developer.apple.com/account/resources/profiles/list).
2. Create or download the **App Store Distribution Profile** for `com.imbu.Dubai-Artists`.
3. Base64 encode:
   ```bash
   base64 -i DubaiArtists.mobileprovision | pbcopy
   ```
   Paste into `APPLE_PROVISIONING_PROFILE_BASE64`.

### 3. Triggering GitHub Deployments

#### Method 1: Manual Run (GitHub Web UI)
1. In your GitHub repository, open the **Actions** tab.
2. Select **Deploy to TestFlight** or **Publish to App Store (Production)**.
3. Click **Run workflow** -> Enter build number or changelog -> Click **Run workflow**.

#### Method 2: Git Tag Release
Push any version tag:
```bash
git tag v3.2.5
git push origin v3.2.5
```
GitHub Actions will automatically build and publish to TestFlight.

---

## Option C: Local macOS Fastlane Deployment

If you are on a Mac with Flutter and Xcode installed:

```bash
# 1. Export your App Store Connect credentials
export APP_STORE_CONNECT_API_KEY_KEY_ID="YOUR_KEY_ID"
export APP_STORE_CONNECT_API_KEY_ISSUER_ID="YOUR_ISSUER_ID"
export APP_STORE_CONNECT_API_KEY_PATH="/path/to/AuthKey_XXXXXX.p8"

# 2. Run the deployment script
./scripts/deploy_testflight.sh

# Or directly via fastlane
cd ios
bundle exec fastlane beta
```
