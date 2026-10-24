-- ==============================================================================
-- Artist Dubai - Official Government Entities & Cultural Hubs Restoration Script
-- ==============================================================================
-- This script safely provisions the government_entities table and inserts
-- the 6 permanent official entities without risk of duplicate rows.
-- ==============================================================================

CREATE TABLE IF NOT EXISTS `government_entities` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `name` VARCHAR(255) NOT NULL UNIQUE,
    `category` VARCHAR(255) NOT NULL,
    `location` VARCHAR(255) NOT NULL,
    `base_rating` DECIMAL(3,1) DEFAULT 4.5,
    `base_review_count` INT DEFAULT 100,
    `rating` DECIMAL(3,1) DEFAULT 4.5,
    `review_count` INT DEFAULT 100,
    `default_timing` VARCHAR(255) NULL,
    `default_is_open` TINYINT(1) DEFAULT 1,
    `website_url` VARCHAR(500) NULL,
    `directions_url` VARCHAR(500) NULL,
    `google_maps_reviews_url` VARCHAR(500) NULL,
    `open_hour` INT DEFAULT 8,
    `open_minute` INT DEFAULT 0,
    `close_hour` INT DEFAULT 18,
    `close_minute` INT DEFAULT 0,
    `closed_days` VARCHAR(50) DEFAULT '6,7',
    `seasonal_notice` VARCHAR(255) NULL,
    `deleted_at` DATETIME NULL DEFAULT NULL,
    `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_gov_deleted` (`deleted_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 1. Dubai Culture & Arts Authority
INSERT INTO `government_entities` (
    `name`, `category`, `location`, `base_rating`, `base_review_count`,
    `rating`, `review_count`, `default_timing`, `default_is_open`,
    `website_url`, `directions_url`, `google_maps_reviews_url`,
    `open_hour`, `open_minute`, `close_hour`, `close_minute`, `closed_days`, `seasonal_notice`, `deleted_at`
) VALUES (
    'Dubai Culture & Arts Authority',
    'Government · Cultural Authority',
    'Al Shindagha, Dubai',
    4.5, 120, 4.5, 120,
    'Open · Closes at 15:00', 1,
    'https://dubaiculture.gov.ae/en',
    'https://maps.google.com/?q=Dubai+Culture+and+Arts+Authority+Al+Shindagha+Dubai',
    'https://www.google.com/maps/search/?api=1&query=Dubai+Culture+and+Arts+Authority+Al+Shindagha+Dubai',
    7, 30, 15, 0, '6,7', NULL, NULL
) ON DUPLICATE KEY UPDATE
    `category` = VALUES(`category`),
    `location` = VALUES(`location`),
    `base_rating` = VALUES(`base_rating`),
    `base_review_count` = VALUES(`base_review_count`),
    `rating` = VALUES(`rating`),
    `review_count` = VALUES(`review_count`),
    `default_timing` = VALUES(`default_timing`),
    `default_is_open` = VALUES(`default_is_open`),
    `website_url` = VALUES(`website_url`),
    `directions_url` = VALUES(`directions_url`),
    `google_maps_reviews_url` = VALUES(`google_maps_reviews_url`),
    `open_hour` = VALUES(`open_hour`),
    `open_minute` = VALUES(`open_minute`),
    `close_hour` = VALUES(`close_hour`),
    `close_minute` = VALUES(`close_minute`),
    `closed_days` = VALUES(`closed_days`),
    `seasonal_notice` = VALUES(`seasonal_notice`),
    `deleted_at` = NULL;

-- 2. Ministry of Culture & Youth
INSERT INTO `government_entities` (
    `name`, `category`, `location`, `base_rating`, `base_review_count`,
    `rating`, `review_count`, `default_timing`, `default_is_open`,
    `website_url`, `directions_url`, `google_maps_reviews_url`,
    `open_hour`, `open_minute`, `close_hour`, `close_minute`, `closed_days`, `seasonal_notice`, `deleted_at`
) VALUES (
    'Ministry of Culture & Youth',
    'Government · Federal Ministry',
    'Abu Dhabi, UAE',
    4.2, 98, 4.2, 98,
    'Open · Closes at 14:30', 1,
    'https://www.mcy.gov.ae/',
    'https://maps.google.com/?q=Ministry+of+Culture+and+Youth+Abu+Dhabi',
    'https://www.google.com/maps/search/?api=1&query=Ministry+of+Culture+and+Youth+Abu+Dhabi',
    7, 30, 14, 30, '6,7', NULL, NULL
) ON DUPLICATE KEY UPDATE
    `category` = VALUES(`category`),
    `location` = VALUES(`location`),
    `base_rating` = VALUES(`base_rating`),
    `base_review_count` = VALUES(`base_review_count`),
    `rating` = VALUES(`rating`),
    `review_count` = VALUES(`review_count`),
    `default_timing` = VALUES(`default_timing`),
    `default_is_open` = VALUES(`default_is_open`),
    `website_url` = VALUES(`website_url`),
    `directions_url` = VALUES(`directions_url`),
    `google_maps_reviews_url` = VALUES(`google_maps_reviews_url`),
    `open_hour` = VALUES(`open_hour`),
    `open_minute` = VALUES(`open_minute`),
    `close_hour` = VALUES(`close_hour`),
    `close_minute` = VALUES(`close_minute`),
    `closed_days` = VALUES(`closed_days`),
    `seasonal_notice` = VALUES(`seasonal_notice`),
    `deleted_at` = NULL;

-- 3. Dubai Design District (d3)
INSERT INTO `government_entities` (
    `name`, `category`, `location`, `base_rating`, `base_review_count`,
    `rating`, `review_count`, `default_timing`, `default_is_open`,
    `website_url`, `directions_url`, `google_maps_reviews_url`,
    `open_hour`, `open_minute`, `close_hour`, `close_minute`, `closed_days`, `seasonal_notice`, `deleted_at`
) VALUES (
    'Dubai Design District (d3)',
    'Creative Hub · Design District',
    'Dubai Design District, Dubai',
    4.7, 215, 4.7, 215,
    'Open · Closes at 22:00', 1,
    'https://dubaidesigndistrict.com/',
    'https://maps.google.com/?q=Dubai+Design+District+Dubai',
    'https://www.google.com/maps/search/?api=1&query=Dubai+Design+District+Dubai',
    8, 0, 22, 0, '', NULL, NULL
) ON DUPLICATE KEY UPDATE
    `category` = VALUES(`category`),
    `location` = VALUES(`location`),
    `base_rating` = VALUES(`base_rating`),
    `base_review_count` = VALUES(`base_review_count`),
    `rating` = VALUES(`rating`),
    `review_count` = VALUES(`review_count`),
    `default_timing` = VALUES(`default_timing`),
    `default_is_open` = VALUES(`default_is_open`),
    `website_url` = VALUES(`website_url`),
    `directions_url` = VALUES(`directions_url`),
    `google_maps_reviews_url` = VALUES(`google_maps_reviews_url`),
    `open_hour` = VALUES(`open_hour`),
    `open_minute` = VALUES(`open_minute`),
    `close_hour` = VALUES(`close_hour`),
    `close_minute` = VALUES(`close_minute`),
    `closed_days` = VALUES(`closed_days`),
    `seasonal_notice` = VALUES(`seasonal_notice`),
    `deleted_at` = NULL;

-- 4. Art Dubai
INSERT INTO `government_entities` (
    `name`, `category`, `location`, `base_rating`, `base_review_count`,
    `rating`, `review_count`, `default_timing`, `default_is_open`,
    `website_url`, `directions_url`, `google_maps_reviews_url`,
    `open_hour`, `open_minute`, `close_hour`, `close_minute`, `closed_days`, `seasonal_notice`, `deleted_at`
) VALUES (
    'Art Dubai',
    'Art Fair · Cultural Event',
    'Madinat Jumeirah, Dubai',
    4.6, 180, 4.6, 180,
    'Closed · Opens Mar 2026', 0,
    'https://www.artdubai.ae/',
    'https://maps.google.com/?q=Madinat+Jumeirah+Dubai',
    'https://www.google.com/maps/search/?api=1&query=Madinat+Jumeirah+Dubai',
    10, 0, 20, 0, '', 'Closed · Opens Mar 2026', NULL
) ON DUPLICATE KEY UPDATE
    `category` = VALUES(`category`),
    `location` = VALUES(`location`),
    `base_rating` = VALUES(`base_rating`),
    `base_review_count` = VALUES(`base_review_count`),
    `rating` = VALUES(`rating`),
    `review_count` = VALUES(`review_count`),
    `default_timing` = VALUES(`default_timing`),
    `default_is_open` = VALUES(`default_is_open`),
    `website_url` = VALUES(`website_url`),
    `directions_url` = VALUES(`directions_url`),
    `google_maps_reviews_url` = VALUES(`google_maps_reviews_url`),
    `open_hour` = VALUES(`open_hour`),
    `open_minute` = VALUES(`open_minute`),
    `close_hour` = VALUES(`close_hour`),
    `close_minute` = VALUES(`close_minute`),
    `closed_days` = VALUES(`closed_days`),
    `seasonal_notice` = VALUES(`seasonal_notice`),
    `deleted_at` = NULL;

-- 5. Alserkal Avenue
INSERT INTO `government_entities` (
    `name`, `category`, `location`, `base_rating`, `base_review_count`,
    `rating`, `review_count`, `default_timing`, `default_is_open`,
    `website_url`, `directions_url`, `google_maps_reviews_url`,
    `open_hour`, `open_minute`, `close_hour`, `close_minute`, `closed_days`, `seasonal_notice`, `deleted_at`
) VALUES (
    'Alserkal Avenue',
    'Arts District · Gallery Hub',
    'Al Quoz, Dubai',
    4.8, 310, 4.8, 310,
    'Open · Closes at 20:00', 1,
    'https://alserkal.online/',
    'https://maps.google.com/?q=Alserkal+Avenue+Al+Quoz+Dubai',
    'https://www.google.com/maps/search/?api=1&query=Alserkal+Avenue+Al+Quoz+Dubai',
    10, 0, 20, 0, '', NULL, NULL
) ON DUPLICATE KEY UPDATE
    `category` = VALUES(`category`),
    `location` = VALUES(`location`),
    `base_rating` = VALUES(`base_rating`),
    `base_review_count` = VALUES(`base_review_count`),
    `rating` = VALUES(`rating`),
    `review_count` = VALUES(`review_count`),
    `default_timing` = VALUES(`default_timing`),
    `default_is_open` = VALUES(`default_is_open`),
    `website_url` = VALUES(`website_url`),
    `directions_url` = VALUES(`directions_url`),
    `google_maps_reviews_url` = VALUES(`google_maps_reviews_url`),
    `open_hour` = VALUES(`open_hour`),
    `open_minute` = VALUES(`open_minute`),
    `close_hour` = VALUES(`close_hour`),
    `close_minute` = VALUES(`close_minute`),
    `closed_days` = VALUES(`closed_days`),
    `seasonal_notice` = VALUES(`seasonal_notice`),
    `deleted_at` = NULL;

-- 6. Dubai Opera
INSERT INTO `government_entities` (
    `name`, `category`, `location`, `base_rating`, `base_review_count`,
    `rating`, `review_count`, `default_timing`, `default_is_open`,
    `website_url`, `directions_url`, `google_maps_reviews_url`,
    `open_hour`, `open_minute`, `close_hour`, `close_minute`, `closed_days`, `seasonal_notice`, `deleted_at`
) VALUES (
    'Dubai Opera',
    'Performing Arts · Venue',
    'Downtown Dubai',
    4.9, 450, 4.9, 450,
    'Open · Next show at 19:30', 1,
    'https://www.dubaiopera.com/en',
    'https://maps.google.com/?q=Dubai+Opera+Downtown+Dubai',
    'https://www.google.com/maps/search/?api=1&query=Dubai+Opera+Downtown+Dubai',
    10, 0, 23, 0, '', NULL, NULL
) ON DUPLICATE KEY UPDATE
    `category` = VALUES(`category`),
    `location` = VALUES(`location`),
    `base_rating` = VALUES(`base_rating`),
    `base_review_count` = VALUES(`base_review_count`),
    `rating` = VALUES(`rating`),
    `review_count` = VALUES(`review_count`),
    `default_timing` = VALUES(`default_timing`),
    `default_is_open` = VALUES(`default_is_open`),
    `website_url` = VALUES(`website_url`),
    `directions_url` = VALUES(`directions_url`),
    `google_maps_reviews_url` = VALUES(`google_maps_reviews_url`),
    `open_hour` = VALUES(`open_hour`),
    `open_minute` = VALUES(`open_minute`),
    `close_hour` = VALUES(`close_hour`),
    `close_minute` = VALUES(`close_minute`),
    `closed_days` = VALUES(`closed_days`),
    `seasonal_notice` = VALUES(`seasonal_notice`),
    `deleted_at` = NULL;
