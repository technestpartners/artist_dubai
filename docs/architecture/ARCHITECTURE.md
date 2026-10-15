# Dubai Artists - Comprehensive Architecture & Design Guide

This document provides a comprehensive technical overview of the **Dubai Artists** platform, detailing its Clean Architecture layers, reactive state management, network client, and scalable backend infrastructure.

---

## 🏛️ System Architecture Overview

The application adheres to **Clean Architecture** with a **Feature-Driven Modular Pattern**:

```
┌─────────────────────────────────────────────────────────────┐
│                    Presentation Layer                       │
│    (Stateful/Stateless Views, Reusable Widgets, Modals)      │
└──────────────────────────────┬──────────────────────────────┘
                               │ (Observes via Consumer)
                               ▼
┌─────────────────────────────────────────────────────────────┐
│                   Controller / State Layer                  │
│    (ChangeNotifier Controllers, Immutable State Objects)    │
└──────────────────────────────┬──────────────────────────────┘
                               │ (Calls Repository contracts)
                               ▼
┌─────────────────────────────────────────────────────────────┐
│                        Domain Layer                         │
│     (Domain Models, Repository Interfaces, Value Objects)   │
└──────────────────────────────┬──────────────────────────────┘
                               │ (Implemented by Data Layer)
                               ▼
┌─────────────────────────────────────────────────────────────┐
│                         Data Layer                          │
│   (Repository Implementations, Remote & Local Data Sources)  │
└──────────────────────────────┬──────────────────────────────┘
                               │ (Executes HTTP / DB I/O)
                               ▼
┌─────────────────────────────────────────────────────────────┐
│                  Core Infrastructure Layer                  │
│  (ApiClient, StorageService, LiveSyncService, DI, Config)   │
└─────────────────────────────────────────────────────────────┘
```

---

## 📂 Frontend Directory Structure (`lib/`)

```
lib/
├── app/
│   ├── app.dart                   # Root MaterialApp with locale & themes
│   ├── app_theme.dart             # Platinum & Royal Purple design tokens
│   └── routes/
│       ├── app_router.dart        # GoRouter navigation & deep linking
│       └── route_names.dart       # Centralized route name constants
├── core/
│   ├── config/
│   │   └── app_config.dart        # Environment configuration via --dart-define
│   ├── constants/
│   │   ├── api_endpoints.dart     # Endpoint catalog delegated to AppConfig
│   │   ├── app_colors.dart        # Palette definitions (gold, purple, neutral)
│   │   └── country_codes.dart     # International dialing prefix constants
│   ├── di/
│   │   └── injection_container.dart # Service locator registration (GetIt)
│   ├── errors/
│   │   ├── exceptions.dart        # Server, Network, Auth & Validation exceptions
│   │   └── failures.dart          # Typed Failures with Failure.fromException()
│   ├── network/
│   │   ├── api_client.dart        # Dio client with automatic retry & timeout handling
│   │   ├── dio_interceptor.dart   # Logging and token injection interceptor
│   │   └── network_info.dart      # Network connectivity monitor
│   ├── services/
│   │   ├── api_service.dart       # High-level domain gateway with caching
│   │   ├── favorites_service.dart # Reactive optimistic favorites state
│   │   ├── live_sync_service.dart # Real-time multi-device sync engine
│   │   ├── locale_provider.dart   # Arabic (RTL) / English language provider
│   │   ├── notification_service.dart # In-app notification queue & badges
│   │   ├── storage_service.dart   # Shared Preferences & Secure Storage wrapper
│   │   └── stripe_payment_service.dart # Stripe payments & client-secret checkout
│   ├── utils/
│   │   ├── data_translator.dart   # Real-time multi-language AI translation
│   │   ├── date_formatter.dart    # Standardized date formatting
│   │   ├── responsive_helper.dart # Screen breakpoint & scale helper
│   │   ├── share_helper.dart      # Deep link & native OS share integration
│   │   ├── ui_helpers.dart        # Standardized SnackBars & error formatting
│   │   └── validators.dart        # Input validation helpers
│   └── widgets/
│       ├── app_back_button.dart   # Directionality-aware RTL back button
│       ├── app_bottom_nav_bar.dart# Persistent bottom navigation bar
│       ├── app_cached_image.dart  # Memory-safe cached network image with shimmer
│       ├── app_empty_state.dart   # Standardized zero-state widget
│       ├── app_loading_indicator.dart # Brand loading spinner
│       ├── app_top_bar.dart       # Header with notification bell & menu
│       └── notifications_panel.dart # Notification dropdown overlay
├── features/
│   ├── admin/                     # Admin portal & moderation
│   ├── ai/                        # AI art curation assistant
│   ├── artists/                   # Artist directories, profiles & registration
│   ├── auth/                      # Clean Architecture login, register & session
│   ├── chat/                      # Artist direct messaging & listing plans
│   ├── events/                    # Art events, galleries & photo submissions
│   ├── favorites/                 # Persisted bookmarks & favorite items
│   ├── galleries/                 # Art centers and exhibition venues
│   ├── government/                # Cultural portals and UAE initiatives
│   ├── home/                      # Dynamic dashboard & menu cards
│   ├── legal/                     # Terms of Service & Privacy Policy
│   ├── onboarding/                # Intro carousel
│   ├── payment/                   # Subscription checkout & payment UI
│   ├── profile/                   # User profile editing
│   ├── settings/                  # Language and account preferences
│   └── splash/                    # Animated video/logo splash entry
└── l10n/                          # App localization delegates (AR / EN)
```

---

## ⚡ State Management Architecture

The project employs **Provider (`package:provider`)** and **`ChangeNotifier`** with strict Separation of Concerns:

1. **Immutable States**: State classes (e.g. `LoginState`, `RegisterState`) hold primitive values and objects with copy-on-write `copyWith()` mechanics.
2. **State Controllers**: Encapsulate presentation logic, validation, and domain repository interactions without importing Flutter UI widgets.
3. **Reactive Views**: Screens wrap their body tree with `ChangeNotifierProvider<T>.value` and listen through `Consumer<T>`, triggering targeted rebuilds only when watched data changes.
4. **Global Singletons**: Cross-cutting states (`LocaleProvider`, `FavoritesService`, `NotificationService`) are registered in `sl` (GetIt) and listened to across navigation surfaces.

---

## 🛡️ Error Handling Strategy

1. **Network Layer**: `ApiClientImpl` intercepts HTTP connection timeouts and socket aborts, executing up to 2 retries with exponential backoff before throwing typed `NetworkException` or `ServerException`.
2. **Failure Mapping**: `Failure.fromException(Object error)` standardizes caught exceptions into typed `Failure` subclasses (`NetworkFailure`, `UnauthorizedFailure`, `ValidationFailure`, `ServerFailure`).
3. **UI Feedback**: `UiHelpers.handleFailure(context, error)` formats raw messages into clear, localized error banners and toasts.
