-- MySQL Database Schema for Artist Dubai
CREATE DATABASE IF NOT EXISTS `artist_dubai` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE `artist_dubai`;

-- 1. Users Table
CREATE TABLE IF NOT EXISTS `users` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `full_name` VARCHAR(100) NOT NULL,
  `email` VARCHAR(120) NOT NULL UNIQUE,
  `password_hash` VARCHAR(255) NOT NULL,
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Insert Default Demo User (password: 12345678)
INSERT INTO `users` (`id`, `full_name`, `email`, `password_hash`, `created_at`) 
VALUES (1, 'Allen Baiyee', 'allenbaiyee@me.com', '$2y$10$e.1Wq2t.7/f5N6A8G7q.ue3H1F8/q5J9Y4V2S1Z8X7C6V5B4N3M2', NOW())
ON DUPLICATE KEY UPDATE `email`=`email`;

-- 2. Categories Table
CREATE TABLE IF NOT EXISTS `categories` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `name` VARCHAR(100) NOT NULL UNIQUE,
  `description` TEXT,
  `emoji` VARCHAR(20) DEFAULT '🎨',
  `color` VARCHAR(50) DEFAULT 'Primary',
  `tags` TEXT,
  `is_featured` TINYINT(1) DEFAULT 0,
  `artist_count` INT DEFAULT 0,
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Seed Default Categories
INSERT INTO `categories` (`name`, `description`, `emoji`, `color`, `tags`, `is_featured`, `artist_count`) VALUES
('Calligraphy & Typography', 'Traditional and contemporary Arabic calligraphy and typographic art.', '✍️', 'Primary', 'Calligraphy,Typography,Arabic Art,Traditional', 1, 1),
('Contemporary Painting', 'Modern oil, acrylic, and mixed media paintings on canvas.', '🎨', 'Pink', 'Contemporary,Abstract,Canvas', 1, 1),
('Digital Art & Sculpture', 'Digital illustrations, 3D artwork, and modern sculpting.', '🗿', 'Blue', 'Digital,Sculpture,3D,Modern', 0, 1),
('Photography', 'Fine art, landscape, portrait, and architectural photography.', '📷', 'Purple', 'Photography,Fine Art,Portrait', 1, 6),
('Abstract Painting', 'Expressive abstract works exploring color, form, and emotion.', '🎨', 'Orange', 'Abstract,Color,Emotion', 0, 1),
('Ceramics & Pottery', 'Handcrafted pottery, clay sculptures, and ceramic installations.', '🏺', 'Yellow', 'Ceramics,Pottery,Handcrafted', 0, 1)
ON DUPLICATE KEY UPDATE `name`=`name`;

-- 3. Artists Table
CREATE TABLE IF NOT EXISTS `artists` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `user_id` INT DEFAULT NULL,
  `name` VARCHAR(100) NOT NULL,
  `category` VARCHAR(100) NOT NULL,
  `location` VARCHAR(100) NOT NULL,
  `bio` TEXT,
  `avatar_url` VARCHAR(255) DEFAULT NULL,
  `banner_url` VARCHAR(255) DEFAULT NULL,
  `followers_count` INT DEFAULT 0,
  `works_count` INT DEFAULT 0,
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Seed Sample Artists
INSERT INTO `artists` (`name`, `category`, `location`, `bio`, `followers_count`, `works_count`) VALUES
('Frankie DeChiazza', 'Mixed Media', 'USA', 'TripTrap ... international alien... alien swag... pop star', 0, 0),
('Alexander Mollov', 'Mixed Media', 'Dubai, UAE', 'Award-winning Music Video Director and multidisciplinary creative professional', 0, 1),
('Fatima Al Qasimi', 'Calligraphy & Typography', 'Sharjah, UAE', 'Traditional calligrapher and contemporary artist specializing in Arabic typography and mixed media installations.', 1200, 6)
ON DUPLICATE KEY UPDATE `name`=`name`;

-- 4. Artworks Table
CREATE TABLE IF NOT EXISTS `artworks` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `artist_id` INT DEFAULT NULL,
  `artist_name` VARCHAR(100) DEFAULT NULL,
  `title` VARCHAR(150) NOT NULL,
  `year` VARCHAR(10) DEFAULT '2024',
  `medium` VARCHAR(100) DEFAULT 'Mixed Media',
  `dimensions` VARCHAR(100) DEFAULT '120 x 80 cm',
  `description` TEXT,
  `price` VARCHAR(50) DEFAULT 'USD 1800 - 2200',
  `image_url` VARCHAR(255) DEFAULT NULL,
  `is_featured` TINYINT(1) DEFAULT 0,
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (`artist_id`) REFERENCES `artists`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Seed Sample Artworks
INSERT INTO `artworks` (`artist_name`, `title`, `year`, `medium`, `dimensions`, `description`, `price`, `image_url`, `is_featured`) VALUES
('Fatima Al Qasimi', 'Sacred Verses', '2024', 'Mixed Media on Paper', '70 x 50 cm', 'Original artwork combining traditional Arabic calligraphy with classical gold leaf & ink techniques.', 'USD 1800 - 2200', 'https://images.unsplash.com/photo-1579783902614-a3fb3927b675?q=80&w=1200&auto=format&fit=crop', 1),
('Fatima Al Qasimi', 'Arabic Calligraphy Composition #2', '2023', 'Acrylic on Canvas', '90 x 60 cm', 'A beautiful piece showcasing calligraphy & typography techniques.', '$2,000', 'https://images.unsplash.com/photo-1541701494587-cb58502866ab?q=80&w=1200&auto=format&fit=crop', 1)
ON DUPLICATE KEY UPDATE `title`=`title`;

