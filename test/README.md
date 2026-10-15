# Dubai Artists - Automated Test Suite

This directory contains comprehensive automated tests for the Dubai Artists application.

---

## 🧪 Test Suite Categories

The test suite covers multiple layers of verification:

### 1. Unit & Foundation Tests
Validate core data manipulation, translation, storage, and utility logic:
- `data_translator_test.dart`: Multi-language dictionary and fallback translation testing.
- `notification_service_test.dart`: In-app notification state and listener verification.
- `share_system_test.dart`: System deep link and sharing utility tests.
- `favorites_persistence_test.dart`: Offline bookmarking and local storage persistence.
- `unit_and_feature_test.dart`: General unit logic and state assertions.

### 2. Widget & Component Tests
Verify individual UI widgets, forms, dialogs, and interactions:
- `widget_test.dart`: Primary smoke test & onboarding interaction flow.
- `home_view_test.dart`: Main dashboard 8-card grid, carousel, and layout verification.
- `guest_artists_view_test.dart`: Unauthenticated guest browsing experience.
- `plan_payment_view_test.dart`: Stripe checkout dialog and payment flows.

### 3. Screen & Responsive Audits
Verify responsiveness across varied device dimensions (iPhone SE, Pro Max, iPad):
- `all_pages_responsive_audit_test.dart`: Multi-screen layout and viewport overflow checks.
- `responsive_and_logic_test.dart`: Adaptive UI sizing and orientation checks.
- `all_pages_verification_test.dart`: Smoke verification across all 31 registered app views.

### 4. Integration & Feature Regression Tests
Verify live API interactions, database synchronization, and role permissions:
- `backend_frontend_sync_integration_test.dart`: End-to-end frontend to MySQL API synchronization.
- `admin_master_management_test.dart`: Administrative control and record lifecycle.
- `admin_open_close_toggle_test.dart`: Event open/close toggle state changes.
- `ai_art_guide_rtl_fix_test.dart`: AI Guide RTL layout and message rendering.
- `ai_chat_date_grouping_test.dart`: Conversation history date grouping logic.
- `artist_chat_and_listing_plans_test.dart`: Artist messaging and listing plan tiers.
- `all_frontend_dataentry_db_test.dart`: Form submissions against database schema.
- `all_pages_db_connectivity_test.dart`: Health and connectivity checks for database-driven pages.
- `full_app_integration_test.dart`: End-to-end full application user journey.
- `manual_e2e_flow_tester.dart`: Interactive E2E flow testing utility.

---

## 🏃 Running Tests

Run all tests:
```bash
flutter test
```

Run an individual test file:
```bash
flutter test test/widget_test.dart
```

Run tests matching a specific tag or name:
```bash
flutter test --plain-name "Responsive"
```
