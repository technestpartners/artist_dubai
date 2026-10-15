# Dubai Artists (فنانو دبي) - Project Features Documentation

---

## 📱 Comprehensive Feature Catalog

This document details all business modules, user workflows, and features implemented in the **Dubai Artists (فنانو دبي)** platform.

---

### 1. 🌟 Splash Screen & Brand Introduction
* **Full-Screen Artwork**: Displays the high-resolution brand artwork edge-to-edge across all device screen ratios.
* **Pre-warm Live Sync**: Silently triggers background cache synchronization (`LiveSyncService`) while the splash animation plays.
* **Intelligent Deep Link Routing**: Checks for incoming deep links or onboarding completion state (`StorageServiceImpl.keyHasCompletedOnboarding`) and routes seamlessly to either Onboarding or the Home Dashboard.
* **Skip On Tap**: Allows users to tap the screen to bypass the 2.8s entrance animation instantly.

---

### 2. 🚀 Interactive Onboarding
* **3-Slide Brand Journey**:
  1. *Discover Vibrant Art*: Exploring local Dubai art scenes.
  2. *Connect with Masters*: Direct artist and gallery access.
  3. *Experience Cultural Events*: Live calendar and booking capabilities.
* **State Persistence**: Saves onboarding completion flag in encrypted persistent storage so returning users bypass onboarding directly to the Home Dashboard.

---

### 3. 🏠 Central Home Dashboard
* **10 Flagship Quick-Access Tiles**:
  1. **About Us**: Platform vision, mission, and leadership.
  2. **Artists**: Discover curated Dubai artists across disciplines.
  3. **Government**: Official Dubai Culture & Arts Authority portals.
  4. **Artist Registration**: Quick registration for emerging and established artists.
  5. **Events Competition**: Art competitions, exhibitions, and workshops.
  6. **Galleries / Art Centers**: Art gallery spaces and exhibitions.
  7. **Events Photos**: Photo galleries from prestigious cultural events.
  8. **Galleries Registration**: Onboarding form for physical art spaces.
  9. **Login / Account**: Authentication and profile management.
  10. **AI Art Advisor**: AI-driven virtual guide.
* **Top Bar Controls**:
  * Real-time language switcher (`EN` / `عربي`) with full RTL adaptation.
  * Notifications badge with unread counters.
* **Bottom Navigation**: Persistent navigation bar with fast switching between Home, Explore, Favorites, and Profile.

---

### 4. 🎨 Artists Directory & Portfolio Showcase
* **Directory Search & Filter**: Real-time search by artist name, bio, discipline, and location.
* **Discipline Filters**: Visual Arts, Photography, Sculpture, Digital Art, Calligraphy, Mixed Media, Music, Theater.
* **Artist Profile View**:
  * High-resolution portfolio galleries and featured artworks.
  * Experience level badge (Emerging, Established, Master).
  * Direct contact channels (Email, Phone, Instagram, Website, Studio location).
* **Social Engagement**:
  * **Like Artist**: Interactive heart button with optimistic local state updates synced to the MySQL backend.
  * **Follow Artist**: Direct follow system allowing collectors to follow their favorite creators.
* **Artist Registration**: Multi-step registration form supporting profile image upload, category selection, bio, and social handles.

---

### 5. 🏛️ Galleries & Art Centers
* **Gallery Directory**: Curated list of premier art galleries across Alserkal Avenue, DIFC, Downtown, and Jumeirah.
* **Exhibitions & Timings**: Opening hours, active exhibitions, and admission policies.
* **Gallery Registration**: Dedicated portal for gallery managers to list exhibition spaces, upload venue imagery, and receive collector inquiries.

---

### 6. 📅 Events, Competitions & Workshops
* **Curated Calendar**: Upcoming art exhibitions, auctions, workshops, and competitions.
* **Event Detail View**: Complete event metadata including dates, timings, venue coordinates, and organizer info.
* **In-App Ticket Booking**:
  * Real-time ticket reservations with seat count validation.
  * Instant booking confirmation stored in the `bookings` database table.
* **My Bookings Portal**:
  * List of user's active and past bookings.
  * Downloadable PDF ticket with verified booking QR code.
* **Event Photo Galleries**: High-resolution photo albums from past exhibitions and gala events.

---

### 7. 🏛️ Government Cultural Portals
* **Official Dubai Culture Integration**: Direct profile for **Dubai Culture & Arts Authority (هيئة الثقافة والفنون في دبي)**, Dubai Opera, and Al Marmoom Heritage.
* **Initiatives & Grants**: Showcase of government cultural initiatives, artist grant programs, and public art opportunities.

---

### 8. 🤖 AI Art Advisor (Powered by Google Gemini)
* **Virtual Art Concierge**: Real-time conversational AI assistant specialized in Dubai art history, exhibition recommendations, and cultural etiquette.
* **Multi-Lingual Support**: Seamlessly understands and responds in both English and Arabic.
* **RTL-Compliant UI**: Chat bubbles and inputs automatically adjust alignment based on language direction.

---

### 9. 💬 Direct Artist Messaging & Chat Plans
* **In-App Collector-to-Artist Chat**: Private direct messaging allowing collectors to inquire about artwork acquisition and commissions.
* **Artist Listing Plans**:
  * **Basic (Free)**: Standard listing with quota of 10 monthly chat interactions.
  * **Featured Plan**: Verified badge, unlimited messaging, and priority discovery.
  * **Master Tier**: Top search placement and dedicated exhibition spotlight.

---

### 10. 💳 Secure Stripe Payments
* **Integrated Checkout**: Native mobile Stripe checkout sheet for subscription plans and event publishing fees.
* **Multi-Currency & AED Native**: Transparent AED pricing with live payment verification.
* **Automated Entitlement**: Payment verification automatically updates user plan status in the `user_plans` database.

---

### 11. 🛡️ Super Admin Management Portal
*(Accessible exclusively to users with `role: admin`)*
* **Live KPI Dashboard**: Overview of total artists, events, galleries, users, and bookings.
* **User Management**:
  * View all registered accounts across all roles.
  * Promote users to `admin` or `artist`.
  * Manual plan assignment and account deactivation.
* **Category & Master Management**:
  * Add, rename, or delete art categories and disciplines.
  * Configure experience levels and Dubai geographic locations.
* **Recycle Bin (Trash Management)**:
  * Soft-deleted artists, events, and artworks can be reviewed, restored, or permanently wiped.
* **Menu Permissions & Feature Toggles**:
  * Real-time toggles to dynamically show, hide, or mark any dashboard tile as *"Coming Soon"* without requiring app updates.
* **Publishing Pricing Controls**:
  * Update weekly, monthly, and annual publishing rates across events, artists, and galleries.

---

### 12. 🔐 Authentication & Security Suite
* **Bcrypt Password Security**: Industry-standard cryptographic password hashing.
* **Persistent API Tokens**: 30-day cryptographically secure SHA-256 tokens stored in hardware-backed `FlutterSecureStorage`.
* **Profile Management**: Update name, avatar, bio, and change password securely.
* **Account Deletion**: Full self-service account deletion conforming to App Store and Google Play privacy guidelines.

---

### 13. 🌐 Internationalization (i18n)
* **Full Dual-Language Support**: Complete English (`en`) and Arabic (`ar`) translations.
* **Automatic Layout Flipping**: Directionality switches between LTR and RTL dynamically with zero layout breakage.
