-- ==============================================================================
-- ARTIST DUBAI — COMPREHENSIVE AUTOMATIC DATABASE TRIGGERS
-- Engine: MySQL 8.0+ / MariaDB 10.4+ (InnoDB Engine)
-- Target: Automated counter synchronization, auto-tag creation, activity notifications,
--         and cascading maintenance in full compliance with 3NF.
-- ==============================================================================

USE `artist_dubai`;

-- -----------------------------------------------------------------------------
-- 1. ARTWORKS: Automatic `works_count` sync on `artists` table
-- -----------------------------------------------------------------------------
DROP TRIGGER IF EXISTS `trg_artworks_after_insert`;
DELIMITER $$
CREATE TRIGGER `trg_artworks_after_insert`
AFTER INSERT ON `artworks`
FOR EACH ROW
BEGIN
    IF NEW.artist_id IS NOT NULL THEN
        UPDATE `artists`
        SET `works_count` = (
            SELECT COUNT(*) 
            FROM `artworks` 
            WHERE `artist_id` = NEW.artist_id 
              AND `deleted_at` IS NULL
        )
        WHERE `id` = NEW.artist_id;
    END IF;
END$$
DELIMITER ;

DROP TRIGGER IF EXISTS `trg_artworks_after_update`;
DELIMITER $$
CREATE TRIGGER `trg_artworks_after_update`
AFTER UPDATE ON `artworks`
FOR EACH ROW
BEGIN
    -- If artwork was soft-deleted or assigned to another artist, sync both
    IF (OLD.artist_id IS NOT NULL AND (OLD.artist_id != NEW.artist_id OR OLD.deleted_at IS NULL AND NEW.deleted_at IS NOT NULL OR OLD.deleted_at IS NOT NULL AND NEW.deleted_at IS NULL)) THEN
        UPDATE `artists`
        SET `works_count` = (
            SELECT COUNT(*) 
            FROM `artworks` 
            WHERE `artist_id` = OLD.artist_id 
              AND `deleted_at` IS NULL
        )
        WHERE `id` = OLD.artist_id;
    END IF;

    IF (NEW.artist_id IS NOT NULL AND (OLD.artist_id != NEW.artist_id OR OLD.deleted_at IS NOT NULL AND NEW.deleted_at IS NULL)) THEN
        UPDATE `artists`
        SET `works_count` = (
            SELECT COUNT(*) 
            FROM `artworks` 
            WHERE `artist_id` = NEW.artist_id 
              AND `deleted_at` IS NULL
        )
        WHERE `id` = NEW.artist_id;
    END IF;
END$$
DELIMITER ;

DROP TRIGGER IF EXISTS `trg_artworks_after_delete`;
DELIMITER $$
CREATE TRIGGER `trg_artworks_after_delete`
AFTER DELETE ON `artworks`
FOR EACH ROW
BEGIN
    IF OLD.artist_id IS NOT NULL THEN
        UPDATE `artists`
        SET `works_count` = (
            SELECT COUNT(*) 
            FROM `artworks` 
            WHERE `artist_id` = OLD.artist_id 
              AND `deleted_at` IS NULL
        )
        WHERE `id` = OLD.artist_id;
    END IF;
END$$
DELIMITER ;

-- -----------------------------------------------------------------------------
-- 2. GALLERY IMAGES: Automatic `photo_count` sync on `galleries` table
-- -----------------------------------------------------------------------------
DROP TRIGGER IF EXISTS `trg_gallery_images_after_insert`;
DELIMITER $$
CREATE TRIGGER `trg_gallery_images_after_insert`
AFTER INSERT ON `gallery_images`
FOR EACH ROW
BEGIN
    IF NEW.gallery_id IS NOT NULL THEN
        UPDATE `galleries`
        SET `photo_count` = (
            SELECT COUNT(*) 
            FROM `gallery_images` 
            WHERE `gallery_id` = NEW.gallery_id
        )
        WHERE `id` = NEW.gallery_id;
    END IF;
END$$
DELIMITER ;

DROP TRIGGER IF EXISTS `trg_gallery_images_after_delete`;
DELIMITER $$
CREATE TRIGGER `trg_gallery_images_after_delete`
AFTER DELETE ON `gallery_images`
FOR EACH ROW
BEGIN
    IF OLD.gallery_id IS NOT NULL THEN
        UPDATE `galleries`
        SET `photo_count` = (
            SELECT COUNT(*) 
            FROM `gallery_images` 
            WHERE `gallery_id` = OLD.gallery_id
        )
        WHERE `id` = OLD.gallery_id;
    END IF;
END$$
DELIMITER ;

-- -----------------------------------------------------------------------------
-- 3. FOLLOWS: Automatic `followers_count` sync on `artists` table
-- -----------------------------------------------------------------------------
DROP TRIGGER IF EXISTS `trg_follows_after_insert`;
DELIMITER $$
CREATE TRIGGER `trg_follows_after_insert`
AFTER INSERT ON `follows`
FOR EACH ROW
BEGIN
    IF NEW.artist_id IS NOT NULL THEN
        UPDATE `artists`
        SET `followers_count` = (
            SELECT COUNT(*) 
            FROM `follows` 
            WHERE `artist_id` = NEW.artist_id
        )
        WHERE `id` = NEW.artist_id;
    END IF;
END$$
DELIMITER ;

DROP TRIGGER IF EXISTS `trg_follows_after_delete`;
DELIMITER $$
CREATE TRIGGER `trg_follows_after_delete`
AFTER DELETE ON `follows`
FOR EACH ROW
BEGIN
    IF OLD.artist_id IS NOT NULL THEN
        UPDATE `artists`
        SET `followers_count` = (
            SELECT COUNT(*) 
            FROM `follows` 
            WHERE `artist_id` = OLD.artist_id
        )
        WHERE `id` = OLD.artist_id;
    END IF;
