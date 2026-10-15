# Dubai Artists - Automation Scripts

This folder contains shell automation scripts for continuous delivery and platform deployments.

---

## 📜 Available Scripts

### 1. `deploy_testflight.sh`
Automates building and uploading the iOS release binary to Apple TestFlight:
```bash
bash scripts/deploy_testflight.sh
```
- Fetches Flutter packages.
- Compiles the release `.ipa` bundle.
- Deploys to TestFlight using Fastlane / App Store Connect API keys.

### 2. `publish_appstore.sh`
Promotes and distributes a validated build to the production Apple App Store:
```bash
bash scripts/publish_appstore.sh
```
- Performs version validation.
- Submits IPA to App Store Connect for final app review.

---

## ⚙️ Environment Prerequisites
- macOS terminal environment with `bash` or `zsh`.
- Fastlane installed (`gem install fastlane` or `brew install fastlane`).
- `APP_STORE_CONNECT_API_KEY_KEY_ID`, `APP_STORE_CONNECT_API_KEY_ISSUER_ID`, and Apple Private Key (`.p8`) configured.
