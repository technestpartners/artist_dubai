# Dubai Artists (فنانو دبي)

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![PHP](https://img.shields.io/badge/PHP-8.2+-777BB4?logo=php&logoColor=white)](https://www.php.net)
[![MySQL](https://img.shields.io/badge/MySQL-8.0+-4479A1?logo=mysql&logoColor=white)](https://www.mysql.com)
[![iOS](https://img.shields.io/badge/iOS-12.0+-000000?logo=apple&logoColor=white)](https://developer.apple.com/ios/)
[![Android](https://img.shields.io/badge/Android-5.0+-3DDC84?logo=android&logoColor=white)](https://developer.android.com)

The flagship mobile and web application ecosystem for Dubai's vibrant artistic and cultural community. Built with **Flutter**, **PHP**, and **MySQL**, adhering to **Clean Architecture** principles.

---

## 📁 Project Directory Structure

```
artist_dubai/
├── .github/                      # CI/CD Workflows (GitHub Actions)
│   └── workflows/
│       ├── deploy_appstore.yml   # App Store production release workflow
│       └── deploy_testflight.yml # TestFlight automated build workflow
├── .vscode/                      # VS Code workspace & launch configurations
├── android/                      # Native Android project configuration
├── api/                          # PHP/MySQL REST API Backend (Hostinger deployment root)
│   ├── .htaccess                 # Routing, CORS, and security header rules
│   ├── api.php                   # Monolithic REST API endpoints controller
│   ├── uploads/                  # Protected media uploads folder
│   └── README.md                 # Backend documentation & configuration guide
├── assets/                       # Static app resources & media
│   ├── icons/                    # App & navigation SVG/PNG icons
│   ├── images/                   # High-res graphics, illustrations & banners
│   └── videos/                   # Intro & brand presentation videos
├── database/                     # Relational database schemas & migrations
│   ├── artist_dubai.sql          # Primary MySQL relational database schema
│   ├── .schema_provisioned       # Auto-provisioning flag
│   └── README.md                 # Database setup & schema guide
├── deploy/                       # Prepared deployment bundles
│   ├── hostinger/
│   │   └── artist_dubai_api_hostinger.zip # Hostinger deployment archive
│   └── README.md                 # Deployment archive registry
├── docs/                         # Project & Engineering Documentation
│   ├── architecture/
│   │   └── ARCHITECTURE.md       # Clean Architecture & Data Flow Guide
│   ├── deployment/
│   │   ├── TESTFLIGHT_PIPELINE_SETUP.md # TestFlight & Xcode Cloud guide
│   │   ├── APP_STORE_DEPLOYMENT.md      # App Store release guide
│   │   └── HOSTINGER_BACKEND_SETUP.md   # Hostinger deployment guide
│   ├── qa/                       # QA Reports, Security Audits & Assets
│   │   ├── BUG_AND_VULNERABILITY_AUDIT_REPORT.md
│   │   ├── QA_DOCUMENTATION_AND_TEST_REPORT.md
│   │   ├── reports/              # Full QA PDF and HTML audit reports
│   │   │   ├── Artist_Dubai_QA_Bug_and_Usability_Report.pdf
│   │   │   └── qa_bug_report.html
│   │   └── screenshots/          # Audit & regression screenshots
│   └── README.md                 # Documentation portal index
├── ios/                          # Native iOS project & Xcode configuration
├── lib/                          # Flutter Application Source Code (Clean Architecture)
│   ├── app/                      # Application navigation & route tables (GoRouter)
│   ├── core/                     # Shared services, network, constants, widgets
│   ├── features/                 # Modular business feature packages (Domain/Presentation)
│   ├── l10n/                     # Internationalization (English & Arabic ARB)
│   ├── main.dart                 # Application entrypoint
│   └── README.md                 # Flutter source architecture guide
├── releases/                     # Compiled binaries & release distribution artifacts
│   ├── v3.2.5/
│   │   └── artist_dubai.apk      # Compiled Android Release APK
│   └── README.md                 # Releases changelog & binary tracking guide
├── scripts/                      # Build & deployment helper shell scripts
│   ├── deploy_testflight.sh      # TestFlight deployment automation
│   ├── publish_appstore.sh       # App Store publication automation
│   └── README.md                 # Script reference and usage guide
├── test/                         # Comprehensive Flutter test suite (Unit, Widget, E2E)
│   └── README.md                 # Test suite documentation & execution instructions
├── uploads/                      # Local media upload folder (secured via .htaccess)
├── .gitignore                    # Git tracking ignore rules
├── .htaccess                     # Root web server routing (Laragon/Apache)
├── api.php                       # Local root API bootstrap / sync endpoint
├── codemagic.yaml                # Codemagic CI/CD pipeline
├── pubspec.yaml                  # Flutter package dependencies & assets manifest
└── README.md                     # Main Project Documentation & Architecture Handbook
```

---

## 🏛️ Application Architecture

The Flutter client uses a **Feature-Driven Clean Architecture** structure:

- **Presentation Layer** (`lib/features/*/presentation/`):
  Views, responsive layouts, feature-specific widgets, and interactive controllers.
- **Domain Layer** (`lib/features/*/domain/`):
  Immutable domain models, entity validation, and data serialization.
- **Core Layer** (`lib/core/`):
  Cross-cutting dependencies:
  - `ApiClient`: Robust HTTP requests via Dio with automatic auth token injection.
  - `ServiceLocator`: Dependency injection container powered by `get_it`.
  - `StorageService`: Persistent key-value storage.
  - `StripePaymentService`: Client-side Stripe checkout sheets.
  - `DataTranslator` & `ResponsiveHelper`: Multi-lingual and adaptive UI sizing.

Detailed architectural documentation: **[docs/architecture/ARCHITECTURE.md](docs/architecture/ARCHITECTURE.md)**.

---

## ⚡ Getting Started

### Prerequisites
- **Flutter SDK**: `^3.22.0` (Dart `^3.4.0`)
- **PHP**: `8.0+` with PDO MySQL, OpenSSL, and cURL extensions
- **MySQL**: `8.0+` or MariaDB `10.4+` (Laragon recommended for local Windows dev)
- **Xcode**: 15+ (for iOS builds) / **Android Studio**: Ladybug or later (for Android builds)

### 1. Repository Setup
```bash
# Clone the repository
git clone https://github.com/technestpartners/artist_dubai.git
cd artist_dubai

# Install Flutter dependencies
flutter pub get
```

### 2. Local Database & API Setup (Laragon)
1. Launch Laragon and start **Apache** and **MySQL**.
2. Create database `artist_dubai` in phpMyAdmin.
3. Import `database/artist_dubai.sql`.
4. Test the local API:
   ```bash
   curl http://artist_dubai.test/api.php?resource=categories
   ```

### 3. Launch the Application
```bash
# Run on connected mobile device or emulator
flutter run

# Run on Chrome for Web
flutter run -d chrome
```

---

## 🧪 Testing Suite

The repository contains 29 comprehensive automated tests across unit, widget, and integration layers:

```bash
# Run the entire test suite
flutter test

# Run a specific test suite
flutter test test/all_pages_verification_test.dart
```

Read **[test/README.md](test/README.md)** for detailed breakdowns of test suites.

---

## 🚀 CI/CD & Deployments

- **iOS TestFlight**: Configured in `.github/workflows/deploy_testflight.yml` and `codemagic.yaml`.
- **App Store**: Configured in `.github/workflows/deploy_appstore.yml` and `scripts/publish_appstore.sh`.
- **Hostinger Backend**: Pre-packaged zip located at `deploy/hostinger/artist_dubai_api_hostinger.zip`. Follow **[docs/deployment/HOSTINGER_BACKEND_SETUP.md](docs/deployment/HOSTINGER_BACKEND_SETUP.md)**.

---

## 📄 License & Ownership

Copyright © 2026 **TechNest Partners / Dubai Artists**. All rights reserved.
