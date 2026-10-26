-- Add missing 3NF foreign key columns safely via stored procedure
DROP PROCEDURE IF EXISTS AddColumnSafely;
DELIMITER $$
CREATE PROCEDURE AddColumnSafely(
    IN p_table VARCHAR(64),
    IN p_column VARCHAR(64),
    IN p_definition VARCHAR(255)
)
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.COLUMNS 
        WHERE TABLE_SCHEMA = DATABASE() 
        AND TABLE_NAME = p_table 
        AND COLUMN_NAME = p_column
    ) THEN
        SET @sql = CONCAT('ALTER TABLE `', p_table, '` ADD COLUMN `', p_column, '` ', p_definition);
        PREPARE stmt FROM @sql;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;
    END IF;
END$$
DELIMITER ;

CALL AddColumnSafely('follows', 'user_id', 'INT NULL AFTER id');
CALL AddColumnSafely('bookings', 'user_id', 'INT NULL AFTER id');
CALL AddColumnSafely('bookings', 'artist_id', 'INT NULL AFTER event_id');
CALL AddColumnSafely('galleries', 'user_id', 'INT NULL AFTER id');
DROP PROCEDURE IF EXISTS AddColumnSafely;
