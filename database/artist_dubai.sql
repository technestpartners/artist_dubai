-- =========================================================
-- Artist Dubai - Full Production MySQL Database Dump
-- Generated for Hostinger MySQL Database (u530915492_artist_dubai)
-- =========================================================

SET FOREIGN_KEY_CHECKS = 0;
SET SQL_MODE = 'NO_AUTO_VALUE_ON_ZERO';
SET time_zone = '+00:00';

-- --------------------------------------------------------
-- Table structure for `users`
-- --------------------------------------------------------
DROP TABLE IF EXISTS `users`;
CREATE TABLE `users` (
  `id` int NOT NULL AUTO_INCREMENT,
  `full_name` varchar(255) NOT NULL,
  `email` varchar(255) NOT NULL,
  `password_hash` varchar(255) NOT NULL,
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `email` (`email`)
) ENGINE=InnoDB AUTO_INCREMENT=8 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Dumping data for table `users`
INSERT INTO `users` (`id`, `full_name`, `email`, `password_hash`, `created_at`) VALUES ('2', 'Demo Artist', 'artist@example.com', '$2y$10$6K6XghO8xDxWcleMbdR.EuBPPbFqtq2UMH0xttuFPNkbTQWUPr2wi', '2026-08-29 16:21:46');
INSERT INTO `users` (`id`, `full_name`, `email`, `password_hash`, `created_at`) VALUES ('3', 'Renish Test', 'renish_1788001988@gmail.com', '$2y$10$z3sUlMo9X47Drw4cd1Z/wOalUyInf0p6SPd.8pH91/p2STMKxX17W', '2026-08-29 16:43:08');
INSERT INTO `users` (`id`, `full_name`, `email`, `password_hash`, `created_at`) VALUES ('4', 'renish', 'renish@gmail.com', '$2y$10$7FHw5iKQ8n9EXZyMuMJJI.rFYm231NHori.m1ZJ3.RlJ08Alw4rWK', '2026-08-29 16:43:48');
INSERT INTO `users` (`id`, `full_name`, `email`, `password_hash`, `created_at`) VALUES ('5', 'QA Tester', 'qa_test_1788076860@artistdubai.com', '$2y$10$aqua9QqzuAPwdhOGEmlRXuHUW0apvgXO1ds7XaBR9wxvwmm5aRHDK', '2026-08-30 13:31:00');
INSERT INTO `users` (`id`, `full_name`, `email`, `password_hash`, `created_at`) VALUES ('6', 'QA Tester', 'qa_test_1788078632@artistdubai.com', '$2y$10$8Yowbb7YGwNmrfTvRHUnEO3DmqOtZ98uIC3g/831j0UXddIbWEaj6', '2026-08-30 14:00:32');
INSERT INTO `users` (`id`, `full_name`, `email`, `password_hash`, `created_at`) VALUES ('7', 'QA Tester', 'qa_test_1788080374@artistdubai.com', '$2y$10$c/ZrVkNy7Zu4oZSeosubCu8KHy3NSXq/kLZC8kbEtg43aMpK7l4.i', '2026-08-30 14:29:34');

