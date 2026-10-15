# Dubai Artists - Database Schema & Migrations

This directory contains database schemas, seeds, and provisioning configurations for the Dubai Artists application.

---

## 🗄️ Database Setup

- **Default Engine**: MySQL 8.0+ / MariaDB 10.4+
- **Default Database Name**: `artist_dubai`
- **Charset / Collation**: `utf8mb4_unicode_ci`

---

## 📥 Importing the Database

### Via phpMyAdmin (Laragon):
1. Open phpMyAdmin (`http://localhost/phpmyadmin/`).
2. Create a new database named `artist_dubai`.
3. Select `artist_dubai` and navigate to the **Import** tab.
4. Select `database/artist_dubai.sql` and click **Go**.

### Via MySQL Command Line:
```bash
mysql -u root -p -e "CREATE DATABASE IF NOT EXISTS artist_dubai CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
mysql -u root -p artist_dubai < database/artist_dubai.sql
```

---

## 📑 Core Tables Overview

- **`users`**: User authentication, profiles, role levels (`user`, `artist`, `admin`, `superadmin`).
- **`artists`**: Artist portfolio details, bio, experience level, nationality, social handles.
- **`categories`**: Art taxonomy (Paintings, Calligraphy, Sculpture, Digital Art, Photography).
- **`events`**: Dubai exhibitions, workshops, competitions, dates, and locations.
- **`bookings`**: Event ticket registrations and attendee RSVP management.
- **`galleries`**: Physical Dubai art centers, opening hours, coordinates.
- **`artworks`**: Artwork catalog, high-resolution imagery, pricing, and availability.
- **`favorites`**: User bookmarks and saved artworks/artists.
- **`publishing_pricing` / `listing_plans`**: Subscription tiers for artist listing and exhibition showcases.
- **`menu_permissions`**: Dynamic access control matrix for mobile menu entries.
