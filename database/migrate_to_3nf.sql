-- ==============================================================================
-- ARTIST DUBAI — 3NF DATA MIGRATION SCRIPT
-- Safely migrates existing data from legacy tables into 3NF normalized tables
-- ==============================================================================

SET FOREIGN_KEY_CHECKS = 0;

-- 1. Migrate gallery images from legacy images_json into normalized gallery_images table
-- Extracts any comma or JSON array image URLs into discrete rows
INSERT IGNORE INTO `gallery_images` (`gallery_id`, `image_url`, `sort_order`)
SELECT 
    g.id,
    TRIM(BOTH '"' FROM jt.image_url) AS image_url,
    jt.ordinality AS sort_order
FROM `galleries` g
CROSS JOIN JSON_TABLE(
    CASE 
        WHEN g.images_json IS NOT NULL AND JSON_VALID(g.images_json) THEN g.images_json
        ELSE JSON_ARRAY()
    END,
    '$[*]' COLUMNS (
        ordinality FOR ORDINALITY,
        image_url VARCHAR(500) PATH '$'
    )
) AS jt
WHERE jt.image_url IS NOT NULL AND jt.image_url != '';

-- 2. Populate tags and event_tags from legacy events.tags CSV string
-- Ensures clean distinct tag records
INSERT IGNORE INTO `tags` (`name`, `slug`)
SELECT DISTINCT
    TRIM(j.tag_name) AS name,
    LOWER(REPLACE(TRIM(j.tag_name), ' ', '-')) AS slug
FROM `events` e
CROSS JOIN JSON_TABLE(
    CONCAT('["', REPLACE(REPLACE(COALESCE(e.tags, ''), '"', ''), ',', '","'), '"]'),
    '$[*]' COLUMNS (tag_name VARCHAR(80) PATH '$')
) AS j
WHERE TRIM(j.tag_name) != '';

INSERT IGNORE INTO `event_tags` (`event_id`, `tag_id`)
SELECT DISTINCT
    e.id AS event_id,
    t.id AS tag_id
FROM `events` e
CROSS JOIN JSON_TABLE(
    CONCAT('["', REPLACE(REPLACE(COALESCE(e.tags, ''), '"', ''), ',', '","'), '"]'),
    '$[*]' COLUMNS (tag_name VARCHAR(80) PATH '$')
) AS j
INNER JOIN `tags` t ON t.name COLLATE utf8mb4_unicode_ci = TRIM(j.tag_name) COLLATE utf8mb4_unicode_ci
WHERE TRIM(j.tag_name) != '';

-- 3. Sync user_id in favorites and follows where user_id is currently NULL
UPDATE `favorites` f
INNER JOIN `users` u ON LOWER(u.email) COLLATE utf8mb4_unicode_ci = LOWER(f.user_email) COLLATE utf8mb4_unicode_ci
SET f.user_id = u.id
WHERE f.user_id IS NULL;

UPDATE `follows` fl
INNER JOIN `users` u ON LOWER(u.email) COLLATE utf8mb4_unicode_ci = LOWER(fl.user_email) COLLATE utf8mb4_unicode_ci
SET fl.user_id = u.id
WHERE fl.user_id IS NULL;

-- 4. Sync artist_id and user_id in bookings where only names/emails were stored
UPDATE `bookings` b
INNER JOIN `users` u ON LOWER(u.email) COLLATE utf8mb4_unicode_ci = LOWER(b.email) COLLATE utf8mb4_unicode_ci
SET b.user_id = u.id
WHERE b.user_id IS NULL;

UPDATE `bookings` b
INNER JOIN `artists` a ON LOWER(a.name) COLLATE utf8mb4_unicode_ci = LOWER(b.artist_name) COLLATE utf8mb4_unicode_ci
SET b.artist_id = a.id
WHERE b.artist_id IS NULL AND b.artist_name IS NOT NULL AND b.artist_name != '';

SET FOREIGN_KEY_CHECKS = 1;
