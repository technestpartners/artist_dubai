<?php
/**
 * Artist Dubai - Strictly Pure MySQL Database Connection & Schema Provisioning
 */

if (!headers_sent()) {
    header("Access-Control-Allow-Origin: *");
    header("Access-Control-Allow-Headers: Content-Type, Authorization");
    header("Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS");
    header("Content-Type: application/json; charset=UTF-8");
}

if (isset($_SERVER['REQUEST_METHOD']) && $_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

$host = '127.0.0.1';
$db   = 'artist_dubai';
$user = 'root';
$pass = '';

try {
    // 1. Connect to MySQL server root to ensure database exists
    $rootPdo = new PDO("mysql:host=$host;charset=utf8mb4", $user, $pass, [
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
    ]);
    $rootPdo->exec("CREATE DATABASE IF NOT EXISTS `$db` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci");

    // 2. Connect to artist_dubai MySQL database
    $pdo = new PDO("mysql:host=$host;dbname=$db;charset=utf8mb4", $user, $pass, [
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
        PDO::ATTR_EMULATE_PREPARES => false,
    ]);

    // 3. Ensure MySQL tables exist
    $pdo->exec("
        CREATE TABLE IF NOT EXISTS users (
            id INT AUTO_INCREMENT PRIMARY KEY,
            full_name VARCHAR(255) NOT NULL,
            email VARCHAR(255) NOT NULL UNIQUE,
            password_hash VARCHAR(255) NOT NULL,
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

        CREATE TABLE IF NOT EXISTS artists (
            id INT AUTO_INCREMENT PRIMARY KEY,
            user_id INT NULL,
            name VARCHAR(255) NOT NULL,
            category VARCHAR(255) NOT NULL,
            location VARCHAR(255) NOT NULL,
            bio TEXT,
            avatar_url VARCHAR(500) NULL,
            banner_url VARCHAR(500) NULL,
            followers_count INT DEFAULT 0,
            works_count INT DEFAULT 0,
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

        CREATE TABLE IF NOT EXISTS bookings (
            id INT AUTO_INCREMENT PRIMARY KEY,
            full_name VARCHAR(255) NOT NULL,
            email VARCHAR(255) NOT NULL,
            phone VARCHAR(100) NULL,
            artist_name VARCHAR(255) NULL,
            booking_type VARCHAR(100) NULL,
            budget_range VARCHAR(100) NULL,
            event_date VARCHAR(100) NULL,
            end_date VARCHAR(100) NULL,
            location VARCHAR(255) NULL,
            description TEXT NULL,
            requirements TEXT NULL,
            status VARCHAR(50) DEFAULT 'Pending',
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

        CREATE TABLE IF NOT EXISTS events (
            id INT AUTO_INCREMENT PRIMARY KEY,
            title VARCHAR(255) NOT NULL,
            description TEXT NULL,
            category VARCHAR(100) NULL,
            event_date VARCHAR(100) NULL,
            end_date VARCHAR(100) NULL,
            location VARCHAR(255) NULL,
            venue VARCHAR(255) NULL,
            is_free TINYINT(1) DEFAULT 1,
            organizer_name VARCHAR(255) NULL,
            contact_email VARCHAR(255) NULL,
            contact_phone VARCHAR(100) NULL,
            tags VARCHAR(500) NULL,
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

        CREATE TABLE IF NOT EXISTS categories (
            id INT AUTO_INCREMENT PRIMARY KEY,
            name VARCHAR(255) NOT NULL UNIQUE,
            description TEXT NULL,
            emoji VARCHAR(50) DEFAULT '🎨',
            color VARCHAR(50) DEFAULT 'Primary',
            tags VARCHAR(500) NULL,
            is_featured TINYINT(1) DEFAULT 0,
            artist_count INT DEFAULT 0,
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ");

    // 4. Seed initial MySQL demo data if empty
    $check = $pdo->query("SELECT COUNT(*) FROM artists")->fetchColumn();
    if ($check == 0) {
        $pdo->exec("
            INSERT INTO users (full_name, email, password_hash) 
            VALUES ('Allen Baiyee', 'allenbaiyee@me.com', '\$2y\$10\$e.1Wq2t.7/f5N6A8G7q.ue3H1F8/q5J9Y4V2S1Z8X7C6V5B4N3M2');

            INSERT INTO artists (name, category, location, bio, followers_count, works_count) 
            VALUES ('Frankie DeChiazza', 'Mixed Media', 'USA', 'TripTrap ... international alien... pop star', 120, 15),
                   ('Alexander Mollov', 'Mixed Media', 'Dubai, UAE', 'Award-winning Music Video Director and multidisciplinary creative', 450, 28);
        ");
    }

} catch (\PDOException $e) {
    http_response_code(500);
    echo json_encode([
        'status' => 'error',
        'success' => false,
        'message' => 'MySQL Connection Error: ' . $e->getMessage()
    ]);
    exit();
}
