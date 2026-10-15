# Dubai Artists (فنانو دبي) - Project Scope Document

**Document Version:** 1.0.0  
**Current Application Release:** v3.2.5+12  
**Target Platforms:** iOS (12.0+), Android (5.0+ / API 21+), Web  
**Primary Tech Stack:** Flutter 3.x (Dart 3.7+), PHP 8.2+, MySQL 8.0+, Stripe API, Google Gemini AI  
**Repository:** `artist_dubai`  

---

## 1. Executive Summary & Project Purpose

**Dubai Artists (فنانو دبي)** is a premier cross-platform mobile and web application ecosystem designed to unify, promote, and empower Dubai's dynamic art and cultural scene. The platform bridges the gap between emerging and established artists, private galleries, art collectors, event organizers, and government cultural authorities (e.g., *Dubai Culture & Arts Authority*).

### Strategic Objectives
- **Digital Art Hub**: Centralize discovery for visual artists, calligraphers, sculptors, and digital creators residing and working in Dubai and the UAE.
- **Cultural Promotion**: Connect residents and tourists with live exhibitions, gallery openings, competitions, and workshops across Dubai's cultural hubs (Alserkal Avenue, DIFC, Downtown Dubai, etc.).
- **Commercial Enablement**: Facilitate verified collector-to-artist messaging, commission inquiries, event ticketing, and tier-based artist listing subscriptions.
- **Bilingual & Inclusive**: Provide complete parity across Arabic (RTL) and English (LTR) language modes, adhering strictly to regional cultural values and modern accessibility standards.

---

## 2. Target Audience & Stakeholders

| Stakeholder Persona | Key Needs & Core Scenarios |
| :--- | :--- |
| **Art Collectors & Enthusiasts** | Browse verified artist portfolios, follow artists, save favorites, attend exhibitions, book tickets, and inquire directly via in-app chat. |
| **Artists (Emerging to Master)** | Register profiles, showcase high-resolution artworks, gain visibility, subscribe to featured listing plans, and engage with collectors. |
| **Galleries & Art Centers** | List physical spaces, post upcoming exhibitions and operating hours, manage attendee inquiries, and promote featured shows. |
| **Event Attendees** | Discover cultural festivals and competitions, book tickets, receive instant confirmation with digital QR tickets. |
| **Super Administrators** | Supervise registered users, curate artists/galleries, manage system taxonomies, toggle features dynamically, and review financial metrics. |

---

## 3. System Architecture & Tech Stack

```
┌────────────────────────────────────────────────────────────────────────┐
│                   Flutter Client Application (Presentation)           │
│   (GoRouter, Provider State Management, Google Fonts, Bi-directional) │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │ HTTPS / REST (Bearer Auth)
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│                      PHP 8.2+ RESTful API Gateway                      │
│      (Monolithic controller /api/api.php, PDO Prepared Statements)     │
└───────────────────┬───────────────────────────────┬────────────────────┘
                    │                               │
                    ▼                               ▼
    ┌───────────────────────────────┐   ┌───────────────────────────────┐
    │     MySQL 8.0+ Database       │   │    External Cloud Services    │
    │  (Relational Storage, InnoDB) │   │  • Stripe Payments (AED)      │
    └───────────────────────────────┘   │  • Google Gemini AI Advisor   │
                                        │  • Cloudinary / Hostinger CDN │
                                        └───────────────────────────────┘
```

- **Frontend Engine**: Flutter 3.x / Dart 3.7+ utilizing **Clean Architecture** (Presentation, Domain, Data, Core layers).
- **Navigation & Routing**: `go_router` with declarative routes, route guard redirects, and deep linking support.
- **State Management**: `provider` (ChangeNotifier controllers) paired with `get_it` dependency injection.
- **Local Persistence**: `flutter_secure_storage` (biometric/hardware-backed encrypted storage for tokens) and `shared_preferences` (theme, locale, onboarding state).
- **Backend Architecture**: Native PHP 8.2+ lightweight REST API with CORS headers, URL routing (`.htaccess`), and PDO transactional security.
- **Database**: MySQL 8.0+ with normalized relational schema (`users`, `artists`, `artworks`, `events`, `galleries`, `bookings`, `favorites`, `follows`, `categories`).

---

## 4. In-Scope Modules & Functional Capabilities

### 4.1. Onboarding & Core Experience
- **Splash Screen**: Full-screen splash with background data pre-warming (`LiveSyncService`), route detection, and instant-tap bypass.
- **Brand Onboarding**: 3-step interactive onboarding slider highlighting art discovery, artist connections, and cultural events.
- **Localization**: Live toggling between English (LTR) and Arabic (RTL) without app restart.

### 4.2. Authentication & User Profiles
- **User Roles**: `collector` (default), `artist`, `gallery_owner`, and `admin`.
- **Security**: Bcrypt password hashing, persistent 30-day SHA-256 Bearer tokens, token refresh, and brute-force protection.
- **Account Self-Service**: Profile editing, avatar uploads, password change, and permanent account deletion compliant with Apple App Store (Guideline 5.1.1) and Google Play policies.

