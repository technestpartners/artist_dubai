# Dubai Artists - Binary Releases & Distribution

This directory archives compiled distribution artifacts for testing and store submission.

---

## 📦 Directory Structure

```
releases/
├── v3.2.5/
│   └── artist_dubai.apk        # Android Release APK (Build version 12)
└── README.md                   # Release documentation & archive registry
```

---

## 🏷️ Release Versioning Scheme

Versions follow Semantic Versioning (`MAJOR.MINOR.PATCH`) accompanied by a platform-specific Build Number:
- **Android Version**: `versionName: 3.2.5`, `versionCode: 12`
- **iOS Version**: `CFBundleShortVersionString: 3.2.5`, `CFBundleVersion: 1`

---

## 📲 Building New Releases

To produce new binaries:

### Android APK:
```bash
flutter build apk --release
# Outputs to: build/app/outputs/flutter-apk/app-release.apk
```

### Android App Bundle (Google Play Store):
```bash
flutter build appbundle --release
# Outputs to: build/app/outputs/bundle/release/app-release.aab
```

### iOS IPA (App Store / TestFlight):
```bash
flutter build ipa --release --export-options-plist=ios/ExportOptions.plist
# Outputs to: build/ios/ipa/
```