END$$
DELIMITER ;

-- -----------------------------------------------------------------------------
-- 4. FAVORITES: Automatic `likes_count` sync on `artists` table
-- -----------------------------------------------------------------------------
DROP TRIGGER IF EXISTS `trg_favorites_after_insert`;
DELIMITER $$
CREATE TRIGGER `trg_favorites_after_insert`
AFTER INSERT ON `favorites`
FOR EACH ROW
BEGIN
    IF NEW.item_type = 'artist' AND NEW.item_id IS NOT NULL THEN
        UPDATE `artists`
        SET `likes_count` = (
            SELECT COUNT(*) 
            FROM `favorites` 
            WHERE `item_type` = 'artist' 
              AND `item_id` = NEW.item_id
        )
        WHERE `id` = NEW.item_id;
    END IF;
END$$
DELIMITER ;

DROP TRIGGER IF EXISTS `trg_favorites_after_delete`;
DELIMITER $$
CREATE TRIGGER `trg_favorites_after_delete`
AFTER DELETE ON `favorites`
FOR EACH ROW
BEGIN
    IF OLD.item_type = 'artist' AND OLD.item_id IS NOT NULL THEN
        UPDATE `artists`
        SET `likes_count` = (
            SELECT COUNT(*) 
            FROM `favorites` 
            WHERE `item_type` = 'artist' 
              AND `item_id` = OLD.item_id
        )
        WHERE `id` = OLD.item_id;
    END IF;
END$$
DELIMITER ;

-- -----------------------------------------------------------------------------
-- 5. BOOKINGS: Automatic `attendees_count` sync on `events` table
-- -----------------------------------------------------------------------------
DROP TRIGGER IF EXISTS `trg_bookings_after_insert`;
DELIMITER $$
CREATE TRIGGER `trg_bookings_after_insert`
AFTER INSERT ON `bookings`
FOR EACH ROW
BEGIN
    IF NEW.event_id IS NOT NULL AND (NEW.status IS NULL OR NEW.status != 'cancelled') THEN
        UPDATE `events`
        SET `attendees_count` = (
            SELECT COALESCE(SUM(`tickets_count`), 0) 
            FROM `bookings` 
            WHERE `event_id` = NEW.event_id 
              AND `status` != 'cancelled'
        )
        WHERE `id` = NEW.event_id;
    END IF;
END$$
DELIMITER ;

DROP TRIGGER IF EXISTS `trg_bookings_after_update`;
DELIMITER $$
CREATE TRIGGER `trg_bookings_after_update`
AFTER UPDATE ON `bookings`
FOR EACH ROW
BEGIN
    -- If ticket count or status changed (e.g., cancelled or confirmed)
    IF (OLD.event_id IS NOT NULL AND (OLD.event_id != NEW.event_id OR OLD.tickets_count != NEW.tickets_count OR OLD.status != NEW.status)) THEN
        UPDATE `events`
        SET `attendees_count` = (
            SELECT COALESCE(SUM(`tickets_count`), 0) 
            FROM `bookings` 
            WHERE `event_id` = OLD.event_id 
              AND `status` != 'cancelled'
        )
        WHERE `id` = OLD.event_id;
    END IF;

    IF (NEW.event_id IS NOT NULL AND OLD.event_id != NEW.event_id) THEN
        UPDATE `events`
        SET `attendees_count` = (
            SELECT COALESCE(SUM(`tickets_count`), 0) 
            FROM `bookings` 
            WHERE `event_id` = NEW.event_id 
              AND `status` != 'cancelled'
        )
        WHERE `id` = NEW.event_id;
    END IF;
END$$
DELIMITER ;

DROP TRIGGER IF EXISTS `trg_bookings_after_delete`;
DELIMITER $$
CREATE TRIGGER `trg_bookings_after_delete`
AFTER DELETE ON `bookings`
FOR EACH ROW
BEGIN
    IF OLD.event_id IS NOT NULL THEN
        UPDATE `events`
        SET `attendees_count` = (
            SELECT COALESCE(SUM(`tickets_count`), 0) 
            FROM `bookings` 
            WHERE `event_id` = OLD.event_id 
              AND `status` != 'cancelled'
        )
        WHERE `id` = OLD.event_id;
    END IF;
END$$
DELIMITER ;

-- -----------------------------------------------------------------------------
-- 6. EVENTS: Automatic Community Notification on Publishing New Event
-- -----------------------------------------------------------------------------
DROP TRIGGER IF EXISTS `trg_events_after_insert_notify`;
DELIMITER $$
CREATE TRIGGER `trg_events_after_insert_notify`
AFTER INSERT ON `events`
FOR EACH ROW
BEGIN
    IF NEW.deleted_at IS NULL AND (NEW.status IS NULL OR NEW.status = 'approved' OR NEW.status = 'active') THEN
        INSERT INTO `notifications` (`user_id`, `user_email`, `title`, `body`, `type`, `route`, `is_read`, `created_at`)
        VALUES (
            NEW.user_id,
            NEW.contact_email,
            CONCAT('New Event: ', NEW.title),
            CONCAT('Explore the upcoming art event "', NEW.title, '" scheduled in ', COALESCE(NEW.location, 'Dubai'), '.'),
            'event',
            CONCAT('/events?id=', NEW.id),
            0,
            NOW()
        );
    END IF;
END$$
DELIMITER ;