### 4.3. Artists Directory & Artworks
- **Discovery**: Filterable and searchable directory categorized by discipline (Visual Arts, Calligraphy, Digital Art, Sculpture, Mixed Media, etc.).
- **Artist Portfolio**: Dynamic profile display featuring artist bio, social links, studio address, experience tier, and artwork gallery.
- **Social Interactions**:
  - Heart / Like artists with optimistic UI updates and backend sync.
  - Follow / Unfollow system for real-time community engagement.
- **Artist Self-Registration**: Multi-step submission form for artists to register directly from the app.

### 4.4. Galleries & Cultural Spaces
- **Directory**: Comprehensive listing of galleries across Dubai's arts districts (DIFC, Alserkal Avenue, Jumeirah).
- **Detail View**: Gallery overview, current/upcoming exhibitions, open hours, and direct contact channels.
- **Gallery Registration**: Dedicated portal for gallery managers to apply for listing.

### 4.5. Cultural Events, Competitions & Workshops
- **Curated Calendar**: Chronological feed of exhibitions, workshops, auctions, and competitions.
- **Ticketing & Booking**:
  - Real-time seat inventory checking and booking reservations.
  - Digital Ticket with scannable QR code and downloadable PDF summary.
- **Past Event Photo Albums**: Dedicated photo archives showcasing past cultural highlights.

### 4.6. Government Cultural Portals
- **Official Hubs**: Dedicated spotlight for **Dubai Culture & Arts Authority (هيئة الثقافة والفنون في دبي)**, Dubai Opera, and Al Marmoom Heritage initiatives.
- **Grants & Public Art**: Information showcase on government art grants, residency programs, and public monument commissions.

### 4.7. AI Art Advisor (Google Gemini)
- **Conversational Concierge**: Virtual assistant knowledgeable about Dubai art history, local gallery recommendations, and artwork interpretation.
- **Multilingual Dialogue**: Real-time natural language query response in fluent English and Arabic.

### 4.8. Direct In-App Chat & Tiered Plans
- **Collector-to-Artist Messaging**: Direct messaging channel for commissions and acquisitions.
- **Tiered Listing Subscriptions**:
  - *Basic (Free)*: Standard directory listing, limited monthly chat quotas.
  - *Featured Plan*: Verified badge, unlimited messaging, priority algorithm ranking.
  - *Master Tier*: Front-page banner spotlight and featured exhibition status.

### 4.9. Payment Processing (Stripe)
- **Native Checkout**: Seamless Stripe Mobile Payment Sheet integration.
- **Currency**: Localized in United Arab Emirates Dirham (**AED**).
- **Automated Entitlement**: Instant subscription activation upon webhook confirmation.

### 4.10. Super Admin Management Portal
- **Dashboard Analytics**: Real-time counter metrics (Active Users, Artists, Events, Bookings, Revenue).
- **User Administration**: Role assignment, manual plan override, and account moderation.
- **Taxonomy Management**: Dynamic addition, editing, and deletion of art disciplines and categories.
- **Dynamic Menu Controls**: Remote show/hide toggles or "Coming Soon" flags for any home tile without requiring client app store updates.
- **Recycle Bin (Trash Management)**: Soft-deletion and restoration for events, artists, and artwork entries.

---

## 5. Non-Functional & Quality Requirements

- **Performance**:
  - Cold launch time $< 2.5\text{s}$ (including splash synchronization).
  - API response latency $< 300\text{ms}$ on standard broadband/4G/5G connections.
  - Smooth 60fps/120fps scrolling powered by `CachedNetworkImage` and lazy list builders.
- **Security & Data Privacy**:
  - HTTPS mandatory for all network endpoints.
  - Hardware-level encryption via Keychain (iOS) and Keystore / EncryptedSharedPreferences (Android).
  - SQL injection immunity via PDO parameterized prepared statements.
  - Content Security Policy and strict CORS headers configured via Apache `.htaccess`.
- **Reliability & Offline Tolerance**:
  - Network connectivity detection via `connectivity_plus`.
  - Graceful fallback error screens and retry banners when network is interrupted.
- **Test Coverage**:
  - Unit, widget, and route verification test suites verifying all top-level application flows.

---

## 6. Out-of-Scope (Deferred to Future Phases)

The following items are explicitly **excluded** from the current release scope (v3.2.x):
1. **Direct Secondary Art Marketplace**: Escrow-based secondary market peer-to-peer artwork resale.
2. **Crypto & NFT Web3 Wallets**: On-chain minting or crypto wallet connectivity.
3. **Augmented Reality (AR) Artwork Preview**: In-room 3D AR wall projection (planned for v4.0).
4. **Physical Shipping & Logistics Integration**: Real-time shipping carrier booking / tracking.

---

## 7. Deliverables & Milestones

| Deliverable | Description | Status |
| :--- | :--- | :--- |
| **Mobile Client App** | Flutter cross-platform binary for iOS (IPA) and Android (APK/AAB) | Complete (v3.2.5+12) |
| **Backend REST API** | PHP 8.2+ API deployed with `.htaccess` rewrite rules and upload storage | Complete |
| **Database Schema** | MySQL relational schema with foreign key constraints & initial seed data | Complete |
| **Admin Control Panel** | In-app secure role-based administrative portal | Complete |
| **CI/CD Pipelines** | Automated GitHub Actions & Codemagic build and deployment workflows | Configured |
| **Documentation Portal** | Comprehensive architecture, API specs, QA reports, and deployment guides | Complete |
