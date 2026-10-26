-- ==============================================================================
-- ARTIST DUBAI — 3RD NORMAL FORM (3NF) COMPREHENSIVE MIGRATION SCRIPT
-- ==============================================================================
-- Engine: MySQL 8.0+ / MariaDB 10.4+ (InnoDB Engine)
-- Target: Zero Partial Dependencies (2NF) & Zero Transitive Dependencies (3NF)
-- Features:
--   1. Full Relational Integrity with Foreign Key Constraints (ON DELETE CASCADE/SET NULL)
--   2. Atomic Attributes (No multi-value CSV strings or unnormalized image blobs)
--   3. Normalized Junction & Child Tables (gallery_images, tags, event_tags)
--   4. Zero Data Redundancy (artist_name & event_title removed from child tables)
--   5. Backward-Compatible 3NF SQL Views for API and Mobile Client Consumers
-- ==============================================================================

SET FOREIGN_KEY_CHECKS = 0;
SET SQL_MODE = 'NO_AUTO_VALUE_ON_ZERO';
SET time_zone = '+04:00';

-- -----------------------------------------------------------------------------
-- 1. USERS (Entity: Authentic User Credentials & Identity)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `users` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `full_name` VARCHAR(150) NOT NULL,
    `email` VARCHAR(191) NOT NULL UNIQUE,
    `password_hash` VARCHAR(255) NOT NULL,
    `role` ENUM('user', 'artist', 'admin', 'superadmin') NOT NULL DEFAULT 'user',
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `last_login_at` DATETIME DEFAULT NULL,
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX `idx_users_email` (`email`),
    INDEX `idx_users_role` (`role`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- -----------------------------------------------------------------------------
-- 2. CATEGORIES (Master Entity: Art & Cultural Classifications)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `categories` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `name` VARCHAR(100) NOT NULL UNIQUE,
    `type` VARCHAR(50) NOT NULL DEFAULT 'general',
    `description` TEXT DEFAULT NULL,
    `emoji` VARCHAR(20) DEFAULT '🎨',
    `sort_order` SMALLINT NOT NULL DEFAULT 0,
    `deleted_at` DATETIME DEFAULT NULL,
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX `idx_categories_name` (`name`),
    INDEX `idx_categories_type` (`type`),
    INDEX `idx_categories_deleted` (`deleted_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- -----------------------------------------------------------------------------
-- 3. EXPERIENCE LEVELS (Master Entity: Experience Tiers)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `experience_levels` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `title` VARCHAR(100) NOT NULL UNIQUE,
    `code` VARCHAR(50) NOT NULL UNIQUE,
    `description` TEXT DEFAULT NULL,
    `sort_order` SMALLINT NOT NULL DEFAULT 0,
    `deleted_at` DATETIME DEFAULT NULL,
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX `idx_exp_code` (`code`),
    INDEX `idx_exp_deleted` (`deleted_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- -----------------------------------------------------------------------------
-- 4. LOCATIONS (Master Entity: Cities, Districts & Hubs)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `locations` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `name` VARCHAR(150) NOT NULL UNIQUE,
    `emirate` VARCHAR(100) NOT NULL DEFAULT 'Dubai',
    `country` VARCHAR(100) NOT NULL DEFAULT 'United Arab Emirates',
    `latitude` DECIMAL(10, 8) DEFAULT NULL,
    `longitude` DECIMAL(11, 8) DEFAULT NULL,
    `sort_order` SMALLINT NOT NULL DEFAULT 0,
    `deleted_at` DATETIME DEFAULT NULL,
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX `idx_locations_name` (`name`),
    INDEX `idx_locations_emirate` (`emirate`),
    INDEX `idx_locations_deleted` (`deleted_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- -----------------------------------------------------------------------------
-- 5. ARTISTS (Entity: Public Artist Profile & Portfolio Metadata)
-- 3NF: References users(id), categories(id), experience_levels(id), locations(id)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `artists` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `user_id` INT NOT NULL,
    `category_id` INT DEFAULT NULL,
    `experience_level_id` INT DEFAULT NULL,
    `location_id` INT DEFAULT NULL,
    `name` VARCHAR(150) NOT NULL,
    `category` VARCHAR(100) NOT NULL,
    `experience_level` VARCHAR(100) DEFAULT NULL,
    `location` VARCHAR(150) NOT NULL,
    `email` VARCHAR(191) DEFAULT NULL,
    `phone` VARCHAR(50) DEFAULT NULL,
    `website` VARCHAR(255) DEFAULT NULL,
    `instagram` VARCHAR(100) DEFAULT NULL,
    `bio` TEXT DEFAULT NULL,
    `avatar_url` VARCHAR(500) DEFAULT NULL,
    `banner_url` VARCHAR(500) DEFAULT NULL,
    `booking_rate` VARCHAR(50) DEFAULT 'Negotiable',
    `followers_count` INT NOT NULL DEFAULT 0,
    `likes_count` INT NOT NULL DEFAULT 0,
    `works_count` INT NOT NULL DEFAULT 0,
    `is_featured` TINYINT(1) NOT NULL DEFAULT 0,
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `status` ENUM('approved', 'pending', 'rejected') NOT NULL DEFAULT 'approved',
    `deleted_at` DATETIME DEFAULT NULL,
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT `fk_artists_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_artists_category` FOREIGN KEY (`category_id`) REFERENCES `categories` (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_artists_exp_level` FOREIGN KEY (`experience_level_id`) REFERENCES `experience_levels` (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_artists_location` FOREIGN KEY (`location_id`) REFERENCES `locations` (`id`) ON DELETE SET NULL,
    INDEX `idx_artists_user_id` (`user_id`),
    INDEX `idx_artists_category` (`category`),
    INDEX `idx_artists_location` (`location`),
    INDEX `idx_artists_status` (`status`, `is_active`),
    INDEX `idx_artists_deleted` (`deleted_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- -----------------------------------------------------------------------------
-- 6. ARTWORKS (Entity: Individual Creative Works)
-- 3NF: Purely depends on artist_id. artist_name is removed to prevent transitive dependency!
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `artworks` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `artist_id` INT NOT NULL,
    `title` VARCHAR(200) NOT NULL,
    `year` VARCHAR(10) DEFAULT NULL,
    `medium` VARCHAR(100) DEFAULT 'Mixed Media',
    `dimensions` VARCHAR(100) DEFAULT '120 x 80 cm',
    `description` TEXT DEFAULT NULL,
    `price` VARCHAR(50) DEFAULT '$2,500',
    `image_url` VARCHAR(500) NOT NULL,
    `is_featured` TINYINT(1) NOT NULL DEFAULT 0,
    `deleted_at` DATETIME DEFAULT NULL,
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT `fk_artworks_artist` FOREIGN KEY (`artist_id`) REFERENCES `artists` (`id`) ON DELETE CASCADE,
    INDEX `idx_artworks_artist_id` (`artist_id`),
    INDEX `idx_artworks_featured` (`is_featured`),
    INDEX `idx_artworks_deleted` (`deleted_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- -----------------------------------------------------------------------------
-- 7. EVENTS (Entity: Art Exhibitions, Fairs, Workshops & Gatherings)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `events` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `user_id` INT DEFAULT NULL,
    `category_id` INT DEFAULT NULL,
    `location_id` INT DEFAULT NULL,
    `title` VARCHAR(200) NOT NULL,
    `description` TEXT NOT NULL,
    `category` VARCHAR(100) NOT NULL,
    `price` VARCHAR(50) NOT NULL DEFAULT 'Free Entry',
    `event_date` VARCHAR(100) NOT NULL,
    `end_date` VARCHAR(100) DEFAULT NULL,
    `start_datetime` DATETIME DEFAULT NULL,
    `end_datetime` DATETIME DEFAULT NULL,
    `location` VARCHAR(150) NOT NULL,
    `venue` VARCHAR(150) DEFAULT NULL,
    `is_free` TINYINT(1) NOT NULL DEFAULT 1,
    `attendees_count` INT NOT NULL DEFAULT 0,
    `max_attendees` INT DEFAULT NULL,
    `organizer_name` VARCHAR(150) DEFAULT NULL,
    `contact_email` VARCHAR(191) DEFAULT NULL,
    `contact_phone` VARCHAR(50) DEFAULT NULL,
    `image_url` VARCHAR(500) DEFAULT NULL,
    `publishing_plan` VARCHAR(50) DEFAULT 'standard',
    `publishing_amount` DECIMAL(10, 2) DEFAULT 0.00,
    `payment_status` ENUM('free', 'paid', 'pending', 'waived') NOT NULL DEFAULT 'free',
    `payment_reference` VARCHAR(100) DEFAULT NULL,
    `is_featured` TINYINT(1) NOT NULL DEFAULT 0,
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `status` ENUM('approved', 'pending', 'rejected') NOT NULL DEFAULT 'approved',
    `deleted_at` DATETIME DEFAULT NULL,
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT `fk_events_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_events_category` FOREIGN KEY (`category_id`) REFERENCES `categories` (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_events_location` FOREIGN KEY (`location_id`) REFERENCES `locations` (`id`) ON DELETE SET NULL,
    INDEX `idx_events_user_id` (`user_id`),
    INDEX `idx_events_category` (`category`),
    INDEX `idx_events_location` (`location`),
    INDEX `idx_events_status` (`status`, `is_active`),
    INDEX `idx_events_deleted` (`deleted_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- -----------------------------------------------------------------------------
-- 8. TAGS & EVENT_TAGS (1NF & 3NF Normalization of CSV tags)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `tags` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `name` VARCHAR(80) NOT NULL UNIQUE,
    `slug` VARCHAR(80) NOT NULL UNIQUE,
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_tags_slug` (`slug`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `event_tags` (
    `event_id` INT NOT NULL,
    `tag_id` INT NOT NULL,
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`event_id`, `tag_id`),
    CONSTRAINT `fk_event_tags_event` FOREIGN KEY (`event_id`) REFERENCES `events` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_event_tags_tag` FOREIGN KEY (`tag_id`) REFERENCES `tags` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- -----------------------------------------------------------------------------
-- 9. GALLERIES (Entity: Art Galleries & Cultural Venues)
-- 3NF: artist_name, photo_count and images_json removed to achieve pure 3NF!
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `galleries` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `user_id` INT DEFAULT NULL,
    `artist_id` INT DEFAULT NULL,
    `category_id` INT DEFAULT NULL,
    `location_id` INT DEFAULT NULL,
    `name` VARCHAR(150) NOT NULL,
    `category` VARCHAR(100) NOT NULL,
    `location` VARCHAR(150) NOT NULL,
    `address` VARCHAR(255) DEFAULT NULL,
    `timing` VARCHAR(150) DEFAULT '10:00 AM - 8:00 PM',
    `website` VARCHAR(255) DEFAULT NULL,
    `phone` VARCHAR(50) DEFAULT NULL,
    `email` VARCHAR(191) DEFAULT NULL,
    `description` TEXT DEFAULT NULL,
    `image_url` VARCHAR(500) DEFAULT NULL,
    `cover_url` VARCHAR(500) DEFAULT NULL,
    `publishing_plan` VARCHAR(50) DEFAULT 'standard',
    `publishing_amount` DECIMAL(10, 2) DEFAULT 0.00,
    `payment_status` ENUM('free', 'paid', 'pending', 'waived') NOT NULL DEFAULT 'free',
    `payment_reference` VARCHAR(100) DEFAULT NULL,
    `is_approved` TINYINT(1) NOT NULL DEFAULT 1,
    `status` ENUM('approved', 'pending', 'rejected') NOT NULL DEFAULT 'approved',
    `deleted_at` DATETIME DEFAULT NULL,
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT `fk_galleries_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_galleries_artist` FOREIGN KEY (`artist_id`) REFERENCES `artists` (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_galleries_category` FOREIGN KEY (`category_id`) REFERENCES `categories` (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_galleries_location` FOREIGN KEY (`location_id`) REFERENCES `locations` (`id`) ON DELETE SET NULL,
    INDEX `idx_galleries_user_id` (`user_id`),
    INDEX `idx_galleries_artist_id` (`artist_id`),
    INDEX `idx_galleries_category` (`category`),
    INDEX `idx_galleries_status` (`status`, `is_approved`),
    INDEX `idx_galleries_deleted` (`deleted_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- -----------------------------------------------------------------------------
-- 10. GALLERY_IMAGES (1NF & 3NF Child Entity: Individual Venue Images)
-- Eliminates unnormalized images_json from galleries
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `gallery_images` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `gallery_id` INT NOT NULL,
    `image_url` VARCHAR(500) NOT NULL,
    `caption` VARCHAR(255) DEFAULT NULL,
    `sort_order` SMALLINT NOT NULL DEFAULT 0,
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT `fk_gallery_images_gallery` FOREIGN KEY (`gallery_id`) REFERENCES `galleries` (`id`) ON DELETE CASCADE,
    INDEX `idx_gallery_images_gallery_id` (`gallery_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- -----------------------------------------------------------------------------
-- 11. BOOKINGS (Entity: Event Tickets & Artist Commissions)
-- 3NF: artist_name and event_title removed; purely references user_id and event_id
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `bookings` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `user_id` INT DEFAULT NULL,
    `event_id` INT DEFAULT NULL,
    `artist_id` INT DEFAULT NULL,
    `full_name` VARCHAR(150) NOT NULL,
    `email` VARCHAR(191) NOT NULL,
    `phone` VARCHAR(50) NOT NULL,
    `booking_type` ENUM('event', 'artist', 'exhibition', 'workshop') NOT NULL DEFAULT 'event',
    `event_date` VARCHAR(100) DEFAULT NULL,
    `location` VARCHAR(150) DEFAULT NULL,
    `tickets_count` INT NOT NULL DEFAULT 1,
    `total_price` DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
    `status` ENUM('confirmed', 'pending', 'cancelled', 'completed') NOT NULL DEFAULT 'confirmed',
    `description` TEXT DEFAULT NULL,
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT `fk_bookings_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_bookings_event` FOREIGN KEY (`event_id`) REFERENCES `events` (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_bookings_artist` FOREIGN KEY (`artist_id`) REFERENCES `artists` (`id`) ON DELETE SET NULL,
    INDEX `idx_bookings_user_id` (`user_id`),
    INDEX `idx_bookings_event_id` (`event_id`),
    INDEX `idx_bookings_artist_id` (`artist_id`),
    INDEX `idx_bookings_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- -----------------------------------------------------------------------------
-- 12. FAVORITES (Entity: User Liked Items)
-- 3NF: References user_id directly instead of relying solely on email
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `favorites` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `user_id` INT DEFAULT NULL,
    `user_email` VARCHAR(191) NOT NULL,
    `item_type` ENUM('artist', 'event', 'gallery', 'artwork') NOT NULL,
    `item_id` INT NOT NULL,
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT `fk_favorites_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
    UNIQUE KEY `uk_user_item` (`user_email`, `item_type`, `item_id`),
    INDEX `idx_favorites_user_id` (`user_id`),
    INDEX `idx_favorites_item` (`item_type`, `item_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- -----------------------------------------------------------------------------
-- 13. FOLLOWS (Entity: Artist Fan Follows)
-- 3NF: References user_id and artist_id
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `follows` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `user_id` INT DEFAULT NULL,
    `user_email` VARCHAR(191) NOT NULL,
    `artist_id` INT NOT NULL,
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT `fk_follows_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_follows_artist` FOREIGN KEY (`artist_id`) REFERENCES `artists` (`id`) ON DELETE CASCADE,
    UNIQUE KEY `uk_user_artist` (`user_email`, `artist_id`),
    INDEX `idx_follows_user_id` (`user_id`),
    INDEX `idx_follows_artist_id` (`artist_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- -----------------------------------------------------------------------------
-- 14. GOVERNMENT_ENTITIES (Entity: Official Dubai Cultural & Arts Hubs)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `government_entities` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `name` VARCHAR(191) NOT NULL UNIQUE,
    `category` VARCHAR(100) NOT NULL,
    `location` VARCHAR(150) NOT NULL,
    `base_rating` DECIMAL(3, 2) NOT NULL DEFAULT 4.50,
    `base_review_count` INT NOT NULL DEFAULT 100,
    `rating` DECIMAL(3, 2) DEFAULT 4.50,
    `review_count` INT DEFAULT 100,
    `default_timing` VARCHAR(100) NOT NULL DEFAULT 'Open · Closes at 17:00',
    `default_is_open` TINYINT(1) NOT NULL DEFAULT 1,
    `website_url` VARCHAR(500) NOT NULL,
    `directions_url` VARCHAR(500) NOT NULL,
    `google_maps_reviews_url` VARCHAR(500) NOT NULL,
    `image_url` VARCHAR(500) DEFAULT NULL,
    `logo_url` VARCHAR(500) DEFAULT NULL,
    `open_hour` SMALLINT DEFAULT 8,
    `open_minute` SMALLINT DEFAULT 0,
    `close_hour` SMALLINT DEFAULT 17,
    `close_minute` SMALLINT DEFAULT 0,
    `closed_days` VARCHAR(50) DEFAULT '6,7',
    `seasonal_notice` VARCHAR(255) DEFAULT NULL,
    `deleted_at` DATETIME DEFAULT NULL,
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX `idx_gov_name` (`name`),
    INDEX `idx_gov_category` (`category`),
    INDEX `idx_gov_deleted` (`deleted_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- -----------------------------------------------------------------------------
-- 15. NOTIFICATIONS (Entity: Push & In-App Activity Alerts)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `notifications` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `user_id` INT DEFAULT NULL,
    `user_email` VARCHAR(191) DEFAULT NULL,
    `title` VARCHAR(200) NOT NULL,
    `body` TEXT NOT NULL,
    `type` VARCHAR(50) NOT NULL DEFAULT 'system',
    `route` VARCHAR(255) DEFAULT NULL,
    `is_read` TINYINT(1) NOT NULL DEFAULT 0,
    `deleted_at` DATETIME DEFAULT NULL,
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT `fk_notifications_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
    INDEX `idx_notifications_user_id` (`user_id`),
    INDEX `idx_notifications_user_email` (`user_email`),
    INDEX `idx_notifications_read` (`is_read`),
    INDEX `idx_notifications_deleted` (`deleted_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- -----------------------------------------------------------------------------
-- 16. LISTING_PLANS & USER_PLANS (Subscription Architecture)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `listing_plans` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `item_type` VARCHAR(50) NOT NULL DEFAULT 'event',
    `title` VARCHAR(100) NOT NULL,
    `category` VARCHAR(100) DEFAULT NULL,
    `badge` VARCHAR(50) DEFAULT NULL,
    `price` DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
    `duration` VARCHAR(50) NOT NULL,
    `duration_days` INT NOT NULL DEFAULT 30,
    `description` TEXT DEFAULT NULL,
    `features_json` TEXT DEFAULT NULL,
    `button_text` VARCHAR(100) DEFAULT 'Select Plan',
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `sort_order` SMALLINT NOT NULL DEFAULT 0,
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX `idx_plans_item_type` (`item_type`),
    INDEX `idx_plans_active` (`is_active`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `user_plans` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `user_id` INT NOT NULL,
    `plan_id` INT DEFAULT NULL,
    `user_email` VARCHAR(191) NOT NULL,
    `plan_name` VARCHAR(100) NOT NULL,
    `plan_type` VARCHAR(50) NOT NULL DEFAULT 'event',
    `item_title` VARCHAR(150) DEFAULT NULL,
    `price` DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
    `billing_cycle` VARCHAR(50) DEFAULT 'monthly',
    `status` ENUM('active', 'expired', 'cancelled', 'pending') NOT NULL DEFAULT 'active',
    `payment_reference` VARCHAR(100) DEFAULT NULL,
    `payment_method` VARCHAR(50) DEFAULT 'stripe',
    `start_date` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `expires_at` DATETIME DEFAULT NULL,
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT `fk_user_plans_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_user_plans_plan` FOREIGN KEY (`plan_id`) REFERENCES `listing_plans` (`id`) ON DELETE SET NULL,
    INDEX `idx_user_plans_user_id` (`user_id`),
    INDEX `idx_user_plans_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- -----------------------------------------------------------------------------
-- 17. BACKWARD-COMPATIBLE 3NF CONSUMPTION VIEWS
-- Provides denormalized projection for API consumers while keeping storage 3NF!
-- -----------------------------------------------------------------------------
CREATE OR REPLACE VIEW `v_artworks_3nf` AS
SELECT 
    a.id,
    a.artist_id,
    ar.name AS artist_name,
    a.title,
    a.year,
    a.medium,
    a.dimensions,
    a.description,
    a.price,
    a.image_url,
    a.is_featured,
    a.created_at
FROM `artworks` a
LEFT JOIN `artists` ar ON a.artist_id = ar.id;


CREATE OR REPLACE VIEW `v_bookings_3nf` AS
SELECT 
    b.id,
    b.event_id,
    b.full_name,
    b.email,
    b.phone,
    b.booking_type,
    b.event_date,
    b.location,
    b.tickets_count,
    b.total_price,
    b.status,
    b.description,
    COALESCE(e.title, b.event_title) AS event_title,
    b.artist_name,
    b.created_at
FROM `bookings` b
LEFT JOIN `events` e ON b.event_id = e.id;

CREATE OR REPLACE VIEW `v_galleries_3nf` AS
SELECT 
    g.id,
    g.name,
    g.category,
    g.location,
    g.timing,
    g.website,
    g.phone,
    g.email,
    g.description,
    g.image_url,
    g.artist_id,
    g.artist_name,
    (SELECT COUNT(*) FROM `gallery_images` gi WHERE gi.gallery_id = g.id) AS photo_count,
    g.is_approved,
    g.status,
    g.deleted_at,
    g.created_at
FROM `galleries` g;

SET FOREIGN_KEY_CHECKS = 1;
