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
INSERT INTO `artworks` (`id`, `artist_id`, `artist_name`, `title`, `year`, `medium`, `dimensions`, `description`, `price`, `image_url`, `is_featured`, `created_at`) VALUES ('6', '1', 'Automated Test Artist', 'Geometric Harmony', '2024', 'Mixed Media Collage', '90 x 90 cm', 'Traditional Islamic geometric patterns reimagined through modern minimalist balance.', '$1,750', 'https://images.unsplash.com/photo-1579783902614-a3fb3927b675?auto=format&fit=crop&w=800&q=80', '0', '2026-08-30 14:38:04');
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
INSERT INTO `categories` (`id`, `name`, `type`, `description`, `emoji`, `created_at`) VALUES ('17', 'Calligraphy & Typography', 'artist', 'Arabic calligraphy, modern lettering and typography', '✍️', '2026-08-29 15:42:42');
INSERT INTO `categories` (`id`, `name`, `type`, `description`, `emoji`, `created_at`) VALUES ('18', 'Contemporary Painting', 'artist', 'Modern and contemporary canvas and acrylic painting', '🎨', '2026-08-29 15:42:42');
INSERT INTO `categories` (`id`, `name`, `type`, `description`, `emoji`, `created_at`) VALUES ('19', 'Digital Art & Sculpture', 'artist', 'Digital 3D installations, sculptures and generative art', '🗿', '2026-08-29 15:42:42');
INSERT INTO `categories` (`id`, `name`, `type`, `description`, `emoji`, `created_at`) VALUES ('20', 'Photography', 'artist', 'Landscape, architectural and fine art photography across UAE', '📷', '2026-08-29 15:42:42');
INSERT INTO `categories` (`id`, `name`, `type`, `description`, `emoji`, `created_at`) VALUES ('21', 'Abstract Painting', 'artist', 'Abstract expressions, mixed media and vibrant color palettes', '🎨', '2026-08-29 15:42:42');
INSERT INTO `categories` (`id`, `name`, `type`, `description`, `emoji`, `created_at`) VALUES ('22', 'Ceramics & Pottery', 'artist', 'Handcrafted ceramics, clay sculptures and pottery', '🏺', '2026-08-29 15:42:42');

SET FOREIGN_KEY_CHECKS = 1;
