# Apple App Store & TestFlight Deployment Guide

This guide covers building, signing, and releasing the **Dubai Artists** Flutter iOS application to Apple TestFlight and the App Store.

---

## 🛠️ Automated Workflows

The repository includes both CI/CD and CLI pipelines:

1. **Codemagic CI**:
   - Configuration: `codemagic.yaml`
   - Triggered on tag or manual release trigger.
   - Automatically signs IPA, runs CocoaPods, and submits to App Store Connect.

2. **GitHub Actions**:
   - `.github/workflows/deploy_testflight.yml`: Builds iOS and uploads build to TestFlight.
   - `.github/workflows/deploy_appstore.yml`: Promotes TestFlight builds to production App Store submission.

3. **Shell Automation**:
   - `scripts/deploy_testflight.sh`: Local automated build & Fastlane upload.
   - `scripts/publish_appstore.sh`: App Store release distribution.

---

## 📱 Manual Build & Release Instructions

### Prerequisites
- macOS machine with Xcode 15+ installed
- CocoaPods (`pod install`)
- Valid Apple Developer Account with distribution certificates and provisioning profiles

### Build IPA
```bash
# Clean and fetch dependencies
flutter clean
flutter pub get

# Build iOS Release IPA
flutter build ipa --release --export-options-plist=ios/ExportOptions.plist
```

Output binary will be generated at:
`build/ios/ipa/Dubai Artists.ipa`