-- 5. Bookings Table
CREATE TABLE IF NOT EXISTS `bookings` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `full_name` VARCHAR(100) NOT NULL,
  `email` VARCHAR(120) NOT NULL,
  `phone` VARCHAR(30) DEFAULT NULL,
  `artist_name` VARCHAR(100) DEFAULT NULL,
  `booking_type` VARCHAR(100) DEFAULT NULL,
  `budget_range` VARCHAR(100) DEFAULT NULL,
  `event_date` VARCHAR(50) DEFAULT NULL,
  `end_date` VARCHAR(50) DEFAULT NULL,
  `location` VARCHAR(150) DEFAULT NULL,
  `description` TEXT,
  `requirements` TEXT,
  `status` VARCHAR(50) DEFAULT 'Pending',
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 6. Events Table
CREATE TABLE IF NOT EXISTS `events` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `title` VARCHAR(150) NOT NULL,
  `description` TEXT,
  `category` VARCHAR(100) DEFAULT NULL,
  `event_date` VARCHAR(50) DEFAULT NULL,
  `end_date` VARCHAR(50) DEFAULT NULL,
  `location` VARCHAR(150) DEFAULT NULL,
  `venue` VARCHAR(150) DEFAULT NULL,
  `is_free` TINYINT(1) DEFAULT 1,
  `organizer_name` VARCHAR(100) DEFAULT NULL,
  `contact_email` VARCHAR(120) DEFAULT NULL,
  `contact_phone` VARCHAR(30) DEFAULT NULL,
  `tags` VARCHAR(255) DEFAULT NULL,
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 7. Government Entities Table
CREATE TABLE IF NOT EXISTS `government_entities` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `name` VARCHAR(150) NOT NULL,
  `default_is_open` TINYINT(1) DEFAULT 1,
  `rating` DECIMAL(3,1) DEFAULT 4.5,
  `review_count` INT DEFAULT 0,
  `category` VARCHAR(120) NOT NULL,
  `location` VARCHAR(150) NOT NULL,
  `default_timing` VARCHAR(100) NOT NULL,
  `website_url` VARCHAR(255) NOT NULL,
  `directions_url` VARCHAR(255) NOT NULL,
  `google_maps_reviews_url` VARCHAR(255) DEFAULT NULL,
  `open_hour` INT DEFAULT NULL,
  `open_minute` INT DEFAULT 0,
  `close_hour` INT DEFAULT NULL,
  `close_minute` INT DEFAULT 0,
  `closed_days` VARCHAR(50) DEFAULT NULL,
  `seasonal_notice` VARCHAR(150) DEFAULT NULL,
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Seed Government Entities Data
INSERT INTO `government_entities` 
(`name`, `default_is_open`, `rating`, `review_count`, `category`, `location`, `default_timing`, `website_url`, `directions_url`, `google_maps_reviews_url`, `open_hour`, `open_minute`, `close_hour`, `close_minute`, `closed_days`, `seasonal_notice`) 
VALUES
('Dubai Culture & Arts Authority', 1, 4.5, 120, 'Government · Cultural Authority', 'Al Shindagha, Dubai', 'Open · Closes at 15:00', 'https://www.dubaiculture.gov.ae/', 'https://maps.google.com/?q=Dubai+Culture+and+Arts+Authority+Al+Shindagha', 'https://maps.google.com/?q=Dubai+Culture+and+Arts+Authority+Al+Shindagha', 7, 30, 15, 0, '6,7', NULL),
('Ministry of Culture & Youth', 1, 4.2, 98, 'Government · Federal Ministry', 'Abu Dhabi, UAE', 'Open · Closes at 14:30', 'https://www.moccae.gov.ae/', 'https://maps.google.com/?q=Ministry+of+Climate+Change+and+Environment+Abu+Dhabi', 'https://maps.google.com/?q=Ministry+of+Climate+Change+and+Environment+Abu+Dhabi', 7, 30, 14, 30, '6,7', NULL),
('Dubai Design District (d3)', 1, 4.7, 215, 'Creative Hub · Design District', 'Dubai Design District, Dubai', 'Open · Closes at 22:00', 'https://dubaidesigndistrict.com/', 'https://maps.google.com/?q=Dubai+Design+District', 'https://maps.google.com/?q=Dubai+Design+District', 8, 0, 22, 0, NULL, NULL),
('Art Dubai', 0, 4.6, 180, 'Art Fair · Cultural Event', 'Madinat Jumeirah, Dubai', 'Closed · Opens Mar 2026', 'https://www.artdubai.ae/', 'https://maps.google.com/?q=Madinat+Jumeirah+Dubai', 'https://maps.google.com/?q=Madinat+Jumeirah+Dubai', NULL, 0, NULL, 0, NULL, 'Closed · Opens Mar 2026'),
('Alserkal Avenue', 1, 4.8, 310, 'Arts District · Gallery Hub', 'Al Quoz, Dubai', 'Open · Closes at 20:00', 'https://alserkal.online/', 'https://maps.google.com/?q=Alserkal+Avenue+Al+Quoz', 'https://maps.google.com/?q=Alserkal+Avenue+Al+Quoz', 10, 0, 20, 0, NULL, NULL),
('Dubai Opera', 1, 4.9, 450, 'Performing Arts · Venue', 'Downtown Dubai', 'Open · Next show at 19:30', 'https://www.dubaiopera.com/en', 'https://maps.google.com/?q=Dubai+Opera+Downtown', 'https://maps.google.com/?q=Dubai+Opera+Downtown', 10, 0, 23, 0, NULL, NULL)
ON DUPLICATE KEY UPDATE `name`=`name`;
