# Dubai Artists - Flutter Application Codebase

This directory contains the complete source code for the **Dubai Artists** mobile and web applications.

---

## 🏛️ Architecture & Folder Conventions

The application adheres to **Clean Architecture** arranged by feature:

```
lib/
├── app/                  # Application-wide navigation and bootstrap
│   └── routes/           # AppRouter & RouteNames configuration (GoRouter)
├── core/                 # Shared foundation modules
│   ├── constants/        # API endpoints, palettes, string constants, assets
│   ├── di/               # Service locator dependency injection (GetIt)
│   ├── errors/           # Failure models and exception handling
│   ├── network/          # Dio client, API interceptors, connectivity
│   ├── services/         # Storage, push notifications, Stripe payments
│   ├── utils/            # Translation, formatting, responsive layout, validations
│   └── widgets/          # Reusable UI widgets across all screens
├── features/             # Modular business feature packages
│   ├── about_us/         # Platform info & credentials
│   ├── admin/            # Administrative management, KPI dash & recycle bin
│   ├── ai/               # AI Art Guide grounded conversational assistant
│   ├── artists/          # Artist directory, registration & profile views
│   ├── auth/             # Authentication, login, signup, session logic
│   ├── chat/             # Direct messaging & artist inquiry channels
│   ├── events/           # Exhibitions, competitions & ticket bookings
│   ├── favorites/        # Bookmarked artworks & favorite artists
│   ├── galleries/        # Dubai art centers & physical spaces
│   ├── government/       # Cultural initiatives & government grants portal
│   ├── home/             # Main dashboard, 8-card grid & featured carousel
│   ├── legal/            # Privacy policy & terms of service
│   ├── onboarding/       # Interactive welcome walkthrough
│   ├── payment/          # Plan checkout & Stripe payment flows
│   ├── placeholder/      # Coming soon & feature gateways
│   ├── profile/          # User profile view & edit forms
│   └── settings/         # App preferences, language switcher, logout
├── l10n/                 # Localization ARB files (English & Arabic)
└── main.dart             # App initialization entrypoint
```

---

## 📐 Development Guidelines

1. **State & Architecture**: Keep UI widgets decoupled from backend calls. Use `ApiClient` and domain models.
2. **Localization**: All visible strings must use `.trData(context)` or `AppLocalizations` to support Arabic and English.
3. **Responsiveness**: Use `ResponsiveHelper` or screen-aware layouts to ensure flawless display across compact phones, tablets, and web viewports.
4. **Theme Consistency**: Rely on `AppColors` for primary gold accents, luxury dark backdrops, and text styling.