-- --------------------------------------------------------
-- Table structure for `artists`
-- --------------------------------------------------------
DROP TABLE IF EXISTS `artists`;
CREATE TABLE `artists` (
  `id` int NOT NULL AUTO_INCREMENT,
  `user_id` int DEFAULT NULL,
  `name` varchar(255) NOT NULL,
  `category` varchar(255) NOT NULL,
  `location` varchar(255) NOT NULL,
  `bio` text,
  `avatar_url` varchar(500) DEFAULT NULL,
  `banner_url` varchar(500) DEFAULT NULL,
  `followers_count` int DEFAULT '0',
  `likes_count` int DEFAULT '0',
  `works_count` int DEFAULT '0',
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  `email` varchar(255) DEFAULT NULL,
  `phone` varchar(50) DEFAULT NULL,
  `website` varchar(255) DEFAULT NULL,
  `instagram` varchar(255) DEFAULT NULL,
  `experience_level` varchar(100) DEFAULT NULL,
  `booking_rate` varchar(100) DEFAULT 'AED 1500+',
  PRIMARY KEY (`id`),
  KEY `idx_artists_category` (`category`(50)),
  KEY `idx_artists_name` (`name`(100)),
  KEY `idx_artists_created` (`created_at`)
) ENGINE=InnoDB AUTO_INCREMENT=9 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Dumping data for table `artists`
INSERT INTO `artists` (`id`, `user_id`, `name`, `category`, `location`, `bio`, `avatar_url`, `banner_url`, `followers_count`, `likes_count`, `works_count`, `created_at`, `email`, `phone`, `website`, `instagram`, `experience_level`, `booking_rate`) VALUES ('1', NULL, 'Automated Test Artist', 'Contemporary Painting', 'Downtown Dubai', 'A test artist profile verified by automated test suite.', 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=400&q=80', 'https://images.unsplash.com/photo-1579783900882-c0d3dad7b119?auto=format&fit=crop&w=1200&q=80', '39', '142', '0', '2026-08-30 13:31:00', '', '', '', '', '', 'AED 1500+');
INSERT INTO `artists` (`id`, `user_id`, `name`, `category`, `location`, `bio`, `avatar_url`, `banner_url`, `followers_count`, `likes_count`, `works_count`, `created_at`, `email`, `phone`, `website`, `instagram`, `experience_level`, `booking_rate`) VALUES ('2', NULL, 'Renish Artistry', 'Contemporary Painting', 'Dubai Design District (d3)', 'Celebrated UAE visual artist specializing in modern abstract, fluid acrylics, and textured canvas commissions for luxury interiors.', 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=600&q=80', 'https://images.unsplash.com/photo-1579783900882-c0d3dad7b119?auto=format&fit=crop&w=1200&q=80', '1421', '420', '38', '2026-08-30 13:32:26', 'renish@artistdubai.com', '+971 50 123 4567', 'https://artistdubai.com/renish', '@renish_art', 'Senior / 9 Years', 'AED 2,500+');
INSERT INTO `artists` (`id`, `user_id`, `name`, `category`, `location`, `bio`, `avatar_url`, `banner_url`, `followers_count`, `likes_count`, `works_count`, `created_at`, `email`, `phone`, `website`, `instagram`, `experience_level`, `booking_rate`) VALUES ('3', NULL, 'Fatima Al-Hashemi', 'Arabic Calligraphy', 'Al Shindagha Historic District', 'Master calligrapher blending classical Thuluth and Diwani scripts with contemporary 24K gold leaf illumination.', 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?auto=format&fit=crop&w=600&q=80', 'https://images.unsplash.com/photo-1582561424760-0321d75e81fa?auto=format&fit=crop&w=1200&q=80', '981', '310', '24', '2026-08-30 13:32:26', 'fatima@artistdubai.com', '+971 55 987 6543', 'https://fatimacalligraphy.ae', '@fatima_calligraphy', 'Master / 12 Years', 'AED 1,800+');
INSERT INTO `artists` (`id`, `user_id`, `name`, `category`, `location`, `bio`, `avatar_url`, `banner_url`, `followers_count`, `likes_count`, `works_count`, `created_at`, `email`, `phone`, `website`, `instagram`, `experience_level`, `booking_rate`) VALUES ('4', NULL, 'Tariq Mansoor', 'Sculpture & Bronze', 'Al Quoz Creative Zone', 'Award-winning sculptor creating monumental bronze and marble installations celebrating UAE maritime and falconry heritage.', 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=600&q=80', 'https://images.unsplash.com/photo-1578301978693-85fa9c0320b9?auto=format&fit=crop&w=1200&q=80', '760', '250', '19', '2026-08-30 13:32:26', 'tariq@artistdubai.com', '+971 52 456 7890', 'https://tariqmansoor.com', '@tariq_sculpts', 'Senior / 14 Years', 'AED 3,200+');
INSERT INTO `artists` (`id`, `user_id`, `name`, `category`, `location`, `bio`, `avatar_url`, `banner_url`, `followers_count`, `likes_count`, `works_count`, `created_at`, `email`, `phone`, `website`, `instagram`, `experience_level`, `booking_rate`) VALUES ('5', NULL, 'Elena Rostova', 'Digital & Generative Art', 'Dubai Media City', 'Pioneer in immersive generative art, 3D projection mapping, and digital collectible artworks for tech and hospitality venues.', 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?auto=format&fit=crop&w=600&q=80', 'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?auto=format&fit=crop&w=1200&q=80', '2340', '680', '45', '2026-08-30 13:32:26', 'elena@artistdubai.com', '+971 56 321 6549', 'https://elenarostova.art', '@elena_digital_visions', 'Expert / 8 Years', 'AED 2,000+');
INSERT INTO `artists` (`id`, `user_id`, `name`, `category`, `location`, `bio`, `avatar_url`, `banner_url`, `followers_count`, `likes_count`, `works_count`, `created_at`, `email`, `phone`, `website`, `instagram`, `experience_level`, `booking_rate`) VALUES ('6', NULL, 'Zayd Al-Nuaimi', 'Fine Art Photography', 'Jumeirah Beach Road', 'Documentary and landscape photographer capturing the architectural marvels and raw desert wilderness of the Arabian peninsula.', 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=600&q=80', 'https://images.unsplash.com/photo-1512453979798-5ea266f8880c?auto=format&fit=crop&w=1200&q=80', '1120', '390', '52', '2026-08-30 13:32:26', 'zayd@artistdubai.com', '+971 50 789 0123', 'https://zaydphotography.ae', '@zayd_nuaimi_photo', 'Mid-Senior / 6 Years', 'AED 1,600+');
INSERT INTO `artists` (`id`, `user_id`, `name`, `category`, `location`, `bio`, `avatar_url`, `banner_url`, `followers_count`, `likes_count`, `works_count`, `created_at`, `email`, `phone`, `website`, `instagram`, `experience_level`, `booking_rate`) VALUES ('7', NULL, 'Automated Test Artist', 'Contemporary Painting', 'Downtown Dubai', 'A test artist profile verified by automated test suite.', 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=400&q=80', 'https://images.unsplash.com/photo-1579783900882-c0d3dad7b119?auto=format&fit=crop&w=1200&q=80', '12', '14', '0', '2026-08-30 14:00:32', '', '', '', '', '', 'AED 1500+');
INSERT INTO `artists` (`id`, `user_id`, `name`, `category`, `location`, `bio`, `avatar_url`, `banner_url`, `followers_count`, `likes_count`, `works_count`, `created_at`, `email`, `phone`, `website`, `instagram`, `experience_level`, `booking_rate`) VALUES ('8', NULL, 'Automated Test Artist', 'Contemporary Painting', 'Downtown Dubai', 'A test artist profile verified by automated test suite.', 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=400&q=80', 'https://images.unsplash.com/photo-1579783900882-c0d3dad7b119?auto=format&fit=crop&w=1200&q=80', '13', '15', '2', '2026-08-30 14:29:34', '', '', '', '', '', 'AED 1500+');

-- --------------------------------------------------------
-- Table structure for `artworks`
-- --------------------------------------------------------
DROP TABLE IF EXISTS `artworks`;
CREATE TABLE `artworks` (
  `id` int NOT NULL AUTO_INCREMENT,
  `artist_id` int DEFAULT NULL,
  `artist_name` varchar(100) DEFAULT NULL,
  `title` varchar(150) NOT NULL,
  `year` varchar(10) DEFAULT '2024',
  `medium` varchar(100) DEFAULT 'Mixed Media',
  `dimensions` varchar(100) DEFAULT '120 x 80 cm',
  `description` text,
  `price` varchar(50) DEFAULT 'USD 1800 - 2200',
  `image_url` varchar(255) DEFAULT NULL,
  `is_featured` tinyint(1) DEFAULT '0',
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_artworks_artist_id` (`artist_id`),
  KEY `idx_artworks_featured` (`is_featured`),
  KEY `idx_artworks_created` (`created_at`),
  CONSTRAINT `artworks_ibfk_1` FOREIGN KEY (`artist_id`) REFERENCES `artists` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB AUTO_INCREMENT=15 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Dumping data for table `artworks`
INSERT INTO `artworks` (`id`, `artist_id`, `artist_name`, `title`, `year`, `medium`, `dimensions`, `description`, `price`, `image_url`, `is_featured`, `created_at`) VALUES ('1', '1', 'Automated Test Artist', 'Ethereal Dunes Horizon', '2024', 'Oil & Acrylic on Canvas', '120 x 90 cm', 'A masterwork blending the shifting sunset tones of the Arabian desert with contemporary textured strokes.', '$2,400', 'https://images.unsplash.com/photo-1579783900882-c0d3dad7b119?auto=format&fit=crop&w=800&q=80', '1', '2026-08-30 14:38:04');
INSERT INTO `artworks` (`id`, `artist_id`, `artist_name`, `title`, `year`, `medium`, `dimensions`, `description`, `price`, `image_url`, `is_featured`, `created_at`) VALUES ('2', '1', 'Automated Test Artist', 'Chromatics in Motion', '2024', 'Mixed Media & Pigments', '100 x 80 cm', 'Dynamic explosion of sapphire blues and fiery ochre symbolizing the kinetic vitality of Dubai.', '$1,950', 'https://images.unsplash.com/photo-1541701494587-cb58502866ab?auto=format&fit=crop&w=800&q=80', '1', '2026-08-30 14:38:04');
INSERT INTO `artworks` (`id`, `artist_id`, `artist_name`, `title`, `year`, `medium`, `dimensions`, `description`, `price`, `image_url`, `is_featured`, `created_at`) VALUES ('3', '1', 'Automated Test Artist', 'Luminous Waves of d3', '2024', 'Digital & Generative Canvas', '140 x 100 cm', 'Fluid gradients and velvet purples inspired by architectural illumination across Dubai Design District.', '$3,100', 'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?auto=format&fit=crop&w=800&q=80', '0', '2026-08-30 14:38:04');
INSERT INTO `artworks` (`id`, `artist_id`, `artist_name`, `title`, `year`, `medium`, `dimensions`, `description`, `price`, `image_url`, `is_featured`, `created_at`) VALUES ('4', '1', 'Automated Test Artist', 'Golden Hour Mirage', '2024', 'Acrylic & 24K Gold Leaf', '110 x 85 cm', 'Rich desert textures overlaid with radiant leaf highlights celebrating UAE heritage.', '$2,800', 'https://images.unsplash.com/photo-1512453979798-5ea266f8880c?auto=format&fit=crop&w=800&q=80', '0', '2026-08-30 14:38:04');
INSERT INTO `artworks` (`id`, `artist_id`, `artist_name`, `title`, `year`, `medium`, `dimensions`, `description`, `price`, `image_url`, `is_featured`, `created_at`) VALUES ('5', '1', 'Automated Test Artist', 'Cosmic Constellations', '2025', 'Oil on Textured Linen', '130 x 95 cm', 'Starry nightscapes over modern architectural skylines rendered in deep lapis lazuli and silver.', '$3,500', 'https://images.unsplash.com/photo-1451187580459-43490279c0fa?auto=format&fit=crop&w=800&q=80', '0', '2026-08-30 14:38:04');
INSERT INTO `artworks` (`id`, `artist_id`, `artist_name`, `title`, `year`, `medium`, `dimensions`, `description`, `price`, `image_url`, `is_featured`, `created_at`) VALUES ('6', '1', 'Automated Test Artist', 'Geometric Harmony', '2024', 'Mixed Media Collage', '90 x 90 cm', 'Traditional Islamic geometric patterns reimagined through modern minimalist balance.', '$1,750', 'https://images.unsplash.com/photo-1579783900882-c0d3dad7b119?auto=format&fit=crop&w=800&q=80', '0', '2026-08-30 14:38:04');
INSERT INTO `artworks` (`id`, `artist_id`, `artist_name`, `title`, `year`, `medium`, `dimensions`, `description`, `price`, `image_url`, `is_featured`, `created_at`) VALUES ('7', '2', 'Renish Artistry', 'Symphony in Emerald & Bronze', '2024', 'Fluid Acrylics & Bronze Pigment', '150 x 100 cm', 'Luxury abstract artwork commissioned for premier hotel and gallery installations.', '$4,200', 'https://images.unsplash.com/photo-1578301978693-85fa9c0320b9?auto=format&fit=crop&w=800&q=80', '1', '2026-08-30 14:38:04');
INSERT INTO `artworks` (`id`, `artist_id`, `artist_name`, `title`, `year`, `medium`, `dimensions`, `description`, `price`, `image_url`, `is_featured`, `created_at`) VALUES ('8', '2', 'Renish Artistry', 'Metropolitan Pulse', '2025', 'Heavy Body Acrylic on Canvas', '120 x 80 cm', 'High-contrast palette capturing the nocturnal rhythm of Sheikh Zayed Road.', '$2,600', 'https://images.unsplash.com/photo-1550684848-fac1c5b4e853?auto=format&fit=crop&w=800&q=80', '1', '2026-08-30 14:38:04');
INSERT INTO `artworks` (`id`, `artist_id`, `artist_name`, `title`, `year`, `medium`, `dimensions`, `description`, `price`, `image_url`, `is_featured`, `created_at`) VALUES ('9', '3', 'Fatima Al-Hashemi', 'Divine Verse in Diwani', '2024', 'Classical Calligraphy & Gold Leaf', '120 x 70 cm', 'Harmonious Diwani script hand-inked on handmade parchment with genuine 24K leaf border.', '$3,800', 'https://images.unsplash.com/photo-1582561424760-0321d75e81fa?auto=format&fit=crop&w=800&q=80', '1', '2026-08-30 14:38:04');
INSERT INTO `artworks` (`id`, `artist_id`, `artist_name`, `title`, `year`, `medium`, `dimensions`, `description`, `price`, `image_url`, `is_featured`, `created_at`) VALUES ('10', '4', 'Tariq Mansoor', 'Falcon Ascending', '2024', 'Cast Bronze & White Marble Base', '65 x 40 x 30 cm', 'Dynamic sculpture representing soaring falconry traditions of the United Arab Emirates.', '$5,500', 'https://images.unsplash.com/photo-1561839561-b13bcfe95249?auto=format&fit=crop&w=800&q=80', '1', '2026-08-30 14:38:04');
INSERT INTO `artworks` (`id`, `artist_id`, `artist_name`, `title`, `year`, `medium`, `dimensions`, `description`, `price`, `image_url`, `is_featured`, `created_at`) VALUES ('11', '5', 'Elena Rostova', 'Quantum Mirage 3D', '2025', 'Generative 3D Spatial Canvas', '160 x 100 cm', 'Immersive holographic-styled generative canvas using algorithmic ray-tracing.', '$4,800', 'https://images.unsplash.com/photo-1634017839464-5c339ebe3cb4?auto=format&fit=crop&w=800&q=80', '1', '2026-08-30 14:38:04');
INSERT INTO `artworks` (`id`, `artist_id`, `artist_name`, `title`, `year`, `medium`, `dimensions`, `description`, `price`, `image_url`, `is_featured`, `created_at`) VALUES ('12', '6', 'Zayd Al-Nuaimi', 'Crests of the Rub al Khali', '2024', 'Archival Fine Art Pigment Print', '150 x 100 cm', 'Breathtaking panoramic capture of untouched crimson dunes at dawn in the Empty Quarter.', '$1,900', 'https://images.unsplash.com/photo-1509316975850-ff9c5deb0cd9?auto=format&fit=crop&w=800&q=80', '1', '2026-08-30 14:38:04');
INSERT INTO `artworks` (`id`, `artist_id`, `artist_name`, `title`, `year`, `medium`, `dimensions`, `description`, `price`, `image_url`, `is_featured`, `created_at`) VALUES ('13', '8', 'Automated Test Artist', 'Golden Sands Symphony', '2026', 'Oil on Canvas', '150 x 100 cm', 'A masterwork celebrating Dubai gold and dunes.', '$3,200', 'http://127.0.0.1:8000/api.php?resource=uploads&file=gallery_1788085387_6505ca97.png', '0', '2026-08-30 15:53:18');
INSERT INTO `artworks` (`id`, `artist_id`, `artist_name`, `title`, `year`, `medium`, `dimensions`, `description`, `price`, `image_url`, `is_featured`, `created_at`) VALUES ('14', '8', 'Automated Test Artist', 'Golden Sands Symphony', '2026', 'Oil on Canvas', '150 x 100 cm', 'A grand symphony of golden desert dunes under morning light.', '$3,200', 'http://localhost:8000/api.php?resource=uploads&file=gallery_1788084700_eed36cfa.png', '1', '2026-08-30 16:07:37');

-- --------------------------------------------------------
-- Table structure for `events`
-- --------------------------------------------------------
DROP TABLE IF EXISTS `events`;
CREATE TABLE `events` (
  `id` int NOT NULL AUTO_INCREMENT,
  `title` varchar(255) NOT NULL,
  `description` text,
  `category` varchar(100) DEFAULT NULL,
  `price` varchar(50) DEFAULT 'Free',
  `event_date` varchar(100) DEFAULT NULL,
  `end_date` varchar(100) DEFAULT NULL,
  `location` varchar(255) DEFAULT NULL,
  `venue` varchar(255) DEFAULT NULL,
  `is_free` tinyint(1) DEFAULT '1',
  `attendees_count` int DEFAULT '0',
  `max_attendees` int DEFAULT '100',
  `organizer_name` varchar(255) DEFAULT NULL,
  `contact_email` varchar(255) DEFAULT NULL,
  `contact_phone` varchar(100) DEFAULT NULL,
  `tags` varchar(500) DEFAULT NULL,
  `image_url` varchar(500) DEFAULT NULL,
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_events_category` (`category`(50)),
  KEY `idx_events_created` (`created_at`)
) ENGINE=InnoDB AUTO_INCREMENT=8 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Dumping data for table `events`
INSERT INTO `events` (`id`, `title`, `description`, `category`, `price`, `event_date`, `end_date`, `location`, `venue`, `is_free`, `attendees_count`, `max_attendees`, `organizer_name`, `contact_email`, `contact_phone`, `tags`, `image_url`, `created_at`) VALUES ('1', 'Dubai Modern Art Showcase', 'A premier art gathering bringing together contemporary painters, sculptors, and digital creators in Dubai.', 'Art Exhibition', 'Free', '2026-10-15 18:00', '2026-10-15 22:00', 'Dubai, UAE', 'Alserkal Avenue, Warehouse 42', '1', '0', '100', 'Renish Artistry', 'renish@gmail.com', '+971 50 123 4567', 'Art,Exhibition,Dubai,Contemporary', 'https://images.unsplash.com/photo-1579783900882-c0d3dad7b119?auto=format&fit=crop&w=1200&q=80', '2026-08-29 16:55:32');
INSERT INTO `events` (`id`, `title`, `description`, `category`, `price`, `event_date`, `end_date`, `location`, `venue`, `is_free`, `attendees_count`, `max_attendees`, `organizer_name`, `contact_email`, `contact_phone`, `tags`, `image_url`, `created_at`) VALUES ('2', 'Automated Art Gala 2026', 'A premier art gala night verified by automated test suite.', 'Art Exhibition', 'Free', '', '', 'Dubai Opera Ballroom', '', '1', '0', '100', 'Dubai Art Collective', '', '', '', 'https://images.unsplash.com/photo-1579783900882-c0d3dad7b119?auto=format&fit=crop&w=1200&q=80', '2026-08-30 13:31:00');
INSERT INTO `events` (`id`, `title`, `description`, `category`, `price`, `event_date`, `end_date`, `location`, `venue`, `is_free`, `attendees_count`, `max_attendees`, `organizer_name`, `contact_email`, `contact_phone`, `tags`, `image_url`, `created_at`) VALUES ('3', 'Dubai Modern Art Showcase 2026', 'A premier gathering bringing together top contemporary painters, sculptors, and digital creators across the Middle East.', 'Art Exhibition', 'Free Entry', '15 Oct 2026', '15 Oct 2026', 'Alserkal Avenue, Warehouse 42, Dubai', 'Warehouse 42', '1', '140', '200', 'Renish Artistry', 'events@artistdubai.com', '+971 50 123 4567', 'Contemporary,Modern,Exhibition,Dubai', 'https://images.unsplash.com/photo-1579783900882-c0d3dad7b119?auto=format&fit=crop&w=1200&q=80', '2026-08-30 13:32:26');
INSERT INTO `events` (`id`, `title`, `description`, `category`, `price`, `event_date`, `end_date`, `location`, `venue`, `is_free`, `attendees_count`, `max_attendees`, `organizer_name`, `contact_email`, `contact_phone`, `tags`, `image_url`, `created_at`) VALUES ('4', 'Arabian Calligraphy Masterclass', 'Exclusive 4-hour hands-on masterclass in classical Thuluth and Diwani calligraphy guided by Fatima Al-Hashemi.', 'Workshop', '120 AED', '22 Oct 2026', '22 Oct 2026', 'Al Shindagha Historic Cultural Center, Dubai', 'Cultural Center', '0', '28', '30', 'Fatima Al-Hashemi', 'fatima@artistdubai.com', '+971 55 987 6543', 'Calligraphy,Arabic,GoldLeaf,Masterclass', 'https://images.unsplash.com/photo-1582561424760-0321d75e81fa?auto=format&fit=crop&w=1200&q=80', '2026-08-30 13:32:26');
INSERT INTO `events` (`id`, `title`, `description`, `category`, `price`, `event_date`, `end_date`, `location`, `venue`, `is_free`, `attendees_count`, `max_attendees`, `organizer_name`, `contact_email`, `contact_phone`, `tags`, `image_url`, `created_at`) VALUES ('5', 'Immersive Digital Visions & VR Night', 'Step into futuristic generative 3D art installations, AI-powered paintings, and interactive projections under the Dubai stars.', 'Digital Showcase', '50 AED', '05 Nov 2026', '05 Nov 2026', 'Dubai Design District (d3), Building 7', 'Building 7 Atrium', '0', '95', '150', 'Elena Rostova & d3 Collective', 'digital@dubaidesigndistrict.com', '+971 56 321 6549', 'DigitalArt,VR,Generative,AI,d3', 'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?auto=format&fit=crop&w=1200&q=80', '2026-08-30 13:32:26');
INSERT INTO `events` (`id`, `title`, `description`, `category`, `price`, `event_date`, `end_date`, `location`, `venue`, `is_free`, `attendees_count`, `max_attendees`, `organizer_name`, `contact_email`, `contact_phone`, `tags`, `image_url`, `created_at`) VALUES ('6', 'Automated Art Gala 2026', 'A premier art gala night verified by automated test suite.', 'Art Exhibition', 'Free', '15 Oct 2026', '', 'Dubai Opera Ballroom', '', '1', '0', '101', 'Dubai Art Collective', '', '', '', 'https://images.unsplash.com/photo-1579783900882-c0d3dad7b119?auto=format&fit=crop&w=1200&q=80', '2026-08-30 14:00:32');
INSERT INTO `events` (`id`, `title`, `description`, `category`, `price`, `event_date`, `end_date`, `location`, `venue`, `is_free`, `attendees_count`, `max_attendees`, `organizer_name`, `contact_email`, `contact_phone`, `tags`, `image_url`, `created_at`) VALUES ('7', 'Automated Art Gala 2026', 'A premier art gala night verified by automated test suite.', 'Art Exhibition', 'Free', '', '', 'Dubai Opera Ballroom', '', '1', '0', '100', 'Dubai Art Collective', '', '', '', 'https://images.unsplash.com/photo-1579783900882-c0d3dad7b119?auto=format&fit=crop&w=1200&q=80', '2026-08-30 14:29:34');

-- --------------------------------------------------------
-- Table structure for `galleries`
-- --------------------------------------------------------
DROP TABLE IF EXISTS `galleries`;
CREATE TABLE `galleries` (
  `id` int NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  `category` varchar(255) DEFAULT NULL,
  `location` varchar(255) DEFAULT NULL,
  `timing` varchar(255) DEFAULT NULL,
  `website` varchar(500) DEFAULT NULL,
  `image_url` varchar(500) DEFAULT NULL,
  `artist_id` varchar(50) DEFAULT NULL,
  `artist_name` varchar(255) DEFAULT NULL,
  `description` text,
  `photo_count` int DEFAULT '1',
  `images_json` text,
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=15 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Dumping data for table `galleries`
INSERT INTO `galleries` (`id`, `name`, `category`, `location`, `timing`, `website`, `image_url`, `artist_id`, `artist_name`, `description`, `photo_count`, `images_json`, `created_at`) VALUES ('1', 'Alserkal Test Gallery', 'Contemporary Art', 'Alserkal Avenue, Warehouse 99, Dubai', NULL, NULL, 'https://images.unsplash.com/photo-1561839561-b13bcfe95249?auto=format&fit=crop&w=1200&q=80', NULL, NULL, NULL, '1', '[\"https:\\/\\/images.unsplash.com\\/photo-1561839561-b13bcfe95249?auto=format&fit=crop&w=1200&q=80\"]', '2026-08-30 13:31:00');
INSERT INTO `galleries` (`id`, `name`, `category`, `location`, `timing`, `website`, `image_url`, `artist_id`, `artist_name`, `description`, `photo_count`, `images_json`, `created_at`) VALUES ('2', 'The Third Line', 'Contemporary Art · Middle East Focus', 'Alserkal Avenue, Warehouse 78, Al Quoz, Dubai', 'Open · Closes at 19:00', 'https://thethirdline.com', 'https://images.unsplash.com/photo-1513364776144-60967b0f800f?auto=format&fit=crop&w=800&q=80', NULL, NULL, NULL, '1', NULL, '2026-08-30 13:32:26');
INSERT INTO `galleries` (`id`, `name`, `category`, `location`, `timing`, `website`, `image_url`, `artist_id`, `artist_name`, `description`, `photo_count`, `images_json`, `created_at`) VALUES ('3', 'Custot Gallery Dubai', 'Modern & International Masters', 'Alserkal Avenue, Warehouse 84, Al Quoz, Dubai', 'Open · Closes at 19:00', 'https://custotgallerydubai.com', 'https://images.unsplash.com/photo-1582561424760-0321d75e81fa?auto=format&fit=crop&w=800&q=80', NULL, NULL, NULL, '1', NULL, '2026-08-30 13:32:26');
INSERT INTO `galleries` (`id`, `name`, `category`, `location`, `timing`, `website`, `image_url`, `artist_id`, `artist_name`, `description`, `photo_count`, `images_json`, `created_at`) VALUES ('4', 'Meem Gallery', 'Modern Arab & Iranian Art', 'Umm Suqeim Road, Al Quoz 3, Dubai', 'Open · Closes at 18:00', 'https://meemartgallery.com', 'https://images.unsplash.com/photo-1579783900882-c0d3dad7b119?auto=format&fit=crop&w=800&q=80', NULL, NULL, NULL, '1', NULL, '2026-08-30 13:32:26');
INSERT INTO `galleries` (`id`, `name`, `category`, `location`, `timing`, `website`, `image_url`, `artist_id`, `artist_name`, `description`, `photo_count`, `images_json`, `created_at`) VALUES ('5', 'Lawrie Shabibi', 'Contemporary Global Art', 'Alserkal Avenue, Warehouse 21, Al Quoz, Dubai', 'Open · Closes at 19:00', 'https://lawrieshabibi.com', 'https://images.unsplash.com/photo-1561839561-b13bcfe95249?auto=format&fit=crop&w=800&q=80', NULL, NULL, NULL, '1', NULL, '2026-08-30 13:32:26');
INSERT INTO `galleries` (`id`, `name`, `category`, `location`, `timing`, `website`, `image_url`, `artist_id`, `artist_name`, `description`, `photo_count`, `images_json`, `created_at`) VALUES ('6', 'Alserkal Test Gallery', 'Contemporary Art', 'Alserkal Avenue, Warehouse 99, Dubai', NULL, NULL, 'https://images.unsplash.com/photo-1561839561-b13bcfe95249?auto=format&fit=crop&w=1200&q=80', NULL, NULL, NULL, '1', '[\"https:\\/\\/images.unsplash.com\\/photo-1561839561-b13bcfe95249?auto=format&fit=crop&w=1200&q=80\"]', '2026-08-30 14:00:32');
INSERT INTO `galleries` (`id`, `name`, `category`, `location`, `timing`, `website`, `image_url`, `artist_id`, `artist_name`, `description`, `photo_count`, `images_json`, `created_at`) VALUES ('7', 'Alserkal Test Gallery', 'Contemporary Art', 'Alserkal Avenue, Warehouse 99, Dubai', NULL, NULL, 'https://images.unsplash.com/photo-1561839561-b13bcfe95249?auto=format&fit=crop&w=1200&q=80', NULL, NULL, NULL, '1', '[\"https:\\/\\/images.unsplash.com\\/photo-1561839561-b13bcfe95249?auto=format&fit=crop&w=1200&q=80\"]', '2026-08-30 14:29:34');
INSERT INTO `galleries` (`id`, `name`, `category`, `location`, `timing`, `website`, `image_url`, `artist_id`, `artist_name`, `description`, `photo_count`, `images_json`, `created_at`) VALUES ('8', 'Exhibition Highlights 2024', 'Curated Showcase', 'Dubai Design District (d3)', NULL, NULL, 'https://images.unsplash.com/photo-1451187580459-43490279c0fa?q=80&w=1200&auto=format&fit=crop', '1', 'Automated Test Artist', 'Curated collection of solo and collaborative exhibition highlights.', '3', '[\"https:\\/\\/images.unsplash.com\\/photo-1451187580459-43490279c0fa?q=80&w=1200&auto=format&fit=crop\",\"https:\\/\\/images.unsplash.com\\/photo-1579783900882-c0d3dad7b119?q=80&w=1200&auto=format&fit=crop\",\"https:\\/\\/images.unsplash.com\\/photo-1578301978693-85fa9c0320b9?q=80&w=1200&auto=format&fit=crop\"]', '2026-08-30 14:57:27');
INSERT INTO `galleries` (`id`, `name`, `category`, `location`, `timing`, `website`, `image_url`, `artist_id`, `artist_name`, `description`, `photo_count`, `images_json`, `created_at`) VALUES ('9', 'Studio Behind The Scenes 2026', 'Art Gallery', 'Dubai, UAE', NULL, NULL, 'https://images.unsplash.com/photo-1513364776144-60967b0f800f?auto=format&fit=crop&w=800&q=80', '1', 'Automated Test Artist', 'Raw creative process and studio canvas preparation', '4', '[\"https:\\/\\/images.unsplash.com\\/photo-1513364776144-60967b0f800f?auto=format&fit=crop&w=800&q=80\",\"https:\\/\\/images.unsplash.com\\/photo-1579783900882-c0d3dad7b119?auto=format&fit=crop&w=800&q=80\"]', '2026-08-30 14:59:05');
INSERT INTO `galleries` (`id`, `name`, `category`, `location`, `timing`, `website`, `image_url`, `artist_id`, `artist_name`, `description`, `photo_count`, `images_json`, `created_at`) VALUES ('10', 'kkkk', 'Art Gallery', 'Dubai, UAE', NULL, NULL, 'https://images.unsplash.com/photo-1518791841217-8f162f1e1131?auto=format&fit=crop&w=1200&q=80', '8', 'Automated Test Artist', 'kkkk', '8', '[\"https:\\/\\/images.unsplash.com\\/photo-1518791841217-8f162f1e1131?auto=format&fit=crop&w=1200&q=80\",\"https:\\/\\/images.unsplash.com\\/photo-1550684848-fac1c5b4e853?auto=format&fit=crop&w=1200&q=80\",\"https:\\/\\/images.unsplash.com\\/photo-1579783900882-c0d3dad7b119?auto=format&fit=crop&w=1200&q=80\",\"https:\\/\\/images.unsplash.com\\/photo-1451187580459-43490279c0fa?auto=format&fit=crop&w=1200&q=80\",\"https:\\/\\/images.unsplash.com\\/photo-1513364776144-60967b0f800f?auto=format&fit=crop&w=800&q=80\",\"https:\\/\\/images.unsplash.com\\/photo-1578301978693-85fa9c0320b9?auto=format&fit=crop&w=1200&q=80\",\"https:\\/\\/images.unsplash.com\\/photo-1544005313-94ddf0286df2?auto=format&fit=crop&w=1200&q=80\",\"https:\\/\\/images.unsplash.com\\/photo-1561839561-b13bcfe95249?auto=format&fit=crop&w=1200&q=80\"]', '2026-08-30 15:04:09');
INSERT INTO `galleries` (`id`, `name`, `category`, `location`, `timing`, `website`, `image_url`, `artist_id`, `artist_name`, `description`, `photo_count`, `images_json`, `created_at`) VALUES ('11', '2222', 'Art Gallery', 'Dubai, UAE', NULL, NULL, 'https://images.unsplash.com/photo-1579783900882-c0d3dad7b119?auto=format&fit=crop&w=1200&q=80', '8', 'Automated Test Artist', '222', '7', '[\"https:\\/\\/images.unsplash.com\\/photo-1579783900882-c0d3dad7b119?auto=format&fit=crop&w=1200&q=80\",\"https:\\/\\/images.unsplash.com\\/photo-1451187580459-43490279c0fa?auto=format&fit=crop&w=1200&q=80\",\"https:\\/\\/images.unsplash.com\\/photo-1513364776144-60967b0f800f?auto=format&fit=crop&w=800&q=80\",\"https:\\/\\/images.unsplash.com\\/photo-1578301978693-85fa9c0320b9?auto=format&fit=crop&w=1200&q=80\",\"https:\\/\\/images.unsplash.com\\/photo-1544005313-94ddf0286df2?auto=format&fit=crop&w=1200&q=80\",\"https:\\/\\/images.unsplash.com\\/photo-1561839561-b13bcfe95249?auto=format&fit=crop&w=1200&q=80\",\"https:\\/\\/images.unsplash.com\\/photo-1582561424760-0321d75e81fa?auto=format&fit=crop&w=1200&q=80\"]', '2026-08-30 15:08:55');
INSERT INTO `galleries` (`id`, `name`, `category`, `location`, `timing`, `website`, `image_url`, `artist_id`, `artist_name`, `description`, `photo_count`, `images_json`, `created_at`) VALUES ('12', '2322', 'Art Gallery', 'Dubai, UAE', NULL, NULL, 'http://localhost:8000/api.php?resource=uploads&file=gallery_1788083316_3154a179.png', '8', 'Automated Test Artist', '2222', '4', '[\"http:\\/\\/localhost:8000\\/uploads\\/gallery_1788083316_3154a179.png\",\"http:\\/\\/localhost:8000\\/uploads\\/gallery_1788083316_1d2014f6.png\",\"http:\\/\\/localhost:8000\\/uploads\\/gallery_1788083317_5b273170.png\",\"http:\\/\\/localhost:8000\\/uploads\\/gallery_1788083317_23a86b9f.png\"]', '2026-08-30 15:18:38');
INSERT INTO `galleries` (`id`, `name`, `category`, `location`, `timing`, `website`, `image_url`, `artist_id`, `artist_name`, `description`, `photo_count`, `images_json`, `created_at`) VALUES ('13', '111152', 'Art Gallery', 'Dubai, UAE', NULL, NULL, 'http://localhost:8000/api.php?resource=uploads&file=gallery_1788084700_eed36cfa.png', '8', 'Automated Test Artist', '12541', '5', '[\"http:\\/\\/localhost:8000\\/uploads\\/gallery_1788084700_eed36cfa.png\",\"http:\\/\\/localhost:8000\\/uploads\\/gallery_1788084700_85c0d865.png\",\"http:\\/\\/localhost:8000\\/uploads\\/gallery_1788084701_a058770e.png\",\"http:\\/\\/localhost:8000\\/uploads\\/gallery_1788084701_ebd452bb.png\",\"http:\\/\\/localhost:8000\\/uploads\\/gallery_1788084701_b9eb948a.png\"]', '2026-08-30 15:41:42');
INSERT INTO `galleries` (`id`, `name`, `category`, `location`, `timing`, `website`, `image_url`, `artist_id`, `artist_name`, `description`, `photo_count`, `images_json`, `created_at`) VALUES ('14', '22', 'Art Gallery', 'Dubai, UAE', NULL, NULL, 'http://localhost:8000/api.php?resource=uploads&file=gallery_1788084945_eefd5919.png', '8', 'Automated Test Artist', '22', '9', '[\"http:\\/\\/localhost:8000\\/api.php?resource=uploads&file=gallery_1788084945_eefd5919.png\",\"http:\\/\\/localhost:8000\\/api.php?resource=uploads&file=gallery_1788084945_03be7502.png\",\"http:\\/\\/localhost:8000\\/api.php?resource=uploads&file=gallery_1788084946_9707aac5.png\",\"http:\\/\\/localhost:8000\\/api.php?resource=uploads&file=gallery_1788084946_a54926f7.png\",\"http:\\/\\/localhost:8000\\/api.php?resource=uploads&file=gallery_1788084947_157d1c6c.png\",\"http:\\/\\/localhost:8000\\/api.php?resource=uploads&file=gallery_1788084947_0b286931.png\",\"http:\\/\\/localhost:8000\\/api.php?resource=uploads&file=gallery_1788084948_61f33229.png\",\"http:\\/\\/localhost:8000\\/api.php?resource=uploads&file=gallery_1788084948_8e657115.png\",\"http:\\/\\/localhost:8000\\/api.php?resource=uploads&file=gallery_1788084949_70c20b4d.png\"]', '2026-08-30 15:45:49');

-- --------------------------------------------------------
-- Table structure for `bookings`
-- --------------------------------------------------------
DROP TABLE IF EXISTS `bookings`;
CREATE TABLE `bookings` (
  `id` int NOT NULL AUTO_INCREMENT,
  `full_name` varchar(255) NOT NULL,
  `email` varchar(255) NOT NULL,
  `phone` varchar(100) DEFAULT NULL,
  `artist_name` varchar(255) DEFAULT NULL,
  `booking_type` varchar(100) DEFAULT NULL,
  `event_date` varchar(100) DEFAULT NULL,
  `location` varchar(255) DEFAULT NULL,
  `description` text,
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  `event_id` int DEFAULT NULL,
  `event_title` varchar(255) DEFAULT NULL,
  `status` varchar(50) DEFAULT 'confirmed',
  `tickets_count` int DEFAULT '1',
  `total_price` varchar(50) DEFAULT 'Free',
  PRIMARY KEY (`id`),
  KEY `idx_bookings_email` (`email`(100))
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Dumping data for table `bookings`
INSERT INTO `bookings` (`id`, `full_name`, `email`, `phone`, `artist_name`, `booking_type`, `event_date`, `location`, `description`, `created_at`, `event_id`, `event_title`, `status`, `tickets_count`, `total_price`) VALUES ('1', 'Sarah Ahmed', 'sarah@example.com', '+971 50 987 6543', 'Renish Artistry', 'Event Booking', '2026-10-15 18:00', 'Alserkal Avenue, Dubai', '', '2026-08-29 17:01:41', '1', 'Dubai Modern Art Showcase', 'Cancelled', '2', 'Free');
INSERT INTO `bookings` (`id`, `full_name`, `email`, `phone`, `artist_name`, `booking_type`, `event_date`, `location`, `description`, `created_at`, `event_id`, `event_title`, `status`, `tickets_count`, `total_price`) VALUES ('2', 'renish', 'renish@gmail.com', '+971 50 123 4567', 'Renish Artistry', 'Event Booking', '15 Oct 2026', 'Dubai, UAE', '', '2026-08-29 19:41:21', '1', 'Dubai Modern Art Showcase', 'Cancelled', '1', 'Free');
INSERT INTO `bookings` (`id`, `full_name`, `email`, `phone`, `artist_name`, `booking_type`, `event_date`, `location`, `description`, `created_at`, `event_id`, `event_title`, `status`, `tickets_count`, `total_price`) VALUES ('3', 'Automated Tester', 'tester@artistdubai.com', '+971501234567', 'Renish Artistry', 'Event Ticket', '15 Oct 2026', 'Dubai, UAE', 'Test booking verified by automated test suite.', '2026-08-30 13:31:00', NULL, 'Dubai Modern Art Showcase', 'Cancelled', '2', 'Free');
INSERT INTO `bookings` (`id`, `full_name`, `email`, `phone`, `artist_name`, `booking_type`, `event_date`, `location`, `description`, `created_at`, `event_id`, `event_title`, `status`, `tickets_count`, `total_price`) VALUES ('4', 'Automated Tester', 'tester@artistdubai.com', '+971501234567', 'Renish Artistry', 'Event Ticket', '15 Oct 2026', 'Dubai, UAE', 'Test booking verified by automated test suite.', '2026-08-30 14:00:32', NULL, 'Dubai Modern Art Showcase', 'Cancelled', '2', 'Free');
INSERT INTO `bookings` (`id`, `full_name`, `email`, `phone`, `artist_name`, `booking_type`, `event_date`, `location`, `description`, `created_at`, `event_id`, `event_title`, `status`, `tickets_count`, `total_price`) VALUES ('5', 'renish', 'renish@gmail.com', '', '', 'Event Booking', '15 Oct 2026', 'Dubai Opera Ballroom', '', '2026-08-30 14:20:42', '6', 'Automated Art Gala 2026', 'Confirmed', '10', 'Free');
INSERT INTO `bookings` (`id`, `full_name`, `email`, `phone`, `artist_name`, `booking_type`, `event_date`, `location`, `description`, `created_at`, `event_id`, `event_title`, `status`, `tickets_count`, `total_price`) VALUES ('6', 'Automated Tester', 'tester@artistdubai.com', '+971501234567', 'Renish Artistry', 'Event Ticket', '15 Oct 2026', 'Dubai, UAE', 'Test booking verified by automated test suite.', '2026-08-30 14:29:34', NULL, 'Dubai Modern Art Showcase', 'Cancelled', '2', 'Free');

-- --------------------------------------------------------
-- Table structure for `favorites`
-- --------------------------------------------------------
DROP TABLE IF EXISTS `favorites`;
CREATE TABLE `favorites` (
  `id` int NOT NULL AUTO_INCREMENT,
  `user_id` int DEFAULT NULL,
  `user_email` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `item_type` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `item_id` int NOT NULL,
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `user_fav` (`user_id`,`item_type`,`item_id`),
  KEY `idx_fav_user_email` (`user_email`),
  KEY `idx_favorites_user` (`user_email`(100),`item_type`(20))
) ENGINE=InnoDB AUTO_INCREMENT=57 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table `favorites`
INSERT INTO `favorites` (`id`, `user_id`, `user_email`, `item_type`, `item_id`, `created_at`) VALUES ('1', NULL, 'renish@technest.ae', 'artist', '1', '2026-08-30 13:58:31');
INSERT INTO `favorites` (`id`, `user_id`, `user_email`, `item_type`, `item_id`, `created_at`) VALUES ('34', NULL, 'renish@gmail.com', 'event', '6', '2026-08-30 14:00:58');
INSERT INTO `favorites` (`id`, `user_id`, `user_email`, `item_type`, `item_id`, `created_at`) VALUES ('35', NULL, 'renish@gmail.com', 'event', '5', '2026-08-30 14:00:59');
INSERT INTO `favorites` (`id`, `user_id`, `user_email`, `item_type`, `item_id`, `created_at`) VALUES ('36', NULL, 'renish@gmail.com', 'event', '4', '2026-08-30 14:00:59');
INSERT INTO `favorites` (`id`, `user_id`, `user_email`, `item_type`, `item_id`, `created_at`) VALUES ('37', NULL, 'renish@gmail.com', 'event', '3', '2026-08-30 14:00:59');
INSERT INTO `favorites` (`id`, `user_id`, `user_email`, `item_type`, `item_id`, `created_at`) VALUES ('38', NULL, 'renish@gmail.com', 'event', '2', '2026-08-30 14:00:59');
INSERT INTO `favorites` (`id`, `user_id`, `user_email`, `item_type`, `item_id`, `created_at`) VALUES ('39', NULL, 'renish@gmail.com', 'event', '1', '2026-08-30 14:01:00');
INSERT INTO `favorites` (`id`, `user_id`, `user_email`, `item_type`, `item_id`, `created_at`) VALUES ('42', NULL, 'renish@gmail.com', 'artist', '5', '2026-08-30 14:01:02');
INSERT INTO `favorites` (`id`, `user_id`, `user_email`, `item_type`, `item_id`, `created_at`) VALUES ('43', NULL, 'renish@gmail.com', 'artist', '4', '2026-08-30 14:01:02');
INSERT INTO `favorites` (`id`, `user_id`, `user_email`, `item_type`, `item_id`, `created_at`) VALUES ('44', NULL, 'renish@gmail.com', 'artist', '3', '2026-08-30 14:01:03');
INSERT INTO `favorites` (`id`, `user_id`, `user_email`, `item_type`, `item_id`, `created_at`) VALUES ('45', NULL, 'renish@gmail.com', 'artist', '2', '2026-08-30 14:01:03');
INSERT INTO `favorites` (`id`, `user_id`, `user_email`, `item_type`, `item_id`, `created_at`) VALUES ('46', NULL, 'renish@gmail.com', 'artist', '1', '2026-08-30 14:01:03');
INSERT INTO `favorites` (`id`, `user_id`, `user_email`, `item_type`, `item_id`, `created_at`) VALUES ('56', NULL, 'renish@gmail.com', 'artwork', '1', '2026-08-30 14:54:54');

-- --------------------------------------------------------
-- Table structure for `follows`
-- --------------------------------------------------------
DROP TABLE IF EXISTS `follows`;
CREATE TABLE `follows` (
  `id` int NOT NULL AUTO_INCREMENT,
  `user_email` varchar(255) NOT NULL,
  `artist_id` varchar(50) NOT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_user_artist_follow` (`user_email`,`artist_id`),
  KEY `idx_follows_user` (`user_email`(100),`artist_id`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Dumping data for table `follows`
INSERT INTO `follows` (`id`, `user_email`, `artist_id`, `created_at`) VALUES ('2', 'renish@gmail.com', '8', '2026-08-30 15:04:27');
INSERT INTO `follows` (`id`, `user_email`, `artist_id`, `created_at`) VALUES ('3', 'renish@gmail.com', '1', '2026-08-30 17:24:40');
INSERT INTO `follows` (`id`, `user_email`, `artist_id`, `created_at`) VALUES ('4', 'renish@gmail.com', '2', '2026-08-30 17:24:46');
INSERT INTO `follows` (`id`, `user_email`, `artist_id`, `created_at`) VALUES ('5', 'renish@gmail.com', '3', '2026-08-30 17:24:51');

-- --------------------------------------------------------
-- Table structure for `categories`
-- --------------------------------------------------------
DROP TABLE IF EXISTS `categories`;
CREATE TABLE `categories` (
  `id` int NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  `type` varchar(50) DEFAULT 'general',
  `description` text,
  `emoji` varchar(50) DEFAULT 0xF09F8EA8,
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `name` (`name`)
) ENGINE=InnoDB AUTO_INCREMENT=23 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Dumping data for table `categories`
INSERT INTO `categories` (`id`, `name`, `type`, `description`, `emoji`, `created_at`) VALUES ('7', 'Art Exhibition', 'event', 'Fine art exhibitions, group showcases, and gallery displays', '🖼️', '2026-08-29 15:42:42');
INSERT INTO `categories` (`id`, `name`, `type`, `description`, `emoji`, `created_at`) VALUES ('8', 'Gallery Opening', 'event', 'New gallery space debuts, exclusive launch receptions and vernissage', '🏛️', '2026-08-29 15:42:42');
INSERT INTO `categories` (`id`, `name`, `type`, `description`, `emoji`, `created_at`) VALUES ('9', 'Art Workshop', 'event', 'Interactive hands-on art classes, live demonstrations and creative sessions', '🎨', '2026-08-29 15:42:42');
INSERT INTO `categories` (`id`, `name`, `type`, `description`, `emoji`, `created_at`) VALUES ('10', 'Artist Talk', 'event', 'Q&A panels, keynote lectures, and creative dialogues with masters', '🎤', '2026-08-29 15:42:42');
INSERT INTO `categories` (`id`, `name`, `type`, `description`, `emoji`, `created_at`) VALUES ('11', 'Art Fair', 'event', 'Large-scale art fairs, cultural expos, and trade exhibitions', '🎪', '2026-08-29 15:42:42');
INSERT INTO `categories` (`id`, `name`, `type`, `description`, `emoji`, `created_at`) VALUES ('12', 'Sculpture Installation', 'event', 'Outdoor, 3D and immersive sculptural installations', '🗿', '2026-08-29 15:42:42');
INSERT INTO `categories` (`id`, `name`, `type`, `description`, `emoji`, `created_at`) VALUES ('13', 'Photography Exhibition', 'event', 'Fine art, documentary and architectural photography showcases', '📷', '2026-08-29 15:42:42');
INSERT INTO `categories` (`id`, `name`, `type`, `description`, `emoji`, `created_at`) VALUES ('14', 'Cultural Festival', 'event', 'Heritage celebrations, arts festivals, and multicultural festivities', '🎉', '2026-08-29 15:42:42');
INSERT INTO `categories` (`id`, `name`, `type`, `description`, `emoji`, `created_at`) VALUES ('15', 'Art Competition', 'event', 'Juried art contests, awards, and youth talent competitions', '🏆', '2026-08-29 15:42:42');
INSERT INTO `categories` (`id`, `name`, `type`, `description`, `emoji`, `created_at`) VALUES ('16', 'Community Art Project', 'event', 'Public murals, collaborative community art, and social initiatives', '🤝', '2026-08-29 15:42:42');
INSERT INTO `categories` (`id`, `name`, `type`, `description`, `emoji`, `created_at`) VALUES ('17', 'Painting', 'artist', 'Canvas, oil, acrylic, and watercolor paintings', '🎨', '2026-08-29 15:42:42');
INSERT INTO `categories` (`id`, `name`, `type`, `description`, `emoji`, `created_at`) VALUES ('18', 'Photography', 'artist', 'Fine art, landscape, and portrait photography', '📷', '2026-08-29 15:42:42');
INSERT INTO `categories` (`id`, `name`, `type`, `description`, `emoji`, `created_at`) VALUES ('19', 'Sculpture', 'artist', '3D sculptural works, stone, bronze, and clay', '🗿', '2026-08-29 15:42:42');
INSERT INTO `categories` (`id`, `name`, `type`, `description`, `emoji`, `created_at`) VALUES ('20', 'Drawing', 'artist', 'Pencil, charcoal, ink, and pastel sketches', '✏️', '2026-08-29 15:42:42');
INSERT INTO `categories` (`id`, `name`, `type`, `description`, `emoji`, `created_at`) VALUES ('21', 'Digital Art', 'artist', 'Digital painting, 3D graphics, and generative art', '💻', '2026-08-29 15:42:42');
INSERT INTO `categories` (`id`, `name`, `type`, `description`, `emoji`, `created_at`) VALUES ('22', 'AI-Generated Art', 'artist', 'Artificial intelligence and algorithmic artworks', '🤖', '2026-08-29 15:42:42');
INSERT INTO `categories` (`id`, `name`, `type`, `description`, `emoji`, `created_at`) VALUES ('23', 'Architecture', 'artist', 'Architectural design, models, and spatial art', '🏛️', '2026-08-29 15:42:42');
INSERT INTO `categories` (`id`, `name`, `type`, `description`, `emoji`, `created_at`) VALUES ('24', 'Theatre', 'artist', 'Stage plays, dramatic productions, and theatrical arts', '🎭', '2026-08-29 15:42:42');
INSERT INTO `categories` (`id`, `name`, `type`, `description`, `emoji`, `created_at`) VALUES ('25', 'Dance', 'artist', 'Choreography, contemporary, and traditional dance', '💃', '2026-08-29 15:42:42');
INSERT INTO `categories` (`id`, `name`, `type`, `description`, `emoji`, `created_at`) VALUES ('26', 'Music', 'artist', 'Composition, instrumental, and acoustic music', '🎵', '2026-08-29 15:42:42');
INSERT INTO `categories` (`id`, `name`, `type`, `description`, `emoji`, `created_at`) VALUES ('27', 'Film', 'artist', 'Cinematography, short films, and indie filmmaking', '🎬', '2026-08-29 15:42:42');
INSERT INTO `categories` (`id`, `name`, `type`, `description`, `emoji`, `created_at`) VALUES ('28', 'Video Art', 'artist', 'Moving image installations and video experimental art', '📹', '2026-08-29 15:42:42');
INSERT INTO `categories` (`id`, `name`, `type`, `description`, `emoji`, `created_at`) VALUES ('29', 'Literature', 'artist', 'Literary works, novels, essays, and prose', '📚', '2026-08-29 15:42:42');
INSERT INTO `categories` (`id`, `name`, `type`, `description`, `emoji`, `created_at`) VALUES ('30', 'Poetry', 'artist', 'Classical, spoken word, and contemporary poetry', '📜', '2026-08-29 15:42:42');
INSERT INTO `categories` (`id`, `name`, `type`, `description`, `emoji`, `created_at`) VALUES ('31', 'Creative Writing', 'artist', 'Narrative storytelling, scripts, and creative writing', '🖋️', '2026-08-29 15:42:42');
INSERT INTO `categories` (`id`, `name`, `type`, `description`, `emoji`, `created_at`) VALUES ('32', 'Drama', 'artist', 'Dramatic performance, acting, and stage dialogue', '🎭', '2026-08-29 15:42:42');
INSERT INTO `categories` (`id`, `name`, `type`, `description`, `emoji`, `created_at`) VALUES ('33', 'Graphic Design', 'artist', 'Visual branding, typography, and graphic layout', '📐', '2026-08-29 15:42:42');
INSERT INTO `categories` (`id`, `name`, `type`, `description`, `emoji`, `created_at`) VALUES ('34', 'Fashion Design', 'artist', 'Haute couture, wearable art, and garment design', '👗', '2026-08-29 15:42:42');
INSERT INTO `categories` (`id`, `name`, `type`, `description`, `emoji`, `created_at`) VALUES ('35', 'Interior Design', 'artist', 'Spatial styling, artistic interiors, and decor', '🛋️', '2026-08-29 15:42:42');
INSERT INTO `categories` (`id`, `name`, `type`, `description`, `emoji`, `created_at`) VALUES ('36', 'Product Design', 'artist', 'Industrial design, aesthetic object creation', '📦', '2026-08-29 15:42:42');
INSERT INTO `categories` (`id`, `name`, `type`, `description`, `emoji`, `created_at`) VALUES ('37', 'Crafts', 'artist', 'Artisan handicrafts, papercraft, and artisanal work', '🧶', '2026-08-29 15:42:42');
INSERT INTO `categories` (`id`, `name`, `type`, `description`, `emoji`, `created_at`) VALUES ('38', 'Textile Art', 'artist', 'Weaving, tapestry, embroidery, and fiber art', '🧵', '2026-08-29 15:42:42');
INSERT INTO `categories` (`id`, `name`, `type`, `description`, `emoji`, `created_at`) VALUES ('39', 'Ceramics', 'artist', 'Pottery, stoneware, porcelain, and terracotta', '🏺', '2026-08-29 15:42:42');
INSERT INTO `categories` (`id`, `name`, `type`, `description`, `emoji`, `created_at`) VALUES ('40', 'Printmaking', 'artist', 'Screen printing, etching, woodcut, and lithography', '🖨️', '2026-08-29 15:42:42');
INSERT INTO `categories` (`id`, `name`, `type`, `description`, `emoji`, `created_at`) VALUES ('41', 'Illustration', 'artist', 'Editorial illustration, book art, and character art', '🖌️', '2026-08-29 15:42:42');
INSERT INTO `categories` (`id`, `name`, `type`, `description`, `emoji`, `created_at`) VALUES ('42', 'Street Art', 'artist', 'Urban graffiti, stencil, and public space art', '🏙️', '2026-08-29 15:42:42');
INSERT INTO `categories` (`id`, `name`, `type`, `description`, `emoji`, `created_at`) VALUES ('43', 'Mural Art', 'artist', 'Large-scale wall murals and outdoor public art', '🧱', '2026-08-29 15:42:42');
INSERT INTO `categories` (`id`, `name`, `type`, `description`, `emoji`, `created_at`) VALUES ('44', 'Performance Art', 'artist', 'Live artistic expression, interactive acts', '🩰', '2026-08-29 15:42:42');
INSERT INTO `categories` (`id`, `name`, `type`, `description`, `emoji`, `created_at`) VALUES ('45', 'Installation Art', 'artist', 'Immersive, site-specific art installations', '💡', '2026-08-29 15:42:42');
INSERT INTO `categories` (`id`, `name`, `type`, `description`, `emoji`, `created_at`) VALUES ('46', 'Conceptual Art', 'artist', 'Idea-driven contemporary art and experimental works', '🧠', '2026-08-29 15:42:42');
INSERT INTO `categories` (`id`, `name`, `type`, `description`, `emoji`, `created_at`) VALUES ('47', 'Mixed Media', 'artist', 'Multi-medium combinations and experimental artwork', '🔀', '2026-08-29 15:42:42');
INSERT INTO `categories` (`id`, `name`, `type`, `description`, `emoji`, `created_at`) VALUES ('48', 'Collage', 'artist', 'Assembled paper, textures, and cut-and-paste art', '📑', '2026-08-29 15:42:42');
INSERT INTO `categories` (`id`, `name`, `type`, `description`, `emoji`, `created_at`) VALUES ('49', 'Video Game Art', 'artist', 'Concept art, character models, and game world design', '🎮', '2026-08-29 15:42:42');
INSERT INTO `categories` (`id`, `name`, `type`, `description`, `emoji`, `created_at`) VALUES ('50', 'Virtual Reality (VR) Art', 'artist', 'Immersive VR painting and 3D spatial worlds', '🥽', '2026-08-29 15:42:42');
INSERT INTO `categories` (`id`, `name`, `type`, `description`, `emoji`, `created_at`) VALUES ('51', 'Animation', 'artist', '2D, 3D, and stop-motion animation', '🎞️', '2026-08-29 15:42:42');
INSERT INTO `categories` (`id`, `name`, `type`, `description`, `emoji`, `created_at`) VALUES ('52', 'Comic Art', 'artist', 'Comic strips, graphic novels, and sequential art', '🗯️', '2026-08-29 15:42:42');
INSERT INTO `categories` (`id`, `name`, `type`, `description`, `emoji`, `created_at`) VALUES ('53', 'Calligraphy', 'artist', 'Arabic, modern, and classical lettering art', '✍️', '2026-08-29 15:42:42');
INSERT INTO `categories` (`id`, `name`, `type`, `description`, `emoji`, `created_at`) VALUES ('54', 'Jewellery Design', 'artist', 'Handmade precious jewellery and gem craftsmanship', '💍', '2026-08-29 15:42:42');
INSERT INTO `categories` (`id`, `name`, `type`, `description`, `emoji`, `created_at`) VALUES ('55', 'Glass Art', 'artist', 'Stained glass, blown glass, and glass sculptures', '🪟', '2026-08-29 15:42:42');
INSERT INTO `categories` (`id`, `name`, `type`, `description`, `emoji`, `created_at`) VALUES ('56', 'Wood Art', 'artist', 'Wood carving, marquetry, and timber sculpture', '🪵', '2026-08-29 15:42:42');
INSERT INTO `categories` (`id`, `name`, `type`, `description`, `emoji`, `created_at`) VALUES ('57', 'Metal Art', 'artist', 'Forged metal, welding, wire art, and metalcraft', '⚙️', '2026-08-29 15:42:42');
INSERT INTO `categories` (`id`, `name`, `type`, `description`, `emoji`, `created_at`) VALUES ('58', 'Puppetry', 'artist', 'Marionettes, shadow puppets, and puppet theater', '🎎', '2026-08-29 15:42:42');
INSERT INTO `categories` (`id`, `name`, `type`, `description`, `emoji`, `created_at`) VALUES ('59', 'Opera', 'artist', 'Classical operatic performance and vocal arts', '🎼', '2026-08-29 15:42:42');
INSERT INTO `categories` (`id`, `name`, `type`, `description`, `emoji`, `created_at`) VALUES ('60', 'Ballet', 'artist', 'Classical and modern ballet dance performance', '🩰', '2026-08-29 15:42:42');
INSERT INTO `categories` (`id`, `name`, `type`, `description`, `emoji`, `created_at`) VALUES ('61', 'Musical Theatre', 'artist', 'Stage musicals blending singing, acting, and dance', '🎤', '2026-08-29 15:42:42');
INSERT INTO `categories` (`id`, `name`, `type`, `description`, `emoji`, `created_at`) VALUES ('62', 'Experimental Art', 'artist', 'Avant-garde boundary-pushing artistic explorations', '🧪', '2026-08-29 15:42:42');
INSERT INTO `categories` (`id`, `name`, `type`, `description`, `emoji`, `created_at`) VALUES ('63', 'Land Art', 'artist', 'Earth art, nature-integrated sculptures and topography', '🏞️', '2026-08-29 15:42:42');
INSERT INTO `categories` (`id`, `name`, `type`, `description`, `emoji`, `created_at`) VALUES ('64', 'Environmental Art', 'artist', 'Eco-conscious art addressing nature and sustainability', '🌿', '2026-08-29 15:42:42');
INSERT INTO `categories` (`id`, `name`, `type`, `description`, `emoji`, `created_at`) VALUES ('65', 'Body Art', 'artist', 'Body painting, henna, and creative epidermal art', '🎨', '2026-08-29 15:42:42');
INSERT INTO `categories` (`id`, `name`, `type`, `description`, `emoji`, `created_at`) VALUES ('66', 'Jewellery and Accessory Design', 'artist', 'Fine jewellery, headpieces, and fashion accessories', '👑', '2026-08-29 15:42:42');

-- --------------------------------------------------------
-- Table structure for `publishing_pricing`
-- --------------------------------------------------------
DROP TABLE IF EXISTS `publishing_pricing`;
CREATE TABLE `publishing_pricing` (
  `id` int NOT NULL AUTO_INCREMENT,
  `item_type` varchar(50) DEFAULT 'event',
  `item_name` varchar(255) NOT NULL,
  `description` text,
  `weekly_price` varchar(100) DEFAULT 'AED 150',
  `monthly_price` varchar(100) DEFAULT 'AED 500',
  `three_month_price` varchar(100) DEFAULT 'AED 2,000',
  `six_month_price` varchar(100) DEFAULT 'AED 3,000',
  `yearly_price` varchar(100) DEFAULT 'AED 5,000',
  `three_month_badge` varchar(50) DEFAULT 'Special Offer',
  `six_month_badge` varchar(50) DEFAULT 'Save 25%',
  `yearly_badge` varchar(50) DEFAULT 'Best Value',
  `currency` varchar(20) DEFAULT 'AED',
  `is_active` tinyint(1) DEFAULT '1',
  `updated_at` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_publishing_item_type` (`item_type`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table `publishing_pricing`
INSERT INTO `publishing_pricing` (`id`, `item_type`, `item_name`, `description`, `weekly_price`, `monthly_price`, `three_month_price`, `six_month_price`, `yearly_price`, `three_month_badge`, `six_month_badge`, `yearly_badge`, `currency`, `is_active`) VALUES
(1, 'event', 'Paid Event Publishing', 'Feature your event on curated maps and event calendars, with professional event photography.', 'AED 150', 'AED 500', 'AED 2,000', 'AED 3,000', 'AED 5,000', 'Special Offer', 'Save 25%', 'Best Value', 'AED', 1),
(2, 'gallery', 'Art Venue Listing', 'Boost your visibility and secure your place in our professional art community. Choose your plan and connect with the art world!', 'AED 250', 'AED 800', 'AED 2,000', 'AED 3,000', 'AED 5,000', 'Special Offer', 'Save 25%', 'Best Value', 'AED', 1),
(3, 'artist', 'Artist Verification & Listing', 'Get verified badge, priority placement in artist directory, and direct commissioning channel.', 'AED 100', 'AED 350', 'AED 1,200', 'AED 2,000', 'AED 3,500', 'Special Offer', 'Save 20%', 'Best Value', 'AED', 1);

-- --------------------------------------------------------
-- Table structure for `listing_plans`
-- --------------------------------------------------------
DROP TABLE IF EXISTS `listing_plans`;
CREATE TABLE `listing_plans` (
  `id` int NOT NULL AUTO_INCREMENT,
  `item_type` varchar(50) NOT NULL,
  `title` varchar(255) NOT NULL,
  `category` varchar(100) NOT NULL,
  `badge` varchar(50) DEFAULT 'One-time',
  `price` varchar(100) NOT NULL,
  `duration` varchar(100) DEFAULT '30 Days',
  `duration_days` int DEFAULT '30',
  `description` text,
  `features_json` text,
  `button_text` varchar(100) DEFAULT 'Pay from My Listings',
  `is_active` tinyint(1) DEFAULT '1',
  `sort_order` int DEFAULT '0',
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_listing_plan_type` (`item_type`)
) ENGINE=InnoDB AUTO_INCREMENT=10 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table `listing_plans`
INSERT INTO `listing_plans` (`id`, `item_type`, `title`, `category`, `badge`, `price`, `duration`, `duration_days`, `description`, `features_json`, `button_text`, `is_active`, `sort_order`) VALUES
(1, 'gallery', '3 Months', 'Art Galleries', 'Special Offer', 'AED 2,000', '3 Months', 90, 'Boost your visibility and secure your place in our professional art community. Choose your plan and connect with the art world!', '["Feature gallery on curated maps","Event calendar listings","Professional event photography","Enjoy your first 3 months free"]', 'Register Gallery', 1, 1),
(2, 'gallery', '6 Months', 'Art Galleries', 'Save 25%', 'AED 3,000', '6 Months', 180, 'Boost your visibility and secure your place in our professional art community. Choose your plan and connect with the art world!', '["Feature gallery on curated maps","Event calendar listings","Professional event photography","Enjoy your first 3 months free"]', 'Register Gallery', 1, 2),
(3, 'gallery', '12 Months', 'Art Galleries', 'Best Value', 'AED 5,000', '12 Months', 365, 'Boost your visibility and secure your place in our professional art community. Choose your plan and connect with the art world!', '["Feature gallery on curated maps","Event calendar listings","Professional event photography","Enjoy your first 3 months free"]', 'Register Gallery', 1, 3),
(4, 'event', '3 Months', 'Exhibitions & Events', 'Special Offer', 'AED 2,000', '3 Months', 90, 'Feature your event on curated maps and event calendars, with professional event photography.', '["Feature event on curated maps","Event calendar & push highlight","Professional event photography","Enjoy your first 3 months free"]', 'Publish Event', 1, 4),
(5, 'event', '6 Months', 'Exhibitions & Events', 'Save 25%', 'AED 3,000', '6 Months', 180, 'Feature your event on curated maps and event calendars, with professional event photography.', '["Feature event on curated maps","Event calendar & push highlight","Professional event photography","Enjoy your first 3 months free"]', 'Publish Event', 1, 5),
(6, 'event', '12 Months', 'Exhibitions & Events', 'Best Value', 'AED 5,000', '12 Months', 365, 'Feature your event on curated maps and event calendars, with professional event photography.', '["Feature event on curated maps","Event calendar & push highlight","Professional event photography","Enjoy your first 3 months free"]', 'Publish Event', 1, 6),
(7, 'chat', 'Starter Plan', 'Messaging', 'Basic', 'Free', 'Monthly Reset', 30, '10 direct artist messages per month', '["10 direct artist messages per month","Direct artist collaboration inquiries","Flyer attachment support"]', 'Current Plan', 1, 7),
(8, 'chat', 'Unlimited VIP Chat', 'Messaging', 'All Access', 'AED 500', 'Monthly', 30, 'Unlimited direct messages with artists & curators for AED 500 per month', '["Unlimited direct artist messages per month","AED 500 per month all-inclusive","Verified VIP sender badge","Priority delivery in recipient inbox","High-resolution flyer attachments"]', 'Upgrade to VIP', 1, 8),
(9, 'art_centre', 'Art Center Partner', 'Institutions & Venues', 'VIP Partner', 'AED 990', '1 Year', 365, 'Official verified institution hub page, workshop hosting & priority event syndication', '["Official verified institution partner badge","Unlimited event & workshop listings","Direct ticket booking with instant notifications"]', 'Join Partner Network', 1, 9);

-- --------------------------------------------------------
-- Table structure for `user_plans`
-- --------------------------------------------------------
DROP TABLE IF EXISTS `user_plans`;
CREATE TABLE `user_plans` (
  `id` int NOT NULL AUTO_INCREMENT,
  `user_id` int DEFAULT NULL,
  `user_email` varchar(255) NOT NULL,
  `plan_name` varchar(255) NOT NULL,
  `plan_type` varchar(100) DEFAULT 'Subscription',
  `item_title` varchar(255) DEFAULT NULL,
  `price` varchar(100) NOT NULL DEFAULT 'Free',
  `billing_cycle` varchar(100) DEFAULT 'Monthly',
  `status` varchar(50) DEFAULT 'Active',
  `payment_reference` varchar(255) DEFAULT NULL,
  `payment_method` varchar(100) DEFAULT 'Card',
  `features_json` text,
  `start_date` datetime DEFAULT CURRENT_TIMESTAMP,
  `expires_at` datetime DEFAULT NULL,
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_user_plans_email` (`user_email`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

SET FOREIGN_KEY_CHECKS = 1;

