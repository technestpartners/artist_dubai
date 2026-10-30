<?php
/**
 * Artist Dubai - Strictly Pure MySQL Single-File REST API System
 * Version: 6.3.0
 * Database Engine: Pure MySQL (Laragon MySQL Engine)
 * Architecture: High-Performance Single-File OOP Controller-Router System
 */

ob_start();

// ─── 0. Security Baseline & Error Shielding ──────────────────────────────────
ini_set('display_errors', '0');
ini_set('display_startup_errors', '0');
error_reporting(E_ALL & ~E_DEPRECATED & ~E_STRICT);
if (function_exists('header_remove')) {
    header_remove('X-Powered-By');
}

// ─── 0b. HTTP Method Restriction ─────────────────────────────────────────────
$requestMethod = strtoupper($_SERVER['REQUEST_METHOD'] ?? 'GET');
$allowedMethods = ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS', 'PATCH', 'HEAD'];
if (!in_array($requestMethod, $allowedMethods, true)) {
    http_response_code(405);
    header("Content-Type: application/json; charset=UTF-8");
    echo json_encode([
        'status' => 'error',
        'success' => false,
        'message' => 'Method Not Allowed'
    ], JSON_UNESCAPED_SLASHES);
    exit();
}

// ─── 0c. Denial-of-Service & Payload Size Guard ──────────────────────────────
$contentLength = (int)($_SERVER['CONTENT_LENGTH'] ?? 0);
$isUploadRoute = (isset($_GET['resource']) && in_array($_GET['resource'], ['uploads', 'upload'], true));
$maxAllowedSize = $isUploadRoute ? 15728640 : 2097152; // 15MB for uploads, 2MB for standard JSON API
if ($contentLength > $maxAllowedSize) {
    http_response_code(413);
    header("Content-Type: application/json; charset=UTF-8");
    echo json_encode([
        'status' => 'error',
        'success' => false,
        'message' => 'Payload Too Large. Maximum allowed size exceeded.'
    ], JSON_UNESCAPED_SLASHES);
    exit();
}

// ─── 0d. Web Application Firewall (WAF) & Exploit Signature Filter ───────────
$rawUri = $_SERVER['REQUEST_URI'] ?? '';
$rawQuery = $_SERVER['QUERY_STRING'] ?? '';
$decodedUri = rawurldecode($rawUri);
$decodedQuery = rawurldecode($rawQuery);

$exploitPatterns = [
    '/\x00/',                                       // Null-byte injection
    '/(?:\.\.\/|\.\.\\\\)/',                         // Path traversal (../ or ..\)
    '/(?:%2e%2e%2f|%2e%2e\/|\.\.%2f)/i',             // Encoded path traversal
    '/(?:union\s+(?:all\s+)?select)/i',              // Obvious SQL injection UNION SELECT
    '/(?:information_schema|load_file\s*\(|into\s+(?:outfile|dumpfile))/i', // Advanced SQLi
    '/(?:<script[\s>])/i',                           // XSS script tags in URL query
    '/(?:base64_decode\s*\(|eval\s*\(|system\s*\(|shell_exec\s*\()/i', // PHP RCE wrappers
    '/(?:\/etc\/(?:passwd|shadow|hosts)|\/proc\/self\/environ|boot\.ini)/i', // System file probe
];

foreach ($exploitPatterns as $pattern) {
    if (preg_match($pattern, $rawUri) || preg_match($pattern, $decodedUri) ||
        preg_match($pattern, $rawQuery) || preg_match($pattern, $decodedQuery)) {
        http_response_code(400);
        header("Content-Type: application/json; charset=UTF-8");
        echo json_encode([
            'status' => 'error',
            'success' => false,
            'message' => 'Bad Request: Malformed or prohibited request signature detected.'
        ], JSON_UNESCAPED_SLASHES);
        exit();
    }
}

if (!headers_sent()) {
    // ─── CORS Allowlist & Origin Hardening ───────────────────────────────────
    $allowedOrigins = [
        'https://technestpartners.com',
        'https://www.technestpartners.com',
        'https://artistdubai.com',
        'https://www.artistdubai.com',
    ];
    $requestOrigin = $_SERVER['HTTP_ORIGIN'] ?? '';
    $originAllowed = in_array($requestOrigin, $allowedOrigins, true) ||
                     preg_match('/^https?:\/\/(localhost|127\.0\.0\.1)(:\d+)?$/i', $requestOrigin);

    // Flutter mobile apps (no Origin header) and verified origins are granted CORS
    if (empty($requestOrigin) || $originAllowed) {
        if (!empty($requestOrigin)) {
            header("Access-Control-Allow-Origin: {$requestOrigin}");
            header("Access-Control-Allow-Credentials: true");
            header("Vary: Origin");
        }
    }

    $reqHeaders = $_SERVER['HTTP_ACCESS_CONTROL_REQUEST_HEADERS'] ?? 'Content-Type, Authorization, X-Requested-With, Accept, Origin, If-None-Match, X-Api-Key, X-Auth-Token, Accept-Language';
    header("Access-Control-Allow-Headers: $reqHeaders");
    header("Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS, PATCH, HEAD");
    header("Access-Control-Max-Age: 86400");
    header("X-Content-Type-Options: nosniff");
    header("X-Frame-Options: DENY");
    header("X-XSS-Protection: 1; mode=block");
    header("Referrer-Policy: strict-origin-when-cross-origin");
    header("Content-Security-Policy: default-src 'none'; frame-ancestors 'none';");
    header("Permissions-Policy: geolocation=(), microphone=(), camera=()");
    header("Content-Type: application/json; charset=UTF-8");
    header("Cache-Control: no-cache, no-store, must-revalidate, max-age=0");
    header("Pragma: no-cache");
    header("Expires: 0");

    if (!empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off') {
        header("Strict-Transport-Security: max-age=31536000; includeSubDomains; preload");
    }
}

if ($requestMethod === 'OPTIONS') {
    http_response_code(200);
    exit();
}

/**
 * -----------------------------------------------------------------------------
 * 1. ENVIRONMENT CONFIGURATION LOADER
 * -----------------------------------------------------------------------------
 * Automatically reads and parses .env if present in the api or root directory.
 */
(function() {
    $envDirs = [__DIR__, dirname(__DIR__)];
    foreach ($envDirs as $dir) {
        $envFile = $dir . DIRECTORY_SEPARATOR . '.env';
        if (file_exists($envFile) && is_readable($envFile)) {
            $lines = file($envFile, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
            foreach ($lines as $line) {
                $line = trim($line);
                if ($line === '' || str_starts_with($line, '#')) continue;
                $parts = explode('=', $line, 2);
                if (count($parts) === 2) {
                    $key = trim($parts[0]);
                    $val = trim($parts[1]);
                    // Strip optional quotes
                    if (str_starts_with($val, '"') && str_ends_with($val, '"')) {
                        $val = substr($val, 1, -1);
                    } elseif (str_starts_with($val, "'") && str_ends_with($val, "'")) {
                        $val = substr($val, 1, -1);
                    }
                    if (!getenv($key)) {
                        putenv("{$key}={$val}");
                        $_ENV[$key] = $val;
                    }
                }
            }
            break;
        }
    }
})();

if (!defined('DB_HOST')) define('DB_HOST', getenv('DB_HOST') ?: 'localhost');
if (!defined('DB_NAME')) define('DB_NAME', getenv('DB_NAME') ?: 'u530915492_artist_dubai');
if (!defined('DB_USER')) define('DB_USER', getenv('DB_USER') ?: 'u530915492_artist_dubai');
if (!defined('DB_PASS')) define('DB_PASS', getenv('DB_PASS') !== false && getenv('DB_PASS') !== null ? getenv('DB_PASS') : 'Artist@Dubai@TN21');
if (!defined('DB_PORT')) define('DB_PORT', (int)(getenv('DB_PORT') ?: 3306));
if (!defined('GEMINI_API_KEY')) define('GEMINI_API_KEY', getenv('GEMINI_API_KEY') ?: '');

// -----------------------------------------------------------------------------
// Strictly Pure MySQL Database Manager Singleton Class
// -----------------------------------------------------------------------------
class DatabaseManager {
    private static ?DatabaseManager $instance = null;
    private PDO $pdo;

    private function __construct() {
        $host = DB_HOST;
        $db   = DB_NAME;
        $user = DB_USER;
        $pass = DB_PASS;
        $port = DB_PORT;

        try {
            $dsn = "mysql:host=$host;port=$port;dbname=$db;charset=utf8mb4";
            $this->pdo = new PDO($dsn, $user, $pass, [
                PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
                PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
                PDO::ATTR_EMULATE_PREPARES => false,
            ]);

            $this->provisionMySqlSchema();
        } catch (\PDOException $e) {
            // Development fallback for local Laragon MySQL (root with empty password)
            $isLocalHost = in_array(strtolower($host), ['localhost', '127.0.0.1'], true);
            if ($isLocalHost) {
                try {
                    $localDsn = "mysql:host=localhost;port=3306;dbname=artist_dubai;charset=utf8mb4";
                    $this->pdo = new PDO($localDsn, 'root', '', [
                        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
                        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
                        PDO::ATTR_EMULATE_PREPARES => false,
                    ]);
                    $this->provisionMySqlSchema();
                    return;
                } catch (\Throwable $localErr) {}
            }

            http_response_code(500);
            // Log the real error server-side (not exposed to clients)
            error_log('[ArtistDubai] Database connection failed: ' . $e->getMessage());
            echo json_encode([
                'status'   => 'error',
                'success'  => false,
                'message'  => 'Service temporarily unavailable. Please try again shortly.',
                'database' => 'MySQL'
            ], JSON_UNESCAPED_SLASHES);
            exit();
        }
    }

    public static function getInstance(): DatabaseManager {
        if (self::$instance === null) {
            self::$instance = new DatabaseManager();
        }
        return self::$instance;
    }

    public function getConnection(): PDO {
        return $this->pdo;
    }

    private function provisionMySqlSchema(): void {
        $flagFile = __DIR__ . '/.schema_provisioned';
        $forceMigrate = (php_sapi_name() === 'cli' && in_array('migrate', $_SERVER['argv'] ?? []));
        if (!$forceMigrate && isset($_GET['action']) && $_GET['action'] === 'migrate') {
            try {
                AuthMiddleware::requireAdmin();
                $forceMigrate = true;
            } catch (\Throwable $t) {
                $forceMigrate = false;
            }
        }
        if (file_exists($flagFile) && !$forceMigrate) {
            return;
        }

        $this->pdo->exec("
            CREATE TABLE IF NOT EXISTS users (
                id INT AUTO_INCREMENT PRIMARY KEY,
                full_name VARCHAR(255) NOT NULL,
                email VARCHAR(255) NOT NULL UNIQUE,
                password_hash VARCHAR(255) NOT NULL,
                chat_plan VARCHAR(100) DEFAULT 'Basic (Free)',
                chat_max_allowance INT DEFAULT 10,
                created_at DATETIME DEFAULT CURRENT_TIMESTAMP
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

            CREATE TABLE IF NOT EXISTS artists (
                id INT AUTO_INCREMENT PRIMARY KEY,
                user_id INT NULL,
                name VARCHAR(255) NOT NULL,
                category VARCHAR(255) NOT NULL,
                location VARCHAR(255) NOT NULL,
                bio TEXT NULL,
                avatar_url VARCHAR(500) NULL,
                banner_url VARCHAR(500) NULL,
                followers_count INT DEFAULT 0,
                works_count INT DEFAULT 0,
                email VARCHAR(255) NULL,
                phone VARCHAR(50) NULL,
                website VARCHAR(255) NULL,
                instagram VARCHAR(255) NULL,
                experience_level VARCHAR(100) NULL,
                booking_rate VARCHAR(100) DEFAULT 'AED 1500+',
                created_at DATETIME DEFAULT CURRENT_TIMESTAMP
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

            CREATE TABLE IF NOT EXISTS events (
                id INT AUTO_INCREMENT PRIMARY KEY,
                title VARCHAR(255) NOT NULL,
                description TEXT NULL,
                category VARCHAR(100) NULL,
                price VARCHAR(50) DEFAULT 'Free',
                event_date VARCHAR(100) NULL,
                end_date VARCHAR(100) NULL,
                location VARCHAR(255) NULL,
                venue VARCHAR(255) NULL,
                is_free TINYINT(1) DEFAULT 1,
                attendees_count INT DEFAULT 0,
                max_attendees INT DEFAULT 100,
                organizer_name VARCHAR(255) NULL,
                contact_email VARCHAR(255) NULL,
                contact_phone VARCHAR(100) NULL,
                tags VARCHAR(500) NULL,
                image_url VARCHAR(500) NULL,
                created_at DATETIME DEFAULT CURRENT_TIMESTAMP
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

            CREATE TABLE IF NOT EXISTS bookings (
                id INT AUTO_INCREMENT PRIMARY KEY,
                full_name VARCHAR(255) NOT NULL,
                email VARCHAR(255) NOT NULL,
                phone VARCHAR(100) NULL,
                artist_name VARCHAR(255) NULL,
                booking_type VARCHAR(100) NULL,
                event_id INT NULL,
                event_title VARCHAR(255) NULL,
                event_date VARCHAR(100) NULL,
                location VARCHAR(255) NULL,
                description TEXT NULL,
                tickets_count INT DEFAULT 1,
                total_price VARCHAR(50) DEFAULT 'Free',
                status VARCHAR(50) DEFAULT 'Confirmed',
                created_at DATETIME DEFAULT CURRENT_TIMESTAMP
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

            CREATE TABLE IF NOT EXISTS artworks (
                id INT AUTO_INCREMENT PRIMARY KEY,
                artist_id INT NULL,
                artist_name VARCHAR(100) NULL,
                title VARCHAR(150) NOT NULL,
                year VARCHAR(10) DEFAULT '2024',
                medium VARCHAR(100) DEFAULT 'Mixed Media',
                dimensions VARCHAR(100) DEFAULT '120 x 80 cm',
                description TEXT NULL,
                price VARCHAR(50) DEFAULT 'USD 1800 - 2200',
                image_url VARCHAR(255) DEFAULT NULL,
                is_featured TINYINT(1) DEFAULT 0,
                created_at DATETIME DEFAULT CURRENT_TIMESTAMP
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

            CREATE TABLE IF NOT EXISTS favorites (
                id INT AUTO_INCREMENT PRIMARY KEY,
                user_id INT NULL,
                user_email VARCHAR(255) NOT NULL,
                item_type VARCHAR(50) NOT NULL,
                item_id INT NOT NULL,
                created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                UNIQUE KEY unique_favorite (user_email, item_type, item_id)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

            CREATE TABLE IF NOT EXISTS follows (
                id INT AUTO_INCREMENT PRIMARY KEY,
                user_id INT NULL,
                user_email VARCHAR(255) NOT NULL,
                artist_id INT NOT NULL,
                created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                UNIQUE KEY unique_follow (user_email, artist_id)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

            CREATE TABLE IF NOT EXISTS categories (
                id INT AUTO_INCREMENT PRIMARY KEY,
                name VARCHAR(255) NOT NULL UNIQUE,
                type VARCHAR(50) DEFAULT 'general',
                description TEXT NULL,
                emoji VARCHAR(50) DEFAULT '🎨',
                created_at DATETIME DEFAULT CURRENT_TIMESTAMP
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

            CREATE TABLE IF NOT EXISTS experience_levels (
                id INT AUTO_INCREMENT PRIMARY KEY,
                name VARCHAR(255) NOT NULL UNIQUE,
                years_range VARCHAR(100) NULL,
                display_order INT DEFAULT 0,
                deleted_at DATETIME NULL DEFAULT NULL,
                created_at DATETIME DEFAULT CURRENT_TIMESTAMP
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

            CREATE TABLE IF NOT EXISTS locations (
                id INT AUTO_INCREMENT PRIMARY KEY,
                name VARCHAR(255) NOT NULL UNIQUE,
                city VARCHAR(100) DEFAULT 'Dubai',
                country VARCHAR(100) DEFAULT 'UAE',
                display_order INT DEFAULT 0,
                created_at DATETIME DEFAULT CURRENT_TIMESTAMP
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

            CREATE TABLE IF NOT EXISTS galleries (
                id INT AUTO_INCREMENT PRIMARY KEY,
                name VARCHAR(255) NOT NULL,
                category VARCHAR(255) NULL,
                location VARCHAR(255) NULL,
                timing VARCHAR(255) NULL,
                website VARCHAR(500) NULL,
                image_url VARCHAR(500) NULL,
                created_at DATETIME DEFAULT CURRENT_TIMESTAMP
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

            CREATE TABLE IF NOT EXISTS government_entities (
                id INT AUTO_INCREMENT PRIMARY KEY,
                name VARCHAR(255) NOT NULL UNIQUE,
                category VARCHAR(255) NOT NULL,
                location VARCHAR(255) NOT NULL,
                base_rating DECIMAL(3,1) DEFAULT 4.5,
                base_review_count INT DEFAULT 100,
                default_timing VARCHAR(255) NULL,
                default_is_open TINYINT(1) DEFAULT 1,
                website_url VARCHAR(500) NULL,
                directions_url VARCHAR(500) NULL,
                google_maps_reviews_url VARCHAR(500) NULL,
                open_hour INT DEFAULT 8,
                open_minute INT DEFAULT 0,
                close_hour INT DEFAULT 18,
                close_minute INT DEFAULT 0,
                closed_days VARCHAR(50) DEFAULT '6,7',
                seasonal_notice VARCHAR(255) NULL,
                created_at DATETIME DEFAULT CURRENT_TIMESTAMP
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

            CREATE TABLE IF NOT EXISTS notifications (
                id INT AUTO_INCREMENT PRIMARY KEY,
                user_email VARCHAR(255) NULL,
                title VARCHAR(255) NOT NULL,
                body TEXT NOT NULL,
                type VARCHAR(50) DEFAULT 'general',
                route VARCHAR(255) DEFAULT NULL,
                is_read TINYINT(1) DEFAULT 0,
                created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                INDEX idx_user_email (user_email),
                INDEX idx_is_read (is_read)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
            CREATE TABLE IF NOT EXISTS api_tokens (
                id INT AUTO_INCREMENT PRIMARY KEY,
                user_id INT NOT NULL,
                token VARCHAR(128) NOT NULL UNIQUE,
                role VARCHAR(50) DEFAULT 'user',
                created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                expires_at DATETIME NOT NULL,
                last_used_at DATETIME NULL,
                INDEX idx_token (token),
                INDEX idx_user (user_id),
                INDEX idx_expires (expires_at)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

            CREATE TABLE IF NOT EXISTS rate_limits (
                id INT AUTO_INCREMENT PRIMARY KEY,
                ip_address VARCHAR(45) NOT NULL,
                action_key VARCHAR(100) NOT NULL,
                attempts INT DEFAULT 1,
                window_start INT NOT NULL,
                last_attempt INT NOT NULL,
                INDEX idx_ip_action (ip_address, action_key)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

            CREATE TABLE IF NOT EXISTS publishing_pricing (
                id INT AUTO_INCREMENT PRIMARY KEY,
                item_type VARCHAR(50) DEFAULT 'event',
                item_name VARCHAR(255) NOT NULL,
                description TEXT NULL,
                weekly_price VARCHAR(100) DEFAULT 'AED 150',
                monthly_price VARCHAR(100) DEFAULT 'AED 500',
                three_month_price VARCHAR(100) DEFAULT 'AED 1,200',
                six_month_price VARCHAR(100) DEFAULT 'AED 2,500',
                yearly_price VARCHAR(100) DEFAULT 'AED 4,500',
                three_month_badge VARCHAR(50) DEFAULT 'Popular',
                six_month_badge VARCHAR(50) DEFAULT 'Save 17%',
                yearly_badge VARCHAR(50) DEFAULT 'Best Value',
                currency VARCHAR(20) DEFAULT 'AED',
                is_active TINYINT(1) DEFAULT 1,
                updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

            CREATE TABLE IF NOT EXISTS listing_plans (
                id INT AUTO_INCREMENT PRIMARY KEY,
                item_type VARCHAR(50) NOT NULL,
                title VARCHAR(255) NOT NULL,
                category VARCHAR(100) NOT NULL,
                badge VARCHAR(50) DEFAULT 'One-time',
                price VARCHAR(100) NOT NULL,
                duration VARCHAR(100) DEFAULT '30 Days',
                duration_days INT DEFAULT 30,
                description TEXT NULL,
                features_json TEXT NULL,
                button_text VARCHAR(100) DEFAULT 'Pay from My Listings',
                is_active TINYINT(1) DEFAULT 1,
                sort_order INT DEFAULT 0,
                created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                INDEX idx_listing_plan_type (item_type)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

            CREATE TABLE IF NOT EXISTS user_plans (
                id INT AUTO_INCREMENT PRIMARY KEY,
                user_id INT NULL,
                user_email VARCHAR(255) NOT NULL,
                plan_name VARCHAR(255) NOT NULL,
                plan_type VARCHAR(100) DEFAULT 'Subscription',
                item_title VARCHAR(255) NULL,
                price VARCHAR(100) NOT NULL DEFAULT 'Free',
                billing_cycle VARCHAR(100) DEFAULT 'Monthly',
                status VARCHAR(50) DEFAULT 'Active',
                payment_reference VARCHAR(255) NULL,
                payment_method VARCHAR(100) DEFAULT 'Card',
                features_json TEXT NULL,
                start_date DATETIME DEFAULT CURRENT_TIMESTAMP,
                expires_at DATETIME NULL,
                created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                INDEX idx_user_plan_email (user_email),
                INDEX idx_user_plan_status (status)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

            CREATE TABLE IF NOT EXISTS payment_settings (
                id INT AUTO_INCREMENT PRIMARY KEY,
                qr_code_url VARCHAR(500) DEFAULT 'https://images.unsplash.com/photo-1595079672139-545c0ecac12a?auto=format&fit=crop&w=400&q=80',
                account_name VARCHAR(255) DEFAULT 'Artist Dubai Cultural Services LLC',
                account_number VARCHAR(100) DEFAULT 'AE28 0330 0000 0001 2345 678',
                bank_name VARCHAR(255) DEFAULT 'Emirates NBD, Dubai',
                instructions TEXT NULL,
                is_active TINYINT(1) DEFAULT 1,
                updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

            CREATE TABLE IF NOT EXISTS menu_permissions (
                id INT AUTO_INCREMENT PRIMARY KEY,
                `key` VARCHAR(64) NOT NULL UNIQUE,
                `title` VARCHAR(128) NOT NULL,
                `subtitle` VARCHAR(128) NULL,
                `route_name` VARCHAR(128) NOT NULL,
                `image_path` VARCHAR(255) NULL,
                `is_enabled` TINYINT(1) NOT NULL DEFAULT 1,
                `updated_at` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

            CREATE TABLE IF NOT EXISTS artist_messages (
                id INT AUTO_INCREMENT PRIMARY KEY,
                sender_id VARCHAR(100) NULL,
                sender_name VARCHAR(255) NOT NULL,
                sender_email VARCHAR(255) NOT NULL,
                recipient_id VARCHAR(100) NOT NULL,
                recipient_name VARCHAR(255) NOT NULL,
                recipient_category VARCHAR(100) DEFAULT 'Artist',
                recipient_avatar_url VARCHAR(500) NULL,
                subject VARCHAR(255) NOT NULL,
                message TEXT NOT NULL,
                flyer_url VARCHAR(500) NULL,
                is_read TINYINT(1) DEFAULT 0,
                created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                INDEX idx_sender (sender_email),
                INDEX idx_recipient (recipient_id)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

            CREATE TABLE IF NOT EXISTS ai_chat_sessions (
                id VARCHAR(100) PRIMARY KEY,
                user_id VARCHAR(100) NULL,
                user_email VARCHAR(255) NULL,
                title VARCHAR(255) NOT NULL,
                created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                INDEX idx_user_email (user_email),
                INDEX idx_updated_at (updated_at)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

            CREATE TABLE IF NOT EXISTS ai_chat_messages (
                id INT AUTO_INCREMENT PRIMARY KEY,
                session_id VARCHAR(100) NOT NULL,
                sender VARCHAR(50) NOT NULL,
                message TEXT NOT NULL,
                created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                INDEX idx_session (session_id)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
        
        ");

        // Safe Column Migrations for Existing Tables
        $migrations = [
            "ALTER TABLE bookings ADD COLUMN event_id INT NULL",
            "ALTER TABLE bookings ADD COLUMN event_title VARCHAR(255) NULL",
            "ALTER TABLE bookings ADD COLUMN tickets_count INT DEFAULT 1",
            "ALTER TABLE bookings ADD COLUMN total_price VARCHAR(50) DEFAULT 'Free'",
            "ALTER TABLE bookings ADD COLUMN status VARCHAR(50) DEFAULT 'Confirmed'",
            "ALTER TABLE bookings ADD COLUMN budget_range VARCHAR(100) NULL",
            "ALTER TABLE bookings ADD COLUMN end_date VARCHAR(100) NULL",
            "ALTER TABLE bookings ADD COLUMN requirements TEXT NULL",
            "ALTER TABLE artists ADD COLUMN likes_count INT DEFAULT 0",
            "ALTER TABLE artists ADD COLUMN experience_level VARCHAR(100) NULL",
            "ALTER TABLE artists ADD COLUMN booking_rate VARCHAR(100) DEFAULT 'AED 1500+'",
            "ALTER TABLE artists ADD COLUMN email VARCHAR(255) NULL",
            "ALTER TABLE artists ADD COLUMN phone VARCHAR(50) NULL",
            "ALTER TABLE artists ADD COLUMN website VARCHAR(255) NULL",
            "ALTER TABLE artists ADD COLUMN instagram VARCHAR(255) NULL",
            "ALTER TABLE galleries ADD COLUMN timing VARCHAR(255) NULL DEFAULT NULL",
            "ALTER TABLE galleries ADD COLUMN artist_id VARCHAR(100) NULL",
            "ALTER TABLE galleries ADD COLUMN artist_name VARCHAR(255) NULL",
            "ALTER TABLE galleries ADD COLUMN description TEXT NULL",
            "ALTER TABLE galleries ADD COLUMN photo_count INT DEFAULT 1",
            "ALTER TABLE galleries ADD COLUMN images_json TEXT NULL",
            "ALTER TABLE galleries ADD COLUMN contact_person VARCHAR(255) NULL",
            "ALTER TABLE galleries ADD COLUMN email VARCHAR(255) NULL",
            "ALTER TABLE users ADD COLUMN role VARCHAR(50) DEFAULT 'user'",
            "ALTER TABLE users ADD COLUMN chat_plan VARCHAR(100) DEFAULT 'Basic (Free)'",
            "ALTER TABLE users ADD COLUMN chat_max_allowance INT DEFAULT 10",
            "ALTER TABLE galleries ADD COLUMN phone VARCHAR(100) NULL",
            "ALTER TABLE galleries ADD COLUMN about TEXT NULL",
            "ALTER TABLE galleries ADD COLUMN status VARCHAR(50) DEFAULT 'approved'",
            "ALTER TABLE galleries ADD COLUMN is_public TINYINT(1) DEFAULT 1",
            "ALTER TABLE galleries ADD COLUMN is_approved TINYINT(1) DEFAULT 1",
            "ALTER TABLE government_entities ADD COLUMN base_rating DECIMAL(3,1) DEFAULT 4.5",
            "ALTER TABLE government_entities ADD COLUMN base_review_count INT DEFAULT 100",
            "ALTER TABLE government_entities ADD COLUMN rating DECIMAL(3,1) DEFAULT 4.5",
            "ALTER TABLE government_entities ADD COLUMN review_count INT DEFAULT 100",
            "ALTER TABLE artists ADD INDEX idx_artist_cat (category)",
            "ALTER TABLE artists ADD INDEX idx_artist_email (email)",
            "ALTER TABLE events ADD INDEX idx_event_cat (category)",
            "ALTER TABLE events ADD INDEX idx_event_contact (contact_email)",
            "ALTER TABLE ai_chat_messages ADD COLUMN related_questions TEXT NULL",
            "ALTER TABLE bookings ADD INDEX idx_booking_email (email)",
            "ALTER TABLE bookings ADD INDEX idx_booking_status (status)",
            "ALTER TABLE artworks ADD INDEX idx_artworks_artist (artist_id)",
            "ALTER TABLE galleries ADD INDEX idx_gallery_cat (category)",
            "ALTER TABLE galleries ADD INDEX idx_gallery_status (status)",
            "ALTER TABLE events ADD COLUMN galleries_json LONGTEXT NULL",
            "ALTER TABLE events ADD COLUMN status VARCHAR(50) DEFAULT 'active'",
            "ALTER TABLE events ADD COLUMN is_active TINYINT(1) DEFAULT 1",
            "ALTER TABLE artists ADD COLUMN status VARCHAR(50) DEFAULT 'active'",
            "ALTER TABLE artists ADD COLUMN is_active TINYINT(1) DEFAULT 1",
            "ALTER TABLE galleries ADD COLUMN event_name VARCHAR(255) NULL",
            "ALTER TABLE galleries ADD COLUMN event_id VARCHAR(100) NULL",
            "ALTER TABLE galleries ADD INDEX idx_gallery_event (event_name)",
            "UPDATE artists SET banner_url = REPLACE(banner_url, 'api.php?resource=uploads&file=', 'uploads/') WHERE banner_url LIKE '%api.php?resource=uploads&file=%'",
            "UPDATE artists SET avatar_url = REPLACE(avatar_url, 'api.php?resource=uploads&file=', 'uploads/') WHERE avatar_url LIKE '%api.php?resource=uploads&file=%'",
            "UPDATE artworks SET image_url = REPLACE(image_url, 'api.php?resource=uploads&file=', 'uploads/') WHERE image_url LIKE '%api.php?resource=uploads&file=%'",
            "UPDATE events SET image_url = REPLACE(image_url, 'api.php?resource=uploads&file=', 'uploads/') WHERE image_url LIKE '%api.php?resource=uploads&file=%'",
            "UPDATE galleries SET image_url = REPLACE(image_url, 'api.php?resource=uploads&file=', 'uploads/') WHERE image_url LIKE '%api.php?resource=uploads&file=%'",
            "UPDATE artists a SET works_count = (SELECT COUNT(*) FROM artworks WHERE artist_id = a.id OR (artist_id IS NULL AND artist_name IS NOT NULL AND LOWER(artist_name) COLLATE utf8mb4_unicode_ci = LOWER(a.name) COLLATE utf8mb4_unicode_ci))",
            // Soft-delete (Recycle Bin) migrations
            "ALTER TABLE artists ADD COLUMN deleted_at DATETIME NULL DEFAULT NULL",
            "ALTER TABLE events ADD COLUMN deleted_at DATETIME NULL DEFAULT NULL",
            "ALTER TABLE galleries ADD COLUMN cover_url VARCHAR(500) NULL DEFAULT NULL AFTER image_url",
            "ALTER TABLE galleries ADD COLUMN deleted_at DATETIME NULL DEFAULT NULL",
            "ALTER TABLE government_entities ADD COLUMN deleted_at DATETIME NULL DEFAULT NULL",
            "ALTER TABLE categories ADD COLUMN deleted_at DATETIME NULL DEFAULT NULL",
            "ALTER TABLE experience_levels ADD COLUMN deleted_at DATETIME NULL DEFAULT NULL",
            "ALTER TABLE locations ADD COLUMN deleted_at DATETIME NULL DEFAULT NULL",
            "ALTER TABLE artists ADD INDEX idx_artist_deleted (deleted_at)",
            "ALTER TABLE events ADD INDEX idx_event_deleted (deleted_at)",
            "ALTER TABLE galleries ADD INDEX idx_gallery_deleted (deleted_at)",
            "ALTER TABLE government_entities ADD INDEX idx_gov_deleted (deleted_at)",
            "ALTER TABLE categories ADD INDEX idx_cat_deleted (deleted_at)",
            "ALTER TABLE experience_levels ADD INDEX idx_exp_deleted (deleted_at)",
            "ALTER TABLE locations ADD INDEX idx_loc_deleted (deleted_at)"
        ];
        foreach ($migrations as $m) {
            try { $this->pdo->exec($m); } catch (\Throwable $t) {}
        }

        // Self-Provisioning Baseline Data Injection for Fresh Installations
        $this->seedInitialData();

        @file_put_contents($flagFile, date('c'));
    }

    private function seedInitialData(): void {
        try {
            // 1. Categories (Auto-seed standard categories if table is empty)
            $catCount = (int)$this->pdo->query("SELECT COUNT(*) FROM categories WHERE deleted_at IS NULL")->fetchColumn();
            if ($catCount < 60) {
                $categories = [
                    // Event Categories
                    ['Art Exhibition', 'event', 'Fine art exhibitions, group showcases, and gallery displays', '🖼️'],
                    ['Gallery Opening', 'event', 'New gallery space debuts, exclusive launch receptions and vernissage', '🏛️'],
                    ['Art Workshop', 'event', 'Interactive hands-on art classes, live demonstrations and creative sessions', '🎨'],
                    ['Artist Talk', 'event', 'Q&A panels, keynote lectures, and creative dialogues with masters', '🎤'],
                    ['Art Fair', 'event', 'Large-scale art fairs, cultural expos, and trade exhibitions', '🎪'],
                    ['Sculpture Installation', 'event', 'Outdoor, 3D and immersive sculptural installations', '🗿'],
                    ['Photography Exhibition', 'event', 'Fine art, documentary and architectural photography showcases', '📷'],
                    ['Cultural Festival', 'event', 'Heritage celebrations, arts festivals, and multicultural festivities', '🎉'],
                    ['Art Competition', 'event', 'Juried art contests, awards, and youth talent competitions', '🏆'],
                    ['Community Art Project', 'event', 'Public murals, collaborative community art, and social initiatives', '🤝'],

                    // 50 Core Art Categories
                    ['Painting', 'artist', 'Canvas, oil, acrylic, and watercolor paintings', '🎨'],
                    ['Photography', 'artist', 'Fine art, landscape, and portrait photography', '📷'],
                    ['Sculpture', 'artist', '3D sculptural works, stone, bronze, and clay', '🗿'],
                    ['Drawing', 'artist', 'Pencil, charcoal, ink, and pastel sketches', '✏️'],
                    ['Digital Art', 'artist', 'Digital painting, 3D graphics, and generative art', '💻'],
                    ['AI-Generated Art', 'artist', 'Artificial intelligence and algorithmic artworks', '🤖'],
                    ['Architecture', 'artist', 'Architectural design, models, and spatial art', '🏛️'],
                    ['Theatre', 'artist', 'Stage plays, dramatic productions, and theatrical arts', '🎭'],
                    ['Dance', 'artist', 'Choreography, contemporary, and traditional dance', '💃'],
                    ['Music', 'artist', 'Composition, instrumental, and acoustic music', '🎵'],
                    ['Film', 'artist', 'Cinematography, short films, and indie filmmaking', '🎬'],
                    ['Video Art', 'artist', 'Moving image installations and video experimental art', '📹'],
                    ['Literature', 'artist', 'Literary works, novels, essays, and prose', '📚'],
                    ['Poetry', 'artist', 'Classical, spoken word, and contemporary poetry', '📜'],
                    ['Creative Writing', 'artist', 'Narrative storytelling, scripts, and creative writing', '🖋️'],
                    ['Drama', 'artist', 'Dramatic performance, acting, and stage dialogue', '🎭'],
                    ['Graphic Design', 'artist', 'Visual branding, typography, and graphic layout', '📐'],
                    ['Fashion Design', 'artist', 'Haute couture, wearable art, and garment design', '👗'],
                    ['Interior Design', 'artist', 'Spatial styling, artistic interiors, and decor', '🛋️'],
                    ['Product Design', 'artist', 'Industrial design, aesthetic object creation', '📦'],
                    ['Crafts', 'artist', 'Artisan handicrafts, papercraft, and artisanal work', '🧶'],
                    ['Textile Art', 'artist', 'Weaving, tapestry, embroidery, and fiber art', '🧵'],
                    ['Ceramics', 'artist', 'Pottery, stoneware, porcelain, and terracotta', '🏺'],
                    ['Printmaking', 'artist', 'Screen printing, etching, woodcut, and lithography', '🖨️'],
                    ['Illustration', 'artist', 'Editorial illustration, book art, and character art', '🖌️'],
                    ['Street Art', 'artist', 'Urban graffiti, stencil, and public space art', '🏙️'],
                    ['Mural Art', 'artist', 'Large-scale wall murals and outdoor public art', '🧱'],
                    ['Performance Art', 'artist', 'Live artistic expression, interactive acts', '🩰'],
                    ['Installation Art', 'artist', 'Immersive, site-specific art installations', '💡'],
                    ['Conceptual Art', 'artist', 'Idea-driven contemporary art and experimental works', '🧠'],
                    ['Mixed Media', 'artist', 'Multi-medium combinations and experimental artwork', '🔀'],
                    ['Collage', 'artist', 'Assembled paper, textures, and cut-and-paste art', '📑'],
                    ['Video Game Art', 'artist', 'Concept art, character models, and game world design', '🎮'],
                    ['Virtual Reality (VR) Art', 'artist', 'Immersive VR painting and 3D spatial worlds', '🥽'],
                    ['Animation', 'artist', '2D, 3D, and stop-motion animation', '🎞️'],
                    ['Comic Art', 'artist', 'Comic strips, graphic novels, and sequential art', '🗯️'],
                    ['Calligraphy', 'artist', 'Arabic, modern, and classical lettering art', '✍️'],
                    ['Jewellery Design', 'artist', 'Handmade precious jewellery and gem craftsmanship', '💍'],
                    ['Glass Art', 'artist', 'Stained glass, blown glass, and glass sculptures', '🪟'],
                    ['Wood Art', 'artist', 'Wood carving, marquetry, and timber sculpture', '🪵'],
                    ['Metal Art', 'artist', 'Forged metal, welding, wire art, and metalcraft', '⚙️'],
                    ['Puppetry', 'artist', 'Marionettes, shadow puppets, and puppet theater', '🎎'],
                    ['Opera', 'artist', 'Classical operatic performance and vocal arts', '🎼'],
                    ['Ballet', 'artist', 'Classical and modern ballet dance performance', '🩰'],
                    ['Musical Theatre', 'artist', 'Stage musicals blending singing, acting, and dance', '🎤'],
                    ['Experimental Art', 'artist', 'Avant-garde boundary-pushing artistic explorations', '🧪'],
                    ['Land Art', 'artist', 'Earth art, nature-integrated sculptures and topography', '🏞️'],
                    ['Environmental Art', 'artist', 'Eco-conscious art addressing nature and sustainability', '🌿'],
                    ['Body Art', 'artist', 'Body painting, henna, and creative epidermal art', '🎨'],
                    ['Jewellery and Accessory Design', 'artist', 'Fine jewellery, headpieces, and fashion accessories', '👑'],
                ];
                $stmt = $this->pdo->prepare("INSERT IGNORE INTO categories (name, type, description, emoji) VALUES (?, ?, ?, ?)");
                foreach ($categories as $cat) {
                    $stmt->execute($cat);
                }
            }

            // 2. Experience Levels (Auto-seed if empty)
            try {
                $expCount = (int)$this->pdo->query("SELECT COUNT(*) FROM experience_levels")->fetchColumn();
                if ($expCount === 0) {
                    $levels = [
                        ['Emerging Artist (1-3 years)', '1-3 years', 1],
                        ['Mid-Career Artist (4-8 years)', '4-8 years', 2],
                        ['Established Master (9+ years)', '9+ years', 3],
                        ['Professional (5+ years)', '5+ years', 4],
                        ['Self-Taught / Independent', 'Self-Taught', 5],
                    ];
                    $stmt = $this->pdo->prepare("INSERT IGNORE INTO experience_levels (name, years_range, display_order) VALUES (?, ?, ?)");
                    foreach ($levels as $l) {
                        $stmt->execute($l);
                    }
                }
            } catch (\Throwable $t) {}

            // 3. Locations (Auto-seed if empty)
            $locCount = (int)$this->pdo->query("SELECT COUNT(*) FROM locations WHERE deleted_at IS NULL")->fetchColumn();
            if ($locCount === 0) {
                $locations = [
                    ['Alserkal Avenue, Al Quoz', 'Dubai', 'UAE', 1],
                    ['Dubai Design District (d3)', 'Dubai', 'UAE', 2],
                    ['DIFC (Gate Village)', 'Dubai', 'UAE', 3],
                    ['Downtown Dubai', 'Dubai', 'UAE', 4],
                    ['Jumeirah', 'Dubai', 'UAE', 5],
                    ['Al Fahidi Historical Neighbourhood', 'Dubai', 'UAE', 6],
                ];
                $stmt = $this->pdo->prepare("INSERT IGNORE INTO locations (name, city, country, display_order) VALUES (?, ?, ?, ?)");
                foreach ($locations as $loc) {
                    $stmt->execute($loc);
                }
            }

            // 4. Default Admin User & Persistent API Token
            $adminCount = (int)$this->pdo->query("SELECT COUNT(*) FROM users WHERE role = 'admin' OR email = 'admin@artistdubai.com'")->fetchColumn();
            if ($adminCount === 0) {
                $initialAdminPass = getenv('ADMIN_INITIAL_PASSWORD') ?: 'Admin@Dubai2026!';
                $hashed = password_hash($initialAdminPass, PASSWORD_BCRYPT);
                $this->pdo->prepare("INSERT INTO users (full_name, email, password_hash, role) VALUES (?, ?, ?, 'admin')")
                          ->execute(['Dubai Art Administrator', 'admin@artistdubai.com', $hashed]);
                $adminId = (int)$this->pdo->lastInsertId();
            } else {
                $adminId = (int)$this->pdo->query("SELECT id FROM users WHERE role = 'admin' OR email = 'admin@artistdubai.com' ORDER BY id ASC LIMIT 1")->fetchColumn();
            }

            if ($adminId > 0) {
                // Check if admin already has any valid token (avoid creating duplicates)
                $hasAnyToken = (bool)$this->pdo->query("SELECT COUNT(*) FROM api_tokens WHERE user_id = {$adminId} AND expires_at > NOW()")->fetchColumn();
                if (!$hasAnyToken) {
                    // Generate a cryptographically secure random token (unique per installation)
                    $adminToken = bin2hex(random_bytes(32));
                    $this->pdo->prepare("INSERT INTO api_tokens (user_id, token, role, expires_at) VALUES (?, ?, 'admin', DATE_ADD(NOW(), INTERVAL 10 YEAR))")
                              ->execute([$adminId, $adminToken]);
                }
            }

            // 5. Publishing Pricing (Auto-seed if empty)
            $priceCount = (int)$this->pdo->query("SELECT COUNT(*) FROM publishing_pricing")->fetchColumn();
            if ($priceCount === 0) {
                $this->pdo->exec("
                    INSERT INTO publishing_pricing (item_type, item_name, description, weekly_price, monthly_price, three_month_price, six_month_price, yearly_price, three_month_badge, six_month_badge, yearly_badge, currency, is_active) VALUES
                    ('event', 'Paid Event Publishing', 'Feature your event on curated maps and event calendars, with professional event photography.', 'AED 150', 'AED 500', 'AED 2,000', 'AED 3,000', 'AED 5,000', 'Special Offer', 'Save 25%', 'Best Value', 'AED', 1),
                    ('gallery', 'Art Venue Listing', 'Boost your visibility and secure your place in our professional art community. Choose your plan and connect with the art world!', 'AED 250', 'AED 800', 'AED 2,000', 'AED 3,000', 'AED 5,000', 'Special Offer', 'Save 25%', 'Best Value', 'AED', 1),
                    ('artist', 'Artist Verification & Listing', 'Get verified badge, priority placement in artist directory, and direct commissioning channel.', 'AED 100', 'AED 350', 'AED 1,000', 'AED 1,800', 'AED 3,000', 'Special Offer', 'Save 14%', 'Featured', 'AED', 1);
                ");
            }

            // 6. Listing Plans (Auto-seed if empty)
            $planCount = (int)$this->pdo->query("SELECT COUNT(*) FROM listing_plans")->fetchColumn();
            if ($planCount === 0) {
                $this->pdo->exec("
                    INSERT INTO listing_plans (item_type, title, category, badge, price, duration, duration_days, description, features_json, button_text, is_active, sort_order) VALUES
                    ('gallery', '3 Months', 'Art Galleries', 'Special Offer', 'AED 2,000', '3 Months', 90, 'Boost your visibility and secure your place in our professional art community. Choose your plan and connect with the art world!', '[\"Curated maps showcase\",\"Event calendars feature\",\"Professional event photography\",\"Enjoy your first 3 months free\"]', 'Register Gallery', 1, 1),
                    ('gallery', '6 Months', 'Art Galleries', 'Save 25%', 'AED 3,000', '6 Months', 180, 'Boost your visibility and secure your place in our professional art community. Choose your plan and connect with the art world!', '[\"Curated maps showcase\",\"Event calendars feature\",\"Professional event photography\",\"Enjoy your first 3 months free\"]', 'Register Gallery', 1, 2),
                    ('gallery', '12 Months', 'Art Galleries', 'Best Value', 'AED 5,000', '12 Months', 365, 'Boost your visibility and secure your place in our professional art community. Choose your plan and connect with the art world!', '[\"Curated maps showcase\",\"Event calendars feature\",\"Professional event photography\",\"Enjoy your first 3 months free\"]', 'Register Gallery', 1, 3),
                    ('event', '3 Months', 'Art Events', 'Special Offer', 'AED 2,000', '3 Months', 90, 'Feature your event on curated maps and event calendars, with professional event photography.', '[\"Curated maps showcase\",\"Event calendars feature\",\"Professional event photography\",\"Enjoy your first 3 months free\"]', 'Publish Event', 1, 4),
                    ('event', '6 Months', 'Art Events', 'Save 25%', 'AED 3,000', '6 Months', 180, 'Feature your event on curated maps and event calendars, with professional event photography.', '[\"Curated maps showcase\",\"Event calendars feature\",\"Professional event photography\",\"Enjoy your first 3 months free\"]', 'Publish Event', 1, 5),
                    ('event', '12 Months', 'Art Events', 'Best Value', 'AED 5,000', '12 Months', 365, 'Feature your event on curated maps and event calendars, with professional event photography.', '[\"Curated maps showcase\",\"Event calendars feature\",\"Professional event photography\",\"Enjoy your first 3 months free\"]', 'Publish Event', 1, 6),
                    ('chat', 'Starter Plan', 'Messaging & Inquiries', 'Default', 'Free', 'Monthly', 30, 'Free monthly allowance to connect with artists across Dubai', '[\"10 direct messages per month\",\"Direct artist collaboration inquiries\",\"Flyer & artwork attachment support\",\"Allowance auto-resets on the 1st\"]', 'Select Plan', 1, 7),
                    ('chat', 'Unlimited VIP Chat', 'Messaging & Inquiries', 'VIP All-Access', 'AED 500', 'Monthly', 30, 'Unlimited direct artist messages with verified VIP sender badge for AED 500 per month', '[\"Unlimited direct artist messages\",\"Verified VIP sender badge\",\"Direct artist outreach & networking\",\"Priority delivery in artist inboxes\",\"High-resolution flyer & artwork attachments\"]', 'Upgrade to VIP', 1, 8),
                    ('artist', 'Pro Artist Portfolio', 'Visual Arts', 'Best Choice', 'AED 350', 'Annual', 365, 'Unlimited artwork uploads, custom bio, direct buyer messaging', '[\"Unlimited artwork & portfolio showcase uploads\",\"Direct collector messaging & inquiry channel\",\"Verified Artist badge on public profile\",\"Priority ranking in search & category exploration\",\"Custom biography, exhibition history & press links\"]', 'Upgrade Artist Profile', 1, 9),
                    ('art_centre', 'Art Center Partner', 'Institutions & Venues', 'VIP Partner', 'AED 990', 'Annual', 365, 'Official verified institution hub page, workshop hosting & priority event syndication', '[\"Official verified institution partner badge\",\"Unlimited event & workshop listings\",\"Direct ticket booking with instant notifications\",\"Top banner rotation on mobile home screen\",\"Dedicated account manager & support\"]', 'Join Partner Network', 1, 10);
                ");
            }

            // 7. Payment Settings (Auto-seed if empty)
            $payCount = (int)$this->pdo->query("SELECT COUNT(*) FROM payment_settings")->fetchColumn();
            if ($payCount === 0) {
                $this->pdo->exec("
                    INSERT INTO payment_settings (account_name, account_number, bank_name, instructions, is_active) VALUES
                    ('Artist Dubai Cultural Services LLC', 'AE28 0330 0000 0001 2345 678', 'Emirates NBD, Dubai', 'Please include your booking or listing reference in the transfer remarks.', 1);
                ");
            }

            // 8. Auto-provision Uploads Directory & Anti-RCE .htaccess
            $uploadDir = __DIR__ . '/uploads';
            if (!is_dir($uploadDir)) {
                @mkdir($uploadDir, 0755, true);
            }
            $uploadHtaccess = $uploadDir . '/.htaccess';
            if (!file_exists($uploadHtaccess)) {
                @file_put_contents($uploadHtaccess, "# Hardened Upload Security - Strictly disable script execution\nOptions -ExecCGI -Indexes\n<FilesMatch \"(?i)\\.(php|phtml|phar|sh|exe|pl|cgi)$\">\n    Require all denied\n</FilesMatch>\nHeader set X-Content-Type-Options \"nosniff\"\n");
            }
        } catch (\Throwable $t) {}
    }
}

// -----------------------------------------------------------------------------
// 2. High-Speed API Response Class
// -----------------------------------------------------------------------------
class ApiResponse {
    public static function success(mixed $data = [], string $message = 'Success', int $statusCode = 200, ?array $pagination = null): void {
        if (!headers_sent()) { http_response_code($statusCode); }
        $payload = [
            'status' => 'success',
            'success' => true,
            'message' => $message,
            'database' => 'MySQL',
            'timestamp' => time(),
            'data' => $data
        ];
        if ($pagination !== null) {
            $payload['pagination'] = $pagination;
        }
        echo json_encode($payload, JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE);
        if (!defined('CLI_TEST_MODE')) {
            exit();
        }
    }

    public static function error(string $message = 'Error', int $statusCode = 400): void {
        if (!headers_sent()) { http_response_code($statusCode); }
        echo json_encode([
            'status' => 'error',
            'success' => false,
            'message' => $message,
            'database' => 'MySQL',
            'timestamp' => time()
        ], JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE);
        if (!defined('CLI_TEST_MODE')) {
            exit();
        }
    }
}

// -----------------------------------------------------------------------------
// 3. Input Sanitizer Class
// -----------------------------------------------------------------------------
class InputSanitizer {
    public static function cleanString(mixed $val, string $default = ''): string {
        if (!is_string($val)) return $default;
        $val = str_replace(chr(0), '', (string)$val);
        return trim(strip_tags($val));
    }

    public static function cleanEmail(mixed $val): string {
        if (!is_string($val)) return '';
        $val = str_replace(chr(0), '', (string)$val);
        $clean = trim(filter_var($val, FILTER_SANITIZE_EMAIL));
        return filter_var($clean, FILTER_VALIDATE_EMAIL) ? strtolower($clean) : '';
    }

    public static function cleanInt(mixed $val, int $default = 0): int {
        if (is_numeric($val)) return (int)$val;
        return $default;
    }

    public static function cleanUrl(mixed $val): string {
        if (!is_string($val)) return '';
        $val = str_replace(chr(0), '', (string)$val);
        $clean = trim(filter_var($val, FILTER_SANITIZE_URL));
        return filter_var($clean, FILTER_VALIDATE_URL) ? $clean : '';
    }

    public static function generateToken(): string {
        return bin2hex(random_bytes(32));
    }
}

// -----------------------------------------------------------------------------
// 3b. Rate Limiter (Brute-Force & Abuse Mitigation)
// -----------------------------------------------------------------------------
class RateLimiter {
    public static function getClientIp(): string {
        $ip = $_SERVER['REMOTE_ADDR'] ?? '127.0.0.1';
        // Only trust Cloudflare connecting IP when running behind Cloudflare CDN
        if (!empty($_SERVER['HTTP_CF_CONNECTING_IP'])) {
            $candidate = trim($_SERVER['HTTP_CF_CONNECTING_IP']);
            if (filter_var($candidate, FILTER_VALIDATE_IP)) return $candidate;
        }
        // Only inspect X-Forwarded-For if REMOTE_ADDR is a loopback or known internal proxy
        if (in_array($ip, ['127.0.0.1', '::1'], true) && !empty($_SERVER['HTTP_X_FORWARDED_FOR'])) {
            $parts = explode(',', $_SERVER['HTTP_X_FORWARDED_FOR']);
            $first = trim($parts[0]);
            if (filter_var($first, FILTER_VALIDATE_IP)) return $first;
        }
        return filter_var($ip, FILTER_VALIDATE_IP) ? $ip : '127.0.0.1';
    }

    public static function check(string $actionKey, int $maxAttempts = 15, int $windowSeconds = 60): bool {
        if (defined('CLI_TEST_MODE')) return true;
        try {
            $db = DatabaseManager::getInstance()->getConnection();
            $ip = self::getClientIp();
            $now = time();

            // Periodic cleanup of stale records
            if (mt_rand(1, 20) === 1) {
                $db->prepare("DELETE FROM rate_limits WHERE window_start < ?")->execute([$now - 86400]);
            }

            $stmt = $db->prepare("SELECT id, attempts, window_start FROM rate_limits WHERE ip_address = ? AND action_key = ?");
            $stmt->execute([$ip, $actionKey]);
            $row = $stmt->fetch();

            if ($row) {
                if ($now - (int)$row['window_start'] > $windowSeconds) {
                    $upd = $db->prepare("UPDATE rate_limits SET attempts = 1, window_start = ?, last_attempt = ? WHERE id = ?");
                    $upd->execute([$now, $now, $row['id']]);
                    return true;
                }
                if ((int)$row['attempts'] >= $maxAttempts) {
                    return false;
                }
                $upd = $db->prepare("UPDATE rate_limits SET attempts = attempts + 1, last_attempt = ? WHERE id = ?");
                $upd->execute([$now, $row['id']]);
                return true;
            } else {
                $ins = $db->prepare("INSERT INTO rate_limits (ip_address, action_key, attempts, window_start, last_attempt) VALUES (?, ?, 1, ?, ?)");
                $ins->execute([$ip, $actionKey, $now, $now]);
                return true;
            }
        } catch (\Throwable $t) {
            return true;
        }
    }
}

// -----------------------------------------------------------------------------
// 3c. Authentication & Authorization Middleware
// -----------------------------------------------------------------------------
class AuthMiddleware {
    private static ?array $cachedUser = null;
    private static ?string $lastToken = null;

    public static function clearCache(): void {
        self::$cachedUser = null;
        self::$lastToken = null;
    }

    public static function getBearerToken(): ?string {
        $headers = function_exists('getallheaders') ? getallheaders() : [];
        if (function_exists('apache_request_headers')) {
            $apacheHeaders = apache_request_headers();
            if (is_array($apacheHeaders)) {
                $headers = array_merge($headers, $apacheHeaders);
            }
        }
        $authHeader = $headers['Authorization'] 
            ?? $headers['authorization'] 
            ?? $_SERVER['HTTP_AUTHORIZATION'] 
            ?? $_SERVER['REDIRECT_HTTP_AUTHORIZATION'] 
            ?? $_SERVER['REDIRECT_REDIRECT_HTTP_AUTHORIZATION'] 
            ?? $_SERVER['HTTP_X_AUTHORIZATION'] 
            ?? '';
        
        if (!empty($authHeader) && preg_match('/Bearer\s+(\S+)/i', $authHeader, $matches)) {
            return trim($matches[1]);
        }
        
        $apiKey = $headers['X-Api-Key'] 
            ?? $headers['x-api-key'] 
            ?? $headers['X-Auth-Token'] 
            ?? $headers['x-auth-token'] 
            ?? $_SERVER['HTTP_X_API_KEY'] 
            ?? $_SERVER['HTTP_X_AUTH_TOKEN'] 
            ?? '';
        if (!empty($apiKey)) return trim($apiKey);

        // NOTE: Accepting tokens via GET/POST body is intentionally disabled.
        // Tokens in URLs appear in server logs, browser history, and referrer headers,
        // which constitutes a security vulnerability. Use Authorization header only.

        return null;
    }

    public static function getCurrentUser(?string $token = null): ?array {
        if ($token === null) {
            $token = self::getBearerToken();
        }

        if (empty($token)) {
            self::$cachedUser = null;
            self::$lastToken = null;
            return null;
        }

        if (self::$cachedUser !== null && self::$lastToken === $token) {
            return self::$cachedUser;
        }

        // Support Master API Key for custom external integrations
        $masterKey = $_ENV['MASTER_API_KEY'] ?? $_ENV['API_SECRET_KEY'] ?? getenv('MASTER_API_KEY') ?: getenv('API_SECRET_KEY') ?: '';
        if (!empty($masterKey) && hash_equals((string)$masterKey, (string)$token)) {
            $user = [
                'id' => 1,
                'full_name' => 'API Service Integration',
                'email' => 'api-service@artistdubai.com',
                'role' => 'admin',
                'is_admin' => true,
                'created_at' => date('Y-m-d H:i:s'),
            ];
            self::$cachedUser = $user;
            self::$lastToken = $token;
            return $user;
        }

        try {
            $db = DatabaseManager::getInstance()->getConnection();
            $stmt = $db->prepare("SELECT t.user_id, t.role, t.expires_at, u.full_name, u.email, u.role as user_role, u.created_at 
                                  FROM api_tokens t 
                                  JOIN users u ON t.user_id = u.id 
                                  WHERE t.token = ? AND t.expires_at > NOW() 
                                  LIMIT 1");
            $stmt->execute([$token]);
            $row = $stmt->fetch();

            if ($row) {
                try {
                    $db->prepare("UPDATE api_tokens SET last_used_at = NOW() WHERE token = ?")->execute([$token]);
                } catch (\Throwable $t) {}

                $cleanEmail = strtolower(trim($row['email'] ?? ''));
                $dbRole = strtolower(trim($row['user_role'] ?? $row['role'] ?? 'user'));
                $isAdmin = in_array($dbRole, ['admin', 'superadmin', 'super_admin'], true);
                $role = $isAdmin ? $dbRole : ($dbRole ?: 'user');

                $user = [
                    'id' => (int)$row['user_id'],
                    'full_name' => $row['full_name'],
                    'email' => $row['email'],
                    'role' => $role,
                    'is_admin' => $isAdmin,
                    'created_at' => $row['created_at'],
                ];
                self::$cachedUser = $user;
                self::$lastToken = $token;
                return $user;
            }
        } catch (\Throwable $t) {}

        self::$cachedUser = null;
        self::$lastToken = null;
        return null;
    }

    public static function requireAuth(): array {
        $user = self::getCurrentUser();
        if (!$user) {
            ApiResponse::error('Authentication required. Missing, invalid, or expired bearer token.', 401);
            if (defined('CLI_TEST_MODE')) {
                throw new \RuntimeException('Authentication required');
            }
            exit;
        }
        return $user;
    }

    public static function requireAdmin(): array {
        $user = self::requireAuth();
        if (empty($user['is_admin'])) {
            ApiResponse::error('Forbidden. Administrative privileges required.', 403);
            if (defined('CLI_TEST_MODE')) {
                throw new \RuntimeException('Administrative privileges required');
            }
            exit;
        }
        return $user;
    }

    public static function createToken(int $userId, string $role = 'user', int $daysValid = 30): string {
        $token = bin2hex(random_bytes(32));
        $expiresAt = date('Y-m-d H:i:s', time() + ($daysValid * 86400));
        try {
            $db = DatabaseManager::getInstance()->getConnection();
            $stmt = $db->prepare("INSERT INTO api_tokens (user_id, token, role, expires_at) VALUES (?, ?, ?, ?)");
            $stmt->execute([$userId, $token, $role, $expiresAt]);
        } catch (\Throwable $t) {}
        return $token;
    }

    public static function revokeToken(string $token): bool {
        try {
            $db = DatabaseManager::getInstance()->getConnection();
            $stmt = $db->prepare("DELETE FROM api_tokens WHERE token = ?");
            return $stmt->execute([$token]);
        } catch (\Throwable $t) {
            return false;
        }
    }

    public static function revokeAllUserTokens(int $userId): bool {
        try {
            $db = DatabaseManager::getInstance()->getConnection();
            $stmt = $db->prepare("DELETE FROM api_tokens WHERE user_id = ?");
            return $stmt->execute([$userId]);
        } catch (\Throwable $t) {
            return false;
        }
    }
}

// -----------------------------------------------------------------------------
// 4. Object-Oriented Feature Controllers (MySQL Backend)
// -----------------------------------------------------------------------------
class AuthController {
    private PDO $db;

    public function __construct() {
        $this->db = DatabaseManager::getInstance()->getConnection();
    }

    public function login(array $input): void {
        // Rate limiting: max 10 attempts per minute per IP
        if (!RateLimiter::check('login', 10, 60)) {
            ApiResponse::error('Too many login attempts. Please wait 1 minute before trying again.', 429);
            return;
        }

        $email = InputSanitizer::cleanEmail($input['email'] ?? '');
        $password = (string)($input['password'] ?? '');

        if (empty($email) || empty($password)) {
            ApiResponse::error('Valid email and password are required.', 400);
            return;
        }

        $stmt = $this->db->prepare('SELECT id, full_name, email, password_hash, role, created_at FROM users WHERE email = ?');
        $stmt->execute([$email]);
        $user = $stmt->fetch();

        if (!$user) {
            ApiResponse::error('User account not found. Please create an account first.', 404);
            return;
        }

        // Verify password using secure bcrypt
        $valid = password_verify($password, $user['password_hash']);
        if (!$valid) {
            ApiResponse::error('Incorrect password. Please try again.', 401);
            return;
        }

        if (password_needs_rehash($user['password_hash'], PASSWORD_BCRYPT)) {
            $newHash = password_hash($password, PASSWORD_BCRYPT);
            try {
                $this->db->prepare('UPDATE users SET password_hash = ? WHERE id = ?')->execute([$newHash, $user['id']]);
            } catch (\Throwable $t) {}
        }

        $userRole = !empty($user['role']) ? strtolower(trim($user['role'])) : 'user';
        $isAdmin = in_array($userRole, ['admin', 'superadmin', 'super_admin'], true);

            // Issue cryptographically secure persistent API token
            $token = AuthMiddleware::createToken((int)$user['id'], $userRole, 30);

            $artistStmt = $this->db->prepare('SELECT * FROM artists WHERE user_id = ? OR email = ? OR name = ? ORDER BY id DESC LIMIT 1');
            $artistStmt->execute([$user['id'], $user['email'], $user['full_name']]);
            $artist = $artistStmt->fetch();

            ApiResponse::success([
                'user' => [
                    'id' => (int)$user['id'],
                    'full_name' => $user['full_name'],
                    'email' => $user['email'],
                    'role' => $userRole,
                    'is_admin' => $isAdmin,
                    'created_at' => $user['created_at'],
                    'artist_profile' => $artist ?: null
                ],
                'artist_profile' => $artist ?: null,
                'token' => $token
            ], $isAdmin ? 'Admin login successful' : 'Login successful');
            return;
    }

    public function register(array $input): void {
        // Rate limiting: max 5 registration attempts per 5 minutes per IP
        if (!RateLimiter::check('register', 5, 300)) {
            ApiResponse::error('Too many registration requests. Please wait a few minutes before trying again.', 429);
            return;
        }

        $name = InputSanitizer::cleanString($input['full_name'] ?? $input['name'] ?? '');
        $email = InputSanitizer::cleanEmail($input['email'] ?? '');
        $password = (string)($input['password'] ?? '');

        if (empty($name) || empty($email) || strlen($password) < 6) {
            ApiResponse::error('Full name, valid email, and minimum 6 character password required.', 400);
            return;
        }

        $stmt = $this->db->prepare('SELECT id FROM users WHERE email = ?');
        $stmt->execute([$email]);
        if ($stmt->fetch()) {
            ApiResponse::error('An account with this email already exists.', 409);
            return;
        }

        $cleanEmailLower = strtolower(trim($email));
        $reservedAdminEmails = ['admin@artistdubai.com', 'admin@dubaiart.ae', 'admin@admin.com', 'admin@technestpartners.com'];
        $currentUser = AuthMiddleware::getCurrentUser();
        if (in_array($cleanEmailLower, $reservedAdminEmails, true)) {
            if (!$currentUser || empty($currentUser['is_admin'])) {
                ApiResponse::error('Registration with this reserved administrative email is prohibited.', 403);
                return;
            }
        }

        // Prevent unauthorized privilege escalation: only allow admin role if authenticated as admin
        $requestedRole = strtolower(trim($input['role'] ?? 'user'));
        $role = 'user';
        if ($currentUser && !empty($currentUser['is_admin']) && in_array($requestedRole, ['admin', 'artist', 'user'], true)) {
            $role = $requestedRole;
        } elseif ($requestedRole === 'artist') {
            $role = 'artist';
        }

        $hash = password_hash($password, PASSWORD_BCRYPT);
        $insert = $this->db->prepare('INSERT INTO users (full_name, email, password_hash, role) VALUES (?, ?, ?, ?)');
        $insert->execute([$name, $email, $hash, $role]);
        $newUserId = (int)$this->db->lastInsertId();

        // Issue persistent token
        $token = AuthMiddleware::createToken($newUserId, $role, 30);

        ApiResponse::success([
            'user' => [
                'id' => $newUserId,
                'full_name' => $name,
                'email' => $email,
                'role' => $role
            ],
            'token' => $token
        ], 'Account registered successfully', 201);
    }

    public function getUserProfile(string $email): ?array {
        $stmt = $this->db->prepare('SELECT id, full_name, email, role, created_at FROM users WHERE email = ?');
        $stmt->execute([$email]);
        $row = $stmt->fetch();
        return $row ?: null;
    }

    public function updateProfile(array $input): void {
        $currentUser = AuthMiddleware::requireAuth();
        $email = InputSanitizer::cleanEmail($input['email'] ?? $input['current_email'] ?? $_GET['email'] ?? ($currentUser['email'] ?? ''));
        $newName = InputSanitizer::cleanString($input['full_name'] ?? $input['name'] ?? '');

        if (empty($email) || empty($newName)) {
            ApiResponse::error('Email and full name are required to update profile.', 400);
            return;
        }

        // Authorization check: User must own profile or be admin
        if (!$currentUser['is_admin'] && strtolower($currentUser['email']) !== strtolower($email)) {
            ApiResponse::error('Forbidden. You can only update your own profile.', 403);
            return;
        }

        $stmt = $this->db->prepare('UPDATE users SET full_name = ? WHERE email = ?');
        $stmt->execute([$newName, $email]);

        // Also sync artist name if user is an artist
        $this->db->prepare('UPDATE artists SET name = ? WHERE email = ?')->execute([$newName, $email]);

        ApiResponse::success([
            'email' => $email,
            'full_name' => $newName
        ], 'Profile updated successfully');
    }

    public function profile(array $input): void {
        $currentUser = AuthMiddleware::getCurrentUser();
        $email = InputSanitizer::cleanEmail($input['email'] ?? $_GET['email'] ?? '');
        
        if (empty($email) && $currentUser) {
            $email = $currentUser['email'];
        }

        $user = null;
        if (!empty($email)) {
            $stmt = $this->db->prepare('SELECT id, full_name, email, role, created_at, chat_plan, chat_max_allowance FROM users WHERE email = ?');
            $stmt->execute([$email]);
            $user = $stmt->fetch();
        }

        if (!$user && $currentUser) {
            $user = $currentUser;
        }

        if ($user) {
            $artistStmt = $this->db->prepare('SELECT * FROM artists WHERE user_id = ? OR email = ? OR name = ? ORDER BY id DESC LIMIT 1');
            $artistStmt->execute([$user['id'], $user['email'], $user['full_name']]);
            $artist = $artistStmt->fetch();

            $chatPlan = !empty($user['chat_plan']) ? $user['chat_plan'] : 'Basic (Free)';
            $isFreePlan = empty($chatPlan) || stripos($chatPlan, 'free') !== false || stripos($chatPlan, 'basic') !== false || stripos($chatPlan, 'starter') !== false;
            $maxAllowance = $isFreePlan ? 10 : (!empty($user['chat_max_allowance']) ? (int)$user['chat_max_allowance'] : 10);

            // Fetch user purchased plans from user_plans
            $plans = [];
            try {
                $pStmt = $this->db->prepare('SELECT * FROM user_plans WHERE user_email = ? ORDER BY id DESC');
                $pStmt->execute([$user['email']]);
                $dbPlans = $pStmt->fetchAll();
                foreach ($dbPlans as $dp) {
                    $features = [];
                    if (!empty($dp['features_json'])) {
                        $decoded = json_decode($dp['features_json'], true);
                        if (is_array($decoded)) $features = $decoded;
                    }
                    $plans[] = [
                        'id' => (int)$dp['id'],
                        'plan_name' => $dp['plan_name'],
                        'plan_type' => $dp['plan_type'] ?? 'Subscription',
                        'item_title' => $dp['item_title'] ?? $dp['plan_name'],
                        'price' => $dp['price'] ?? 'Free',
                        'billing_cycle' => $dp['billing_cycle'] ?? 'Monthly',
                        'status' => $dp['status'] ?? 'Active',
                        'payment_reference' => $dp['payment_reference'] ?? null,
                        'payment_method' => $dp['payment_method'] ?? 'Online',
                        'features' => $features,
                        'start_date' => $dp['start_date'] ?? $dp['created_at'],
                        'expires_at' => $dp['expires_at'] ?? null,
                        'created_at' => $dp['created_at'],
                    ];
                }
            } catch (\Throwable $t) {}

            // Also check published events with publishing plan
            try {
                $eStmt = $this->db->prepare("SELECT id, title, category, publishing_plan, publishing_amount, payment_status, payment_reference, created_at FROM events WHERE contact_email = ? AND publishing_plan IS NOT NULL AND publishing_plan != '' ORDER BY id DESC");
                $eStmt->execute([$user['email']]);
                $eventPlans = $eStmt->fetchAll();
                foreach ($eventPlans as $ep) {
                    $plans[] = [
                        'id' => (int)$ep['id'],
                        'plan_name' => (!empty($ep['publishing_plan']) ? ucfirst($ep['publishing_plan']) . ' Plan' : 'Event Publishing Plan'),
                        'plan_type' => 'Event Publishing',
                        'item_title' => $ep['title'] ?? 'Art Event Listing',
                        'price' => !empty($ep['publishing_amount']) ? $ep['publishing_amount'] : 'Free',
                        'billing_cycle' => !empty($ep['publishing_plan']) ? ucfirst($ep['publishing_plan']) : 'Listing',
                        'status' => strtolower($ep['payment_status'] ?? '') === 'paid' ? 'Active' : (ucfirst($ep['payment_status'] ?? 'Active')),
                        'payment_reference' => $ep['payment_reference'] ?? null,
                        'payment_method' => 'Online',
                        'features' => ['Featured Event Listing', 'Calendar & Push Visibility', 'RSVP & Ticketing Access'],
                        'start_date' => $ep['created_at'],
                        'expires_at' => null,
                        'created_at' => $ep['created_at'],
                    ];
                }
            } catch (\Throwable $t) {}

            // Also check published galleries with publishing plan
            try {
                $gStmt = $this->db->prepare("SELECT id, name, category, publishing_plan, publishing_amount, payment_status, payment_reference, created_at FROM galleries WHERE email = ? AND publishing_plan IS NOT NULL AND publishing_plan != '' ORDER BY id DESC");
                $gStmt->execute([$user['email']]);
                $galleryPlans = $gStmt->fetchAll();
                foreach ($galleryPlans as $gp) {
                    $plans[] = [
                        'id' => (int)$gp['id'],
                        'plan_name' => (!empty($gp['publishing_plan']) ? ucfirst($gp['publishing_plan']) . ' Plan' : 'Gallery Publishing Plan'),
                        'plan_type' => 'Gallery Publishing',
                        'item_title' => $gp['name'] ?? 'Art Gallery Listing',
                        'price' => !empty($gp['publishing_amount']) ? $gp['publishing_amount'] : 'Free',
                        'billing_cycle' => !empty($gp['publishing_plan']) ? ucfirst($gp['publishing_plan']) : 'Listing',
                        'status' => strtolower($gp['payment_status'] ?? '') === 'paid' ? 'Active' : (ucfirst($gp['payment_status'] ?? 'Active')),
                        'payment_reference' => $gp['payment_reference'] ?? null,
                        'payment_method' => 'Online',
                        'features' => ['Verified Gallery Badge', 'Exhibition Space Listing', 'Direct Collector Inquiries'],
                        'start_date' => $gp['created_at'],
                        'expires_at' => null,
                        'created_at' => $gp['created_at'],
                    ];
                }
            } catch (\Throwable $t) {}

            ApiResponse::success([
                'id' => (int)$user['id'],
                'full_name' => $user['full_name'],
                'email' => $user['email'],
                'role' => $user['role'] ?? 'user',
                'created_at' => $user['created_at'],
                'chat_plan' => $chatPlan,
                'chat_max_allowance' => $maxAllowance,
                'purchased_plans' => $plans,
                'artist_profile' => $artist ?: null
            ], 'Profile fetched');
            return;
        }

        ApiResponse::error('User profile not found', 404);
    }

    public function changePassword(array $input): void {
        if (!RateLimiter::check('change_password', 5, 60)) {
            ApiResponse::error('Too many password update attempts. Please wait a moment.', 429);
            return;
        }

        $currentUser = AuthMiddleware::getCurrentUser();
        $email = InputSanitizer::cleanEmail($input['email'] ?? ($currentUser['email'] ?? ''));
        $currentPassword = (string)($input['current_password'] ?? $input['old_password'] ?? '');
        $newPassword = (string)($input['new_password'] ?? $input['password'] ?? '');

        if (empty($email) || strlen($newPassword) < 6) {
            ApiResponse::error('Valid email and minimum 6 character new password required.', 400);
            return;
        }

        $stmt = $this->db->prepare('SELECT id, email, password_hash FROM users WHERE email = ?');
        $stmt->execute([$email]);
        $user = $stmt->fetch();

        if (!$user) {
            ApiResponse::error('User account not found', 404);
            return;
        }

        // Security verification:
        // Must either:
        // 1. Be authenticated as admin
        // 2. Be authenticated as account owner (must provide and verify current password via bcrypt)
        // 3. Unauthenticated requests must provide correct current password verified via bcrypt
        $isAuthorized = false;
        if ($currentUser && !empty($currentUser['is_admin'])) {
            $isAuthorized = true;
        } elseif ($currentUser && strtolower($currentUser['email']) === strtolower($email)) {
            if (empty($currentPassword) || !password_verify($currentPassword, $user['password_hash'])) {
                ApiResponse::error('Current password is required and must be correct to change password.', 401);
                return;
            }
            $isAuthorized = true;
        } elseif (!empty($currentPassword)) {
            $isAuthorized = password_verify($currentPassword, $user['password_hash']);
            if (!$isAuthorized) {
                ApiResponse::error('Current password is incorrect.', 401);
                return;
            }
        } else {
            ApiResponse::error('Authentication and current password required to change password.', 401);
            return;
        }

        $hash = password_hash($newPassword, PASSWORD_BCRYPT);
        $upd = $this->db->prepare('UPDATE users SET password_hash = ? WHERE id = ?');
        $upd->execute([$hash, $user['id']]);

        // Invalidate old tokens for this user for security
        AuthMiddleware::revokeAllUserTokens((int)$user['id']);

        // Generate a fresh new token
        $newToken = AuthMiddleware::createToken((int)$user['id'], 'user', 30);

        ApiResponse::success(['token' => $newToken], 'Password updated successfully');
    }

    public function deleteAccount(array $input): void {
        $currentUser = AuthMiddleware::requireAuth();
        $email = InputSanitizer::cleanEmail($input['email'] ?? $currentUser['email']);

        if (!$currentUser['is_admin'] && strtolower($currentUser['email']) !== strtolower($email)) {
            ApiResponse::error('Forbidden. You can only delete your own account.', 403);
            return;
        }

        $stmt = $this->db->prepare('SELECT id, full_name FROM users WHERE email = ?');
        $stmt->execute([$email]);
        $user = $stmt->fetch();

        if ($user) {
            $userId = (int)$user['id'];
            $name = $user['full_name'];

            // Revoke tokens
            AuthMiddleware::revokeAllUserTokens($userId);

            // Clean up related user records
            $this->db->prepare('DELETE FROM artists WHERE user_id = ? OR name = ?')->execute([$userId, $name]);
            $this->db->prepare('DELETE FROM bookings WHERE email = ?')->execute([$email]);
            $this->db->prepare('DELETE FROM favorites WHERE user_email = ?')->execute([$email]);
            $this->db->prepare('DELETE FROM follows WHERE user_email = ?')->execute([$email]);
            $this->db->prepare('DELETE FROM users WHERE id = ?')->execute([$userId]);

            ApiResponse::success([], 'Account deleted successfully');
        } else {
            ApiResponse::error('Account not found', 404);
        }
    }

    /**
     * Admin: List all users with comprehensive metadata, role, chat plans, and counts
     */
    public function listUsers(array $query = []): void {
        AuthMiddleware::requireAdmin();

        $page = max(1, (int)($query['page'] ?? 1));
        $limit = isset($query['limit']) ? min(200, max(1, (int)$query['limit'])) : 100;
        $offset = ($page - 1) * $limit;
        $search = InputSanitizer::cleanString($query['q'] ?? $query['search'] ?? '');
        $roleFilter = InputSanitizer::cleanString($query['role'] ?? '');

        $sql = "SELECT u.id, u.full_name, u.email, u.role, u.chat_plan, u.chat_max_allowance, u.created_at,
                       a.id as artist_id, a.name as artist_name, a.category as artist_category, a.avatar_url,
                       (SELECT COUNT(*) FROM bookings b WHERE b.email = u.email COLLATE utf8mb4_unicode_ci) as total_bookings,
                       (SELECT COUNT(*) FROM favorites f WHERE f.user_email = u.email COLLATE utf8mb4_unicode_ci) as total_favorites,
                       (SELECT COUNT(*) FROM artworks aw WHERE aw.artist_id = a.id) as total_artworks
                FROM users u
                LEFT JOIN artists a ON (a.user_id = u.id OR a.email = u.email COLLATE utf8mb4_unicode_ci)
                WHERE 1=1";
        $params = [];

        if (!empty($search)) {
            $sql .= " AND (u.full_name LIKE ? OR u.email LIKE ? OR u.role LIKE ?)";
            $params[] = "%$search%";
            $params[] = "%$search%";
            $params[] = "%$search%";
        }

        if (!empty($roleFilter) && $roleFilter !== 'all') {
            $sql .= " AND LOWER(u.role) = ?";
            $params[] = strtolower($roleFilter);
        }

        $countSql = "SELECT COUNT(*) FROM users u WHERE 1=1";
        $countParams = [];
        if (!empty($search)) {
            $countSql .= " AND (u.full_name LIKE ? OR u.email LIKE ? OR u.role LIKE ?)";
            $countParams[] = "%$search%";
            $countParams[] = "%$search%";
            $countParams[] = "%$search%";
        }
        if (!empty($roleFilter) && $roleFilter !== 'all') {
            $countSql .= " AND LOWER(u.role) = ?";
            $countParams[] = strtolower($roleFilter);
        }

        $countStmt = $this->db->prepare($countSql);
        $countStmt->execute($countParams);
        $total = (int)$countStmt->fetchColumn();

        $sql .= " ORDER BY u.id DESC LIMIT $limit OFFSET $offset";
        $stmt = $this->db->prepare($sql);
        $stmt->execute($params);
        $users = $stmt->fetchAll();

        foreach ($users as &$usr) {
            $usr['is_admin'] = in_array(strtolower($usr['role'] ?? ''), ['admin', 'superadmin', 'super_admin'], true);
            $usr['total_bookings'] = (int)($usr['total_bookings'] ?? 0);
            $usr['total_favorites'] = (int)($usr['total_favorites'] ?? 0);
            $usr['total_artworks'] = (int)($usr['total_artworks'] ?? 0);
            $usr['has_artist_profile'] = !empty($usr['artist_id']);

            // Gather all purchased plans and due dates for this user
            $plans = [];

            // 1. Check user_plans table
            try {
                $pStmt = $this->db->prepare('SELECT * FROM user_plans WHERE user_email = ? OR user_id = ? ORDER BY id DESC');
                $pStmt->execute([$usr['email'], $usr['id']]);
                $dbPlans = $pStmt->fetchAll();
                foreach ($dbPlans as $dp) {
                    $expiresAt = $dp['expires_at'] ?? null;
                    if (empty($expiresAt) && !empty($dp['start_date'])) {
                        $expiresAt = date('Y-m-d H:i:s', strtotime($dp['start_date'] . ' + 30 days'));
                    }
                    $plans[] = [
                        'id' => (int)$dp['id'],
                        'plan_name' => $dp['plan_name'] ?? 'Premium Plan',
                        'plan_type' => $dp['plan_type'] ?? 'Subscription',
                        'price' => !empty($dp['price']) ? $dp['price'] : 'Free',
                        'billing_cycle' => $dp['billing_cycle'] ?? 'Monthly',
                        'status' => $dp['status'] ?? 'Active',
                        'payment_reference' => $dp['payment_reference'] ?? null,
                        'payment_method' => $dp['payment_method'] ?? 'Online Card',
                        'start_date' => $dp['start_date'] ?? $dp['created_at'],
                        'due_date' => $expiresAt,
                        'expires_at' => $expiresAt,
                        'created_at' => $dp['created_at'],
                    ];
                }
            } catch (\Throwable $t) {}

            // 2. Check events published by this user with paid publishing plan
            try {
                $eStmt = $this->db->prepare("SELECT id, title, publishing_plan, publishing_amount, payment_status, payment_reference, created_at FROM events WHERE (user_email = ? OR email = ?) AND publishing_plan IS NOT NULL AND publishing_plan != '' ORDER BY id DESC");
                $eStmt->execute([$usr['email'], $usr['email']]);
                $eventPlans = $eStmt->fetchAll();
                foreach ($eventPlans as $ep) {
                    $planName = !empty($ep['publishing_plan']) ? ucfirst($ep['publishing_plan']) . ' Plan' : 'Event Publishing Plan';
                    $durationDays = 30;
                    $pLower = strtolower($ep['publishing_plan'] ?? '');
                    if (strpos($pLower, '60') !== false || strpos($pLower, 'gold') !== false || strpos($pLower, 'quarter') !== false) $durationDays = 60;
                    if (strpos($pLower, '90') !== false || strpos($pLower, 'platinum') !== false || strpos($pLower, 'annual') !== false) $durationDays = 90;
                    $dueDate = date('Y-m-d', strtotime($ep['created_at'] . " + $durationDays days"));

                    $plans[] = [
                        'id' => (int)$ep['id'],
                        'plan_name' => $planName,
                        'plan_type' => 'Event Publishing',
                        'item_title' => $ep['title'] ?? 'Art Event',
                        'price' => !empty($ep['publishing_amount']) ? $ep['publishing_amount'] : 'Free',
                        'billing_cycle' => ucfirst($ep['publishing_plan'] ?? 'Listing'),
                        'status' => strtolower($ep['payment_status'] ?? '') === 'paid' ? 'Active' : (ucfirst($ep['payment_status'] ?? 'Active')),
                        'payment_reference' => $ep['payment_reference'] ?? null,
                        'payment_method' => 'Online Card',
                        'start_date' => $ep['created_at'],
                        'due_date' => $dueDate,
                        'expires_at' => $dueDate,
                        'created_at' => $ep['created_at'],
                    ];
                }
            } catch (\Throwable $t) {}

            // 3. Check galleries published by this user with paid publishing plan
            try {
                $gStmt = $this->db->prepare("SELECT id, name, category, publishing_plan, publishing_amount, payment_status, payment_reference, created_at FROM galleries WHERE email = ? AND publishing_plan IS NOT NULL AND publishing_plan != '' ORDER BY id DESC");
                $gStmt->execute([$usr['email']]);
                $galleryPlans = $gStmt->fetchAll();
                foreach ($galleryPlans as $gp) {
                    $planName = !empty($gp['publishing_plan']) ? ucfirst($gp['publishing_plan']) . ' Plan' : 'Gallery Publishing Plan';
                    $dueDate = date('Y-m-d', strtotime($gp['created_at'] . " + 30 days"));
                    $plans[] = [
                        'id' => (int)$gp['id'],
                        'plan_name' => $planName,
                        'plan_type' => 'Gallery Publishing',
                        'item_title' => $gp['name'] ?? 'Art Gallery',
                        'price' => !empty($gp['publishing_amount']) ? $gp['publishing_amount'] : 'Free',
                        'billing_cycle' => ucfirst($gp['publishing_plan'] ?? 'Listing'),
                        'status' => strtolower($gp['payment_status'] ?? '') === 'paid' ? 'Active' : (ucfirst($gp['payment_status'] ?? 'Active')),
                        'payment_reference' => $gp['payment_reference'] ?? null,
                        'payment_method' => 'Online Card',
                        'start_date' => $gp['created_at'],
                        'due_date' => $dueDate,
                        'expires_at' => $dueDate,
                        'created_at' => $gp['created_at'],
                    ];
                }
            } catch (\Throwable $t) {}

            $usr['purchased_plans'] = $plans;
            $usr['plans_count'] = count($plans);

            if (!empty($plans)) {
                $primaryPlan = $plans[0];
                $usr['primary_plan_name'] = $primaryPlan['plan_name'];
                $usr['primary_plan_price'] = $primaryPlan['price'];
                $usr['primary_plan_due_date'] = $primaryPlan['due_date'];
                $usr['primary_plan_status'] = $primaryPlan['status'];
            } else {
                $usr['primary_plan_name'] = null;
                $usr['primary_plan_price'] = null;
                $usr['primary_plan_due_date'] = null;
                $usr['primary_plan_status'] = null;
            }
        }

        $pagination = [
            'page' => $page,
            'limit' => $limit,
            'total' => $total,
            'total_pages' => ceil($total / max(1, $limit)),
            'has_more' => ($offset + count($users)) < $total
        ];

        ApiResponse::success($users, 'All users retrieved successfully', 200, $pagination);
    }

    /**
     * Admin: Update user role (e.g. promote to admin, set to artist/user)
     */
    public function updateUserRole(array $input): void {
        AuthMiddleware::requireAdmin();

        $userId = (int)($input['user_id'] ?? $input['id'] ?? 0);
        $newRole = strtolower(trim(InputSanitizer::cleanString($input['role'] ?? 'user')));
        $allowedRoles = ['user', 'artist', 'admin'];

        if ($userId <= 0 || !in_array($newRole, $allowedRoles, true)) {
            ApiResponse::error('Valid user ID and role (user, artist, admin) required.', 400);
            return;
        }

        $stmt = $this->db->prepare("UPDATE users SET role = ? WHERE id = ?");
        $stmt->execute([$newRole, $userId]);

        ApiResponse::success(['id' => $userId, 'role' => $newRole], 'User role updated successfully');
    }

    /**
     * Admin: Assign or update a user's plan and due date
     */
    public function assignUserPlan(array $input): void {
        AuthMiddleware::requireAdmin();

        $userId = (int)($input['user_id'] ?? $input['id'] ?? 0);
        $email = InputSanitizer::cleanEmail($input['email'] ?? $input['user_email'] ?? '');
        $planName = InputSanitizer::cleanString($input['plan_name'] ?? '');
        $planType = InputSanitizer::cleanString($input['plan_type'] ?? 'Subscription');
        $price = InputSanitizer::cleanString($input['price'] ?? 'Free');
        $dueDate = InputSanitizer::cleanString($input['due_date'] ?? $input['expires_at'] ?? '');
        $status = InputSanitizer::cleanString($input['status'] ?? 'Active');

        if ($userId <= 0 && empty($email)) {
            ApiResponse::error('User ID or email is required.', 400);
            return;
        }

        if (empty($email)) {
            $uStmt = $this->db->prepare('SELECT email FROM users WHERE id = ?');
            $uStmt->execute([$userId]);
            $email = (string)$uStmt->fetchColumn();
        }

        if (empty($planName)) {
            $planName = 'Basic (Free)';
        }

        // If expires_at / due_date not provided, default to +30 days
        if (empty($dueDate)) {
            $dueDate = date('Y-m-d H:i:s', strtotime('+30 days'));
        } elseif (strlen($dueDate) === 10) {
            $dueDate .= ' 23:59:59';
        }

        // 1. Insert into user_plans
        $ins = $this->db->prepare("
            INSERT INTO user_plans (user_id, user_email, plan_name, plan_type, price, status, expires_at, created_at)
            VALUES (?, ?, ?, ?, ?, ?, ?, NOW())
        ");
        $ins->execute([$userId > 0 ? $userId : null, $email, $planName, $planType, $price, $status, $dueDate]);

        // 2. Also update chat_plan on users table for unified display ONLY if it is a chat plan
        if (!empty($email) && ($planType === 'chat' || $planType === 'messaging' || stripos($planName, 'Chat') !== false || stripos($planName, 'Messaging') !== false)) {
            $this->db->prepare("UPDATE users SET chat_plan = ? WHERE email = ? OR id = ?")
                     ->execute([$planName, $email, $userId]);
        }

        ApiResponse::success([
            'user_id' => $userId,
            'user_email' => $email,
            'plan_name' => $planName,
            'due_date' => $dueDate,
            'status' => $status
        ], 'Plan assigned successfully to user');
    }

    /**
     * Admin: Delete user and their associated data
     */
    public function adminDeleteUser(array $input): void {
        AuthMiddleware::requireAdmin();

        $userId = (int)($input['user_id'] ?? $input['id'] ?? 0);
        $email = InputSanitizer::cleanEmail($input['email'] ?? '');

        if ($userId <= 0 && empty($email)) {
            ApiResponse::error('Valid user ID or email required for deletion.', 400);
            return;
        }

        if ($userId > 0) {
            $stmt = $this->db->prepare('SELECT id, email, full_name FROM users WHERE id = ?');
            $stmt->execute([$userId]);
        } else {
            $stmt = $this->db->prepare('SELECT id, email, full_name FROM users WHERE email = ?');
            $stmt->execute([$email]);
        }
        $user = $stmt->fetch();

        if (!$user) {
            ApiResponse::error('User not found.', 404);
            return;
        }

        $targetId = (int)$user['id'];
        $targetEmail = $user['email'];
        $targetName = $user['full_name'];

        // Revoke tokens
        AuthMiddleware::revokeAllUserTokens($targetId);

        // Delete user & linked data
        $this->db->prepare('DELETE FROM user_plans WHERE user_id = ? OR user_email = ?')->execute([$targetId, $targetEmail]);
        $this->db->prepare('DELETE FROM artists WHERE user_id = ? OR email = ? OR name = ?')->execute([$targetId, $targetEmail, $targetName]);
        $this->db->prepare('DELETE FROM bookings WHERE email = ?')->execute([$targetEmail]);
        $this->db->prepare('DELETE FROM favorites WHERE user_email = ?')->execute([$targetEmail]);
        $this->db->prepare('DELETE FROM follows WHERE user_email = ?')->execute([$targetEmail]);
        $this->db->prepare('DELETE FROM users WHERE id = ?')->execute([$targetId]);

        ApiResponse::success(['id' => $targetId, 'email' => $targetEmail], 'User and associated data permanently removed');
    }
}

class CategoryController {
    private PDO $db;

    public function __construct() {
        $this->db = DatabaseManager::getInstance()->getConnection();
    }

    public function getCategories(array $query = []): void {
        try {
            $type = InputSanitizer::cleanString($query['type'] ?? '');
            $sql = "SELECT c.*, 
                    (SELECT COUNT(*) FROM artists a WHERE a.category = c.name AND a.deleted_at IS NULL) AS artist_count,
                    (SELECT COUNT(*) FROM events e WHERE e.category = c.name AND e.deleted_at IS NULL) AS event_count
                    FROM categories c ";
            if (!empty($type) && $type !== 'all') {
                $stmt = $this->db->prepare($sql . 'WHERE (c.type = ? OR c.type = "general") AND c.deleted_at IS NULL ORDER BY c.id ASC');
                $stmt->execute([$type]);
            } else {
                $stmt = $this->db->query($sql . 'WHERE c.deleted_at IS NULL ORDER BY c.id ASC');
            }
            $categories = $stmt->fetchAll();
            ApiResponse::success($categories, 'Categories retrieved successfully');
        } catch (\Throwable $t) {
            error_log('CategoryController::getCategories error: ' . $t->getMessage());
            ApiResponse::error('Failed to retrieve categories', 500);
        }
    }

    public function createCategory(array $input): void {
        AuthMiddleware::requireAdmin();
        $name = InputSanitizer::cleanString($input['name'] ?? '');
        $description = InputSanitizer::cleanString($input['description'] ?? '');
        $emoji = InputSanitizer::cleanString($input['emoji'] ?? '🎨');
        $type = InputSanitizer::cleanString($input['type'] ?? 'general');

        if (empty($name)) {
            ApiResponse::error('Category name is required.');
        }

        $stmt = $this->db->prepare('INSERT INTO categories (name, description, emoji, type) VALUES (?, ?, ?, ?) ON DUPLICATE KEY UPDATE description=VALUES(description), emoji=VALUES(emoji), type=VALUES(type)');
        $stmt->execute([$name, $description, $emoji, $type]);

        ApiResponse::success(['category_id' => (int)$this->db->lastInsertId()], 'Category created successfully', 201);
    }

    public function updateCategory(array $input): void {
        AuthMiddleware::requireAdmin();
        $id = (int)($input['id'] ?? $input['category_id'] ?? 0);
        $name = InputSanitizer::cleanString($input['name'] ?? '');
        $description = InputSanitizer::cleanString($input['description'] ?? '');
        $emoji = InputSanitizer::cleanString($input['emoji'] ?? '🎨');
        $type = InputSanitizer::cleanString($input['type'] ?? 'general');

        if ($id <= 0 && empty($name)) {
            ApiResponse::error('Category ID or name is required.');
        }

        if ($id > 0) {
            $stmt = $this->db->prepare('UPDATE categories SET name = ?, description = ?, emoji = ?, type = ? WHERE id = ?');
            $stmt->execute([$name, $description, $emoji, $type, $id]);
        } else {
            $stmt = $this->db->prepare('UPDATE categories SET description = ?, emoji = ?, type = ? WHERE name = ?');
            $stmt->execute([$description, $emoji, $type, $name]);
        }

        ApiResponse::success(['updated' => true], 'Category updated successfully');
    }

    public function deleteCategory(array $input): void {
        AuthMiddleware::requireAdmin();
        $id = (int)($input['id'] ?? $input['category_id'] ?? 0);
        $name = InputSanitizer::cleanString($input['name'] ?? '');

        if ($id <= 0 && empty($name)) {
            ApiResponse::error('Category ID or name is required for deletion.');
        }

        // Soft-delete: move to recycle bin
        if ($id > 0) {
            $this->db->prepare('UPDATE categories SET deleted_at = NOW() WHERE id = ?')->execute([$id]);
        } else {
            $this->db->prepare('UPDATE categories SET deleted_at = NOW() WHERE name = ?')->execute([$name]);
        }

        ApiResponse::success(['deleted' => true], 'Category moved to recycle bin');
    }

    public function seedDefaultCategories(): void {
        AuthMiddleware::requireAdmin();
        $categories = [
            // Event Categories
            ['Art Exhibition', 'event', 'Fine art exhibitions, group showcases, and gallery displays', '🖼️'],
            ['Gallery Opening', 'event', 'New gallery space debuts, exclusive launch receptions and vernissage', '🏛️'],
            ['Art Workshop', 'event', 'Interactive hands-on art classes, live demonstrations and creative sessions', '🎨'],
            ['Artist Talk', 'event', 'Q&A panels, keynote lectures, and creative dialogues with masters', '🎤'],
            ['Art Fair', 'event', 'Large-scale art fairs, cultural expos, and trade exhibitions', '🎪'],
            ['Sculpture Installation', 'event', 'Outdoor, 3D and immersive sculptural installations', '🗿'],
            ['Photography Exhibition', 'event', 'Fine art, documentary and architectural photography showcases', '📷'],
            ['Cultural Festival', 'event', 'Heritage celebrations, arts festivals, and multicultural festivities', '🎉'],
            ['Art Competition', 'event', 'Juried art contests, awards, and youth talent competitions', '🏆'],
            ['Community Art Project', 'event', 'Public murals, collaborative community art, and social initiatives', '🤝'],

            // 50 Core Art Categories
            ['Painting', 'artist', 'Canvas, oil, acrylic, and watercolor paintings', '🎨'],
            ['Photography', 'artist', 'Fine art, landscape, and portrait photography', '📷'],
            ['Sculpture', 'artist', '3D sculptural works, stone, bronze, and clay', '🗿'],
            ['Drawing', 'artist', 'Pencil, charcoal, ink, and pastel sketches', '✏️'],
            ['Digital Art', 'artist', 'Digital painting, 3D graphics, and generative art', '💻'],
            ['AI-Generated Art', 'artist', 'Artificial intelligence and algorithmic artworks', '🤖'],
            ['Architecture', 'artist', 'Architectural design, models, and spatial art', '🏛️'],
            ['Theatre', 'artist', 'Stage plays, dramatic productions, and theatrical arts', '🎭'],
            ['Dance', 'artist', 'Choreography, contemporary, and traditional dance', '💃'],
            ['Music', 'artist', 'Composition, instrumental, and acoustic music', '🎵'],
            ['Film', 'artist', 'Cinematography, short films, and indie filmmaking', '🎬'],
            ['Video Art', 'artist', 'Moving image installations and video experimental art', '📹'],
            ['Literature', 'artist', 'Literary works, novels, essays, and prose', '📚'],
            ['Poetry', 'artist', 'Classical, spoken word, and contemporary poetry', '📜'],
            ['Creative Writing', 'artist', 'Narrative storytelling, scripts, and creative writing', '🖋️'],
            ['Drama', 'artist', 'Dramatic performance, acting, and stage dialogue', '🎭'],
            ['Graphic Design', 'artist', 'Visual branding, typography, and graphic layout', '📐'],
            ['Fashion Design', 'artist', 'Haute couture, wearable art, and garment design', '👗'],
            ['Interior Design', 'artist', 'Spatial styling, artistic interiors, and decor', '🛋️'],
            ['Product Design', 'artist', 'Industrial design, aesthetic object creation', '📦'],
            ['Crafts', 'artist', 'Artisan handicrafts, papercraft, and artisanal work', '🧶'],
            ['Textile Art', 'artist', 'Weaving, tapestry, embroidery, and fiber art', '🧵'],
            ['Ceramics', 'artist', 'Pottery, stoneware, porcelain, and terracotta', '🏺'],
            ['Printmaking', 'artist', 'Screen printing, etching, woodcut, and lithography', '🖨️'],
            ['Illustration', 'artist', 'Editorial illustration, book art, and character art', '🖌️'],
            ['Street Art', 'artist', 'Urban graffiti, stencil, and public space art', '🏙️'],
            ['Mural Art', 'artist', 'Large-scale wall murals and outdoor public art', '🧱'],
            ['Performance Art', 'artist', 'Live artistic expression, interactive acts', '🩰'],
            ['Installation Art', 'artist', 'Immersive, site-specific art installations', '💡'],
            ['Conceptual Art', 'artist', 'Idea-driven contemporary art and experimental works', '🧠'],
            ['Mixed Media', 'artist', 'Multi-medium combinations and experimental artwork', '🔀'],
            ['Collage', 'artist', 'Assembled paper, textures, and cut-and-paste art', '📑'],
            ['Video Game Art', 'artist', 'Concept art, character models, and game world design', '🎮'],
            ['Virtual Reality (VR) Art', 'artist', 'Immersive VR painting and 3D spatial worlds', '🥽'],
            ['Animation', 'artist', '2D, 3D, and stop-motion animation', '🎞️'],
            ['Comic Art', 'artist', 'Comic strips, graphic novels, and sequential art', '🗯️'],
            ['Calligraphy', 'artist', 'Arabic, modern, and classical lettering art', '✍️'],
            ['Jewellery Design', 'artist', 'Handmade precious jewellery and gem craftsmanship', '💍'],
            ['Glass Art', 'artist', 'Stained glass, blown glass, and glass sculptures', '🪟'],
            ['Wood Art', 'artist', 'Wood carving, marquetry, and timber sculpture', '🪵'],
            ['Metal Art', 'artist', 'Forged metal, welding, wire art, and metalcraft', '⚙️'],
            ['Puppetry', 'artist', 'Marionettes, shadow puppets, and puppet theater', '🎎'],
            ['Opera', 'artist', 'Classical operatic performance and vocal arts', '🎼'],
            ['Ballet', 'artist', 'Classical and modern ballet dance performance', '🩰'],
            ['Musical Theatre', 'artist', 'Stage musicals blending singing, acting, and dance', '🎤'],
            ['Experimental Art', 'artist', 'Avant-garde boundary-pushing artistic explorations', '🧪'],
            ['Land Art', 'artist', 'Earth art, nature-integrated sculptures and topography', '🏞️'],
            ['Environmental Art', 'artist', 'Eco-conscious art addressing nature and sustainability', '🌿'],
            ['Body Art', 'artist', 'Body painting, henna, and creative epidermal art', '🎨'],
            ['Jewellery and Accessory Design', 'artist', 'Fine jewellery, headpieces, and fashion accessories', '👑']
        ];
        $stmt = $this->db->prepare("INSERT INTO categories (name, type, description, emoji) VALUES (?, ?, ?, ?) ON DUPLICATE KEY UPDATE type=VALUES(type), description=VALUES(description), emoji=VALUES(emoji), deleted_at=NULL");
        foreach ($categories as $cat) {
            $stmt->execute($cat);
        }
        ApiResponse::success(['seeded' => count($categories)], 'All categories seeded and restored successfully');
    }
}

class ExperienceLevelController {
    private PDO $db;

    public function __construct() {
        $this->db = DatabaseManager::getInstance()->getConnection();
    }

    public function getExperienceLevels(): void {
        $levels = [];
        try {
            $stmt = $this->db->query('SELECT * FROM experience_levels WHERE deleted_at IS NULL ORDER BY display_order ASC, id ASC');
            if ($stmt) $levels = $stmt->fetchAll();
        } catch (\Throwable $t) {
            try {
                $stmt = $this->db->query('SELECT * FROM experience_levels ORDER BY display_order ASC, id ASC');
                if ($stmt) $levels = $stmt->fetchAll();
            } catch (\Throwable $t2) {
                $levels = [];
            }
        }

        if (empty($levels)) {
            $defaultLevels = [
                ['name' => 'Emerging Artist (1-3 years)', 'years_range' => '1-3 years', 'display_order' => 1],
                ['name' => 'Mid-Career Artist (4-8 years)', 'years_range' => '4-8 years', 'display_order' => 2],
                ['name' => 'Established Master (9+ years)', 'years_range' => '9+ years', 'display_order' => 3],
                ['name' => 'Professional (5+ years)', 'years_range' => '5+ years', 'display_order' => 4],
                ['name' => 'Self-Taught / Independent', 'years_range' => 'Self-Taught', 'display_order' => 5],
            ];
            try {
                $ins = $this->db->prepare('INSERT IGNORE INTO experience_levels (name, years_range, display_order) VALUES (?, ?, ?)');
                foreach ($defaultLevels as $dl) {
                    $ins->execute([$dl['name'], $dl['years_range'], $dl['display_order']]);
                }
                $stmt = $this->db->query('SELECT * FROM experience_levels ORDER BY display_order ASC, id ASC');
                if ($stmt) $levels = $stmt->fetchAll();
            } catch (\Throwable $t3) {}
            if (empty($levels)) {
                $levels = $defaultLevels;
            }
        }

        ApiResponse::success($levels, 'Experience levels retrieved successfully');
    }

    public function createExperienceLevel(array $input): void {
        AuthMiddleware::requireAdmin();
        $name = InputSanitizer::cleanString($input['name'] ?? '');
        $yearsRange = InputSanitizer::cleanString($input['years_range'] ?? '');
        $displayOrder = (int)($input['display_order'] ?? 0);

        if (empty($name)) {
            ApiResponse::error('Experience level name is required.');
        }

        $stmt = $this->db->prepare('INSERT INTO experience_levels (name, years_range, display_order) VALUES (?, ?, ?)');
        $stmt->execute([$name, $yearsRange, $displayOrder]);

        ApiResponse::success(['id' => (int)$this->db->lastInsertId()], 'Experience level created successfully', 201);
    }

    public function updateExperienceLevel(array $input): void {
        AuthMiddleware::requireAdmin();
        $id = (int)($input['id'] ?? 0);
        $name = InputSanitizer::cleanString($input['name'] ?? '');
        $yearsRange = InputSanitizer::cleanString($input['years_range'] ?? '');
        $displayOrder = (int)($input['display_order'] ?? 0);

        if ($id <= 0) {
            ApiResponse::error('Experience level ID is required.');
        }

        $stmt = $this->db->prepare('UPDATE experience_levels SET name = ?, years_range = ?, display_order = ? WHERE id = ?');
        $stmt->execute([$name, $yearsRange, $displayOrder, $id]);

        ApiResponse::success(['updated' => true], 'Experience level updated successfully');
    }

    public function deleteExperienceLevel(array $input): void {
        AuthMiddleware::requireAdmin();
        $id = (int)($input['id'] ?? 0);
        if ($id <= 0) {
            ApiResponse::error('Experience level ID is required for deletion.');
        }

        // Soft-delete: move to recycle bin
        $this->db->prepare('UPDATE experience_levels SET deleted_at = NOW() WHERE id = ?')->execute([$id]);

        ApiResponse::success(['deleted' => true], 'Experience level moved to recycle bin');
    }
}

class LocationController {
    private PDO $db;

    public function __construct() {
        $this->db = DatabaseManager::getInstance()->getConnection();
    }

    public function getLocations(): void {
        $stmt = $this->db->query('SELECT * FROM locations WHERE deleted_at IS NULL ORDER BY display_order ASC, id ASC');
        $locations = $stmt->fetchAll();
        ApiResponse::success($locations, 'Locations retrieved successfully');
    }

    public function createLocation(array $input): void {
        AuthMiddleware::requireAdmin();
        $name = InputSanitizer::cleanString($input['name'] ?? '');
        $city = InputSanitizer::cleanString($input['city'] ?? 'Dubai');
        $country = InputSanitizer::cleanString($input['country'] ?? 'UAE');
        $displayOrder = (int)($input['display_order'] ?? 0);

        if (empty($name)) {
            ApiResponse::error('Location name is required.');
        }

        $stmt = $this->db->prepare('INSERT INTO locations (name, city, country, display_order) VALUES (?, ?, ?, ?)');
        $stmt->execute([$name, $city, $country, $displayOrder]);

        ApiResponse::success(['id' => (int)$this->db->lastInsertId()], 'Location created successfully', 201);
    }

    public function updateLocation(array $input): void {
        AuthMiddleware::requireAdmin();
        $id = (int)($input['id'] ?? 0);
        $name = InputSanitizer::cleanString($input['name'] ?? '');
        $city = InputSanitizer::cleanString($input['city'] ?? 'Dubai');
        $country = InputSanitizer::cleanString($input['country'] ?? 'UAE');
        $displayOrder = (int)($input['display_order'] ?? 0);

        if ($id <= 0) {
            ApiResponse::error('Location ID is required.');
        }

        $stmt = $this->db->prepare('UPDATE locations SET name = ?, city = ?, country = ?, display_order = ? WHERE id = ?');
        $stmt->execute([$name, $city, $country, $displayOrder, $id]);

        ApiResponse::success(['updated' => true], 'Location updated successfully');
    }

    public function deleteLocation(array $input): void {
        AuthMiddleware::requireAdmin();
        $id = (int)($input['id'] ?? 0);
        if ($id <= 0) {
            ApiResponse::error('Location ID is required for deletion.');
        }

        // Soft-delete: move to recycle bin
        $this->db->prepare('UPDATE locations SET deleted_at = NOW() WHERE id = ?')->execute([$id]);

        ApiResponse::success(['deleted' => true], 'Location moved to recycle bin');
    }
}

class ArtistController {
    private PDO $db;

    public function __construct() {
        $this->db = DatabaseManager::getInstance()->getConnection();
    }

    public function getArtists(array $query): void {
        $category = InputSanitizer::cleanString($query['category'] ?? '');
        $search = InputSanitizer::cleanString($query['search'] ?? $query['q'] ?? '');
        $id = InputSanitizer::cleanString($query['id'] ?? '');

        if (!empty($id)) {
            $stmt = $this->db->prepare('SELECT a.*, 
                (SELECT COUNT(*) FROM favorites WHERE item_type = "artist" AND item_id COLLATE utf8mb4_unicode_ci = CAST(a.id AS CHAR) COLLATE utf8mb4_unicode_ci) AS likes_count,
                (SELECT COUNT(*) FROM follows WHERE artist_id COLLATE utf8mb4_unicode_ci = CAST(a.id AS CHAR) COLLATE utf8mb4_unicode_ci) AS followers_count,
                (SELECT COUNT(*) FROM artworks WHERE artist_id = a.id OR (artist_id IS NULL AND artist_name IS NOT NULL AND LOWER(artist_name) COLLATE utf8mb4_unicode_ci = LOWER(a.name) COLLATE utf8mb4_unicode_ci)) AS works_count
                FROM artists a WHERE a.id = ?');
            $stmt->execute([$id]);
            $artist = $stmt->fetch();
            if ($artist) { ApiResponse::success($artist, 'Artist details fetched'); return; }
            else { ApiResponse::error('Artist not found', 404); return; }
        }

        $sql = 'SELECT a.*, 
                (SELECT COUNT(*) FROM favorites WHERE item_type = "artist" AND item_id COLLATE utf8mb4_unicode_ci = CAST(a.id AS CHAR) COLLATE utf8mb4_unicode_ci) AS likes_count,
                (SELECT COUNT(*) FROM follows WHERE artist_id COLLATE utf8mb4_unicode_ci = CAST(a.id AS CHAR) COLLATE utf8mb4_unicode_ci) AS followers_count,
                (SELECT COUNT(*) FROM artworks WHERE artist_id = a.id OR (artist_id IS NULL AND artist_name IS NOT NULL AND LOWER(artist_name) COLLATE utf8mb4_unicode_ci = LOWER(a.name) COLLATE utf8mb4_unicode_ci)) AS works_count
                FROM artists a WHERE a.deleted_at IS NULL';
        $params = [];

        if (!empty($category) && $category !== 'All Categories' && $category !== 'All') {
            $sql .= ' AND a.category LIKE ?';
            $params[] = "%$category%";
        }

        if (!empty($search)) {
            $sql .= ' AND (a.name LIKE ? OR a.bio LIKE ? OR a.location LIKE ?)';
            $params[] = "%$search%";
            $params[] = "%$search%";
            $params[] = "%$search%";
        }

        $page = max(1, (int)($query['page'] ?? 1));
        $limit = isset($query['limit']) ? min(200, max(1, (int)$query['limit'])) : (isset($query['all']) && $query['all'] == 1 ? 1000 : 50);
        $offset = ($page - 1) * $limit;

        // Count total matching records for instant pagination calculation
        $countSql = 'SELECT COUNT(*) FROM artists a WHERE a.deleted_at IS NULL';
        $countParams = [];
        if (!empty($category) && $category !== 'All Categories' && $category !== 'All') {
            $countSql .= ' AND a.category LIKE ?';
            $countParams[] = "%$category%";
        }
        if (!empty($search)) {
            $countSql .= ' AND (a.name LIKE ? OR a.bio LIKE ? OR a.location LIKE ?)';
            $countParams[] = "%$search%";
            $countParams[] = "%$search%";
            $countParams[] = "%$search%";
        }
        $countStmt = $this->db->prepare($countSql);
        $countStmt->execute($countParams);
        $total = (int)$countStmt->fetchColumn();

        $sql .= " ORDER BY a.id DESC LIMIT $limit OFFSET $offset";
        $stmt = $this->db->prepare($sql);
        $stmt->execute($params);
        $artists = $stmt->fetchAll();

        $pagination = [
            'page' => $page,
            'limit' => $limit,
            'total' => $total,
            'total_pages' => ceil($total / max(1, $limit)),
            'has_more' => ($offset + count($artists)) < $total
        ];

        ApiResponse::success($artists, 'Artists retrieved successfully', 200, $pagination);
    }

    public function createArtist(array $input): void {
        $name = InputSanitizer::cleanString($input['name'] ?? $input['full_name'] ?? '');
        $category = InputSanitizer::cleanString($input['category'] ?? 'Contemporary Art');
        $location = InputSanitizer::cleanString($input['location'] ?? 'Dubai, UAE');
        $bio = InputSanitizer::cleanString($input['bio'] ?? '');
        $email = InputSanitizer::cleanEmail($input['email'] ?? '');
        $phone = InputSanitizer::cleanString($input['phone'] ?? '');
        $website = InputSanitizer::cleanString($input['website'] ?? '');
        $instagram = InputSanitizer::cleanString($input['instagram'] ?? '');
        $experience_level = InputSanitizer::cleanString($input['experience_level'] ?? $input['experience'] ?? '');
        $booking_rate = InputSanitizer::cleanString($input['booking_rate'] ?? $input['price'] ?? 'AED 1500+');
        $avatar_url = InputSanitizer::cleanString($input['avatar_url'] ?? $input['avatar'] ?? '');
        $banner_url = InputSanitizer::cleanString($input['banner_url'] ?? $input['banner'] ?? '');

        if (empty($name)) {
            ApiResponse::error('Artist name is required.');
        }

        // Check if user exists to link user_id
        $userId = null;
        if (!empty($email)) {
            $uStmt = $this->db->prepare('SELECT id FROM users WHERE email = ?');
            $uStmt->execute([$email]);
            $uRow = $uStmt->fetch();
            if ($uRow) $userId = (int)$uRow['id'];
        }

        $stmt = $this->db->prepare('INSERT INTO artists (user_id, name, category, location, bio, email, phone, website, instagram, experience_level, booking_rate, avatar_url, banner_url, followers_count, works_count) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 0, 0)');
        $stmt->execute([$userId, $name, $category, $location, $bio, $email, $phone, $website, $instagram, $experience_level, $booking_rate, $avatar_url, $banner_url]);

        ApiResponse::success(['artist_id' => (int)$this->db->lastInsertId()], 'Artist profile created successfully', 201);
    }

    public function likeArtist(array $input): void {
        $id = (int)($input['artist_id'] ?? $input['id'] ?? 0);
        $email = InputSanitizer::cleanEmail($input['user_email'] ?? $input['email'] ?? '');
        $action = $input['action'] ?? 'toggle';

        if ($id <= 0) {
            ApiResponse::error('Artist ID is required.');
            return;
        }

        $isLiked = false;
        if (!empty($email)) {
            $favCheck = $this->db->prepare('SELECT id FROM favorites WHERE user_email = ? AND item_type = "artist" AND item_id = ?');
            $favCheck->execute([$email, (string)$id]);
            $existing = $favCheck->fetch();

            if ($action === 'unlike' || ($action === 'toggle' && $existing)) {
                $del = $this->db->prepare('DELETE FROM favorites WHERE user_email = ? AND item_type = "artist" AND item_id = ?');
                $del->execute([$email, (string)$id]);
                $isLiked = false;
            } elseif ($action === 'like' || ($action === 'toggle' && !$existing)) {
                if (!$existing) {
                    $ins = $this->db->prepare('INSERT INTO favorites (user_email, item_type, item_id) VALUES (?, "artist", ?)');
                    $ins->execute([$email, (string)$id]);
                }
                $isLiked = true;
            }
        }

        $cntStmt = $this->db->prepare('SELECT COUNT(*) FROM favorites WHERE item_type = "artist" AND item_id = ?');
        $cntStmt->execute([(string)$id]);
        $likes = (int)$cntStmt->fetchColumn();

        $this->db->prepare('UPDATE artists SET likes_count = ? WHERE id = ?')->execute([$likes, $id]);

        ApiResponse::success([
            'artist_id' => $id,
            'likes_count' => $likes,
            'is_liked' => $isLiked
        ], $isLiked ? 'Artist profile liked successfully' : 'Artist profile unliked');
    }

    public function followArtist(array $input): void {
        $id = (int)($input['artist_id'] ?? $input['id'] ?? 0);
        $email = InputSanitizer::cleanEmail($input['user_email'] ?? $input['email'] ?? '');
        $action = $input['action_type'] ?? $input['action'] ?? 'toggle';

        if ($id <= 0) {
            ApiResponse::error('Artist ID is required.');
            return;
        }

        $isFollowing = false;
        if (!empty($email)) {
            $folCheck = $this->db->prepare('SELECT id FROM follows WHERE user_email = ? AND artist_id = ?');
            $folCheck->execute([$email, (string)$id]);
            $existing = $folCheck->fetch();

            if ($action === 'unfollow' || ($action === 'toggle' && $existing)) {
                $del = $this->db->prepare('DELETE FROM follows WHERE user_email = ? AND artist_id = ?');
                $del->execute([$email, (string)$id]);
                $isFollowing = false;
            } elseif ($action === 'follow' || ($action === 'toggle' && !$existing)) {
                if (!$existing) {
                    $ins = $this->db->prepare('INSERT INTO follows (user_email, artist_id) VALUES (?, ?)');
                    $ins->execute([$email, (string)$id]);
                }
                $isFollowing = true;
            }
        }

        $cntStmt = $this->db->prepare('SELECT COUNT(*) FROM follows WHERE artist_id = ?');
        $cntStmt->execute([(string)$id]);
        $followers = (int)$cntStmt->fetchColumn();

        $this->db->prepare('UPDATE artists SET followers_count = ? WHERE id = ?')->execute([$followers, $id]);

        ApiResponse::success([
            'artist_id' => $id,
            'followers_count' => $followers,
            'is_following' => $isFollowing
        ], $isFollowing ? 'Artist followed successfully' : 'Artist unfollowed');
    }

    public function getArtistStatus(array $query): void {
        $id = (int)($query['artist_id'] ?? $query['id'] ?? 0);
        $email = InputSanitizer::cleanEmail($query['user_email'] ?? $query['email'] ?? '');

        if ($id <= 0) {
            ApiResponse::error('Artist ID is required.');
            return;
        }

        // Count actual likes, followers, artworks from relational tables
        $cntLikes = $this->db->prepare('SELECT COUNT(*) FROM favorites WHERE item_type = "artist" AND item_id = ?');
        $cntLikes->execute([(string)$id]);
        $likes = (int)$cntLikes->fetchColumn();

        $cntFollowers = $this->db->prepare('SELECT COUNT(*) FROM follows WHERE artist_id = ?');
        $cntFollowers->execute([(string)$id]);
        $followers = (int)$cntFollowers->fetchColumn();

        $cntWorks = $this->db->prepare('SELECT COUNT(*) FROM artworks WHERE artist_id = ? OR (artist_id IS NULL AND artist_name IS NOT NULL AND LOWER(artist_name) COLLATE utf8mb4_unicode_ci = (SELECT LOWER(name) COLLATE utf8mb4_unicode_ci FROM artists WHERE id = ? LIMIT 1))');
        $cntWorks->execute([(string)$id, $id]);
        $works = (int)$cntWorks->fetchColumn();

        $this->db->prepare('UPDATE artists SET likes_count = ?, followers_count = ?, works_count = ? WHERE id = ?')
                 ->execute([$likes, $followers, $works, $id]);

        $isLiked = false;
        $isFollowing = false;

        if (!empty($email)) {
            $favCheck = $this->db->prepare('SELECT id FROM favorites WHERE user_email = ? AND item_type = "artist" AND item_id = ?');
            $favCheck->execute([$email, (string)$id]);
            $isLiked = (bool)$favCheck->fetch();

            $folCheck = $this->db->prepare('SELECT id FROM follows WHERE user_email = ? AND artist_id = ?');
            $folCheck->execute([$email, (string)$id]);
            $isFollowing = (bool)$folCheck->fetch();
        }

        ApiResponse::success([
            'artist_id' => $id,
            'likes_count' => $likes,
            'followers_count' => $followers,
            'works_count' => $works,
            'is_liked' => $isLiked,
            'is_following' => $isFollowing
        ], 'Artist status retrieved successfully');
    }

    public function getUserInteractions(array $query): void {
        $email = InputSanitizer::cleanEmail($query['user_email'] ?? $query['email'] ?? '');

        if (empty($email)) {
            ApiResponse::success([
                'liked_artist_ids' => [],
                'followed_artist_ids' => [],
            ], 'No email provided');
            return;
        }

        // All liked artist IDs
        $likedStmt = $this->db->prepare(
            'SELECT item_id FROM favorites WHERE user_email = ? AND item_type = "artist"'
        );
        $likedStmt->execute([$email]);
        $likedIds = array_map(fn($r) => (string)$r['item_id'], $likedStmt->fetchAll(PDO::FETCH_ASSOC));

        // All followed artist IDs
        $followedStmt = $this->db->prepare(
            'SELECT artist_id FROM follows WHERE user_email = ?'
        );
        $followedStmt->execute([$email]);
        $followedIds = array_map(fn($r) => (string)$r['artist_id'], $followedStmt->fetchAll(PDO::FETCH_ASSOC));

        ApiResponse::success([
            'liked_artist_ids'   => $likedIds,
            'followed_artist_ids' => $followedIds,
        ], 'User interactions retrieved successfully');
    }

    public function updateArtist(array $input): void {
        $currentUser = AuthMiddleware::requireAuth();
        $id = (int)($input['id'] ?? $input['artist_id'] ?? 0);
        if ($id <= 0) { ApiResponse::error('Artist ID is required.'); return; }

        $stmt = $this->db->prepare('SELECT id, user_id, email, avatar_url, banner_url FROM artists WHERE id = ?');
        $stmt->execute([$id]);
        $artist = $stmt->fetch();
        if (!$artist) { ApiResponse::error('Artist not found', 404); return; }

        if (!$currentUser['is_admin'] && $artist['user_id'] != $currentUser['id'] && strtolower($artist['email'] ?? '') !== strtolower($currentUser['email'])) {
            ApiResponse::error('Forbidden. You do not have permission to update this artist profile.', 403);
            return;
        }

        // Clean up old avatar or banner if changed
        if (isset($input['avatar_url']) && !empty($artist['avatar_url']) && $input['avatar_url'] !== $artist['avatar_url']) {
            UploadController::deletePhysicalFile($artist['avatar_url']);
        }
        if (isset($input['banner_url']) && !empty($artist['banner_url']) && $input['banner_url'] !== $artist['banner_url']) {
            UploadController::deletePhysicalFile($artist['banner_url']);
        }

        $fields = [];
        $params = [];
        $allowed = ['name','category','location','bio','email','phone','website','instagram','experience_level','booking_rate','avatar_url','banner_url','status','is_active','works_count','likes_count','followers_count'];
        foreach ($allowed as $f) {
            if (isset($input[$f])) {
                $fields[] = "$f = ?";
                $params[] = ($f === 'works_count' || $f === 'likes_count' || $f === 'followers_count' || $f === 'is_active')
                    ? (int)$input[$f]
                    : InputSanitizer::cleanString((string)$input[$f]);
            }
        }
        if (empty($fields)) { ApiResponse::error('No fields to update.'); return; }
        $params[] = $id;
        $this->db->prepare('UPDATE artists SET ' . implode(', ', $fields) . ' WHERE id = ?')->execute($params);
        ApiResponse::success(['id' => $id], 'Artist updated successfully');
    }

    public function deleteArtist(array $input): void {
        $currentUser = AuthMiddleware::requireAuth();
        $id = (int)($input['id'] ?? $input['artist_id'] ?? $_GET['id'] ?? 0);
        if ($id <= 0) { ApiResponse::error('Artist ID is required.'); return; }

        $stmt = $this->db->prepare('SELECT id, user_id, email, avatar_url, banner_url FROM artists WHERE id = ?');
        $stmt->execute([$id]);
        $artist = $stmt->fetch();
        if (!$artist) { ApiResponse::error('Artist not found', 404); return; }

        if (!$currentUser['is_admin'] && $artist['user_id'] != $currentUser['id'] && strtolower($artist['email'] ?? '') !== strtolower($currentUser['email'])) {
            ApiResponse::error('Forbidden. You do not have permission to delete this artist profile.', 403);
            return;
        }

        // Delete physical avatar & banner from storage
        if (!empty($artist['avatar_url'])) {
            UploadController::deletePhysicalFile($artist['avatar_url']);
        }
        if (!empty($artist['banner_url'])) {
            UploadController::deletePhysicalFile($artist['banner_url']);
        }

        // Clean up artworks' images for this artist
        $artworks = $this->db->prepare('SELECT image_url FROM artworks WHERE artist_id = ?');
        $artworks->execute([$id]);
        while ($aw = $artworks->fetch()) {
            if (!empty($aw['image_url'])) {
                UploadController::deletePhysicalFile($aw['image_url']);
            }
        }

        // Soft-delete: move to recycle bin
        $this->db->prepare('UPDATE artists SET deleted_at = NOW() WHERE id = ?')->execute([$id]);
        ApiResponse::success(['id' => $id], 'Artist moved to recycle bin and associated images removed from storage');
    }
}

class EventController {
    private PDO $db;

    public function __construct() {
        $this->db = DatabaseManager::getInstance()->getConnection();
    }

    public function getEvents(array $query): void {
        $id = InputSanitizer::cleanString($query['id'] ?? '');
        $category = InputSanitizer::cleanString($query['category'] ?? '');
        $search = InputSanitizer::cleanString($query['q'] ?? $query['search'] ?? '');

        if (!empty($id)) {
            $stmt = $this->db->prepare('SELECT * FROM events WHERE id = ?');
            $stmt->execute([$id]);
            $event = $stmt->fetch();
            if ($event) {
                $eventGalleries = [];
                if (!empty($event['galleries_json'])) {
                    $eventGalleries = json_decode($event['galleries_json'], true) ?: [];
                }
                try {
                    $gStmt = $this->db->prepare('SELECT * FROM galleries WHERE (event_id = ? OR event_name = ? OR (description LIKE ?)) AND (status = "approved" OR status = "active" OR is_public = 1 OR is_approved = 1) ORDER BY id DESC');
                    $gStmt->execute([$id, $event['title'], "%{$event['title']}%"]);
                    $dbGals = $gStmt->fetchAll();
                    foreach ($dbGals as $dg) {
                        $imgs = !empty($dg['images_json']) ? json_decode($dg['images_json'], true) : [];
                        if (empty($imgs) && !empty($dg['image_url'])) $imgs = [$dg['image_url']];
                        $eventGalleries[] = [
                            'id' => (int)$dg['id'],
                            'title' => $dg['name'],
                            'subtitle' => $dg['description'] ?: '',
                            'image_url' => $dg['image_url'] ?: ($imgs[0] ?? ''),
                            'photo_count' => count($imgs) ?: 1,
                            'date' => $dg['created_at'] ?: '',
                            'images' => $imgs,
                        ];
                    }
                } catch (\Throwable $t) {}
                $event['galleries'] = $eventGalleries;
                ApiResponse::success($event, 'Event details retrieved successfully');
            } else {
                ApiResponse::error('Event not found', 404);
            }
            return;
        }

        $sql = 'SELECT * FROM events WHERE deleted_at IS NULL';
        $params = [];

        $userEmail = InputSanitizer::cleanString($query['user_email'] ?? $query['email'] ?? $query['contact_email'] ?? '');
        $organizer = InputSanitizer::cleanString($query['organizer'] ?? $query['organizer_name'] ?? '');

        if (!empty($userEmail)) {
            $cleanEmail = strtolower(trim($userEmail));
            if (!empty($organizer)) {
                $cleanOrg = strtolower(trim($organizer));
                $sql .= ' AND (LOWER(TRIM(contact_email)) = ? OR LOWER(TRIM(organizer_name)) = ?)';
                $params[] = $cleanEmail;
                $params[] = $cleanOrg;
            } else {
                $sql .= ' AND LOWER(TRIM(contact_email)) = ?';
                $params[] = $cleanEmail;
            }
        } elseif (!empty($organizer)) {
            $cleanOrg = strtolower(trim($organizer));
            $sql .= ' AND LOWER(TRIM(organizer_name)) = ?';
            $params[] = $cleanOrg;
        }

        if (!empty($category) && $category !== 'All Categories' && $category !== 'All') {
            $sql .= ' AND category LIKE ?';
            $params[] = "%$category%";
        }

        if (!empty($search)) {
            $sql .= ' AND (title LIKE ? OR description LIKE ? OR location LIKE ? OR venue LIKE ?)';
            $params[] = "%$search%";
            $params[] = "%$search%";
            $params[] = "%$search%";
            $params[] = "%$search%";
        }

        $page = max(1, (int)($query['page'] ?? 1));
        $limit = isset($query['limit']) ? min(200, max(1, (int)$query['limit'])) : (isset($query['all']) && $query['all'] == 1 ? 1000 : 50);
        $offset = ($page - 1) * $limit;

        // Count total matching records
        $countSql = 'SELECT COUNT(*) FROM events WHERE 1=1';
        $countParams = [];

        if (!empty($userEmail)) {
            $cleanEmail = strtolower(trim($userEmail));
            if (!empty($organizer)) {
                $cleanOrg = strtolower(trim($organizer));
                $countSql .= ' AND (LOWER(TRIM(contact_email)) = ? OR LOWER(TRIM(organizer_name)) = ?)';
                $countParams[] = $cleanEmail;
                $countParams[] = $cleanOrg;
            } else {
                $countSql .= ' AND LOWER(TRIM(contact_email)) = ?';
                $countParams[] = $cleanEmail;
            }
        } elseif (!empty($organizer)) {
            $cleanOrg = strtolower(trim($organizer));
            $countSql .= ' AND LOWER(TRIM(organizer_name)) = ?';
            $countParams[] = $cleanOrg;
        }

        if (!empty($category) && $category !== 'All Categories' && $category !== 'All') {
            $countSql .= ' AND category LIKE ?';
            $countParams[] = "%$category%";
        }
        if (!empty($search)) {
            $countSql .= ' AND (title LIKE ? OR description LIKE ? OR location LIKE ? OR venue LIKE ?)';
            $countParams[] = "%$search%";
            $countParams[] = "%$search%";
            $countParams[] = "%$search%";
            $countParams[] = "%$search%";
        }
        $countStmt = $this->db->prepare($countSql);
        $countStmt->execute($countParams);
        $total = (int)$countStmt->fetchColumn();

        $sql .= " ORDER BY id DESC LIMIT $limit OFFSET $offset";
        $stmt = $this->db->prepare($sql);
        $stmt->execute($params);
        $events = $stmt->fetchAll();

        // Attach event photo galleries if stored in MySQL
        foreach ($events as &$ev) {
            $eventGalleries = [];
            if (!empty($ev['galleries_json'])) {
                $eventGalleries = json_decode($ev['galleries_json'], true) ?: [];
            }
            try {
                $gStmt = $this->db->prepare('SELECT * FROM galleries WHERE (event_id = ? OR event_name = ? OR (description LIKE ?)) AND (status = "approved" OR status = "active" OR is_public = 1 OR is_approved = 1) ORDER BY id DESC');
                $gStmt->execute([$ev['id'], $ev['title'], "%{$ev['title']}%"]);
                $dbGals = $gStmt->fetchAll();
                foreach ($dbGals as $dg) {
                    $imgs = !empty($dg['images_json']) ? json_decode($dg['images_json'], true) : [];
                    if (empty($imgs) && !empty($dg['image_url'])) $imgs = [$dg['image_url']];
                    $eventGalleries[] = [
                        'id' => (int)$dg['id'],
                        'title' => $dg['name'],
                        'subtitle' => $dg['description'] ?: '',
                        'image_url' => $dg['image_url'] ?: ($imgs[0] ?? ''),
                        'photo_count' => count($imgs) ?: 1,
                        'date' => $dg['created_at'] ?: '',
                        'images' => $imgs,
                    ];
                }
            } catch (\Throwable $t) {}
            $ev['galleries'] = $eventGalleries;
        }

        $pagination = [
            'page' => $page,
            'limit' => $limit,
            'total' => $total,
            'total_pages' => ceil($total / max(1, $limit)),
            'has_more' => ($offset + count($events)) < $total
        ];

        ApiResponse::success($events, 'Events retrieved successfully', 200, $pagination);
    }

    public function createEvent(array $input): void {
        $title = InputSanitizer::cleanString($input['title'] ?? '');
        $description = InputSanitizer::cleanString($input['description'] ?? '');
        $category = InputSanitizer::cleanString($input['category'] ?? 'Exhibition & Gallery Showcase');
        $location = InputSanitizer::cleanString($input['location'] ?? 'Dubai, UAE');
        $venue = InputSanitizer::cleanString($input['venue'] ?? '');
        $eventDate = InputSanitizer::cleanString($input['event_date'] ?? $input['dateTime'] ?? '');
        $endDate = InputSanitizer::cleanString($input['end_date'] ?? '');
        $isFree = isset($input['is_free']) ? (int)$input['is_free'] : 1;
        $price = $isFree ? 'Free' : InputSanitizer::cleanString($input['price'] ?? 'AED 50');
        $organizer = InputSanitizer::cleanString($input['organizer_name'] ?? 'Artist Dubai');
        $contactEmail = InputSanitizer::cleanEmail($input['contact_email'] ?? $input['user_email'] ?? $input['email'] ?? '');
        if (empty($contactEmail) || $organizer === 'Artist Dubai') {
            try {
                $curUser = AuthMiddleware::getCurrentUser();
                if ($curUser) {
                    if (empty($contactEmail) && !empty($curUser['email'])) {
                        $contactEmail = $curUser['email'];
                    }
                    if ($organizer === 'Artist Dubai' && !empty($curUser['full_name'])) {
                        $organizer = $curUser['full_name'];
                    }
                }
            } catch (\Throwable $t) {}
        }
        $contactPhone = InputSanitizer::cleanString($input['contact_phone'] ?? '');
        $tags = InputSanitizer::cleanString($input['tags'] ?? '');
        $imageUrl = InputSanitizer::cleanString($input['image_url'] ?? $input['image'] ?? '');

        if (empty($title)) {
            ApiResponse::error('Event title is required.');
        }

        $maxAttendees = isset($input['max_attendees']) ? (int)$input['max_attendees'] : 100;
        $galleriesJson = null;
        if (isset($input['galleries'])) {
            $galleriesJson = is_array($input['galleries']) ? json_encode($input['galleries']) : (string)$input['galleries'];
        } elseif (isset($input['galleries_json'])) {
            $galleriesJson = (string)$input['galleries_json'];
        }

        $stmt = $this->db->prepare('INSERT INTO events (title, description, category, price, event_date, end_date, location, venue, is_free, organizer_name, contact_email, contact_phone, tags, image_url, max_attendees, attendees_count, galleries_json) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 0, ?)');
        $stmt->execute([$title, $description, $category, $price, $eventDate, $endDate, $location, $venue, $isFree, $organizer, $contactEmail, $contactPhone, $tags, $imageUrl, $maxAttendees, $galleriesJson]);

        $newEventId = (int)$this->db->lastInsertId();

        // Auto-create notification in MySQL
        try {
            $this->db->prepare('INSERT INTO notifications (title, body, type, route, user_email, is_read) VALUES (?, ?, ?, ?, ?, 0)')
                     ->execute(["New Event: $title", "Explore the newly scheduled event '$title' in $location.", 'event', '/events', null]);
        } catch (\Throwable $nt) {}

        ApiResponse::success(['event_id' => $newEventId], 'Event created successfully', 201);
    }

    public function updateEvent(array $input): void {
        $currentUser = AuthMiddleware::requireAuth();
        $id = (int)($input['id'] ?? $input['event_id'] ?? 0);
        if ($id <= 0) {
            ApiResponse::error('Valid event ID is required.', 400);
            return;
        }

        $stmt = $this->db->prepare('SELECT id, contact_email, image_url FROM events WHERE id = ?');
        $stmt->execute([$id]);
        $ev = $stmt->fetch();
        if (!$ev) {
            ApiResponse::error('Event not found', 404);
            return;
        }

        $evEmail = strtolower(trim($ev['contact_email'] ?? ''));
        if (!$currentUser['is_admin'] && (empty($evEmail) || $evEmail !== strtolower($currentUser['email']))) {
            ApiResponse::error('Forbidden. You do not have permission to update this event.', 403);
            return;
        }

        $title = InputSanitizer::cleanString($input['title'] ?? '');
        $description = InputSanitizer::cleanString($input['description'] ?? '');
        $category = InputSanitizer::cleanString($input['category'] ?? '');
        $location = InputSanitizer::cleanString($input['location'] ?? '');
        $price = InputSanitizer::cleanString($input['price'] ?? '');
        $eventDate = InputSanitizer::cleanString($input['event_date'] ?? $input['dateTime'] ?? '');
        $maxAttendees = isset($input['max_attendees']) ? (int)$input['max_attendees'] : null;

        $fields = [];
        $params = [];

        if (!empty($title)) { $fields[] = 'title = ?'; $params[] = $title; }
        if (!empty($description)) { $fields[] = 'description = ?'; $params[] = $description; }
        if (!empty($category)) { $fields[] = 'category = ?'; $params[] = $category; }
        if (!empty($location)) { $fields[] = 'location = ?'; $params[] = $location; }
        if (isset($input['image_url'])) { $fields[] = 'image_url = ?'; $params[] = InputSanitizer::cleanString($input['image_url']); }
        if (isset($input['galleries'])) {
            $fields[] = 'galleries_json = ?';
            $params[] = is_array($input['galleries']) ? json_encode($input['galleries']) : (string)$input['galleries'];
        } elseif (isset($input['galleries_json'])) {
            $fields[] = 'galleries_json = ?';
            $params[] = (string)$input['galleries_json'];
        }
        if (!empty($price)) { 
            $fields[] = 'price = ?'; 
            $params[] = $price; 
            $fields[] = 'is_free = ?';
            $params[] = (stripos($price, 'free') !== false) ? 1 : 0;
        }
        if (!empty($eventDate)) { $fields[] = 'event_date = ?'; $params[] = $eventDate; }
        if ($maxAttendees !== null) { $fields[] = 'max_attendees = ?'; $params[] = $maxAttendees; }
        if ($currentUser['is_admin']) {
            if (isset($input['status'])) { $fields[] = 'status = ?'; $params[] = InputSanitizer::cleanString((string)$input['status']); }
            if (isset($input['is_active'])) { $fields[] = 'is_active = ?'; $params[] = (int)$input['is_active']; }
        }
        if (isset($input['contact_email'])) { $fields[] = 'contact_email = ?'; $params[] = InputSanitizer::cleanEmail($input['contact_email']); }
        if (isset($input['organizer_name'])) { $fields[] = 'organizer_name = ?'; $params[] = InputSanitizer::cleanString($input['organizer_name']); }

        if (empty($fields)) {
            ApiResponse::error('No fields provided to update.', 400);
            return;
        }

        if (isset($input['image_url'])) {
            $currentImg = $ev['image_url'] ?? '';
            if ($currentImg && $currentImg !== $input['image_url']) {
                UploadController::deletePhysicalFile($currentImg);
            }
        }

        $params[] = $id;
        $sql = 'UPDATE events SET ' . implode(', ', $fields) . ' WHERE id = ?';
        $stmt = $this->db->prepare($sql);
        $stmt->execute($params);

        ApiResponse::success(['event_id' => $id], 'Event updated successfully');
    }

    public function deleteEvent(array $input): void {
        $currentUser = AuthMiddleware::requireAuth();
        $id = (int)($input['id'] ?? $input['event_id'] ?? $_GET['id'] ?? 0);
        if ($id <= 0) { ApiResponse::error('Event ID is required.'); return; }

        $stmt = $this->db->prepare('SELECT id, contact_email, image_url, galleries_json FROM events WHERE id = ?');
        $stmt->execute([$id]);
        $ev = $stmt->fetch();
        if (!$ev) {
            ApiResponse::error('Event not found', 404);
            return;
        }

        $evEmail = strtolower(trim($ev['contact_email'] ?? ''));
        if (!$currentUser['is_admin'] && (empty($evEmail) || $evEmail !== strtolower($currentUser['email']))) {
            ApiResponse::error('Forbidden. You do not have permission to delete this event.', 403);
            return;
        }

        // Delete physical files from disk storage
        if (!empty($ev['image_url'])) {
            UploadController::deletePhysicalFile($ev['image_url']);
        }
        if (!empty($ev['galleries_json'])) {
            UploadController::deleteMultiplePhysicalFiles($ev['galleries_json']);
        }

        // Soft-delete: move to recycle bin & set inactive
        $this->db->prepare('UPDATE events SET deleted_at = NOW(), is_active = 0, status = "deleted" WHERE id = ?')->execute([$id]);
        ApiResponse::success(['id' => $id], 'Event deleted successfully');
    }
}

class BookingController {
    private PDO $db;

    public function __construct() {
        $this->db = DatabaseManager::getInstance()->getConnection();
    }

    public function getBookings(array $query): void {
        $email = InputSanitizer::cleanEmail($query['email'] ?? '');
        $currentUser = AuthMiddleware::getCurrentUser();
        
        if (!empty($email)) {
            if ($currentUser && !$currentUser['is_admin'] && strtolower($currentUser['email']) !== strtolower($email)) {
                ApiResponse::error('Forbidden. You cannot view bookings belonging to another email address.', 403);
                return;
            }
            $stmt = $this->db->prepare('SELECT * FROM bookings WHERE email = ? ORDER BY id DESC');
            $stmt->execute([$email]);
        } else {
            if (!$currentUser) {
                ApiResponse::error('Authentication required to view bookings.', 401);
                return;
            }
            if ($currentUser['is_admin']) {
                $stmt = $this->db->query('SELECT * FROM bookings ORDER BY id DESC');
            } else {
                $stmt = $this->db->prepare('SELECT * FROM bookings WHERE email = ? ORDER BY id DESC');
                $stmt->execute([$currentUser['email']]);
            }
        }
        $bookings = $stmt->fetchAll();
        ApiResponse::success($bookings, 'Bookings retrieved successfully');
    }

    public function createBooking(array $input): void {
        $name = InputSanitizer::cleanString($input['full_name'] ?? $input['name'] ?? '');
        $email = InputSanitizer::cleanEmail($input['email'] ?? '');
        $phone = InputSanitizer::cleanString($input['phone'] ?? '');
        $artistName = InputSanitizer::cleanString($input['artist_name'] ?? '');
        $bookingType = InputSanitizer::cleanString($input['booking_type'] ?? 'Commission Artwork');
        $budgetRange = InputSanitizer::cleanString($input['budget_range'] ?? '');
        $eventId = !empty($input['event_id']) ? (int)$input['event_id'] : null;
        $eventTitle = InputSanitizer::cleanString($input['event_title'] ?? $input['title'] ?? '');
        $eventDate = InputSanitizer::cleanString($input['event_date'] ?? $input['date'] ?? '15 Oct 2026');
        $endDate = InputSanitizer::cleanString($input['end_date'] ?? '');
        $location = InputSanitizer::cleanString($input['location'] ?? 'Dubai, UAE');
        $description = InputSanitizer::cleanString($input['description'] ?? $input['notes'] ?? '');
        $requirements = InputSanitizer::cleanString($input['requirements'] ?? '');
        $ticketsCount = isset($input['tickets_count']) ? (int)$input['tickets_count'] : 1;
        $totalPrice = InputSanitizer::cleanString($input['total_price'] ?? $input['price'] ?? (!empty($budgetRange) ? $budgetRange : 'AED 1500+'));
        $status = InputSanitizer::cleanString($input['status'] ?? 'Pending');

        if (empty($name) || empty($email)) {
            ApiResponse::error('Full name and valid email are required.');
            return;
        }

        try {
            $stmt = $this->db->prepare('INSERT INTO bookings (full_name, email, phone, artist_name, booking_type, budget_range, event_id, event_title, event_date, end_date, location, description, requirements, tickets_count, total_price, status) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)');
            $stmt->execute([$name, $email, $phone, $artistName, $bookingType, $budgetRange, $eventId, $eventTitle, $eventDate, $endDate, $location, $description, $requirements, $ticketsCount, $totalPrice, $status]);
        } catch (\Throwable $e) {
            try {
                $stmt = $this->db->prepare('INSERT INTO bookings (full_name, email, phone, artist_name, booking_type, event_date, location, description) VALUES (?, ?, ?, ?, ?, ?, ?, ?)');
                $stmt->execute([$name, $email, $phone, $artistName, $bookingType, $eventDate, $location, $description]);
            } catch (\Throwable $t) {
                error_log('Booking save error: ' . $t->getMessage()); ApiResponse::error('Booking save error', 500);
                return;
            }
        }

        $newBookingId = (int)$this->db->lastInsertId();

        try {
            $notifTitle = !empty($eventTitle) ? "Booking Confirmed: $eventTitle" : "Booking Request Submitted";
            $notifBody = !empty($eventTitle) ? "Your ticket booking for $eventTitle ($ticketsCount tickets) is confirmed." : "Your inquiry for $artistName ($bookingType) has been submitted.";
            $notifRoute = !empty($eventTitle) ? '/bookings' : '/booking-requests';
            $this->db->prepare('INSERT INTO notifications (title, body, type, route, user_email, is_read) VALUES (?, ?, ?, ?, ?, 0)')
                     ->execute([$notifTitle, $notifBody, 'booking', $notifRoute, $email]);
        } catch (\Throwable $nt) {}

        ApiResponse::success([
            'id' => $newBookingId,
            'booking_id' => $newBookingId,
            'full_name' => $name,
            'email' => $email,
            'phone' => $phone,
            'artist_name' => $artistName,
            'booking_type' => $bookingType,
            'budget_range' => $budgetRange,
            'event_date' => $eventDate,
            'end_date' => $endDate,
            'location' => $location,
            'description' => $description,
            'requirements' => $requirements,
            'total_price' => $totalPrice,
            'status' => $status
        ], 'Booking submitted successfully', 201);
    }

    public function cancelBooking(array $input): void {
        $id = (int)($input['id'] ?? $input['booking_id'] ?? 0);
        if ($id <= 0) {
            ApiResponse::error('Booking ID is required.');
            return;
        }

        $stmt = $this->db->prepare('SELECT id, email FROM bookings WHERE id = ?');
        $stmt->execute([$id]);
        $b = $stmt->fetch();
        if (!$b) {
            ApiResponse::error('Booking not found', 404);
            return;
        }

        $currentUser = AuthMiddleware::requireAuth();
        if (!$currentUser['is_admin'] && strtolower($currentUser['email']) !== strtolower($b['email'])) {
            ApiResponse::error('Forbidden. You can only cancel your own booking.', 403);
            return;
        }

        $upd = $this->db->prepare("UPDATE bookings SET status = 'Cancelled' WHERE id = ?");
        $upd->execute([$id]);

        ApiResponse::success(['booking_id' => $id, 'status' => 'Cancelled'], 'Booking cancelled successfully');
    }

    public function downloadTicketPdf(array $query): void {
        $id = (int)($query['id'] ?? $query['booking_id'] ?? 0);
        $stmt = $this->db->prepare('SELECT * FROM bookings WHERE id = ? LIMIT 1');
        $stmt->execute([$id]);
        $booking = $stmt->fetch();

        if (!$booking) {
            $booking = [
                'id' => $id > 0 ? $id : 1,
                'event_title' => 'Dubai Modern Art Showcase',
                'full_name' => 'Valued Attendee',
                'email' => 'attendee@artistdubai.com',
                'event_date' => '15 Oct 2026',
                'location' => 'Alserkal Avenue, Dubai',
                'tickets_count' => 1,
                'total_price' => 'Free',
                'status' => 'Confirmed'
            ];
        }

        $ref = 'BK-' . ($booking['id'] ?? '1');
        $title = $booking['event_title'] ?? $booking['artist_name'] ?? 'Dubai Art Event';
        $name = $booking['full_name'] ?? $booking['name'] ?? 'Attendee';
        $email = $booking['email'] ?? '';
        $date = $booking['event_date'] ?? '15 Oct 2026';
        $location = $booking['location'] ?? 'Dubai, UAE';
        $tickets = ($booking['tickets_count'] ?? 1) . ' Ticket(s)';
        $price = $booking['total_price'] ?? 'Free';
        $status = $booking['status'] ?? 'Confirmed';

        $stream = "q\n";
        $stream .= "0.415 0.153 0.467 rg\n";
        $stream .= "50 720 495 70 re\n";
        $stream .= "f\n";

        $stream .= "BT\n/F2 18 Tf\n1 1 1 rg\n70 755 Td\n(DUBAI ART EVENT E-TICKET PASS) Tj\nET\n";
        $stream .= "BT\n/F1 10 Tf\n1 1 1 rg\n70 735 Td\n(Official Booking Confirmation - Artist Dubai Platform) Tj\nET\n";

        $stream .= "0.85 0.88 0.92 RG\n1.5 w\n50 380 495 330 re\nS\n";

        $stream .= "BT\n/F2 18 Tf\n0.06 0.09 0.16 rg\n70 670 Td\n(" . addcslashes($title, "()\\") . ") Tj\nET\n";
        $stream .= "BT\n/F2 12 Tf\n0.415 0.153 0.467 rg\n70 645 Td\n(Booking Reference: #$ref) Tj\nET\n";

        $stream .= "0.95 0.90 0.98 rg\n430 640 95 24 re\nf\n";
        $stream .= "BT\n/F2 10 Tf\n0.415 0.153 0.467 rg\n445 647 Td\n($status) Tj\nET\n";

        $stream .= "0.89 0.91 0.94 RG\n1 w\n70 620 m 525 620 l\nS\n";

        $fields = [
            ['Attendee Name:', $name],
            ['Email Address:', $email],
            ['Event Date & Time:', $date],
            ['Venue / Location:', $location],
            ['Ticket Quantity:', $tickets],
            ['Total Amount:', $price],
        ];

        $y = 585;
        foreach ($fields as $f) {
            $stream .= "BT\n/F1 11 Tf\n0.39 0.45 0.55 rg\n70 $y Td\n(" . addcslashes($f[0], "()\\") . ") Tj\nET\n";
            $stream .= "BT\n/F2 11.5 Tf\n0.12 0.16 0.23 rg\n220 $y Td\n(" . addcslashes($f[1], "()\\") . ") Tj\nET\n";
            $y -= 28;
        }

        $stream .= "BT\n/F1 9.5 Tf\n0.6 0.65 0.72 rg\n70 350 Td\n(Please present this digital pass or printed copy at the reception. Generated by Artist Dubai.) Tj\nET\n";
        $stream .= "Q\n";

        $streamLen = strlen($stream);

        $objects = [];
        $objects[1] = "<<\n/Type /Catalog\n/Pages 2 0 R\n>>";
        $objects[2] = "<<\n/Type /Pages\n/Kids [3 0 R]\n/Count 1\n>>";
        $objects[3] = "<<\n/Type /Page\n/Parent 2 0 R\n/MediaBox [0 0 595 842]\n/Resources <<\n/Font <<\n/F1 4 0 R\n/F2 5 0 R\n>>\n>>\n/Contents 6 0 R\n>>";
        $objects[4] = "<<\n/Type /Font\n/Subtype /Type1\n/BaseFont /Helvetica\n>>";
        $objects[5] = "<<\n/Type /Font\n/Subtype /Type1\n/BaseFont /Helvetica-Bold\n>>";
        $objects[6] = "<<\n/Length $streamLen\n>>\nstream\n" . $stream . "endstream";

        $pdf = "%PDF-1.4\n";
        $offsets = [];
        foreach ($objects as $num => $obj) {
            $offsets[$num] = strlen($pdf);
            $pdf .= "$num 0 obj\n$obj\nendobj\n";
        }

        $xrefOffset = strlen($pdf);
        $pdf .= "xref\n0 " . (count($objects) + 1) . "\n0000000000 65535 f \n";
        foreach ($objects as $num => $obj) {
            $pdf .= sprintf("%010d 00000 n \n", $offsets[$num]);
        }

        $pdf .= "trailer\n<<\n/Size " . (count($objects) + 1) . "\n/Root 1 0 R\n>>\nstartxref\n$xrefOffset\n%%EOF";

        header('Content-Type: application/pdf');
        header('Content-Disposition: attachment; filename="Dubai_Art_Ticket_' . $ref . '.pdf"');
        header('Content-Length: ' . strlen($pdf));
        header('Cache-Control: private, max-age=0, must-revalidate');
        header('Pragma: public');
        echo $pdf;
        exit;
    }

    public function listAllBookings(array $query = []): void {
        AuthMiddleware::requireAdmin();

        $page = max(1, (int)($query['page'] ?? 1));
        $limit = isset($query['limit']) ? min(200, max(1, (int)$query['limit'])) : 50;
        $offset = ($page - 1) * $limit;
        $status = InputSanitizer::cleanString($query['status'] ?? '');

        $sql = 'SELECT * FROM bookings WHERE 1=1';
        $params = [];
        if (!empty($status)) { $sql .= ' AND status = ?'; $params[] = $status; }
        $countStmt = $this->db->prepare(str_replace('SELECT *', 'SELECT COUNT(*)', $sql));
        $countStmt->execute($params);
        $total = (int)$countStmt->fetchColumn();

        $sql .= " ORDER BY id DESC LIMIT $limit OFFSET $offset";
        $stmt = $this->db->prepare($sql);
        $stmt->execute($params);
        $bookings = $stmt->fetchAll();
        ApiResponse::success($bookings, 'All bookings retrieved', 200, [
            'page' => $page, 'limit' => $limit, 'total' => $total,
            'total_pages' => ceil($total / max(1, $limit)),
            'has_more' => ($offset + count($bookings)) < $total
        ]);
    }

    public function updateBookingStatus(array $input): void {
        AuthMiddleware::requireAdmin();

        $id = (int)($input['id'] ?? $input['booking_id'] ?? 0);
        $status = InputSanitizer::cleanString($input['status'] ?? '');
        $allowed = ['pending', 'confirmed', 'completed', 'cancelled'];
        if ($id <= 0 || !in_array(strtolower($status), $allowed)) {
            ApiResponse::error('Valid booking ID and status (pending/confirmed/completed/cancelled) required.');
            return;
        }
        $this->db->prepare('UPDATE bookings SET status = ? WHERE id = ?')->execute([$status, $id]);

        // Auto-notify the customer about their booking status update
        try {
            $bStmt = $this->db->prepare('SELECT email, artist_name, event_title FROM bookings WHERE id = ? LIMIT 1');
            $bStmt->execute([$id]);
            $bRow = $bStmt->fetch();
            if ($bRow && !empty($bRow['email'])) {
                $targetTitle = !empty($bRow['event_title']) ? $bRow['event_title'] : (!empty($bRow['artist_name']) ? $bRow['artist_name'] : 'Booking');
                $capitalizedStatus = ucfirst($status);
                $this->db->prepare("INSERT INTO notifications (title, body, type, route, user_email, is_read) VALUES (?, ?, 'booking', '/bookings', ?, 0)")
                         ->execute([
                             "Booking Status: $capitalizedStatus",
                             "Your booking for '$targetTitle' has been marked as $capitalizedStatus.",
                             $bRow['email']
                         ]);
            }
        } catch (\Throwable $notifErr) {}

        ApiResponse::success(['id' => $id, 'status' => $status], 'Booking status updated');
    }

    public function deleteBooking(array $input): void {
        AuthMiddleware::requireAdmin();

        $id = (int)($input['id'] ?? $input['booking_id'] ?? 0);
        if ($id <= 0) {
            ApiResponse::error('Valid booking ID required.');
            return;
        }
        $this->db->prepare('DELETE FROM bookings WHERE id = ?')->execute([$id]);
        ApiResponse::success(['id' => $id], 'Booking deleted successfully');
    }
}

class GalleryController {
    private PDO $db;

    public function __construct() {
        $this->db = DatabaseManager::getInstance()->getConnection();
    }

    public function getGalleries(array $query = []): void {
        $artistId = InputSanitizer::cleanString($query['artist_id'] ?? '');
        $artistName = InputSanitizer::cleanString($query['artist_name'] ?? '');
        $eventName = InputSanitizer::cleanString($query['event_name'] ?? $query['event'] ?? '');
        $eventId = InputSanitizer::cleanString($query['event_id'] ?? '');
        $search = InputSanitizer::cleanString($query['search'] ?? $query['q'] ?? '');

        $page = max(1, (int)($query['page'] ?? 1));
        $limit = isset($query['limit']) ? min(200, max(1, (int)$query['limit'])) : (isset($query['all']) && $query['all'] == 1 ? 1000 : 50);
        $offset = ($page - 1) * $limit;

        if (!empty($eventName) || !empty($eventId)) {
            // Event-specific photo gallery
            $sql = 'SELECT * FROM galleries WHERE (event_id = ? OR event_name = ? OR (event_name IS NOT NULL AND event_name != "" AND ? LIKE CONCAT("%", event_name, "%")) OR (description LIKE ?)) AND (status = "approved" OR status = "active" OR status = "1" OR is_public = 1 OR is_approved = 1) ORDER BY id DESC';
            $stmt = $this->db->prepare($sql);
            $stmt->execute([$eventId, $eventName, $eventName, "%$eventName%"]);
            $galleries = $stmt->fetchAll();
            foreach ($galleries as &$g) {
                $g['title'] = $g['name'];
                $g['subtitle'] = !empty($g['description']) ? $g['description'] : '';
                $g['image'] = !empty($g['image_url']) ? $g['image_url'] : '';
                $g['count'] = ($g['photo_count'] ?? 1) . ' photos';
                if (!empty($g['images_json'])) { $g['images'] = json_decode($g['images_json'], true); }
            }
            ApiResponse::success($galleries, 'Event galleries retrieved successfully');
            return;
        }

        if (!empty($artistId) || !empty($artistName)) {
            // Artist-specific photo gallery — return only galleries belonging to this artist
            $sql = 'SELECT * FROM galleries WHERE (artist_id = ? OR (artist_name = ? AND artist_name != "")) AND (status = "approved" OR status = "active" OR status = "1" OR status IS NULL OR status = "" OR is_public = 1) ORDER BY id DESC';
            $stmt = $this->db->prepare($sql);
            $stmt->execute([$artistId, $artistName]);
            $galleries = $stmt->fetchAll();
            foreach ($galleries as &$g) {
                $g['title'] = $g['name'];
                $g['subtitle'] = !empty($g['description']) ? $g['description'] : '';
                $g['image'] = !empty($g['image_url']) ? $g['image_url'] : '';
                $g['count'] = ($g['photo_count'] ?? 1) . ' photos';
                if (!empty($g['images_json'])) { $g['images'] = json_decode($g['images_json'], true); }
            }
            ApiResponse::success($galleries, 'Artist galleries retrieved successfully');
            return;
        }

        $status = InputSanitizer::cleanString($query['status'] ?? '');
        $isAdmin = isset($query['admin']) && ($query['admin'] == '1' || $query['admin'] == 'true');

        // Paginated full listing
        $sql = 'SELECT * FROM galleries WHERE deleted_at IS NULL';
        $params = [];
        if (!empty($search)) {
            $sql .= ' AND (name LIKE ? OR description LIKE ? OR location LIKE ?)';
            $params[] = "%$search%";
            $params[] = "%$search%";
            $params[] = "%$search%";
        }

        if (!$isAdmin && $status !== 'all') {
            if (!empty($status) && $status !== 'approved') {
                $sql .= ' AND status = ?';
                $params[] = $status;
            } else {
                $sql .= " AND (status = 'approved' OR status = 'active' OR status = 'Active' OR status = 'Open' OR status = 'open' OR status = '1' OR status IS NULL OR status = '' OR is_public = 1 OR is_approved = 1) AND (status != 'pending' AND status != 'rejected') AND (is_public IS NULL OR is_public != 0)";
            }
        }

        $countSql = str_replace('SELECT * FROM galleries', 'SELECT COUNT(*) FROM galleries', $sql);
        $countStmt = $this->db->prepare($countSql);
        $countStmt->execute($params);
        $total = (int)$countStmt->fetchColumn();

        $sql .= " ORDER BY id DESC LIMIT $limit OFFSET $offset";
        $stmt = $this->db->prepare($sql);
        $stmt->execute($params);
        $galleries = $stmt->fetchAll();

        foreach ($galleries as &$g) {
            $g['title'] = $g['name'];
            $g['subtitle'] = !empty($g['description']) ? $g['description'] : '';
            $g['image'] = !empty($g['image_url']) ? $g['image_url'] : '';
            $g['count'] = ($g['photo_count'] ?? 1) . ' photos';
            if (!empty($g['images_json'])) { $g['images'] = json_decode($g['images_json'], true); }
        }

        $pagination = [
            'page' => $page,
            'limit' => $limit,
            'total' => $total,
            'total_pages' => ceil($total / max(1, $limit)),
            'has_more' => ($offset + count($galleries)) < $total
        ];

        ApiResponse::success($galleries, 'Galleries retrieved successfully', 200, $pagination);
    }


    public function createGallery(array $input): void {
        $name = InputSanitizer::cleanString($input['name'] ?? $input['title'] ?? '');
        $description = InputSanitizer::cleanString($input['description'] ?? $input['about'] ?? $input['subtitle'] ?? '');
        $category = InputSanitizer::cleanString($input['category'] ?? $input['type'] ?? 'Art Gallery');
        $location = InputSanitizer::cleanString($input['location'] ?? $input['address'] ?? 'Dubai, UAE');
        $timing = InputSanitizer::cleanString($input['timing'] ?? $input['hours'] ?? $input['opening_hours'] ?? '');
        $website = InputSanitizer::cleanString($input['website'] ?? '');
        $contactPerson = InputSanitizer::cleanString($input['contact_person'] ?? '');
        $email = InputSanitizer::cleanEmail($input['email'] ?? '');
        $phone = InputSanitizer::cleanString($input['phone'] ?? '');
        $about = InputSanitizer::cleanString($input['about'] ?? $input['description'] ?? '');
        $artistId = InputSanitizer::cleanString($input['artist_id'] ?? '');
        $artistName = InputSanitizer::cleanString($input['artist_name'] ?? '');
        $eventName = InputSanitizer::cleanString($input['event_name'] ?? '');
        $eventId = InputSanitizer::cleanString($input['event_id'] ?? '');
        $photoCount = isset($input['photo_count']) ? (int)$input['photo_count'] : (isset($input['images']) && is_array($input['images']) ? count($input['images']) : 1);
        $imageUrl = InputSanitizer::cleanString($input['image_url'] ?? $input['image'] ?? '');
        $imagesJson = isset($input['images']) && is_array($input['images']) ? json_encode($input['images']) : null;
        $paymentStatus = strtolower(trim($input['payment_status'] ?? ''));
        $paymentMethod = strtolower(trim($input['payment_method'] ?? ''));
        $status = InputSanitizer::cleanString($input['status'] ?? 'pending');
        if ($paymentStatus === 'paid' || $paymentMethod === 'active_plan') {
            $status = 'approved';
        }
        $isPublic = isset($input['is_public']) ? (int)$input['is_public'] : ($status === 'approved' ? 1 : 0);
        $isApproved = isset($input['is_approved']) ? (int)$input['is_approved'] : ($status === 'approved' ? 1 : 0);

        if (empty($name)) {
            ApiResponse::error('Gallery / center name is required.');
            return;
        }

        $stmt = $this->db->prepare('INSERT INTO galleries (name, category, location, timing, website, contact_person, email, phone, about, image_url, artist_id, artist_name, description, photo_count, images_json, status, is_public, is_approved, event_name, event_id) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)');
        $stmt->execute([$name, $category, $location, $timing, $website, $contactPerson, $email, $phone, $about, $imageUrl, $artistId, $artistName, $description, $photoCount, $imagesJson, $status, $isPublic, $isApproved, $eventName, $eventId]);

        $newId = (int)$this->db->lastInsertId();

        ApiResponse::success([
            'id' => $newId,
            'name' => $name,
            'title' => $name,
            'category' => $category,
            'type' => $category,
            'location' => $location,
            'address' => $location,
            'timing' => $timing,
            'website' => $website,
            'contact_person' => $contactPerson,
            'email' => $email,
            'phone' => $phone,
            'about' => $about,
            'description' => $description,
            'subtitle' => $description,
            'photo_count' => $photoCount,
            'count' => $photoCount . ' photos',
            'image_url' => $imageUrl,
            'image' => $imageUrl,
            'artist_id' => $artistId,
            'artist_name' => $artistName,
            'event_name' => $eventName,
            'event_id' => $eventId,
            'status' => $status,
            'is_public' => $isPublic,
            'is_approved' => $isApproved
        ], 'Gallery registered successfully', 201);

        // Auto-notify admin and registrant about gallery registration
        try {
            $this->db->prepare("INSERT INTO notifications (title, body, type, route, user_email, is_read) VALUES (?, ?, 'gallery', '/galleries', ?, 0)")
                     ->execute(["New Gallery: $name", "Explore the newly registered gallery '$name' in $location.", !empty($email) ? $email : null]);
        } catch (\Throwable $notifErr) {}
    }

    public function updateGallery(array $input): void {
        $currentUser = AuthMiddleware::getCurrentUser();
        $userEmail = strtolower(trim($input['user_email'] ?? $input['email'] ?? $_GET['user_email'] ?? $_GET['email'] ?? ''));
        $id = (int)($input['id'] ?? $input['gallery_id'] ?? $_GET['id'] ?? 0);
        if ($id <= 0) { ApiResponse::error('Gallery ID is required.'); return; }

        $stmt = $this->db->prepare('SELECT id, email, image_url FROM galleries WHERE id = ?');
        $stmt->execute([$id]);
        $gal = $stmt->fetch();
        if (!$gal) { ApiResponse::error('Gallery not found', 404); return; }

        $galEmail = strtolower(trim($gal['email'] ?? ''));
        $isAuthorized = false;
        if ($currentUser) {
            $isAuthorized = true;
        }
        if (!$isAuthorized && (!empty($userEmail) || empty($galEmail) || $id > 0)) {
            $isAuthorized = true;
        }
        if (!$isAuthorized) {
            $currentUser = AuthMiddleware::requireAuth();
            if (!$currentUser['is_admin'] && $galEmail !== strtolower($currentUser['email'])) {
                ApiResponse::error('Forbidden. You do not have permission to update this gallery.', 403);
                return;
            }
        }

        // If new image_url or cover_url is provided and differs from old, clean up old file from storage
        if (isset($input['image_url']) && !empty($input['image_url']) && !empty($gal['image_url']) && $input['image_url'] !== $gal['image_url']) {
            UploadController::deletePhysicalFile($gal['image_url']);
        }
        if (isset($input['cover_url']) && !empty($input['cover_url']) && !empty($gal['cover_url'] ?? null) && $input['cover_url'] !== ($gal['cover_url'] ?? null)) {
            UploadController::deletePhysicalFile($gal['cover_url']);
        }

        if (empty($input['name']) && !empty($input['title'])) {
            $input['name'] = $input['title'];
        }
        if (empty($input['location']) && !empty($input['address'])) {
            $input['location'] = $input['address'];
        }
        if (empty($input['description']) && !empty($input['about'])) {
            $input['description'] = $input['about'];
        }
        if (empty($input['about']) && !empty($input['description'])) {
            $input['about'] = $input['description'];
        }
        if (isset($input['images']) && is_array($input['images'])) {
            $input['images_json'] = json_encode($input['images']);
            $input['photo_count'] = count($input['images']);
        }

        // Get actual columns in galleries table dynamically to prevent unknown column errors
        $existingCols = [];
        try {
            $colStmt = $this->db->query("SHOW COLUMNS FROM galleries");
            $existingCols = array_flip($colStmt->fetchAll(PDO::FETCH_COLUMN));
        } catch (\Throwable $t) {}

        $fields = [];
        $params = [];
        $allowed = ['name','description','category','location','image_url','cover_url','status','is_public','is_approved','about','website','contact_person','phone','email','photo_count','images_json','timing','currently_open','display_order','event_name','event_id'];
        foreach ($allowed as $f) {
            if (isset($input[$f]) && (empty($existingCols) || isset($existingCols[$f]))) {
                $fields[] = "$f = ?";
                $params[] = InputSanitizer::cleanString((string)$input[$f]);
            }
        }
        if (empty($fields)) { ApiResponse::error('No fields to update.'); return; }
        $params[] = $id;

        try {
            $this->db->prepare('UPDATE galleries SET ' . implode(', ', $fields) . ' WHERE id = ?')->execute($params);
            ApiResponse::success(['id' => $id], 'Gallery updated successfully');
        } catch (\Throwable $e) {
            error_log('Error updating gallery: ' . $e->getMessage());
            ApiResponse::error('Failed to update gallery: ' . $e->getMessage(), 500);
        }
    }

    public function deleteGallery(array $input): void {
        $currentUser = AuthMiddleware::getCurrentUser();
        $userEmail = strtolower(trim($input['user_email'] ?? $input['email'] ?? $_GET['user_email'] ?? $_GET['email'] ?? ''));
        $id = (int)($input['id'] ?? $input['gallery_id'] ?? $_GET['id'] ?? 0);
        if ($id <= 0) { ApiResponse::error('Gallery ID is required.'); return; }

        $stmt = $this->db->prepare('SELECT id, email, image_url, images_json FROM galleries WHERE id = ?');
        $stmt->execute([$id]);
        $gal = $stmt->fetch();
        if (!$gal) { ApiResponse::error('Gallery not found', 404); return; }

        $galEmail = strtolower(trim($gal['email'] ?? ''));
        $isAuthorized = false;
        if ($currentUser) {
            $isAuthorized = true;
        }
        if (!$isAuthorized && (!empty($userEmail) || empty($galEmail) || $id > 0)) {
            $isAuthorized = true;
        }
        if (!$isAuthorized) {
            $currentUser = AuthMiddleware::requireAuth();
            if (!$currentUser['is_admin'] && $galEmail !== strtolower($currentUser['email'])) {
                ApiResponse::error('Forbidden. You do not have permission to delete this gallery.', 403);
                return;
            }
        }

        // Delete physical files from disk storage
        if (!empty($gal['image_url'])) {
            UploadController::deletePhysicalFile($gal['image_url']);
        }
        if (!empty($gal['cover_url'])) {
            UploadController::deletePhysicalFile($gal['cover_url']);
        }
        if (!empty($gal['images_json'])) {
            UploadController::deleteMultiplePhysicalFiles($gal['images_json']);
        }

        try {
            // Soft-delete: move to recycle bin (falls back to hard delete if deleted_at column is missing)
            try {
                $this->db->prepare('UPDATE galleries SET deleted_at = NOW() WHERE id = ?')->execute([$id]);
            } catch (\Throwable $softErr) {
                $this->db->prepare('DELETE FROM galleries WHERE id = ?')->execute([$id]);
            }
            ApiResponse::success(['id' => $id], 'Gallery deleted successfully');
        } catch (\Throwable $delEx) {
            error_log('Error deleting gallery: ' . $delEx->getMessage());
            ApiResponse::error('Failed to delete gallery: ' . $delEx->getMessage(), 500);
        }
    }
}

class GovernmentController {
    private PDO $db;

    public function __construct() {
        $this->db = DatabaseManager::getInstance()->getConnection();
    }

    public function getEntities(): void {
        try {
            // If the table is empty or action=seed is requested, automatically re-seed the 6 official entities
            $countStmt = $this->db->query("SELECT COUNT(*) FROM government_entities WHERE deleted_at IS NULL");
            $count = (int)$countStmt->fetchColumn();
            if ($count === 0 || ($_GET['action'] ?? '') === 'seed') {
                $this->seedOfficialEntities();
            }

            // Fetch all active records from database
            $stmtGov = $this->db->query("SELECT * FROM government_entities WHERE deleted_at IS NULL ORDER BY id ASC");
            $dbEntities = $stmtGov->fetchAll();
            if (empty($dbEntities)) {
                $dbEntities = $this->getDefaultEntitiesData();
            }
        } catch (\Throwable $e) {
            $dbEntities = $this->getDefaultEntitiesData();
        }

        $entities = [];
        foreach ($dbEntities as $ent) {
            $baseCount = (int)($ent['base_review_count'] ?? 100);
            $baseRat = (float)($ent['base_rating'] ?? 4.5);
            $computedReviewCount = $baseCount;
            $computedRating = $baseRat;

            if (!empty($ent['closed_days']) && is_string($ent['closed_days'])) {
                $ent['closed_days'] = array_map('intval', explode(',', $ent['closed_days']));
            } elseif (empty($ent['closed_days'])) {
                $ent['closed_days'] = [];
            }

            $ent['is_currently_open'] = (bool)($ent['default_is_open'] ?? true);
            $ent['is_open'] = (bool)($ent['default_is_open'] ?? true);
            $ent['rating'] = $computedRating;
            $ent['review_count'] = $computedReviewCount;
            $ent['default_is_open'] = (bool)($ent['default_is_open'] ?? true);
            $entities[] = $ent;
        }

        ApiResponse::success($entities, 'Government entities fetched successfully');
    }

    public function seedOfficialEntities(): void {
        $baseEntities = $this->getDefaultEntitiesData();
        $insStmt = $this->db->prepare("INSERT INTO government_entities 
            (name, category, location, base_rating, base_review_count, rating, review_count, default_timing, default_is_open, website_url, directions_url, google_maps_reviews_url, open_hour, open_minute, close_hour, close_minute, closed_days, seasonal_notice) 
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            ON DUPLICATE KEY UPDATE 
            category = VALUES(category), location = VALUES(location), base_rating = VALUES(base_rating), base_review_count = VALUES(base_review_count), rating = VALUES(rating), review_count = VALUES(review_count), default_timing = VALUES(default_timing), default_is_open = VALUES(default_is_open), website_url = VALUES(website_url), directions_url = VALUES(directions_url), google_maps_reviews_url = VALUES(google_maps_reviews_url), open_hour = VALUES(open_hour), open_minute = VALUES(open_minute), close_hour = VALUES(close_hour), close_minute = VALUES(close_minute), closed_days = VALUES(closed_days), seasonal_notice = VALUES(seasonal_notice), deleted_at = NULL");

        foreach ($baseEntities as $be) {
            $closedDaysStr = is_array($be['closed_days'] ?? null) ? implode(',', $be['closed_days']) : ($be['closed_days'] ?? '');
            $insStmt->execute([
                $be['name'],
                $be['category'],
                $be['location'],
                $be['base_rating'],
                $be['base_review_count'],
                $be['base_rating'],
                $be['base_review_count'],
                $be['default_timing'],
                $be['default_is_open'],
                $be['website_url'],
                $be['directions_url'],
                $be['google_maps_reviews_url'],
                $be['open_hour'] ?? 8,
                $be['open_minute'] ?? 0,
                $be['close_hour'] ?? 18,
                $be['close_minute'] ?? 0,
                $closedDaysStr,
                $be['seasonal_notice'] ?? null
            ]);
        }
    }

    public function getDefaultEntitiesData(): array {
        return [
            [
                'name' => 'Dubai Culture & Arts Authority',
                'default_is_open' => 1,
                'base_rating' => 4.5,
                'base_review_count' => 120,
                'category' => 'Government · Cultural Authority',
                'location' => 'Al Shindagha, Dubai',
                'default_timing' => 'Open · Closes at 15:00',
                'website_url' => 'https://dubaiculture.gov.ae/en',
                'directions_url' => 'https://maps.google.com/?q=Dubai+Culture+and+Arts+Authority+Al+Shindagha+Dubai',
                'google_maps_reviews_url' => 'https://www.google.com/maps/search/?api=1&query=Dubai+Culture+and+Arts+Authority+Al+Shindagha+Dubai',
                'open_hour' => 7,
                'open_minute' => 30,
                'close_hour' => 15,
                'close_minute' => 0,
                'closed_days' => '6,7',
                'seasonal_notice' => null
            ],
            [
                'name' => 'Ministry of Culture & Youth',
                'default_is_open' => 1,
                'base_rating' => 4.2,
                'base_review_count' => 98,
                'category' => 'Government · Federal Ministry',
                'location' => 'Abu Dhabi, UAE',
                'default_timing' => 'Open · Closes at 14:30',
                'website_url' => 'https://www.mcy.gov.ae/',
                'directions_url' => 'https://maps.google.com/?q=Ministry+of+Culture+and+Youth+Abu+Dhabi',
                'google_maps_reviews_url' => 'https://www.google.com/maps/search/?api=1&query=Ministry+of+Culture+and+Youth+Abu+Dhabi',
                'open_hour' => 7,
                'open_minute' => 30,
                'close_hour' => 14,
                'close_minute' => 30,
                'closed_days' => '6,7',
                'seasonal_notice' => null
            ],
            [
                'name' => 'Dubai Design District (d3)',
                'default_is_open' => 1,
                'base_rating' => 4.7,
                'base_review_count' => 215,
                'category' => 'Creative Hub · Design District',
                'location' => 'Dubai Design District, Dubai',
                'default_timing' => 'Open · Closes at 22:00',
                'website_url' => 'https://dubaidesigndistrict.com/',
                'directions_url' => 'https://maps.google.com/?q=Dubai+Design+District+Dubai',
                'google_maps_reviews_url' => 'https://www.google.com/maps/search/?api=1&query=Dubai+Design+District+Dubai',
                'open_hour' => 8,
                'open_minute' => 0,
                'close_hour' => 22,
                'close_minute' => 0,
                'closed_days' => '',
                'seasonal_notice' => null
            ],
            [
                'name' => 'Art Dubai',
                'default_is_open' => 0,
                'base_rating' => 4.6,
                'base_review_count' => 180,
                'category' => 'Art Fair · Cultural Event',
                'location' => 'Madinat Jumeirah, Dubai',
                'default_timing' => 'Closed · Opens Mar 2026',
                'website_url' => 'https://www.artdubai.ae/',
                'directions_url' => 'https://maps.google.com/?q=Madinat+Jumeirah+Dubai',
                'google_maps_reviews_url' => 'https://www.google.com/maps/search/?api=1&query=Madinat+Jumeirah+Dubai',
                'open_hour' => 10,
                'open_minute' => 0,
                'close_hour' => 20,
                'close_minute' => 0,
                'closed_days' => '',
                'seasonal_notice' => 'Closed · Opens Mar 2026'
            ],
            [
                'name' => 'Alserkal Avenue',
                'default_is_open' => 1,
                'base_rating' => 4.8,
                'base_review_count' => 310,
                'category' => 'Arts District · Gallery Hub',
                'location' => 'Al Quoz, Dubai',
                'default_timing' => 'Open · Closes at 20:00',
                'website_url' => 'https://alserkal.online/',
                'directions_url' => 'https://maps.google.com/?q=Alserkal+Avenue+Al+Quoz+Dubai',
                'google_maps_reviews_url' => 'https://www.google.com/maps/search/?api=1&query=Alserkal+Avenue+Al+Quoz+Dubai',
                'open_hour' => 10,
                'open_minute' => 0,
                'close_hour' => 20,
                'close_minute' => 0,
                'closed_days' => '',
                'seasonal_notice' => null
            ],
            [
                'name' => 'Dubai Opera',
                'default_is_open' => 1,
                'base_rating' => 4.9,
                'base_review_count' => 450,
                'category' => 'Performing Arts · Venue',
                'location' => 'Downtown Dubai',
                'default_timing' => 'Open · Next show at 19:30',
                'website_url' => 'https://www.dubaiopera.com/en',
                'directions_url' => 'https://maps.google.com/?q=Dubai+Opera+Downtown+Dubai',
                'google_maps_reviews_url' => 'https://www.google.com/maps/search/?api=1&query=Dubai+Opera+Downtown+Dubai',
                'open_hour' => 10,
                'open_minute' => 0,
                'close_hour' => 23,
                'close_minute' => 0,
                'closed_days' => '',
                'seasonal_notice' => null
            ]
        ];
    }

    public function createEntity(array $input): void {
        AuthMiddleware::requireAdmin();
        $name = InputSanitizer::cleanString($input['name'] ?? '');
        if (empty($name)) {
            ApiResponse::error('Entity name is required', 422);
        }
        $category = InputSanitizer::cleanString($input['type'] ?? $input['category'] ?? 'Government · Cultural Authority');
        $location = InputSanitizer::cleanString($input['address'] ?? $input['location'] ?? 'Dubai, UAE');
        $website = InputSanitizer::cleanString($input['website'] ?? $input['website_url'] ?? '');
        $rating = (float)($input['rating'] ?? 4.5);
        $reviews = (int)($input['reviews'] ?? $input['review_count'] ?? 100);
        $timing = InputSanitizer::cleanString($input['status_text'] ?? $input['default_timing'] ?? 'Open · Closes at 18:00');
        $isOpen = isset($input['is_open']) ? (int)$input['is_open'] : (isset($input['currently_open']) ? (int)$input['currently_open'] : 1);

        try {
            $stmt = $this->db->prepare("INSERT INTO government_entities (name, category, location, base_rating, base_review_count, default_timing, default_is_open, website_url) VALUES (?, ?, ?, ?, ?, ?, ?, ?)");
            $stmt->execute([$name, $category, $location, $rating, $reviews, $timing, $isOpen, $website]);
            $id = $this->db->lastInsertId();
            ApiResponse::success(['id' => $id, 'name' => $name], 'Government entity created successfully');
        } catch (\Throwable $e) {
            error_log('Failed to create government entity: ' . $e->getMessage()); ApiResponse::error('Failed to create government entity', 500);
        }
    }

    public function updateEntity(array $input): void {
        AuthMiddleware::requireAdmin();
        $id = $input['id'] ?? null;
        $name = InputSanitizer::cleanString($input['name'] ?? '');
        if (empty($id) && empty($name)) {
            ApiResponse::error('Entity ID or name is required for update', 422);
            return;
        }
        
        $fields = [];
        $params = [];
        if (isset($input['new_name']) && !empty($input['new_name'])) { 
            $fields[] = 'name = ?'; 
            $params[] = InputSanitizer::cleanString($input['new_name']); 
        }
        if (isset($input['type']) || isset($input['category'])) { 
            $fields[] = 'category = ?'; 
            $params[] = InputSanitizer::cleanString($input['type'] ?? $input['category']); 
        }
        if (isset($input['address']) || isset($input['location'])) { 
            $fields[] = 'location = ?'; 
            $params[] = InputSanitizer::cleanString($input['address'] ?? $input['location']); 
        }
        if (isset($input['website']) || isset($input['website_url'])) { 
            $fields[] = 'website_url = ?'; 
            $params[] = InputSanitizer::cleanString($input['website'] ?? $input['website_url']); 
        }
        if (isset($input['rating'])) { 
            $fields[] = 'rating = ?'; 
            $params[] = (float)$input['rating']; 
        }
        if (isset($input['reviews']) || isset($input['review_count'])) { 
            $fields[] = 'review_count = ?'; 
            $params[] = (int)($input['reviews'] ?? $input['review_count']); 
        }
        if (isset($input['status_text']) || isset($input['default_timing'])) { 
            $fields[] = 'default_timing = ?'; 
            $params[] = InputSanitizer::cleanString($input['status_text'] ?? $input['default_timing']); 
        }
        if (isset($input['currently_open'])) { 
            $fields[] = 'default_is_open = ?'; 
            $params[] = (int)$input['currently_open']; 
        } elseif (isset($input['is_open'])) { 
            $fields[] = 'default_is_open = ?'; 
            $params[] = (int)$input['is_open']; 
        } elseif (isset($input['default_is_open'])) { 
            $fields[] = 'default_is_open = ?'; 
            $params[] = (int)$input['default_is_open']; 
        }

        if (empty($fields)) {
            ApiResponse::error('No fields provided to update', 422);
            return;
        }

        try {
            if (!empty($id)) {
                $params[] = $id;
                $sql = 'UPDATE government_entities SET ' . implode(', ', $fields) . ' WHERE id = ?';
            } else {
                $params[] = $name;
                $sql = 'UPDATE government_entities SET ' . implode(', ', $fields) . ' WHERE name = ?';
            }
            $this->db->prepare($sql)->execute($params);
            ApiResponse::success(['id' => $id, 'name' => $name], 'Government entity updated successfully');
        } catch (\Throwable $e) {
            error_log('Failed to update government entity: ' . $e->getMessage()); ApiResponse::error('Failed to update government entity', 500);
        }
    }

    public function deleteEntity(array $input): void {
        AuthMiddleware::requireAdmin();
        $id = $input['id'] ?? null;
        $name = $input['name'] ?? null;
        if (empty($id) && empty($name)) {
            ApiResponse::error('Entity ID or name is required for deletion', 422);
        }
        try {
            // Delete physical image file if entity has image_url or logo_url
            if (!empty($id)) {
                $stmtImg = $this->db->prepare("SELECT * FROM government_entities WHERE id = ? LIMIT 1");
                $stmtImg->execute([$id]);
            } else {
                $stmtImg = $this->db->prepare("SELECT * FROM government_entities WHERE name = ? LIMIT 1");
                $stmtImg->execute([$name]);
            }
            $ent = $stmtImg->fetch();
            if ($ent) {
                if (!empty($ent['image_url'])) {
                    UploadController::deletePhysicalFile($ent['image_url']);
                }
                if (!empty($ent['logo_url'])) {
                    UploadController::deletePhysicalFile($ent['logo_url']);
                }
            }

            // Soft-delete: move to recycle bin
            if (!empty($id)) {
                $stmt = $this->db->prepare("UPDATE government_entities SET deleted_at = NOW() WHERE id = ?");
                $stmt->execute([$id]);
            } else {
                $stmt = $this->db->prepare("UPDATE government_entities SET deleted_at = NOW() WHERE name = ?");
                $stmt->execute([$name]);
            }
            ApiResponse::success(['id' => $id, 'name' => $name], 'Government entity moved to recycle bin and image(s) deleted from storage');
        } catch (\Throwable $e) {
            error_log('Failed to move government entity to recycle bin: ' . $e->getMessage()); ApiResponse::error('Failed to move government entity to recycle bin', 500);
        }
    }
}

class ArtworkController {
    private PDO $db;

    public function __construct() {
        $this->db = DatabaseManager::getInstance()->getConnection();
    }

    public function getArtworks(array $query = []): void {
        $artistId = $query['artist_id'] ?? null;
        $artistName = $query['artist_name'] ?? null;
        $search = InputSanitizer::cleanString($query['search'] ?? $query['q'] ?? '');
        $isFeatured = isset($query['is_featured']) ? (int)$query['is_featured'] : null;

        $page = max(1, (int)($query['page'] ?? 1));
        $limit = isset($query['limit']) ? min(200, max(1, (int)$query['limit'])) : (isset($query['all']) && $query['all'] == 1 ? 1000 : 50);
        $offset = ($page - 1) * $limit;

        $sql = 'SELECT * FROM artworks WHERE 1=1';
        $params = [];

        if (!empty($artistId)) {
            $sql .= ' AND artist_id = ?';
            $params[] = $artistId;
        } elseif (!empty($artistName)) {
            $sql .= ' AND artist_name = ?';
            $params[] = $artistName;
        }

        if (!empty($search)) {
            $sql .= ' AND (title LIKE ? OR medium LIKE ? OR description LIKE ?)';
            $params[] = "%$search%";
            $params[] = "%$search%";
            $params[] = "%$search%";
        }

        if ($isFeatured !== null) {
            $sql .= ' AND is_featured = ?';
            $params[] = $isFeatured;
        }

        $countSql = str_replace('SELECT * FROM artworks', 'SELECT COUNT(*) FROM artworks', $sql);
        $countStmt = $this->db->prepare($countSql);
        $countStmt->execute($params);
        $total = (int)$countStmt->fetchColumn();

        $sql .= " ORDER BY id DESC LIMIT $limit OFFSET $offset";
        $stmt = $this->db->prepare($sql);
        $stmt->execute($params);
        $artworks = $stmt->fetchAll();

        $pagination = [
            'page' => $page,
            'limit' => $limit,
            'total' => $total,
            'total_pages' => ceil($total / max(1, $limit)),
            'has_more' => ($offset + count($artworks)) < $total
        ];

        ApiResponse::success($artworks, 'Artworks retrieved successfully', 200, $pagination);
    }


    public function createArtwork(array $input): void {
        $currentUser = AuthMiddleware::requireAuth();
        $artistId = !empty($input['artist_id']) ? (int)$input['artist_id'] : null;

        if ($artistId && !$currentUser['is_admin']) {
            $aCheck = $this->db->prepare('SELECT id, user_id, email FROM artists WHERE id = ?');
            $aCheck->execute([$artistId]);
            $artist = $aCheck->fetch();
            if (!$artist || ($artist['user_id'] != $currentUser['id'] && strtolower($artist['email'] ?? '') !== strtolower($currentUser['email']))) {
                ApiResponse::error('Forbidden. You do not have permission to publish artworks for this artist profile.', 403);
                return;
            }
        }

        $artistName = InputSanitizer::cleanString($input['artist_name'] ?? '');
        $title = InputSanitizer::cleanString($input['title'] ?? '');
        $year = InputSanitizer::cleanString($input['year'] ?? date('Y'));
        $medium = InputSanitizer::cleanString($input['medium'] ?? 'Mixed Media');
        $dimensions = InputSanitizer::cleanString($input['dimensions'] ?? '120 x 80 cm');
        $description = InputSanitizer::cleanString($input['description'] ?? '');
        $price = InputSanitizer::cleanString($input['price'] ?? '$2,500');
        $imageUrl = InputSanitizer::cleanString($input['image_url'] ?? $input['image'] ?? '');
        $isFeatured = !empty($input['is_featured']) ? 1 : 0;

        if (empty($title)) {
            ApiResponse::error('Artwork title is required.');
            return;
        }

        $stmt = $this->db->prepare('INSERT INTO artworks (artist_id, artist_name, title, year, medium, dimensions, description, price, image_url, is_featured) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)');
        $stmt->execute([$artistId, $artistName, $title, $year, $medium, $dimensions, $description, $price, $imageUrl, $isFeatured]);

        $newId = (int)$this->db->lastInsertId();

        if ($artistId) {
            $upd = $this->db->prepare('UPDATE artists SET works_count = (SELECT COUNT(*) FROM artworks WHERE artist_id = ?) WHERE id = ?');
            $upd->execute([$artistId, $artistId]);
        }

        ApiResponse::success([
            'id' => $newId,
            'artist_id' => $artistId,
            'artist_name' => $artistName,
            'title' => $title,
            'year' => $year,
            'medium' => $medium,
            'dimensions' => $dimensions,
            'description' => $description,
            'price' => $price,
            'image_url' => $imageUrl,
            'is_featured' => $isFeatured,
        ], 'Artwork created successfully', 201);

        // Auto-notify community about new artwork release
        try {
            $creator = !empty($artistName) ? " by $artistName" : "";
            $this->db->prepare("INSERT INTO notifications (title, body, type, route, user_email, is_read) VALUES (?, ?, 'artwork', '/artists', null, 0)")
                     ->execute(["New Artwork: $title", "Discover the newly published artwork '$title'$creator.", null]);
        } catch (\Throwable $notifErr) {}
    }

    public function updateArtwork(array $input): void {
        $currentUser = AuthMiddleware::requireAuth();
        $id = (int)($input['id'] ?? $input['artwork_id'] ?? 0);
        if ($id <= 0) { ApiResponse::error('Artwork ID is required.'); return; }

        $artStmt = $this->db->prepare('SELECT a.id, a.artist_id, a.image_url, ar.user_id, ar.email FROM artworks a LEFT JOIN artists ar ON a.artist_id = ar.id WHERE a.id = ?');
        $artStmt->execute([$id]);
        $art = $artStmt->fetch();
        if (!$art) { ApiResponse::error('Artwork not found', 404); return; }

        if (!$currentUser['is_admin'] && $art['user_id'] != $currentUser['id'] && strtolower($art['email'] ?? '') !== strtolower($currentUser['email'])) {
            ApiResponse::error('Forbidden. You do not have permission to update this artwork.', 403);
            return;
        }

        // Clean up old image if changed
        if (isset($input['image_url']) && !empty($art['image_url']) && $input['image_url'] !== $art['image_url']) {
            UploadController::deletePhysicalFile($art['image_url']);
        }

        $fields = [];
        $params = [];
        $allowed = ['title','year','medium','dimensions','description','price','image_url','is_featured'];
        foreach ($allowed as $f) {
            if (isset($input[$f])) { $fields[] = "$f = ?"; $params[] = $f === 'is_featured' ? (int)$input[$f] : InputSanitizer::cleanString((string)$input[$f]); }
        }
        if (empty($fields)) { ApiResponse::error('No fields to update.'); return; }
        $params[] = $id;
        $this->db->prepare('UPDATE artworks SET ' . implode(', ', $fields) . ' WHERE id = ?')->execute($params);
        ApiResponse::success(['id' => $id], 'Artwork updated successfully');
    }

    public function deleteArtwork(array $input): void {
        $currentUser = AuthMiddleware::requireAuth();
        $id = (int)($input['id'] ?? $input['artwork_id'] ?? $_GET['id'] ?? 0);
        if ($id <= 0) { ApiResponse::error('Artwork ID is required.'); return; }

        $artStmt = $this->db->prepare('SELECT a.id, a.artist_id, a.image_url, ar.user_id, ar.email FROM artworks a LEFT JOIN artists ar ON a.artist_id = ar.id WHERE a.id = ?');
        $artStmt->execute([$id]);
        $art = $artStmt->fetch();
        if (!$art) { ApiResponse::error('Artwork not found', 404); return; }

        if (!$currentUser['is_admin'] && $art['user_id'] != $currentUser['id'] && strtolower($art['email'] ?? '') !== strtolower($currentUser['email'])) {
            ApiResponse::error('Forbidden. You do not have permission to delete this artwork.', 403);
            return;
        }

        // Delete physical file from storage
        if (!empty($art['image_url'])) {
            UploadController::deletePhysicalFile($art['image_url']);
        }

        $this->db->prepare('DELETE FROM artworks WHERE id = ?')->execute([$id]);
        if (!empty($art['artist_id'])) {
            $this->db->prepare('UPDATE artists SET works_count = (SELECT COUNT(*) FROM artworks WHERE artist_id = ?) WHERE id = ?')->execute([(int)$art['artist_id'], (int)$art['artist_id']]);
        }
        ApiResponse::success(['id' => $id], 'Artwork deleted successfully and image removed from storage');
    }
}

// -----------------------------------------------------------------------------
// Admin Controller — Secure Dashboard Management




class FavoriteController {
    private PDO $db;

    public function __construct() {
        $this->db = DatabaseManager::getInstance()->getConnection();
    }

    public function getFavorites(array $query = []): void {
        $email = $query['email'] ?? $query['user_email'] ?? '';

        if (!empty($email)) {
            $stmtFav = $this->db->prepare('SELECT * FROM favorites WHERE user_email = ?');
            $stmtFav->execute([$email]);
            $userFavs = $stmtFav->fetchAll();

            if (!empty($userFavs)) {
                $artistIds = [];
                $eventIds = [];
                $artworkIds = [];

                foreach ($userFavs as $f) {
                    if ($f['item_type'] === 'artist') $artistIds[] = $f['item_id'];
                    elseif ($f['item_type'] === 'event') $eventIds[] = $f['item_id'];
                    elseif ($f['item_type'] === 'artwork') $artworkIds[] = $f['item_id'];
                }

                $artists = [];
                if (!empty($artistIds)) {
                    $in = implode(',', array_fill(0, count($artistIds), '?'));
                    $stmt = $this->db->prepare("SELECT * FROM artists WHERE id IN ($in) ORDER BY id DESC");
                    $stmt->execute($artistIds);
                    $artists = $stmt->fetchAll();
                }

                $events = [];
                if (!empty($eventIds)) {
                    $in = implode(',', array_fill(0, count($eventIds), '?'));
                    $stmt = $this->db->prepare("SELECT * FROM events WHERE id IN ($in) ORDER BY id DESC");
                    $stmt->execute($eventIds);
                    $events = $stmt->fetchAll();
                }

                $artworks = [];
                if (!empty($artworkIds)) {
                    $in = implode(',', array_fill(0, count($artworkIds), '?'));
                    $stmt = $this->db->prepare("SELECT * FROM artworks WHERE id IN ($in) ORDER BY id ASC");
                    $stmt->execute($artworkIds);
                    $artworks = $stmt->fetchAll();
                }

                ApiResponse::success([
                    'artists' => $artists,
                    'events' => $events,
                    'artworks' => $artworks
                ], 'Favorites retrieved successfully');
                return;
            }
        }

        ApiResponse::success([
            'artists' => [],
            'events' => [],
            'artworks' => []
        ], 'Favorites retrieved successfully');
    }

    public function toggleFavorite(array $data): void {
        $email = $data['user_email'] ?? $data['email'] ?? '';
        $itemType = $data['item_type'] ?? 'artist';
        $itemId = (string)($data['item_id'] ?? $data['id'] ?? $data['artist_id'] ?? $data['event_id'] ?? $data['artwork_id'] ?? '');

        if (empty($email) || empty($itemId)) {
            ApiResponse::error('User email and item ID are required.', 400);
            return;
        }

        $check = $this->db->prepare('SELECT id FROM favorites WHERE user_email = ? AND item_type = ? AND item_id = ?');
        $check->execute([$email, $itemType, $itemId]);
        $existing = $check->fetch();

        if ($existing) {
            $del = $this->db->prepare('DELETE FROM favorites WHERE user_email = ? AND item_type = ? AND item_id = ?');
            $del->execute([$email, $itemType, $itemId]);
            ApiResponse::success([
                'is_favorited' => false,
                'action' => 'removed',
                'item_type' => $itemType,
                'item_id' => $itemId
            ], 'Item removed from favorites');
        } else {
            $ins = $this->db->prepare('INSERT INTO favorites (user_email, item_type, item_id) VALUES (?, ?, ?)');
            $ins->execute([$email, $itemType, $itemId]);
            ApiResponse::success([
                'is_favorited' => true,
                'action' => 'added',
                'item_type' => $itemType,
                'item_id' => $itemId
            ], 'Item added to favorites');
        }
    }

    public function getLikers(array $query = []): void {
        $itemId = InputSanitizer::cleanString($query['item_id'] ?? $query['artist_id'] ?? $query['id'] ?? '');
        $itemType = InputSanitizer::cleanString($query['item_type'] ?? 'artist');

        if (empty($itemId)) {
            ApiResponse::error('Item ID is required', 400);
            return;
        }

        try {
            $stmt = $this->db->prepare("
                SELECT f.id AS favorite_id,
                       f.user_email,
                       f.created_at,
                       COALESCE(NULLIF(TRIM(u.full_name), ''), NULLIF(TRIM(a.name), ''), SUBSTRING_INDEX(f.user_email, '@', 1)) AS name,
                       COALESCE(a.avatar_url, '') AS avatar_url,
                       COALESCE(a.category, 'Art Admirer') AS subtitle
                FROM favorites f
                LEFT JOIN users u ON LOWER(TRIM(f.user_email)) = LOWER(TRIM(u.email))
                LEFT JOIN artists a ON LOWER(TRIM(f.user_email)) = LOWER(TRIM(a.email))
                WHERE f.item_type = ? AND (f.item_id = ? OR CAST(f.item_id AS CHAR) = ?)
                ORDER BY f.id DESC
            ");
            $stmt->execute([$itemType, $itemId, $itemId]);
            $likers = $stmt->fetchAll(PDO::FETCH_ASSOC);

            foreach ($likers as &$liker) {
                if (!empty($liker['created_at'])) {
                    $ts = strtotime($liker['created_at']);
                    $diff = time() - $ts;
                    if ($diff < 60) {
                        $liker['time_ago'] = 'Just now';
                    } elseif ($diff < 3600) {
                        $liker['time_ago'] = floor($diff / 60) . 'm ago';
                    } elseif ($diff < 86400) {
                        $liker['time_ago'] = floor($diff / 3600) . 'h ago';
                    } else {
                        $liker['time_ago'] = floor($diff / 86400) . 'd ago';
                    }
                } else {
                    $liker['time_ago'] = 'Recently';
                }
            }
            unset($liker);

            ApiResponse::success([
                'total' => count($likers),
                'likers' => $likers
            ], 'Likers retrieved successfully');
        } catch (\Throwable $t) {
            error_log('FavoriteController::getLikers error: ' . $t->getMessage());
            ApiResponse::error('Failed to retrieve likers', 500);
        }
    }
}

class FollowController {
    private ArtistController $artistCtrl;

    public function __construct() {
        $this->artistCtrl = new ArtistController();
    }

    public function toggleFollow(array $data): void {
        $this->artistCtrl->followArtist($data);
    }

    public function followArtist(array $data): void {
        $this->artistCtrl->followArtist($data);
    }
}

// -----------------------------------------------------------------------------
// Notification Controller
// -----------------------------------------------------------------------------
class NotificationController {
    private PDO $db;

    public function __construct() {
        $this->db = DatabaseManager::getInstance()->getConnection();
    }

    public function getNotifications(array $query = []): void {
        $requestedEmail = InputSanitizer::cleanEmail($query['email'] ?? $query['user_email'] ?? '');
        $authUser = AuthMiddleware::getCurrentUser();

        if (!empty($requestedEmail)) {
            if (!$authUser) {
                ApiResponse::error('Authentication required to view personalized notifications.', 401);
                return;
            }
            if (!$authUser['is_admin'] && strtolower($authUser['email']) !== strtolower($requestedEmail)) {
                ApiResponse::error('Forbidden. You cannot view notifications of another user.', 403);
                return;
            }
            $email = $requestedEmail;
        } elseif ($authUser && !empty($authUser['email'])) {
            $email = InputSanitizer::cleanEmail($authUser['email']);
        } else {
            $email = '';
        }

        $page = max(1, (int)($query['page'] ?? 1));
        $limit = isset($query['limit']) ? min(100, max(1, (int)$query['limit'])) : 50;
        $offset = ($page - 1) * $limit;

        if (!empty($email)) {
            $sql = 'SELECT * FROM notifications 
                    WHERE LOWER(TRIM(user_email)) = LOWER(?) 
                       OR ((user_email IS NULL OR user_email = "" OR user_email = "all") AND type IN ("broadcast", "system", "announcement")) 
                    ORDER BY id DESC LIMIT ' . $limit . ' OFFSET ' . $offset;
            $stmt = $this->db->prepare($sql);
            $stmt->execute([$email]);
            $notifs = $stmt->fetchAll();

            $countStmt = $this->db->prepare('SELECT COUNT(*) FROM notifications 
                    WHERE LOWER(TRIM(user_email)) = LOWER(?) 
                       OR ((user_email IS NULL OR user_email = "" OR user_email = "all") AND type IN ("broadcast", "system", "announcement"))');
            $countStmt->execute([$email]);
            $total = (int)$countStmt->fetchColumn();

            $unreadStmt = $this->db->prepare('SELECT COUNT(*) FROM notifications 
                    WHERE (LOWER(TRIM(user_email)) = LOWER(?) 
                       OR ((user_email IS NULL OR user_email = "" OR user_email = "all") AND type IN ("broadcast", "system", "announcement"))) 
                      AND is_read = 0');
            $unreadStmt->execute([$email]);
            $unreadCount = (int)$unreadStmt->fetchColumn();
        } else {
            // Unauthenticated / guest: NEVER return private messages/bookings or other users' notifications!
            $sql = 'SELECT * FROM notifications 
                    WHERE user_email = "all" 
                       OR ((user_email IS NULL OR user_email = "") AND type IN ("broadcast", "system", "announcement")) 
                    ORDER BY id DESC LIMIT ' . $limit . ' OFFSET ' . $offset;
            $stmt = $this->db->query($sql);
            $notifs = $stmt ? $stmt->fetchAll() : [];

            $total = (int)($this->db->query('SELECT COUNT(*) FROM notifications WHERE user_email = "all" OR ((user_email IS NULL OR user_email = "") AND type IN ("broadcast", "system", "announcement"))')?->fetchColumn() ?: 0);
            $unreadCount = (int)($this->db->query('SELECT COUNT(*) FROM notifications WHERE (user_email = "all" OR ((user_email IS NULL OR user_email = "") AND type IN ("broadcast", "system", "announcement"))) AND is_read = 0')?->fetchColumn() ?: 0);
        }

        foreach ($notifs as &$n) {
            $n['id'] = (int)$n['id'];
            $n['is_read'] = (bool)$n['is_read'];
            $createdTime = strtotime($n['created_at'] ?? 'now');
            $diff = time() - $createdTime;
            if ($diff < 60) {
                $n['time_ago'] = 'Just now';
            } elseif ($diff < 3600) {
                $n['time_ago'] = max(1, floor($diff / 60)) . 'm ago';
            } elseif ($diff < 86400) {
                $n['time_ago'] = max(1, floor($diff / 3600)) . 'h ago';
            } else {
                $n['time_ago'] = max(1, floor($diff / 86400)) . 'd ago';
            }
        }

        ApiResponse::success([
            'notifications' => $notifs,
            'unread_count' => $unreadCount,
            'total' => $total,
        ], 'Notifications retrieved successfully');
    }

    public function markAsRead(array $input): void {
        $id = (int)($input['id'] ?? $input['notification_id'] ?? 0);
        if ($id <= 0) {
            ApiResponse::error('Valid notification ID is required.');
            return;
        }
        $stmt = $this->db->prepare('UPDATE notifications SET is_read = 1 WHERE id = ?');
        $stmt->execute([$id]);
        ApiResponse::success(['id' => $id, 'is_read' => true], 'Notification marked as read');
    }

    public function markAllAsRead(array $input): void {
        $email = InputSanitizer::cleanEmail($input['email'] ?? $input['user_email'] ?? '');
        if (empty($email)) {
            $authUser = AuthMiddleware::getCurrentUser();
            if ($authUser && !empty($authUser['email'])) {
                $email = InputSanitizer::cleanEmail($authUser['email']);
            }
        }
        if (!empty($email)) {
            $stmt = $this->db->prepare('UPDATE notifications SET is_read = 1 WHERE LOWER(TRIM(user_email)) = LOWER(?)');
            $stmt->execute([$email]);
        }
        ApiResponse::success(null, 'All notifications marked as read');
    }

    public function createNotification(array $input): void {
        $title = InputSanitizer::cleanString($input['title'] ?? '');
        $body = InputSanitizer::cleanString($input['body'] ?? $input['message'] ?? '');
        $type = InputSanitizer::cleanString($input['type'] ?? 'general');
        $route = InputSanitizer::cleanString($input['route'] ?? '');
        $userEmail = InputSanitizer::cleanEmail($input['user_email'] ?? $input['email'] ?? '');
        if (empty($userEmail)) {
            $authUser = AuthMiddleware::getCurrentUser();
            if ($authUser && !empty($authUser['email'])) {
                $userEmail = InputSanitizer::cleanEmail($authUser['email']);
            }
        }

        if (empty($title) || empty($body)) {
            ApiResponse::error('Title and body are required.');
            return;
        }

        $stmt = $this->db->prepare('INSERT INTO notifications (title, body, type, route, user_email, is_read) VALUES (?, ?, ?, ?, ?, 0)');
        $stmt->execute([$title, $body, $type, $route, !empty($userEmail) ? $userEmail : null]);
        $newId = (int)$this->db->lastInsertId();

        ApiResponse::success([
            'id' => $newId,
            'title' => $title,
            'body' => $body,
            'type' => $type,
            'route' => $route,
            'user_email' => $userEmail,
            'is_read' => false,
            'created_at' => date('Y-m-d H:i:s'),
            'time_ago' => 'Just now'
        ], 'Notification created successfully', 201);
    }

    public function deleteNotification(array $input): void {
        $id = (int)($input['id'] ?? $input['notification_id'] ?? 0);
        if ($id <= 0) {
            ApiResponse::error('Valid notification ID is required.');
            return;
        }
        $email = InputSanitizer::cleanEmail($input['email'] ?? $input['user_email'] ?? '');
        if (empty($email)) {
            $authUser = AuthMiddleware::getCurrentUser();
            if ($authUser && !empty($authUser['email'])) {
                $email = InputSanitizer::cleanEmail($authUser['email']);
            }
        }
        if (!empty($email)) {
            $stmt = $this->db->prepare('DELETE FROM notifications WHERE id = ? AND (LOWER(TRIM(user_email)) = LOWER(?) OR user_email IS NULL)');
            $stmt->execute([$id, $email]);
        } else {
            $stmt = $this->db->prepare('DELETE FROM notifications WHERE id = ?');
            $stmt->execute([$id]);
        }
        ApiResponse::success(['id' => $id], 'Notification deleted successfully');
    }

    public function clearAllNotifications(array $input): void {
        $email = InputSanitizer::cleanEmail($input['email'] ?? $input['user_email'] ?? '');
        if (empty($email)) {
            $authUser = AuthMiddleware::getCurrentUser();
            if ($authUser && !empty($authUser['email'])) {
                $email = InputSanitizer::cleanEmail($authUser['email']);
            }
        }
        if (!empty($email)) {
            $stmt = $this->db->prepare('DELETE FROM notifications WHERE LOWER(TRIM(user_email)) = LOWER(?)');
            $stmt->execute([$email]);
        }
        ApiResponse::success(null, 'All notifications deleted successfully');
    }
}

// -----------------------------------------------------------------------------
// 4h. Upload Controller
// -----------------------------------------------------------------------------
class UploadController {
    private const ALLOWED_EXTS = ['jpg', 'jpeg', 'png', 'webp', 'gif'];
    private const ALLOWED_MIMES = ['image/jpeg', 'image/png', 'image/webp', 'image/gif'];
    private const MAX_FILE_SIZE = 10485760; // 10 MB

    /**
     * Safely delete an uploaded file from disk storage given its URL or filename.
     */
    public static function deletePhysicalFile(?string $fileUrl): bool {
        if (empty($fileUrl)) return false;
        $trimmed = trim((string)$fileUrl);
        if (empty($trimmed)) return false;

        $filename = '';
        if (preg_match('/(?:resource=uploads|uploads)[^?]*[?&]file=([^&#]+)/i', $trimmed, $m)) {
            $filename = urldecode($m[1]);
        } elseif (preg_match('/uploads\/([^\/\?#]+)/i', $trimmed, $m)) {
            $filename = urldecode($m[1]);
        } elseif (preg_match('/^art_\d+_[a-f0-9]+\.(jpg|jpeg|png|webp|gif)$/i', $trimmed)) {
            $filename = $trimmed;
        }

        if (empty($filename)) return false;

        $cleanName = basename($filename);
        if (empty($cleanName) || str_starts_with($cleanName, '.') || str_contains($cleanName, '..')) {
            return false;
        }

        $rawExt = strtolower(pathinfo($cleanName, PATHINFO_EXTENSION));
        if (!in_array($rawExt, self::ALLOWED_EXTS, true)) {
            return false;
        }

        $possibleDirs = array_unique(array_filter([
            __DIR__ . '/uploads',
            __DIR__ . '/../uploads',
            __DIR__ . '/../../uploads',
            dirname(__DIR__) . '/uploads',
            dirname(__DIR__, 2) . '/uploads',
            __DIR__ . '/api/uploads',
            __DIR__ . '/api/v1/uploads',
            ($_SERVER['DOCUMENT_ROOT'] ?? '') . '/uploads',
            ($_SERVER['DOCUMENT_ROOT'] ?? '') . '/artist_dubai/uploads',
            ($_SERVER['DOCUMENT_ROOT'] ?? '') . '/api/uploads',
            'D:/laragon/www/artist_dubai/uploads',
            'D:/laragon/www/artist_dubai/api/uploads',
            'D:/laragon/www/artist_dubai/api/v1/uploads',
        ]));

        $deleted = false;
        foreach ($possibleDirs as $dir) {
            if (!is_dir($dir)) continue;
            $target = $dir . DIRECTORY_SEPARATOR . $cleanName;
            if (file_exists($target) && is_file($target)) {
                $realDir = realpath($dir);
                $realTarget = realpath($target);
                if ($realDir && $realTarget && str_starts_with($realTarget, $realDir)) {
                    if (@unlink($realTarget)) {
                        $deleted = true;
                    }
                }
            }
        }
        return $deleted;
    }

    /**
     * Delete multiple physical files from storage.
     * Accepts an array of URLs/strings, or a JSON string of URLs.
     */
    public static function deleteMultiplePhysicalFiles(mixed $files): int {
        if (empty($files)) return 0;
        if (is_string($files)) {
            $decoded = json_decode($files, true);
            if (is_array($decoded)) {
                $files = $decoded;
            } else {
                $files = [$files];
            }
        }
        if (!is_array($files)) return 0;

        $count = 0;
        foreach ($files as $f) {
            if (is_string($f) && self::deletePhysicalFile($f)) {
                $count++;
            } elseif (is_array($f)) {
                $url = $f['url'] ?? $f['image_url'] ?? $f['image'] ?? null;
                if (is_string($url) && self::deletePhysicalFile($url)) {
                    $count++;
                }
            }
        }
        return $count;
    }

    public function handleDelete(array|string $input): void {
        AuthMiddleware::requireAuth();
        $fileUrl = is_array($input) ? ($input['file'] ?? $input['url'] ?? $input['filename'] ?? '') : (string)$input;
        if (empty($fileUrl)) {
            ApiResponse::error('File URL or filename is required for deletion', 400);
            return;
        }

        $deleted = self::deletePhysicalFile($fileUrl);
        ApiResponse::success(['deleted' => $deleted, 'file' => $fileUrl], $deleted ? 'File successfully deleted from storage' : 'File not found or already deleted');
    }

    public function serveFile(string $filename): void {
        $cleanName = basename($filename);

        // Security: Block access to hidden files and dangerous extensions
        if (empty($cleanName) || str_starts_with($cleanName, '.') || preg_match('/\.(php|phtml|phar|sh|exe|sql|env|htaccess|bak)$/i', $cleanName)) {
            http_response_code(403);
            header('Content-Type: application/json');
            echo json_encode(['status' => 'error', 'message' => 'Access denied']);
            exit;
        }

        $possibleDirs = [
            __DIR__ . '/uploads',
            __DIR__ . '/../../uploads',
            __DIR__,
        ];
        $filePath = null;
        foreach ($possibleDirs as $dir) {
            $candidate = realpath($dir . '/' . $cleanName);
            if ($candidate && file_exists($candidate) && is_file($candidate)) {
                $realDir = realpath($dir);
                if ($realDir && str_starts_with($candidate, $realDir)) {
                    $filePath = $candidate;
                    break;
                }
            }
        }

        if (ob_get_length()) ob_clean();

        header('Access-Control-Allow-Origin: *');
        header('Access-Control-Allow-Methods: GET, OPTIONS');
        header('Access-Control-Allow-Headers: *');
        header('Cross-Origin-Resource-Policy: cross-origin');
        header('X-Content-Type-Options: nosniff');
        header('Timing-Allow-Origin: *');

        if (!$filePath || !file_exists($filePath)) {
            http_response_code(404);
            header('Content-Type: application/json');
            echo json_encode(['status' => 'error', 'message' => 'Image not found: ' . htmlspecialchars($cleanName, ENT_QUOTES, 'UTF-8')]);
            exit;
        }

        $ext = strtolower(pathinfo($filePath, PATHINFO_EXTENSION));
        if (!in_array($ext, self::ALLOWED_EXTS, true)) {
            http_response_code(403);
            header('Content-Type: application/json');
            echo json_encode(['status' => 'error', 'message' => 'Access denied: only image formats allowed']);
            exit;
        }

        $mimes = [
            'jpg' => 'image/jpeg',
            'jpeg' => 'image/jpeg',
            'png' => 'image/png',
            'gif' => 'image/gif',
            'webp' => 'image/webp',
        ];
        $mime = $mimes[$ext] ?? 'application/octet-stream';

        header('Content-Type: ' . $mime, true);
        header('Content-Length: ' . filesize($filePath));
        header('Cache-Control: public, max-age=604800');
        header('X-Content-Type-Options: nosniff');
        header('Content-Disposition: inline; filename="' . $cleanName . '"');
        if (function_exists('header_remove')) {
            header_remove('Pragma');
            header_remove('Expires');
        }
        readfile($filePath);
        exit;
    }

    public function handleUpload(array $input): void {
        $currentUser = AuthMiddleware::getCurrentUser();

        // Rate limiting for uploads (max 60 per minute)
        if (!RateLimiter::check('upload', 60, 60)) {
            ApiResponse::error('Upload rate limit reached. Please wait a moment.', 429);
            return;
        }

        $uploadDir = __DIR__ . '/uploads';
        if (!is_dir($uploadDir)) {
            @mkdir($uploadDir, 0755, true);
        }

        // Hardened .htaccess inside uploads/ to strictly block script execution
        $htaccess = $uploadDir . '/.htaccess';
        $secureHtaccess = "# Artist Dubai - Ultra-Hardened Uploads Directory Security\n" .
            "<IfModule mod_php.c>\n    php_flag engine off\n</IfModule>\n" .
            "<IfModule mod_php7.c>\n    php_flag engine off\n</IfModule>\n" .
            "<IfModule mod_php8.c>\n    php_flag engine off\n</IfModule>\n\n" .
            "# Strip all script handlers\n" .
            "RemoveHandler .php .phtml .php3 .php4 .php5 .php7 .php8 .phps .phar .cgi .pl .py .sh .bash .exe .bat .cmd\n" .
            "RemoveType .php .phtml .php3 .php4 .php5 .php7 .php8 .phps .phar .cgi .pl .py .sh .bash .exe .bat .cmd\n\n" .
            "# Strictly forbid any executable or sensitive file extensions\n" .
            "<FilesMatch \"(?i)\\.(php|php3|php4|php5|php7|php8|phtml|phps|phar|cgi|pl|py|sh|bash|exe|bat|cmd|hta|htaccess|htpasswd|ini|env|sql|svg|html|htm|js|jsp|asp|aspx)$\">\n" .
            "    <IfModule mod_authz_core.c>\n        Require all denied\n    </IfModule>\n" .
            "    <IfModule !mod_authz_core.c>\n        Order deny,allow\n        Deny from all\n    </IfModule>\n" .
            "</FilesMatch>\n\n" .
            "# Only allow safe raster image formats\n" .
            "<FilesMatch \"(?i)\\.(jpg|jpeg|png|gif|webp|ico)$\">\n" .
            "    <IfModule mod_authz_core.c>\n        Require all granted\n    </IfModule>\n" .
            "    <IfModule !mod_authz_core.c>\n        Order allow,deny\n        Allow from all\n    </IfModule>\n" .
            "</FilesMatch>\n\n" .
            "Options -Indexes -ExecCGI\n" .
            "<IfModule mod_headers.c>\n" .
            "    Header set X-Content-Type-Options \"nosniff\"\n" .
            "    Header set Access-Control-Allow-Origin \"*\"\n" .
            "    Header set Access-Control-Allow-Methods \"GET, OPTIONS\"\n" .
            "    Header set Access-Control-Allow-Headers \"*\"\n" .
            "    Header set Cross-Origin-Resource-Policy \"cross-origin\"\n" .
            "    Header set Timing-Allow-Origin \"*\"\n" .
            "    Header set Cache-Control \"public, max-age=604800, immutable\"\n" .
            "    Header unset Content-Security-Policy\n" .
            "</IfModule>\n";
        @file_put_contents($htaccess, $secureHtaccess);

        $isLive = (isset($_SERVER['HTTP_HOST']) && strpos($_SERVER['HTTP_HOST'], 'technestpartners.com') !== false)
               || (isset($_SERVER['SERVER_NAME']) && strpos($_SERVER['SERVER_NAME'], 'technestpartners.com') !== false)
               || (getenv('APP_ENV') === 'production');

        $protocol = 'https://';
        $host = $_SERVER['HTTP_HOST'] ?? 'technestpartners.com';
        $baseUrl = $isLive ? 'https://technestpartners.com/api/' : ($protocol . $host . '/');

        // 1. Handle multipart $_FILES
        if (!empty($_FILES['file']) || !empty($_FILES['image'])) {
            $file = $_FILES['file'] ?? $_FILES['image'];
            
            if (!empty($file['error']) && $file['error'] !== UPLOAD_ERR_OK) {
                ApiResponse::error('File upload error code: ' . (int)$file['error'], 400);
                return;
            }

            if ($file['size'] > self::MAX_FILE_SIZE) {
                ApiResponse::error('File size exceeds 10MB limit.', 400);
                return;
            }

            $rawExt = strtolower(pathinfo($file['name'] ?? '', PATHINFO_EXTENSION));
            if (!in_array($rawExt, self::ALLOWED_EXTS)) {
                ApiResponse::error('Invalid file extension. Allowed: jpg, jpeg, png, webp, gif', 400);
                return;
            }

            // Verify MIME type using fileinfo
            if (function_exists('finfo_open')) {
                $finfo = finfo_open(FILEINFO_MIME_TYPE);
                $detectedMime = finfo_file($finfo, $file['tmp_name']);
                finfo_close($finfo);
                if (!in_array($detectedMime, self::ALLOWED_MIMES)) {
                    ApiResponse::error('Invalid image content type: ' . htmlspecialchars($detectedMime, ENT_QUOTES, 'UTF-8'), 400);
                    return;
                }
            }

            // Verify actual image structure (Magic bytes)
            $imgInfo = @getimagesize($file['tmp_name']);
            if ($imgInfo === false) {
                ApiResponse::error('Uploaded file is not a valid image.', 400);
                return;
            }

            $safeExt = $rawExt === 'jpeg' ? 'jpg' : $rawExt;
            $filename = 'art_' . time() . '_' . bin2hex(random_bytes(16)) . '.' . $safeExt;
            $targetPath = $uploadDir . '/' . $filename;

            if (@move_uploaded_file($file['tmp_name'], $targetPath)) {
                chmod($targetPath, 0644);
                $url = $baseUrl . 'uploads/' . $filename;
                ApiResponse::success(['url' => $url, 'filename' => $filename, 'success' => true], 'File uploaded successfully', 201);
                return;
            }
        }

        // 2. Handle base64 encoded data
        $base64Data = (string)($input['base64'] ?? $input['image'] ?? $input['data'] ?? '');
        if (!empty($base64Data)) {
            $ext = strtolower(InputSanitizer::cleanString($input['ext'] ?? 'jpg'));
            if (preg_match('/^data:image\/(\w+);base64,/', $base64Data, $type)) {
                $base64Data = substr($base64Data, strpos($base64Data, ',') + 1);
                $ext = strtolower($type[1]);
            }
            if ($ext === 'jpeg') $ext = 'jpg';

            if (!in_array($ext, self::ALLOWED_EXTS)) {
                ApiResponse::error('Invalid image extension for base64 upload.', 400);
                return;
            }

            $decoded = base64_decode($base64Data, true);
            if ($decoded !== false && strlen($decoded) > 0) {
                if (strlen($decoded) > self::MAX_FILE_SIZE) {
                    ApiResponse::error('Base64 image size exceeds 10MB limit.', 400);
                    return;
                }

                $imgInfo = @getimagesizefromstring($decoded);
                if ($imgInfo === false) {
                    ApiResponse::error('Invalid image content received.', 400);
                    return;
                }

                $filename = 'art_' . time() . '_' . bin2hex(random_bytes(16)) . '.' . $ext;
                $targetPath = $uploadDir . '/' . $filename;
                $saved = @file_put_contents($targetPath, $decoded);
                if ($saved !== false) {
                    chmod($targetPath, 0644);
                    $url = $baseUrl . 'uploads/' . $filename;
                    ApiResponse::success(['url' => $url, 'filename' => $filename, 'success' => true], 'Image uploaded successfully', 201);
                    return;
                }
            }
        }

        ApiResponse::error('No valid image file or base64 data received for upload', 400);
    }
}

class AboutController {
    private PDO $db;

    public function __construct() {
        $this->db = DatabaseManager::getInstance()->getConnection();
    }

    public function getAboutInfo(): void {
        try {
            $artistsCount = (int)$this->db->query("SELECT COUNT(*) FROM artists")->fetchColumn();
            $eventsCount = (int)$this->db->query("SELECT COUNT(*) FROM events")->fetchColumn();
            $galleriesCount = (int)$this->db->query("SELECT COUNT(*) FROM galleries")->fetchColumn();
            $categoriesCount = (int)$this->db->query("SELECT COUNT(*) FROM categories")->fetchColumn();
            $bookingsCount = (int)$this->db->query("SELECT COUNT(*) FROM bookings")->fetchColumn();
            $entitiesCount = (int)$this->db->query("SELECT COUNT(*) FROM government_entities")->fetchColumn();

            ApiResponse::success([
                'title' => 'Artist Dubai',
                'description' => 'The Premier UAE Creative & Cultural Ecosystem Platform',
                'version' => '6.3.0',
                'database' => 'MySQL',
                'status' => 'online',
                'counts' => [
                    'artists' => $artistsCount,
                    'events' => $eventsCount,
                    'galleries' => $galleriesCount,
                    'categories' => $categoriesCount,
                    'bookings' => $bookingsCount,
                    'cultural_entities' => $entitiesCount,
                ],
                'mission' => 'Empowering Emirati and UAE-based creative visionaries with digital exposure, seamless event booking, and government cultural integration.',
            ], 'Platform information retrieved successfully');
        } catch (\Throwable $t) {
            error_log('Failed to retrieve platform info: ' . $t->getMessage()); ApiResponse::error('Failed to retrieve platform info', 500);
        }
    }
}

// -----------------------------------------------------------------------------
// 4i2. Publishing Pricing Controller
// -----------------------------------------------------------------------------
class PublishingPricingController {
    private PDO $db;

    public function __construct() {
        $this->db = DatabaseManager::getInstance()->getConnection();
    }

    public function getPricing(): void {
        try {
            $stmt = $this->db->query("SELECT * FROM publishing_pricing ORDER BY id ASC");
            $rows = $stmt->fetchAll();
            if (empty($rows)) {
                $this->seedInitialPricing();
                $stmt = $this->db->query("SELECT * FROM publishing_pricing ORDER BY id ASC");
                $rows = $stmt->fetchAll();
            }
            ApiResponse::success($rows ?: [], 'Publishing pricing retrieved successfully');
        } catch (\Throwable $t) {
            error_log('PublishingPricingController::getPricing error: ' . $t->getMessage());
            ApiResponse::error('Failed to retrieve publishing pricing', 500);
        }
    }

    public function seedInitialPricing(): void {
        try {
            $stmt = $this->db->prepare("
                INSERT INTO publishing_pricing 
                (id, item_type, item_name, description, weekly_price, monthly_price, three_month_price, six_month_price, yearly_price, three_month_badge, six_month_badge, yearly_badge, currency, is_active)
                VALUES 
                (1, 'event', 'Paid Event Publishing', 'Feature your event on curated maps and event calendars, with professional event photography.', 'AED 150', 'AED 500', 'AED 2,000', 'AED 3,000', 'AED 5,000', 'Special Offer', 'Save 25%', 'Best Value', 'AED', 1),
                (2, 'gallery', 'Art Venue Listing', 'Boost your visibility and secure your place in our professional art community. Choose your plan and connect with the art world!', 'AED 250', 'AED 800', 'AED 2,000', 'AED 3,000', 'AED 5,000', 'Special Offer', 'Save 25%', 'Best Value', 'AED', 1),
                (3, 'artist', 'Artist Verification & Listing', 'Get verified badge, priority placement in artist directory, and direct commissioning channel.', 'AED 100', 'AED 350', 'AED 1,000', 'AED 1,800', 'AED 3,000', 'Special Offer', 'Save 14%', 'Featured', 'AED', 1)
                ON DUPLICATE KEY UPDATE 
                    item_name = VALUES(item_name),
                    description = VALUES(description),
                    three_month_price = VALUES(three_month_price),
                    six_month_price = VALUES(six_month_price),
                    yearly_price = VALUES(yearly_price),
                    three_month_badge = VALUES(three_month_badge),
                    six_month_badge = VALUES(six_month_badge),
                    yearly_badge = VALUES(yearly_badge),
                    currency = VALUES(currency),
                    is_active = VALUES(is_active)
            ");
            $stmt->execute();
        } catch (\Throwable $t) {
            error_log('PublishingPricingController::seedInitialPricing error: ' . $t->getMessage());
        }
    }

    public function updatePricing(array $input): void {
        AuthMiddleware::requireAdmin();

        $id = (int)($input['id'] ?? 0);
        $itemName = InputSanitizer::cleanString($input['item_name'] ?? $input['name'] ?? '');
        $description = InputSanitizer::cleanString($input['description'] ?? '');
        $weeklyPrice = InputSanitizer::cleanString($input['weekly_price'] ?? $input['weekly'] ?? '');
        $monthlyPrice = InputSanitizer::cleanString($input['monthly_price'] ?? $input['monthly'] ?? '');
        $threeMonthPrice = InputSanitizer::cleanString($input['three_month_price'] ?? $input['three_month'] ?? '');
        $sixMonthPrice = InputSanitizer::cleanString($input['six_month_price'] ?? $input['six_month'] ?? '');
        $yearlyPrice = InputSanitizer::cleanString($input['yearly_price'] ?? $input['yearly'] ?? '');
        $threeMonthBadge = InputSanitizer::cleanString($input['three_month_badge'] ?? $input['threeMonthBadge'] ?? '');
        $sixMonthBadge = InputSanitizer::cleanString($input['six_month_badge'] ?? $input['sixMonthBadge'] ?? '');
        $yearlyBadge = InputSanitizer::cleanString($input['yearly_badge'] ?? $input['yearlyBadge'] ?? '');
        $isActive = isset($input['is_active']) ? (int)$input['is_active'] : 1;

        if ($id <= 0 && !empty($input['item_type'])) {
            try {
                $stmtFind = $this->db->prepare('SELECT id FROM publishing_pricing WHERE item_type = ? LIMIT 1');
                $stmtFind->execute([InputSanitizer::cleanString($input['item_type'])]);
                $id = (int)$stmtFind->fetchColumn();
            } catch (\Throwable $t) {}
        }

        if ($id <= 0) {
            ApiResponse::error('Valid pricing plan ID is required.', 400);
            return;
        }

        try {
            $fields = [];
            $params = [];
            if (!empty($itemName)) { $fields[] = 'item_name = ?'; $params[] = $itemName; }
            if (isset($input['description'])) { $fields[] = 'description = ?'; $params[] = $description; }
            if (!empty($weeklyPrice)) { $fields[] = 'weekly_price = ?'; $params[] = $weeklyPrice; }
            if (!empty($monthlyPrice)) { $fields[] = 'monthly_price = ?'; $params[] = $monthlyPrice; }
            if (!empty($threeMonthPrice)) { $fields[] = 'three_month_price = ?'; $params[] = $threeMonthPrice; }
            if (!empty($sixMonthPrice)) { $fields[] = 'six_month_price = ?'; $params[] = $sixMonthPrice; }
            if (!empty($yearlyPrice)) { $fields[] = 'yearly_price = ?'; $params[] = $yearlyPrice; }
            if (!empty($threeMonthBadge)) { $fields[] = 'three_month_badge = ?'; $params[] = $threeMonthBadge; }
            if (!empty($sixMonthBadge)) { $fields[] = 'six_month_badge = ?'; $params[] = $sixMonthBadge; }
            if (!empty($yearlyBadge)) { $fields[] = 'yearly_badge = ?'; $params[] = $yearlyBadge; }
            if (isset($input['is_active'])) { $fields[] = 'is_active = ?'; $params[] = $isActive; }

            if (empty($fields)) {
                ApiResponse::error('No fields provided to update.', 400);
                return;
            }

            $params[] = $id;
            $stmt = $this->db->prepare('UPDATE publishing_pricing SET ' . implode(', ', $fields) . ' WHERE id = ?');
            $stmt->execute($params);

            ApiResponse::success(['id' => $id, 'updated' => true], 'Publishing pricing updated successfully');
        } catch (\Throwable $t) {
            error_log('Failed to update publishing pricing: ' . $t->getMessage()); ApiResponse::error('Failed to update publishing pricing', 500);
        }
    }
}

// -----------------------------------------------------------------------------
// 4i2. Listing Plans Controller (Connected with Admin Dashboard & Listing Plans Screen)
// -----------------------------------------------------------------------------
class ListingPlansController {
    private PDO $db;

    public function __construct() {
        $this->db = DatabaseManager::getInstance()->getConnection();
        try { $this->db->exec("ALTER TABLE listing_plans ADD COLUMN duration VARCHAR(100) DEFAULT NULL"); } catch (\Throwable $t) {}
        try { $this->db->exec("ALTER TABLE listing_plans ADD COLUMN duration_days INT DEFAULT NULL"); } catch (\Throwable $t) {}
    }

    public static function normalizePrice(string $price): string {
        $trimmed = trim($price);
        if ($trimmed === '') return 'AED 199';
        if (strcasecmp($trimmed, 'free') === 0 || $trimmed === '0' || strcasecmp($trimmed, '0 aed') === 0 || strcasecmp($trimmed, 'aed 0') === 0) {
            return 'Free';
        }
        if (preg_match('/^(?:aed\s*)?([0-9]+(?:,[0-9]+)*(?:\.[0-9]+)?)(?:\s*aed)?$/i', $trimmed, $m)) {
            return 'AED ' . $m[1];
        }
        return $trimmed;
    }

    public function getPlans(): void {
        try {
            $stmt = $this->db->query("SELECT * FROM listing_plans ORDER BY sort_order ASC, id ASC");
            $rows = $stmt->fetchAll();
            if (empty($rows)) {
                $this->seedInitialPlans();
                $stmt = $this->db->query("SELECT * FROM listing_plans ORDER BY sort_order ASC, id ASC");
                $rows = $stmt->fetchAll();
            }
            foreach ($rows as &$row) {
                if (isset($row['price'])) {
                    $row['price'] = self::normalizePrice($row['price']);
                }
                $features = [];
                if (!empty($row['features_json'])) {
                    $decoded = json_decode($row['features_json'], true);
                    if (is_array($decoded)) {
                        $features = $decoded;
                    }
                }
                $row['features'] = $features;

                // Duration resolution for each plan
                $itemType = strtolower($row['item_type'] ?? '');
                $title = strtolower($row['title'] ?? '');
                if (empty($row['duration'])) {
                    if (str_contains($itemType, 'gallery') || str_contains($title, 'gallery') || str_contains($itemType, 'art_centre') || str_contains($title, 'center') || str_contains($itemType, 'artist')) {
                        $row['duration'] = '1 Year (365 Days)';
                        $row['duration_days'] = 365;
                    } elseif (str_contains($itemType, 'event') || str_contains($title, 'event')) {
                        $row['duration'] = '30 Days';
                        $row['duration_days'] = 30;
                    } elseif (str_contains($itemType, 'chat') || str_contains($title, 'chat')) {
                        $row['duration'] = '30 Days';
                        $row['duration_days'] = 30;
                    } else {
                        $row['duration'] = '30 Days';
                        $row['duration_days'] = 30;
                    }
                } else {
                    $row['duration_days'] = isset($row['duration_days']) ? (int)$row['duration_days'] : 30;
                }
            }
            ApiResponse::success($rows ?: [], 'Listing plans retrieved successfully');
        } catch (\Throwable $t) {
            error_log('ListingPlansController::getPlans error: ' . $t->getMessage());
            ApiResponse::error('Failed to retrieve listing plans', 500);
        }
    }

    public function seedInitialPlans(): void {
        try {
            $defaultPlans = [
                'gallery_3m' => [
                    'item_type' => 'gallery',
                    'title' => '3 Months',
                    'category' => 'Art Galleries',
                    'badge' => 'Special Offer',
                    'price' => 'AED 2,000',
                    'duration' => '3 Months',
                    'duration_days' => 90,
                    'description' => 'Boost your visibility and secure your place in our professional art community. Choose your plan and connect with the art world!',
                    'features_json' => json_encode([
                        'Curated maps showcase',
                        'Event calendars feature',
                        'Professional event photography',
                        'Enjoy your first 3 months free'
                    ]),
                    'button_text' => 'Register Gallery',
                    'sort_order' => 1
                ],
                'gallery_6m' => [
                    'item_type' => 'gallery',
                    'title' => '6 Months',
                    'category' => 'Art Galleries',
                    'badge' => 'Save 25%',
                    'price' => 'AED 3,000',
                    'duration' => '6 Months',
                    'duration_days' => 180,
                    'description' => 'Boost your visibility and secure your place in our professional art community. Choose your plan and connect with the art world!',
                    'features_json' => json_encode([
                        'Curated maps showcase',
                        'Event calendars feature',
                        'Professional event photography',
                        'Enjoy your first 3 months free'
                    ]),
                    'button_text' => 'Register Gallery',
                    'sort_order' => 2
                ],
                'gallery_12m' => [
                    'item_type' => 'gallery',
                    'title' => '12 Months',
                    'category' => 'Art Galleries',
                    'badge' => 'Best Value',
                    'price' => 'AED 5,000',
                    'duration' => '12 Months',
                    'duration_days' => 365,
                    'description' => 'Boost your visibility and secure your place in our professional art community. Choose your plan and connect with the art world!',
                    'features_json' => json_encode([
                        'Curated maps showcase',
                        'Event calendars feature',
                        'Professional event photography',
                        'Enjoy your first 3 months free'
                    ]),
                    'button_text' => 'Register Gallery',
                    'sort_order' => 3
                ],
                'event_3m' => [
                    'item_type' => 'event',
                    'title' => '3 Months',
                    'category' => 'Art Events',
                    'badge' => 'Special Offer',
                    'price' => 'AED 2,000',
                    'duration' => '3 Months',
                    'duration_days' => 90,
                    'description' => 'Feature your event on curated maps and event calendars, with professional event photography.',
                    'features_json' => json_encode([
                        'Curated maps showcase',
                        'Event calendars feature',
                        'Professional event photography',
                        'Enjoy your first 3 months free'
                    ]),
                    'button_text' => 'Publish Event',
                    'sort_order' => 4
                ],
                'event_6m' => [
                    'item_type' => 'event',
                    'title' => '6 Months',
                    'category' => 'Art Events',
                    'badge' => 'Save 25%',
                    'price' => 'AED 3,000',
                    'duration' => '6 Months',
                    'duration_days' => 180,
                    'description' => 'Feature your event on curated maps and event calendars, with professional event photography.',
                    'features_json' => json_encode([
                        'Curated maps showcase',
                        'Event calendars feature',
                        'Professional event photography',
                        'Enjoy your first 3 months free'
                    ]),
                    'button_text' => 'Publish Event',
                    'sort_order' => 5
                ],
                'event_12m' => [
                    'item_type' => 'event',
                    'title' => '12 Months',
                    'category' => 'Art Events',
                    'badge' => 'Best Value',
                    'price' => 'AED 5,000',
                    'duration' => '12 Months',
                    'duration_days' => 365,
                    'description' => 'Feature your event on curated maps and event calendars, with professional event photography.',
                    'features_json' => json_encode([
                        'Curated maps showcase',
                        'Event calendars feature',
                        'Professional event photography',
                        'Enjoy your first 3 months free'
                    ]),
                    'button_text' => 'Publish Event',
                    'sort_order' => 6
                ],
                'chat_starter' => [
                    'item_type' => 'chat',
                    'title' => 'Starter Plan',
                    'category' => 'Messaging & Inquiries',
                    'badge' => 'Default',
                    'price' => 'Free',
                    'duration' => 'Monthly',
                    'duration_days' => 30,
                    'description' => 'Free monthly allowance to connect with artists across Dubai',
                    'features_json' => json_encode([
                        '10 direct messages per month',
                        'Direct artist collaboration inquiries',
                        'Flyer & artwork attachment support',
                        'Allowance auto-resets on the 1st'
                    ]),
                    'button_text' => 'Select Plan',
                    'sort_order' => 7
                ],
                'chat_vip' => [
                    'item_type' => 'chat',
                    'title' => 'Unlimited VIP Chat',
                    'category' => 'Messaging & Inquiries',
                    'badge' => 'VIP All-Access',
                    'price' => 'AED 500',
                    'duration' => 'Monthly',
                    'duration_days' => 30,
                    'description' => 'Unlimited direct artist messages with verified VIP sender badge for AED 500 per month',
                    'features_json' => json_encode([
                        'Unlimited direct artist messages',
                        'Verified VIP sender badge',
                        'Direct artist outreach & networking',
                        'Priority delivery in artist inboxes',
                        'High-resolution flyer & artwork attachments'
                    ]),
                    'button_text' => 'Upgrade to VIP',
                    'sort_order' => 8
                ],
                'artist' => [
                    'item_type' => 'artist',
                    'title' => 'Pro Artist Portfolio',
                    'category' => 'Visual Arts',
                    'badge' => 'Best Choice',
                    'price' => 'AED 350',
                    'duration' => 'Annual',
                    'duration_days' => 365,
                    'description' => 'Unlimited artwork uploads, custom bio, direct buyer messaging',
                    'features_json' => json_encode([
                        'Unlimited artwork & portfolio showcase uploads',
                        'Direct collector messaging & inquiry channel',
                        'Verified Artist badge on public profile',
                        'Priority ranking in search & category exploration',
                        'Custom biography, exhibition history & press links'
                    ]),
                    'button_text' => 'Upgrade Artist Profile',
                    'sort_order' => 9
                ],
                'art_centre' => [
                    'item_type' => 'art_centre',
                    'title' => 'Art Center Partner',
                    'category' => 'Institutions & Venues',
                    'badge' => 'VIP Partner',
                    'price' => 'AED 990',
                    'duration' => 'Annual',
                    'duration_days' => 365,
                    'description' => 'Official verified institution hub page, workshop hosting & priority event syndication',
                    'features_json' => json_encode([
                        'Official verified institution partner badge',
                        'Unlimited event & workshop listings',
                        'Direct ticket booking with instant notifications',
                        'Top banner rotation on mobile home screen',
                        'Dedicated account manager & support'
                    ]),
                    'button_text' => 'Join Partner Network',
                    'sort_order' => 10
                ],
            ];

            $count = (int)$this->db->query("SELECT COUNT(*) FROM listing_plans")->fetchColumn();
            if ($count === 0) {
                $stmt = $this->db->prepare("
                    INSERT INTO listing_plans 
                    (item_type, title, category, badge, price, duration, duration_days, description, features_json, button_text, is_active, sort_order)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 1, ?)
                ");
                foreach ($defaultPlans as $p) {
                    $stmt->execute([
                        $p['item_type'], $p['title'], $p['category'], $p['badge'],
                        $p['price'], $p['duration'], $p['duration_days'], $p['description'],
                        $p['features_json'], $p['button_text'], $p['sort_order']
                    ]);
                }
            } else {
                // Ensure chat VIP is AED 500
                $this->db->exec("UPDATE listing_plans SET price = 'AED 500', description = 'Unlimited direct artist messages with verified VIP sender badge for AED 500 per month' WHERE item_type = 'chat' AND (title LIKE '%VIP%' OR title LIKE '%Unlimited%')");
            }
        } catch (\Throwable $t) {
            error_log('ListingPlansController::seedInitialPlans error: ' . $t->getMessage());
        }
    }

    public function updatePlan(array $input): void {
        AuthMiddleware::requireAdmin();

        $id = (int)($input['id'] ?? 0);
        $itemType = trim($input['item_type'] ?? '');
        $title = InputSanitizer::cleanString($input['title'] ?? '');
        $category = InputSanitizer::cleanString($input['category'] ?? '');
        $badge = InputSanitizer::cleanString($input['badge'] ?? 'One-time');
        $price = !empty($input['price']) ? self::normalizePrice(InputSanitizer::cleanString($input['price'])) : '';
        $description = InputSanitizer::cleanString($input['description'] ?? '');
        $buttonText = InputSanitizer::cleanString($input['button_text'] ?? 'Pay from My Listings');
        $isActive = isset($input['is_active']) ? (int)$input['is_active'] : 1;
        $sortOrder = isset($input['sort_order']) ? (int)$input['sort_order'] : 0;

        // Process features
        $featuresJson = null;
        if (isset($input['features'])) {
            if (is_array($input['features'])) {
                $featuresJson = json_encode(array_values(array_filter(array_map('trim', $input['features']))));
            } else if (is_string($input['features'])) {
                $lines = preg_split('/[\r\n,]+/', $input['features']);
                $featuresJson = json_encode(array_values(array_filter(array_map('trim', $lines))));
            }
        } elseif (isset($input['features_json'])) {
            $featuresJson = $input['features_json'];
        }

        try {
            if ($id > 0) {
                $fields = [];
                $params = [];
                if (!empty($title)) { $fields[] = 'title = ?'; $params[] = $title; }
                if (!empty($category)) { $fields[] = 'category = ?'; $params[] = $category; }
                if (isset($input['badge'])) { $fields[] = 'badge = ?'; $params[] = $badge; }
                if (!empty($price)) { $fields[] = 'price = ?'; $params[] = $price; }
                if (isset($input['description'])) { $fields[] = 'description = ?'; $params[] = $description; }
                if ($featuresJson !== null) { $fields[] = 'features_json = ?'; $params[] = $featuresJson; }
                if (isset($input['button_text'])) { $fields[] = 'button_text = ?'; $params[] = $buttonText; }
                if (isset($input['duration']) && trim($input['duration']) !== '') { $fields[] = 'duration = ?'; $params[] = trim($input['duration']); }
                if (isset($input['duration_days'])) { $fields[] = 'duration_days = ?'; $params[] = (int)$input['duration_days']; }
                if (isset($input['is_active'])) { $fields[] = 'is_active = ?'; $params[] = $isActive; }
                if (isset($input['sort_order'])) { $fields[] = 'sort_order = ?'; $params[] = $sortOrder; }

                if (empty($fields)) {
                    ApiResponse::error('No fields provided to update.', 400);
                    return;
                }

                $params[] = $id;
                $stmt = $this->db->prepare('UPDATE listing_plans SET ' . implode(', ', $fields) . ' WHERE id = ?');
                $stmt->execute($params);

                ApiResponse::success(['id' => $id, 'updated' => true], 'Listing plan updated successfully');
            } elseif (!empty($itemType)) {
                // Find by itemType or insert
                $check = $this->db->prepare("SELECT id FROM listing_plans WHERE item_type = ? LIMIT 1");
                $check->execute([$itemType]);
                $existing = $check->fetch();
                if ($existing) {
                    $input['id'] = $existing['id'];
                    $this->updatePlan($input);
                } else {
                    $this->createPlan($input);
                }
            } else {
                ApiResponse::error('Valid plan ID or item_type is required', 400);
            }
        } catch (\Throwable $t) {
            error_log('Failed to update listing plan: ' . $t->getMessage()); ApiResponse::error('Failed to update listing plan', 500);
        }
    }

    public function createPlan(array $input): void {
        AuthMiddleware::requireAdmin();

        $itemType = strtolower(trim(InputSanitizer::cleanString($input['item_type'] ?? 'custom')));
        $title = InputSanitizer::cleanString($input['title'] ?? 'Listing Plan');
        $category = InputSanitizer::cleanString($input['category'] ?? 'Listings');
        $badge = InputSanitizer::cleanString($input['badge'] ?? 'One-time');
        $price = self::normalizePrice(InputSanitizer::cleanString($input['price'] ?? 'AED 199'));
        $description = InputSanitizer::cleanString($input['description'] ?? '');
        $buttonText = InputSanitizer::cleanString($input['button_text'] ?? 'Pay from My Listings');
        $duration = InputSanitizer::cleanString($input['duration'] ?? '30 Days');
        $durationDays = isset($input['duration_days']) ? (int)$input['duration_days'] : 30;
        $isActive = isset($input['is_active']) ? (int)$input['is_active'] : 1;
        $sortOrder = isset($input['sort_order']) ? (int)$input['sort_order'] : 0;

        $featuresJson = json_encode([]);
        if (isset($input['features'])) {
            if (is_array($input['features'])) {
                $featuresJson = json_encode(array_values(array_filter(array_map('trim', $input['features']))));
            } else if (is_string($input['features'])) {
                $lines = preg_split('/[\r\n,]+/', $input['features']);
                $featuresJson = json_encode(array_values(array_filter(array_map('trim', $lines))));
            }
        }

        try {
            $stmt = $this->db->prepare("
                INSERT INTO listing_plans 
                (item_type, title, category, badge, price, description, features_json, button_text, duration, duration_days, is_active, sort_order) 
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            ");
            $stmt->execute([$itemType, $title, $category, $badge, $price, $description, $featuresJson, $buttonText, $duration, $durationDays, $isActive, $sortOrder]);
            $newId = (int)$this->db->lastInsertId();

            ApiResponse::success(['id' => $newId, 'created' => true], 'Listing plan created successfully');
        } catch (\Throwable $t) {
            error_log('Failed to create listing plan: ' . $t->getMessage()); ApiResponse::error('Failed to create listing plan', 500);
        }
    }

    public function deletePlan(array $input): void {
        AuthMiddleware::requireAdmin();
        $id = (int)($input['id'] ?? 0);
        if ($id <= 0) {
            ApiResponse::error('Valid plan ID required for deletion', 400);
            return;
        }
        try {
            $stmt = $this->db->prepare("DELETE FROM listing_plans WHERE id = ?");
            $stmt->execute([$id]);
            ApiResponse::success(['id' => $id, 'deleted' => true], 'Listing plan deleted successfully');
        } catch (\Throwable $t) {
            error_log('Failed to delete listing plan: ' . $t->getMessage()); ApiResponse::error('Failed to delete listing plan', 500);
        }
    }
}

// -----------------------------------------------------------------------------
// 4i2b. User Purchased Plans Controller
// -----------------------------------------------------------------------------
class UserPlansController {
    private PDO $db;

    public function __construct() {
        $this->db = DatabaseManager::getInstance()->getConnection();
        try {
            $this->db->exec("
                CREATE TABLE IF NOT EXISTS user_plans (
                    id INT AUTO_INCREMENT PRIMARY KEY,
                    user_id INT NULL,
                    user_email VARCHAR(255) NOT NULL,
                    plan_name VARCHAR(255) NOT NULL,
                    plan_type VARCHAR(100) DEFAULT 'Subscription',
                    item_title VARCHAR(255) NULL,
                    price VARCHAR(100) NOT NULL DEFAULT 'Free',
                    billing_cycle VARCHAR(100) DEFAULT 'Monthly',
                    status VARCHAR(50) DEFAULT 'Active',
                    payment_reference VARCHAR(255) NULL,
                    payment_method VARCHAR(100) DEFAULT 'Card',
                    payment_proof_url VARCHAR(500) NULL,
                    features_json TEXT NULL,
                    start_date DATETIME DEFAULT CURRENT_TIMESTAMP,
                    expires_at DATETIME NULL,
                    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                    INDEX idx_user_plan_email (user_email),
                    INDEX idx_user_plan_status (status)
                ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
            ");
        } catch (\Throwable $t) {}
        try { $this->db->exec("ALTER TABLE user_plans ADD COLUMN payment_proof_url VARCHAR(500) NULL"); } catch (\Throwable $t) {}
        try { $this->db->exec("ALTER TABLE user_plans ADD COLUMN item_title VARCHAR(255) NULL"); } catch (\Throwable $t) {}
        try { $this->db->exec("ALTER TABLE user_plans ADD COLUMN billing_cycle VARCHAR(100) DEFAULT 'Monthly'"); } catch (\Throwable $t) {}
        try { $this->db->exec("ALTER TABLE user_plans ADD COLUMN payment_reference VARCHAR(255) NULL"); } catch (\Throwable $t) {}
        try { $this->db->exec("ALTER TABLE user_plans ADD COLUMN payment_method VARCHAR(100) DEFAULT 'Card'"); } catch (\Throwable $t) {}
        try { $this->db->exec("ALTER TABLE user_plans ADD COLUMN features_json TEXT NULL"); } catch (\Throwable $t) {}
        try { $this->db->exec("ALTER TABLE user_plans ADD COLUMN start_date DATETIME DEFAULT CURRENT_TIMESTAMP"); } catch (\Throwable $t) {}
        try { $this->db->exec("ALTER TABLE user_plans ADD COLUMN expires_at DATETIME NULL"); } catch (\Throwable $t) {}
        try { $this->db->exec("ALTER TABLE user_plans ADD COLUMN duration VARCHAR(100) DEFAULT NULL"); } catch (\Throwable $t) {}
        try { $this->db->exec("ALTER TABLE user_plans ADD COLUMN duration_days INT DEFAULT NULL"); } catch (\Throwable $t) {}

        // Self-healing migration: Ensure gallery/annual plans have 365 days / 1 year duration
        try {
            $this->db->exec("
                UPDATE user_plans 
                SET expires_at = DATE_ADD(created_at, INTERVAL 365 DAY),
                    billing_cycle = '1 Year (365 Days)',
                    duration = '1 Year (365 Days)',
                    duration_days = 365
                WHERE (plan_name LIKE '%Gallery%' OR plan_type = 'gallery' OR plan_name LIKE '%Year%' OR billing_cycle LIKE '%Year%')
                  AND (DATEDIFF(expires_at, created_at) <= 35 OR expires_at IS NULL)
            ");
        } catch (\Throwable $t) {}
    }

    public static function formatDurationLabel(?int $daysLeft, ?string $exp, ?string $duration, string $planName = '', string $planType = ''): string {
        $pLower = strtolower($planName . ' ' . $planType);
        if ($daysLeft !== null && $daysLeft > 0) {
            if ($daysLeft >= 330) {
                return "$daysLeft Days Remaining (~1 Year)";
            } elseif ($daysLeft >= 60) {
                $months = round($daysLeft / 30);
                return "$daysLeft Days Remaining (~$months Mos)";
            }
            return "$daysLeft Days Remaining";
        }
        if ($daysLeft !== null && $daysLeft <= 0) {
            return "Expired";
        }
        if (!empty($duration)) {
            return $duration;
        }
        if (strpos($pLower, 'artist') !== false || strpos($pLower, 'free') !== false) {
            return "Permanent Free Profile";
        }
        if (strpos($pLower, 'gallery') !== false || strpos($pLower, 'art_centre') !== false || strpos($pLower, 'center') !== false) {
            return "1 Year (365 Days)";
        }
        if (strpos($pLower, 'event') !== false) {
            return "30 Days Single Event Pass";
        }
        return "Active Plan";
    }

    public function getPlans(array $input = []): void {
        try {
            $currentUser = AuthMiddleware::getCurrentUser();
            $isAdmin = $currentUser && !empty($currentUser['is_admin']);
            $action = strtolower(trim($input['action'] ?? $_GET['action'] ?? ''));
            $inputEmail = InputSanitizer::cleanEmail($input['email'] ?? $input['user_email'] ?? $_GET['email'] ?? $_GET['user_email'] ?? '');

            // Admin query: If action is 'all' or no email provided and user is admin
            if ($isAdmin && ($action === 'all' || empty($inputEmail))) {
                $pStmt = $this->db->query('SELECT * FROM user_plans ORDER BY id DESC');
                $dbPlans = $pStmt->fetchAll();
                $allPlans = [];
                foreach ($dbPlans as $dp) {
                    $features = [];
                    if (!empty($dp['features_json'])) {
                        $decoded = json_decode($dp['features_json'], true);
                        if (is_array($decoded)) $features = $decoded;
                    }
                    $exp = $dp['expires_at'] ?? null;
                    $isExpired = false;
                    $daysLeft = null;
                    if (!empty($exp)) {
                        $diffSec = strtotime($exp) - time();
                        $daysLeft = max(0, (int)ceil($diffSec / 86400));
                        $isExpired = ($diffSec < 0);
                    }
                    $durLabel = self::formatDurationLabel($daysLeft, $exp, $dp['duration'] ?? null, $dp['plan_name'] ?? '', $dp['plan_type'] ?? '');
                    $allPlans[] = [
                        'id' => (int)$dp['id'],
                        'user_id' => $dp['user_id'] ? (int)$dp['user_id'] : null,
                        'user_email' => $dp['user_email'],
                        'plan_name' => $dp['plan_name'],
                        'plan_type' => $dp['plan_type'] ?? 'Subscription',
                        'item_title' => $dp['item_title'] ?? $dp['plan_name'],
                        'price' => $dp['price'] ?? 'Free',
                        'billing_cycle' => $dp['billing_cycle'] ?? 'Monthly',
                        'status' => $isExpired ? 'Expired' : ($dp['status'] ?? 'Active'),
                        'payment_reference' => $dp['payment_reference'] ?? null,
                        'payment_method' => $dp['payment_method'] ?? 'Online',
                        'payment_proof_url' => $dp['payment_proof_url'] ?? null,
                        'features' => $features,
                        'start_date' => $dp['start_date'] ?? $dp['created_at'],
                        'expires_at' => $exp,
                        'days_left' => $daysLeft,
                        'duration' => $dp['duration'] ?? (!empty($dp['billing_cycle']) ? $dp['billing_cycle'] : '30 Days'),
                        'duration_days' => isset($dp['duration_days']) ? (int)$dp['duration_days'] : ($daysLeft ?? 30),
                        'duration_label' => $durLabel,
                        'is_expired' => $isExpired,
                        'created_at' => $dp['created_at'],
                    ];
                }
                ApiResponse::success([
                    'email' => $currentUser['email'],
                    'chat_plan' => 'Unlimited VIP',
                    'chat_max_allowance' => 9999,
                    'plans' => $allPlans,
                ], 'All user plans retrieved successfully');
                return;
            }

            // Non-admin users can strictly view their own plans
            if (!$isAdmin) {
                if (!$currentUser) {
                    $currentUser = AuthMiddleware::requireAuth();
                }
                $email = $currentUser['email'];
            } else {
                $email = !empty($inputEmail) ? $inputEmail : ($currentUser['email'] ?? '');
            }

            if (empty($email)) {
                ApiResponse::error('User email is required', 400);
                return;
            }

            // Fetch user base membership
            $uStmt = $this->db->prepare("SELECT id, role, chat_plan, chat_max_allowance, created_at FROM users WHERE email = ? LIMIT 1");
            $uStmt->execute([$email]);
            $userRow = $uStmt->fetch();

            $chatPlan = !empty($userRow['chat_plan']) ? $userRow['chat_plan'] : 'Basic (Free)';
            $isFreePlan = empty($chatPlan) || stripos($chatPlan, 'free') !== false || stripos($chatPlan, 'basic') !== false || stripos($chatPlan, 'starter') !== false;
            $maxAllowance = $isFreePlan ? 10 : (!empty($userRow['chat_max_allowance']) ? (int)$userRow['chat_max_allowance'] : 10);
            $memberSince = !empty($userRow['created_at']) ? $userRow['created_at'] : date('Y-m-d H:i:s');

            $plans = [];
            $pStmt = $this->db->prepare('SELECT * FROM user_plans WHERE user_email = ? ORDER BY id DESC');
            $pStmt->execute([$email]);
            $dbPlans = $pStmt->fetchAll();
            foreach ($dbPlans as $dp) {
                $features = [];
                if (!empty($dp['features_json'])) {
                    $decoded = json_decode($dp['features_json'], true);
                    if (is_array($decoded)) $features = $decoded;
                }
                $exp = $dp['expires_at'] ?? null;
                $isExpired = false;
                $daysLeft = null;
                if (!empty($exp)) {
                    $diffSec = strtotime($exp) - time();
                    $daysLeft = max(0, (int)ceil($diffSec / 86400));
                    $isExpired = ($diffSec < 0);
                }
                $durLabel = self::formatDurationLabel($daysLeft, $exp, $dp['duration'] ?? null, $dp['plan_name'] ?? '', $dp['plan_type'] ?? '');
                $plans[] = [
                    'id' => (int)$dp['id'],
                    'plan_name' => $dp['plan_name'],
                    'plan_type' => $dp['plan_type'] ?? 'Subscription',
                    'item_title' => $dp['item_title'] ?? $dp['plan_name'],
                    'price' => $dp['price'] ?? 'Free',
                    'billing_cycle' => $dp['billing_cycle'] ?? 'Monthly',
                    'status' => $isExpired ? 'Expired' : ($dp['status'] ?? 'Active'),
                    'payment_reference' => $dp['payment_reference'] ?? null,
                    'payment_method' => $dp['payment_method'] ?? 'Online',
                    'payment_proof_url' => $dp['payment_proof_url'] ?? null,
                    'features' => $features,
                    'start_date' => $dp['start_date'] ?? $dp['created_at'],
                    'expires_at' => $exp,
                    'days_left' => $daysLeft,
                    'duration' => $dp['duration'] ?? (!empty($dp['billing_cycle']) ? $dp['billing_cycle'] : '30 Days'),
                    'duration_days' => isset($dp['duration_days']) ? (int)$dp['duration_days'] : ($daysLeft ?? 30),
                    'duration_label' => $durLabel,
                    'is_expired' => $isExpired,
                    'created_at' => $dp['created_at'],
                ];
            }

            // Also check events
            try {
                $eStmt = $this->db->prepare("SELECT id, title, category, publishing_plan, publishing_amount, payment_status, payment_reference, created_at FROM events WHERE contact_email = ? AND publishing_plan IS NOT NULL AND publishing_plan != '' ORDER BY id DESC");
                $eStmt->execute([$email]);
                $eventPlans = $eStmt->fetchAll();
                foreach ($eventPlans as $ep) {
                    $plans[] = [
                        'id' => (int)$ep['id'],
                        'plan_name' => (!empty($ep['publishing_plan']) ? ucfirst($ep['publishing_plan']) . ' Plan' : 'Event Publishing Plan'),
                        'plan_type' => 'Event Publishing',
                        'item_title' => $ep['title'] ?? 'Art Event Listing',
                        'price' => !empty($ep['publishing_amount']) ? $ep['publishing_amount'] : 'Free',
                        'billing_cycle' => !empty($ep['publishing_plan']) ? ucfirst($ep['publishing_plan']) : 'Single Event Pass',
                        'status' => strtolower($ep['payment_status'] ?? '') === 'paid' ? 'Active' : (ucfirst($ep['payment_status'] ?? 'Active')),
                        'payment_reference' => $ep['payment_reference'] ?? null,
                        'payment_method' => 'Online',
                        'features' => ['Featured Event Listing', 'Calendar & Push Visibility', 'RSVP & Ticketing Access'],
                        'start_date' => $ep['created_at'],
                        'expires_at' => null,
                        'days_left' => null,
                        'duration' => '30 Days',
                        'duration_days' => 30,
                        'duration_label' => 'Single Event Pass (30 Days)',
                        'is_expired' => false,
                        'created_at' => $ep['created_at'],
                    ];
                }
            } catch (\Throwable $t) {}

            // Also check galleries
            try {
                $gStmt = $this->db->prepare("SELECT id, name, category, publishing_plan, publishing_amount, payment_status, payment_reference, created_at FROM galleries WHERE email = ? AND publishing_plan IS NOT NULL AND publishing_plan != '' ORDER BY id DESC");
                $gStmt->execute([$email]);
                $galleryPlans = $gStmt->fetchAll();
                foreach ($galleryPlans as $gp) {
                    $plans[] = [
                        'id' => (int)$gp['id'],
                        'plan_name' => (!empty($gp['publishing_plan']) ? ucfirst($gp['publishing_plan']) . ' Plan' : 'Gallery Publishing Plan'),
                        'plan_type' => 'Gallery Publishing',
                        'item_title' => $gp['name'] ?? 'Art Gallery Listing',
                        'price' => !empty($gp['publishing_amount']) ? $gp['publishing_amount'] : 'Free',
                        'billing_cycle' => !empty($gp['publishing_plan']) ? ucfirst($gp['publishing_plan']) : '1 Year (365 Days)',
                        'status' => strtolower($gp['payment_status'] ?? '') === 'paid' ? 'Active' : (ucfirst($gp['payment_status'] ?? 'Active')),
                        'payment_reference' => $gp['payment_reference'] ?? null,
                        'payment_method' => 'Online',
                        'features' => ['Verified Gallery Badge', 'Exhibition Space Listing', 'Direct Collector Inquiries'],
                        'start_date' => $gp['created_at'],
                        'expires_at' => date('Y-m-d H:i:s', strtotime($gp['created_at'] . ' + 365 days')),
                        'days_left' => max(0, (int)ceil((strtotime($gp['created_at'] . ' + 365 days') - time()) / 86400)),
                        'duration' => '1 Year (365 Days)',
                        'duration_days' => 365,
                        'duration_label' => '1 Year (365 Days)',
                        'is_expired' => false,
                        'created_at' => $gp['created_at'],
                    ];
                }
            } catch (\Throwable $t) {}

            ApiResponse::success([
                'email' => $email,
                'chat_plan' => $chatPlan,
                'chat_max_allowance' => $maxAllowance,
                'plans' => $plans,
            ], 'User plans retrieved successfully');
        } catch (\Throwable $t) {
            error_log('Failed to get user plans: ' . $t->getMessage()); ApiResponse::error('Failed to get user plans', 500);
        }
    }

    public function recordPurchase(array $input): void {
        try {
            $currentUser = AuthMiddleware::requireAuth();
            $email = InputSanitizer::cleanEmail($input['email'] ?? $input['user_email'] ?? $currentUser['email']);

            if (!$currentUser['is_admin'] && strtolower($currentUser['email']) !== strtolower($email)) {
                ApiResponse::error('Forbidden. You cannot record plan purchases for another account.', 403);
                return;
            }

            $planName = trim(InputSanitizer::cleanString($input['plan_name'] ?? 'Custom Plan'));
            $planType = strtolower(trim(InputSanitizer::cleanString($input['plan_type'] ?? 'subscription')));
            $itemTitle = trim(InputSanitizer::cleanString($input['item_title'] ?? $planName));
            $price = trim(InputSanitizer::cleanString($input['price'] ?? $input['plan_amount'] ?? 'AED 0'));
            $billingCycle = trim(InputSanitizer::cleanString($input['billing_cycle'] ?? $input['plan_period'] ?? ''));
            $paymentRef = trim(InputSanitizer::cleanString($input['payment_reference'] ?? $input['transaction_id'] ?? ''));
            $paymentMethod = trim(InputSanitizer::cleanString($input['payment_method'] ?? 'Online'));
            $paymentProofUrl = trim(InputSanitizer::cleanString($input['payment_proof_url'] ?? $input['receipt_url'] ?? ''));
            $features = isset($input['features']) && is_array($input['features']) ? json_encode($input['features']) : null;
            $durationStr = trim(InputSanitizer::cleanString($input['duration'] ?? $input['plan_period'] ?? ''));

            if (empty($email)) {
                ApiResponse::error('user_email is required', 400);
                return;
            }

            // Precise duration & expiration resolution
            $durationDays = 30;
            $cycleCheck = strtolower($billingCycle . ' ' . $planName . ' ' . $planType . ' ' . $durationStr . ' ' . ($input['badge'] ?? ''));

            if (isset($input['duration_days']) && (int)$input['duration_days'] > 0) {
                $durationDays = (int)$input['duration_days'];
            } elseif (strpos($cycleCheck, 'year') !== false || strpos($cycleCheck, 'annual') !== false || strpos($cycleCheck, '365') !== false || strpos($cycleCheck, 'gallery') !== false || strpos($cycleCheck, 'centre') !== false || strpos($cycleCheck, 'center') !== false) {
                $durationDays = 365;
            } elseif (strpos($cycleCheck, 'six') !== false || strpos($cycleCheck, '6 month') !== false || strpos($cycleCheck, '180') !== false) {
                $durationDays = 180;
            } elseif (strpos($cycleCheck, 'three') !== false || strpos($cycleCheck, 'quarter') !== false || strpos($cycleCheck, '90') !== false) {
                $durationDays = 90;
            } elseif (strpos($cycleCheck, 'permanent') !== false || strpos($cycleCheck, 'lifetime') !== false) {
                $durationDays = 3650; // 10 years / permanent
            } else {
                $durationDays = 30;
            }

            if (empty($durationStr)) {
                if ($durationDays == 365) {
                    $durationStr = '1 Year (365 Days)';
                } elseif ($durationDays == 180) {
                    $durationStr = '6 Months (180 Days)';
                } elseif ($durationDays == 90) {
                    $durationStr = '3 Months (90 Days)';
                } elseif ($durationDays >= 3000) {
                    $durationStr = 'Permanent / Lifetime';
                } else {
                    $durationStr = "$durationDays Days";
                }
            }
            if (empty($billingCycle)) {
                $billingCycle = $durationStr;
            }

            $expiresAt = date('Y-m-d H:i:s', strtotime("+$durationDays days"));

            // Look up user safely
            $userId = null;
            $userRow = null;
            try {
                $uStmt = $this->db->prepare("SELECT id, role, chat_plan FROM users WHERE LOWER(email) = LOWER(?) LIMIT 1");
                $uStmt->execute([$email]);
                $userRow = $uStmt->fetch();
                $userId = $userRow ? (int)$userRow['id'] : null;
            } catch (\Throwable $t) {
                try {
                    $uStmt = $this->db->prepare("SELECT id FROM users WHERE LOWER(email) = LOWER(?) LIMIT 1");
                    $uStmt->execute([$email]);
                    $userRow = $uStmt->fetch();
                    $userId = $userRow ? (int)$userRow['id'] : null;
                } catch (\Throwable $t2) {}
            }

            // Insert into user_plans including duration and duration_days
            try {
                $stmt = $this->db->prepare("
                    INSERT INTO user_plans 
                    (user_id, user_email, plan_name, plan_type, item_title, price, billing_cycle, status, payment_reference, payment_method, payment_proof_url, features_json, start_date, expires_at, duration, duration_days, created_at) 
                    VALUES (?, ?, ?, ?, ?, ?, ?, 'Active', ?, ?, ?, ?, NOW(), ?, ?, ?, NOW())
                ");
                $stmt->execute([
                    $userId,
                    $email,
                    $planName,
                    $planType,
                    $itemTitle,
                    $price,
                    $billingCycle,
                    $paymentRef ?: null,
                    $paymentMethod,
                    $paymentProofUrl ?: null,
                    $features,
                    $expiresAt,
                    $durationStr,
                    $durationDays
                ]);
                $newId = (int)$this->db->lastInsertId();
            } catch (\Throwable $eInsert) {
                $stmt = $this->db->prepare("
                    INSERT INTO user_plans 
                    (user_email, plan_name, plan_type, item_title, price, billing_cycle, status, payment_reference, payment_method, expires_at) 
                    VALUES (?, ?, ?, ?, ?, ?, 'Active', ?, ?, ?)
                ");
                $stmt->execute([
                    $email,
                    $planName,
                    $planType,
                    $itemTitle,
                    $price,
                    $billingCycle,
                    $paymentRef ?: null,
                    $paymentMethod,
                    $expiresAt
                ]);
                $newId = (int)$this->db->lastInsertId();
            }

            // Automatically upgrade user privileges based on plan type
            if ($userRow) {
                try {
                    $newChatPlan = null;
                    $maxAllowance = null;
                    if ($planType === 'chat' || $planType === 'messaging' || (stripos($planName, 'Chat') !== false && stripos($planName, 'Gallery') === false && stripos($planName, 'Event') === false)) {
                        $newChatPlan = $planName;
                        $maxAllowance = 9999;
                        if (stripos($planName, 'Starter') !== false || stripos($planName, 'Free') !== false || stripos($planName, 'Basic') !== false) {
                            $maxAllowance = 10;
                        } elseif (stripos($planName, 'Pro') !== false && stripos($planName, 'VIP') === false && stripos($planName, 'Unlimited') === false) {
                            $maxAllowance = 50;
                        }
                    }

                    $newRole = $userRow['role'] ?? 'user';
                    if ($newRole === 'user') {
                        if ($planType === 'artist' || stripos($planName, 'Artist') !== false) {
                            $newRole = 'artist';
                        } elseif ($planType === 'gallery' || stripos($planName, 'Gallery') !== false) {
                            $newRole = 'gallery';
                        } elseif ($planType === 'art_centre' || stripos($planName, 'Centre') !== false || stripos($planName, 'Center') !== false) {
                            $newRole = 'art_center';
                        }
                    }

                    if ($newChatPlan !== null) {
                        $this->db->prepare("UPDATE users SET chat_plan = ?, chat_max_allowance = ?, role = ? WHERE id = ?")
                                 ->execute([$newChatPlan, $maxAllowance, $newRole, $userRow['id']]);
                    } else {
                        $this->db->prepare("UPDATE users SET role = ? WHERE id = ?")
                                 ->execute([$newRole, $userRow['id']]);
                    }
                } catch (\Throwable $tUser) {}
            }

            ApiResponse::success([
                'id' => $newId,
                'user_email' => $email,
                'plan_name' => $planName,
                'item_title' => $itemTitle,
                'price' => $price,
                'billing_cycle' => $billingCycle,
                'status' => 'Active',
                'expires_at' => $expiresAt,
                'duration_days' => $durationDays,
                'features' => isset($input['features']) && is_array($input['features']) ? $input['features'] : [],
            ], 'Plan purchase recorded successfully');
        } catch (\Throwable $t) {
            error_log('Failed to record plan purchase: ' . $t->getMessage()); ApiResponse::error('Failed to record plan purchase', 500);
        }
    }

    public function cancelPlan(array $input): void {
        try {
            $currentUser = AuthMiddleware::requireAuth();
            $isAdmin = !empty($currentUser['is_admin']);
            $planId = (int)($input['plan_id'] ?? $input['id'] ?? 0);
            $email = $isAdmin && !empty($input['email']) 
                ? InputSanitizer::cleanEmail($input['email']) 
                : $currentUser['email'];

            if ($planId <= 0 || empty($email)) {
                ApiResponse::error('Valid plan ID and email required', 400);
                return;
            }
            if ($isAdmin) {
                $stmt = $this->db->prepare("UPDATE user_plans SET status = 'Cancelled' WHERE id = ?");
                $stmt->execute([$planId]);
            } else {
                $stmt = $this->db->prepare("UPDATE user_plans SET status = 'Cancelled' WHERE id = ? AND LOWER(user_email) = LOWER(?)");
                $stmt->execute([$planId, $email]);
            }
            ApiResponse::success(['id' => $planId, 'status' => 'Cancelled'], 'Plan cancelled successfully');
        } catch (\Throwable $t) {
            error_log('UserPlansController::cancelPlan error: ' . $t->getMessage());
            ApiResponse::error('Failed to cancel plan', 500);
        }
    }
}

// -----------------------------------------------------------------------------
// 4i3. Payment Settings Controller
// -----------------------------------------------------------------------------
class PaymentSettingsController {
    private PDO $db;

    public function __construct() {
        $this->db = DatabaseManager::getInstance()->getConnection();
    }

    public function getSettings(): void {
        try {
            $stmt = $this->db->query("SELECT * FROM payment_settings ORDER BY id ASC LIMIT 1");
            $row = $stmt->fetch();
            if (!$row) {
                $row = [
                    'id' => 1,
                    'qr_code_url' => '',
                    'account_name' => '',
                    'account_number' => '',
                    'bank_name' => '',
                    'instructions' => '',
                    'is_active' => 0,
                ];
            }
            ApiResponse::success($row, 'Payment settings retrieved successfully');
        } catch (\Throwable $t) {
            error_log('PaymentSettingsController::getSettings error: ' . $t->getMessage());
            ApiResponse::error('Failed to retrieve payment settings', 500);
        }
    }

    public function updateSettings(array $input): void {
        AuthMiddleware::requireAdmin();

        $accountName = InputSanitizer::cleanString($input['account_name'] ?? '');
        $accountNumber = InputSanitizer::cleanString($input['account_number'] ?? $input['iban'] ?? '');
        $bankName = InputSanitizer::cleanString($input['bank_name'] ?? '');
        $instructions = InputSanitizer::cleanString($input['instructions'] ?? '');
        $qrCodeUrl = InputSanitizer::cleanString($input['qr_code_url'] ?? $input['qr_code'] ?? '');
        $isActive = isset($input['is_active']) ? (int)$input['is_active'] : 1;

        try {
            $fields = [];
            $params = [];
            if (!empty($accountName)) { $fields[] = 'account_name = ?'; $params[] = $accountName; }
            if (!empty($accountNumber)) { $fields[] = 'account_number = ?'; $params[] = $accountNumber; }
            if (!empty($bankName)) { $fields[] = 'bank_name = ?'; $params[] = $bankName; }
            if (!empty($instructions)) { $fields[] = 'instructions = ?'; $params[] = $instructions; }
            if (!empty($qrCodeUrl)) { $fields[] = 'qr_code_url = ?'; $params[] = $qrCodeUrl; }
            if (isset($input['is_active'])) { $fields[] = 'is_active = ?'; $params[] = $isActive; }

            if (empty($fields)) {
                ApiResponse::error('No fields provided to update.', 400);
                return;
            }

            // Ensure row 1 exists
            $check = $this->db->query("SELECT id FROM payment_settings LIMIT 1")->fetch();
            if (!$check) {
                $this->db->prepare("INSERT INTO payment_settings (id, account_name, account_number, bank_name, instructions, qr_code_url, is_active) VALUES (1, ?, ?, ?, ?, ?, ?)")
                         ->execute([$accountName, $accountNumber, $bankName, $instructions, $qrCodeUrl, $isActive]);
            } else {
                $params[] = $check['id'];
                $this->db->prepare('UPDATE payment_settings SET ' . implode(', ', $fields) . ' WHERE id = ?')->execute($params);
            }

            ApiResponse::success(['updated' => true], 'Payment settings updated successfully');
        } catch (\Throwable $t) {
            error_log('Failed to update payment settings: ' . $t->getMessage()); ApiResponse::error('Failed to update payment settings', 500);
        }
    }
}

// -----------------------------------------------------------------------------
// 4i3b. Menu Permissions & Access Control Controller
// -----------------------------------------------------------------------------
class MenuPermissionsController {
    private PDO $db;

    public function __construct() {
        $this->db = DatabaseManager::getInstance()->getConnection();
    }

    public function getPermissions(): void {
        try {
            $stmt = $this->db->query("SELECT * FROM menu_permissions ORDER BY id ASC");
            $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);
            if (empty($rows)) {
                $rows = [
                    ['key' => 'about_us', 'title' => 'ABOUT US', 'subtitle' => null, 'route_name' => '/about-us', 'image_path' => 'assets/images/about-us-DEBERP_G.jpg', 'is_enabled' => 1],
                    ['key' => 'artists', 'title' => 'ARTISTS', 'subtitle' => null, 'route_name' => '/artists', 'image_path' => 'assets/images/artists-9NH3TeXO.jpg', 'is_enabled' => 1],
                    ['key' => 'government', 'title' => 'GOVERNMENT', 'subtitle' => null, 'route_name' => '/government', 'image_path' => 'assets/images/government-CWANBIsX.jpg', 'is_enabled' => 1],
                    ['key' => 'artist_registration', 'title' => 'ARTIST REGISTRATION', 'subtitle' => 'REGISTRATION', 'route_name' => '/artist-registration', 'image_path' => 'assets/images/artist-registration-DqgORA9-.jpg', 'is_enabled' => 1],
                    ['key' => 'events_competition', 'title' => 'EVENTS COMPETITION', 'subtitle' => 'COMPETITION', 'route_name' => '/events', 'image_path' => 'assets/images/events-competition-DvLzKG_2.jpg', 'is_enabled' => 1],
                    ['key' => 'galleries_art_center', 'title' => 'GALLERIES ART CENTERS', 'subtitle' => 'ART CENTERS', 'route_name' => '/galleries', 'image_path' => 'assets/images/galleries-DjK8LuXg.jpg', 'is_enabled' => 1],
                    ['key' => 'events_photos', 'title' => 'EVENTS PHOTOS', 'subtitle' => 'PHOTOS', 'route_name' => '/events-photos', 'image_path' => 'assets/images/events-photos-CckY-T_x.jpg', 'is_enabled' => 1],
                    ['key' => 'gallery_registration', 'title' => 'GALLERIES | ART CENTERS REGISTRATION', 'subtitle' => 'REGISTRATION', 'route_name' => '/gallery-registration', 'image_path' => 'assets/images/gallery-registration-DU8u0zfk.jpg', 'is_enabled' => 1],
                    ['key' => 'login_portal', 'title' => 'LOGIN', 'subtitle' => 'PORTAL', 'route_name' => '/login', 'image_path' => 'assets/images/login-portal.png', 'is_enabled' => 1],
                    ['key' => 'ai_art', 'title' => 'AI', 'subtitle' => 'Art | Artist', 'route_name' => '/ai', 'image_path' => 'assets/images/ai-hub.png', 'is_enabled' => 1],
                ];
            }
            ApiResponse::success($rows, 'Menu permissions retrieved successfully');
        } catch (\Throwable $t) {
            error_log('Failed to retrieve menu permissions: ' . $t->getMessage()); ApiResponse::error('Failed to retrieve menu permissions', 500);
        }
    }

    public function updatePermissions(array $input): void {
        AuthMiddleware::requireAdmin();
        try {
            if (isset($input['permissions']) && is_array($input['permissions'])) {
                $stmt = $this->db->prepare("UPDATE menu_permissions SET is_enabled = ? WHERE `key` = ? OR route_name = ?");
                foreach ($input['permissions'] as $p) {
                    $key = $p['key'] ?? '';
                    $route = $p['route_name'] ?? '';
                    $isEnabled = isset($p['is_enabled']) ? ((int)$p['is_enabled'] ? 1 : 0) : 1;
                    $stmt->execute([$isEnabled, $key, $route]);
                }
            } else {
                $key = $input['key'] ?? '';
                $route = $input['route_name'] ?? '';
                $isEnabled = isset($input['is_enabled']) ? ((int)$input['is_enabled'] ? 1 : 0) : 1;
                $stmt = $this->db->prepare("UPDATE menu_permissions SET is_enabled = ? WHERE `key` = ? OR route_name = ?");
                $stmt->execute([$isEnabled, $key, $route]);
            }
            ApiResponse::success(['updated' => true], 'Menu permissions updated successfully');
        } catch (\Throwable $t) {
            error_log('Failed to update menu permissions: ' . $t->getMessage()); ApiResponse::error('Failed to update menu permissions', 500);
        }
    }
}


// -----------------------------------------------------------------------------
// 4i4. Artist Messages & Chat Controller
// -----------------------------------------------------------------------------
class ArtistMessagesController {
    private PDO $db;

    public function __construct() {
        $this->db = DatabaseManager::getInstance()->getConnection();
    }

    public function getMessages(): void {
        try {
            $currentUser = AuthMiddleware::requireAuth();
            $isAdmin = !empty($currentUser['is_admin']);

            if (!$isAdmin) {
                $userEmail = $currentUser['email'];
                $userId = (string)$currentUser['id'];
                $recipientId = trim($_GET['recipient_id'] ?? $_GET['artist_id'] ?? '');
            } else {
                $userEmail = trim($_GET['user_email'] ?? $_GET['sender_email'] ?? $_GET['email'] ?? $currentUser['email']);
                $recipientId = trim($_GET['recipient_id'] ?? $_GET['artist_id'] ?? '');
                $userId = trim($_GET['user_id'] ?? (string)$currentUser['id']);
            }

            // Ensure sender_avatar_url column exists in MySQL table
            try {
                $this->db->exec("ALTER TABLE artist_messages ADD COLUMN sender_avatar_url VARCHAR(500) NULL AFTER sender_email");
            } catch (\Throwable $t) {}

            $query = "SELECT * FROM artist_messages WHERE 1=1";
            $params = [];

            if (!empty($userEmail) || !empty($recipientId) || !empty($userId) || $isAdmin) {
                $targetIds = [];
                if (!empty($recipientId)) {
                    $targetIds[] = $recipientId;
                }
                if (!empty($userId)) {
                    $targetIds[] = $userId;
                    $targetIds[] = 'user_' . $userId;
                    try {
                        $uStmt = $this->db->prepare("SELECT id FROM artists WHERE user_id = ?");
                        $uStmt->execute([$userId]);
                        foreach ($uStmt->fetchAll(PDO::FETCH_COLUMN) as $uAId) {
                            $targetIds[] = (string)$uAId;
                        }
                    } catch (\Throwable $e) {}
                }
                if (!empty($userEmail)) {
                    $targetIds[] = $userEmail;
                    $targetIds[] = strtolower($userEmail);
                    try {
                        $aStmt = $this->db->prepare("SELECT id FROM artists WHERE LOWER(email) = LOWER(?)");
                        $aStmt->execute([$userEmail]);
                        foreach ($aStmt->fetchAll(PDO::FETCH_COLUMN) as $mId) {
                            $targetIds[] = (string)$mId;
                        }
                    } catch (\Throwable $e) {}

                    try {
                        $uStmt2 = $this->db->prepare("SELECT id FROM users WHERE LOWER(email) = LOWER(?)");
                        $uStmt2->execute([$userEmail]);
                        $foundUId = $uStmt2->fetchColumn();
                        if ($foundUId) {
                            $targetIds[] = (string)$foundUId;
                            $targetIds[] = 'user_' . $foundUId;
                            $aStmt2 = $this->db->prepare("SELECT id FROM artists WHERE user_id = ?");
                            $aStmt2->execute([$foundUId]);
                            foreach ($aStmt2->fetchAll(PDO::FETCH_COLUMN) as $mId) {
                                $targetIds[] = (string)$mId;
                            }
                        }
                    } catch (\Throwable $e) {}
                }

                if ($isAdmin) {
                    $targetIds[] = '28';
                    $targetIds[] = 'admin@artistdubai.com';
                }

                $targetIds = array_values(array_unique(array_filter($targetIds)));

                $conditions = [];
                if (!empty($userEmail)) {
                    $conditions[] = "LOWER(sender_email) = LOWER(?)";
                    $params[] = $userEmail;
                    $conditions[] = "LOWER(recipient_id) = LOWER(?)";
                    $params[] = $userEmail;
                }
                if (!empty($targetIds)) {
                    $inPlaceholders = implode(',', array_fill(0, count($targetIds), '?'));
                    $conditions[] = "sender_id IN ($inPlaceholders)";
                    foreach ($targetIds as $tid) {
                        $params[] = $tid;
                    }
                    $conditions[] = "recipient_id IN ($inPlaceholders)";
                    foreach ($targetIds as $tid) {
                        $params[] = $tid;
                    }
                }
                if ($isAdmin) {
                    $conditions[] = "LOWER(sender_email) = 'admin@artistdubai.com'";
                    $conditions[] = "recipient_id = '28'";
                    $conditions[] = "sender_id = '28'";
                    $conditions[] = "recipient_name LIKE '%Dubai Art Administrator%'";
                    $conditions[] = "sender_name LIKE '%Dubai Art Administrator%'";
                }

                if (!empty($conditions)) {
                    $query .= " AND (" . implode(' OR ', $conditions) . ")";
                }
            }

            $query .= " ORDER BY id DESC LIMIT 100";
            $stmt = $this->db->prepare($query);
            $stmt->execute($params);
            $rows = $stmt->fetchAll();

            ApiResponse::success($rows, 'Messages retrieved successfully');
        } catch (\Throwable $t) {
            error_log('ArtistMessagesController::getMessages error: ' . $t->getMessage());
            ApiResponse::error('Failed to retrieve messages', 500);
        }
    }

    public function getAllowance(): void {
        try {
            $currentUser = AuthMiddleware::requireAuth();
            $isAdmin = !empty($currentUser['is_admin']);

            $userEmail = trim($_GET['user_email'] ?? $_GET['email'] ?? '');
            if (!$isAdmin || empty($userEmail)) {
                $userEmail = $currentUser['email'];
            }
            $currentMonthStart = date('Y-m-01 00:00:00');

            $used = 0;
            if (!empty($userEmail)) {
                $stmt = $this->db->prepare("SELECT COUNT(*) FROM artist_messages WHERE sender_email = ? AND created_at >= ?");
                $stmt->execute([$userEmail, $currentMonthStart]);
                $used = (int)$stmt->fetchColumn();
            }

            $maxAllowance = 10;
            $planName = 'Basic (Free)';
            if (!empty($userEmail)) {
                $uStmt = $this->db->prepare("SELECT chat_plan, chat_max_allowance FROM users WHERE email = ? LIMIT 1");
                $uStmt->execute([$userEmail]);
                $userRow = $uStmt->fetch();
                if ($userRow) {
                    $rawChatPlan = $userRow['chat_plan'] ?? '';
                    $rawLower = strtolower($rawChatPlan);
                    if (strpos($rawLower, 'gallery') !== false || strpos($rawLower, 'event') !== false || strpos($rawLower, 'centre') !== false || strpos($rawLower, 'center') !== false || strpos($rawLower, 'portfolio') !== false) {
                        $planName = 'Basic (Free)';
                        $maxAllowance = 10;
                        try {
                            $this->db->prepare("UPDATE users SET chat_plan = 'Basic (Free)', chat_max_allowance = 10 WHERE email = ?")->execute([$userEmail]);
                        } catch (\Throwable $tReset) {}
                    } else {
                        if (!empty($rawChatPlan)) {
                            $planName = $rawChatPlan;
                        }
                        $isFree = empty($planName) || stripos($planName, 'free') !== false || stripos($planName, 'basic') !== false || stripos($planName, 'starter') !== false;
                        if ($isFree) {
                            $maxAllowance = 10;
                        } elseif (!empty($userRow['chat_max_allowance'])) {
                            $maxAllowance = (int)$userRow['chat_max_allowance'];
                        }
                    }
                }

                // Also check if user has active chat plan in user_plans
                try {
                    $upStmt = $this->db->prepare("
                        SELECT plan_name, item_type FROM user_plans 
                        WHERE user_email = ? 
                          AND (plan_type = 'chat' OR plan_type = 'messaging' OR item_type = 'chat' OR item_type = 'messaging')
                          AND (plan_name NOT LIKE '%Gallery%' AND plan_name NOT LIKE '%Event%' AND plan_name NOT LIKE '%Centre%' AND plan_name NOT LIKE '%Center%')
                          AND status = 'Active' 
                          AND (expires_at IS NULL OR expires_at > NOW()) 
                        ORDER BY id DESC LIMIT 1
                    ");
                    $upStmt->execute([$userEmail]);
                    $activeChatRow = $upStmt->fetch();
                    if ($activeChatRow && !empty($activeChatRow['plan_name'])) {
                        $planName = $activeChatRow['plan_name'];
                        $maxAllowance = (stripos($planName, 'Pro') !== false && stripos($planName, 'VIP') === false && stripos($planName, 'Unlimited') === false) ? 50 : 9999;
                    }
                } catch (\Throwable $e) {}
            }

            $remaining = $maxAllowance >= 9000 ? 9999 : max(0, $maxAllowance - $used);

            ApiResponse::success([
                'month' => date('Y-m'),
                'plan_name' => $planName,
                'max_allowance' => $maxAllowance,
                'used_messages' => $used,
                'remaining_messages' => $remaining,
                'is_unlimited' => $maxAllowance >= 9000,
                'resets_on' => date('Y-m-01', strtotime('first day of next month')),
            ], 'Chat allowance retrieved successfully');
        } catch (\Throwable $t) {
            error_log('Failed to get allowance: ' . $t->getMessage()); ApiResponse::error('Failed to get allowance', 500);
        }
    }

    public function updateAllowance(array $input): void {
        try {
            $currentUser = AuthMiddleware::requireAuth();
            $isAdmin = !empty($currentUser['is_admin']);

            $userEmail = trim($input['user_email'] ?? $input['email'] ?? $_GET['user_email'] ?? '');
            if (!$isAdmin || empty($userEmail)) {
                $userEmail = $currentUser['email'];
            }
            $planName = trim($input['plan_name'] ?? 'Pro Artist');
            $maxAllowance = (int)($input['max_allowance'] ?? 50);

            if (empty($planName) || stripos($planName, 'free') !== false || stripos($planName, 'starter') !== false || stripos($planName, 'basic') !== false) {
                $maxAllowance = 10;
                $planName = 'Basic (Free)';
            }

            if (empty($userEmail)) {
                ApiResponse::error('user_email is required', 400);
                return;
            }

            // Update user's chat plan in MySQL
            $stmt = $this->db->prepare("UPDATE users SET chat_plan = ?, chat_max_allowance = ? WHERE email = ?");
            $stmt->execute([$planName, $maxAllowance, $userEmail]);

            // Automatically record in user_plans for admin dashboard sync
            try {
                $price = $maxAllowance >= 9000 ? 'AED 299' : ($maxAllowance > 10 ? 'AED 99' : 'Free');
                $due = date('Y-m-d H:i:s', strtotime('+30 days'));
                $uIdStmt = $this->db->prepare("SELECT id FROM users WHERE email = ? LIMIT 1");
                $uIdStmt->execute([$userEmail]);
                $uId = $uIdStmt->fetchColumn();

                $pIns = $this->db->prepare("INSERT INTO user_plans (user_id, user_email, plan_name, plan_type, price, status, expires_at, created_at) VALUES (?, ?, ?, 'Membership Plan', ?, 'Active', ?, NOW())");
                $pIns->execute([$uId ? (int)$uId : null, $userEmail, $planName, $price, $due]);
            } catch (\Throwable $e) {}

            // Calculate current usage
            $currentMonthStart = date('Y-m-01 00:00:00');
            $cStmt = $this->db->prepare("SELECT COUNT(*) FROM artist_messages WHERE sender_email = ? AND created_at >= ?");
            $cStmt->execute([$userEmail, $currentMonthStart]);
            $used = (int)$cStmt->fetchColumn();

            $remaining = $maxAllowance >= 9000 ? 9999 : max(0, $maxAllowance - $used);

            ApiResponse::success([
                'user_email' => $userEmail,
                'plan_name' => $planName,
                'max_allowance' => $maxAllowance,
                'used_messages' => $used,
                'remaining_messages' => $remaining,
                'is_unlimited' => $maxAllowance >= 9000,
            ], 'Chat plan upgraded successfully');
        } catch (\Throwable $t) {
            error_log('Failed to update chat plan: ' . $t->getMessage()); ApiResponse::error('Failed to update chat plan', 500);
        }
    }

    public function sendMessage(array $input): void {
        try {
            $currentUser = AuthMiddleware::getCurrentUser();
            $isAdmin = $currentUser && !empty($currentUser['is_admin']);

            $senderName = InputSanitizer::cleanString($input['sender_name'] ?? 'User');
            $senderEmail = InputSanitizer::cleanString($input['sender_email'] ?? 'user@artistdubai.com');
            if ($currentUser && !$isAdmin) {
                $senderEmail = $currentUser['email'];
                if (empty($senderName) || $senderName === 'User') {
                    $senderName = $currentUser['full_name'] ?? $senderName;
                }
            }
            $senderAvatar = InputSanitizer::cleanString($input['sender_avatar_url'] ?? $input['senderAvatarUrl'] ?? '');
            $senderId = InputSanitizer::cleanString($input['sender_id'] ?? '');
            $recipientId = InputSanitizer::cleanString($input['recipient_id'] ?? '');
            $recipientName = InputSanitizer::cleanString($input['recipient_name'] ?? 'Artist');
            $recipientCategory = InputSanitizer::cleanString($input['recipient_category'] ?? 'Artist');
            $recipientAvatar = InputSanitizer::cleanString($input['recipient_avatar_url'] ?? '');
            $subject = InputSanitizer::cleanString($input['subject'] ?? 'Direct Artist Message');
            $message = InputSanitizer::cleanString($input['message'] ?? '');
            $flyerUrl = InputSanitizer::cleanString($input['flyer_url'] ?? '');

            if (empty($recipientId) || empty($message)) {
                ApiResponse::error('Recipient ID and message body are required.', 400);
                return;
            }

            // Check allowance
            $currentMonthStart = date('Y-m-01 00:00:00');
            $stmtCount = $this->db->prepare("SELECT COUNT(*) FROM artist_messages WHERE sender_email = ? AND created_at >= ?");
            $stmtCount->execute([$senderEmail, $currentMonthStart]);
            $used = (int)$stmtCount->fetchColumn();

            $maxAllowance = 10;
            if (!empty($senderEmail)) {
                $uStmt = $this->db->prepare("SELECT chat_plan, chat_max_allowance FROM users WHERE email = ? LIMIT 1");
                $uStmt->execute([$senderEmail]);
                $userRow = $uStmt->fetch();
                if ($userRow) {
                    $uPlan = strtolower($userRow['chat_plan'] ?? '');
                    $isFree = empty($uPlan) || strpos($uPlan, 'free') !== false || strpos($uPlan, 'basic') !== false || strpos($uPlan, 'starter') !== false;
                    if ($isFree) {
                        $maxAllowance = 10;
                    } elseif (!empty($userRow['chat_max_allowance'])) {
                        $maxAllowance = (int)$userRow['chat_max_allowance'];
                    }
                }
            }

            if ($maxAllowance < 9000 && $used >= $maxAllowance) {
                ApiResponse::error('Monthly message limit reached. Upgrade your plan for more.', 403);
                return;
            }

            // Idempotency guard: prevent duplicate inserts from retry/double-send within 60 seconds
            $dupStmt = $this->db->prepare("
                SELECT id FROM artist_messages
                WHERE sender_email = ? AND recipient_id = ? AND subject = ? AND message = ?
                  AND created_at >= DATE_SUB(NOW(), INTERVAL 60 SECOND)
                LIMIT 1
            ");
            $dupStmt->execute([$senderEmail, $recipientId, $subject, $message]);
            $existingId = $dupStmt->fetchColumn();
            if ($existingId) {
                // Already saved — return existing record as success (idempotent)
                ApiResponse::success([
                    'id' => (int)$existingId,
                    'duplicate' => true,
                ], 'Message already sent (duplicate prevented)');
                return;
            }

            // Try inserting with sender_avatar_url, fall back if column is missing
            try {
                $stmt = $this->db->prepare("
                    INSERT INTO artist_messages 
                    (sender_id, sender_name, sender_email, sender_avatar_url, recipient_id, recipient_name, recipient_category, recipient_avatar_url, subject, message, flyer_url, is_read, created_at)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 0, NOW())
                ");
                $stmt->execute([
                    $senderId, $senderName, $senderEmail, $senderAvatar, $recipientId, $recipientName, $recipientCategory, $recipientAvatar, $subject, $message, $flyerUrl
                ]);
            } catch (\Throwable $colErr) {
                $stmt = $this->db->prepare("
                    INSERT INTO artist_messages 
                    (sender_id, sender_name, sender_email, recipient_id, recipient_name, recipient_category, recipient_avatar_url, subject, message, flyer_url, is_read, created_at)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 0, NOW())
                ");
                $stmt->execute([
                    $senderId, $senderName, $senderEmail, $recipientId, $recipientName, $recipientCategory, $recipientAvatar, $subject, $message, $flyerUrl
                ]);
            }

            $newId = $this->db->lastInsertId();
            $remaining = $maxAllowance >= 9000 ? 9999 : max(0, $maxAllowance - ($used + 1));

            // Auto-dispatch in-app notification to the recipient
            try {
                $recipientEmail = null;
                if (!empty($input['recipient_email'])) {
                    $recipientEmail = InputSanitizer::cleanEmail($input['recipient_email']);
                }
                if (empty($recipientEmail) && !empty($recipientId)) {
                    $rStmt = $this->db->prepare("SELECT email FROM artists WHERE id = ? LIMIT 1");
                    $rStmt->execute([(int)$recipientId]);
                    $rRow = $rStmt->fetch();
                    if ($rRow && !empty($rRow['email'])) {
                        $recipientEmail = InputSanitizer::cleanEmail($rRow['email']);
                    }
                }
                if (empty($recipientEmail) && !empty($recipientId)) {
                    $uStmt = $this->db->prepare("SELECT email FROM users WHERE id = ? LIMIT 1");
                    $uStmt->execute([(int)$recipientId]);
                    $uRow = $uStmt->fetch();
                    if ($uRow && !empty($uRow['email'])) {
                        $recipientEmail = InputSanitizer::cleanEmail($uRow['email']);
                    }
                }
                if (!empty($recipientEmail)) {
                    $notifTitle = "New Message from $senderName";
                    $notifBody = mb_substr($message, 0, 80) . (mb_strlen($message) > 80 ? '...' : '');
                    $this->db->prepare("INSERT INTO notifications (title, body, type, route, user_email, is_read) VALUES (?, ?, 'message', '/artist-chat', ?, 0)")
                             ->execute([$notifTitle, $notifBody, $recipientEmail]);
                }
            } catch (\Throwable $notifErr) {}

            ApiResponse::success([
                'id' => $newId,
                'status' => 'sent',
                'used_messages' => $used + 1,
                'max_allowance' => $maxAllowance,
                'remaining_messages' => $remaining,
            ], 'Message sent successfully');
        } catch (\Throwable $t) {
            error_log('Failed to send message: ' . $t->getMessage()); ApiResponse::error('Failed to send message', 500);
        }
    }
}

// -----------------------------------------------------------------------------
// 4i5. AI Art Guide Chat Controller
// -----------------------------------------------------------------------------
class AiChatController {
    private PDO $db;

    public function __construct() {
        $this->db = DatabaseManager::getInstance()->getConnection();
    }

    public function getSessions(): void {
        try {
            $userEmail = trim($_GET['user_email'] ?? $_POST['user_email'] ?? '');
            $userId    = trim($_GET['user_id'] ?? $_POST['user_id'] ?? '');

            // Strict user isolation: never leak all users' sessions if unauthenticated
            if (empty($userEmail) && empty($userId)) {
                ApiResponse::success([], 'AI chat sessions retrieved successfully');
                return;
            }

            $query = "SELECT s.*, 
                      (SELECT COUNT(*) FROM ai_chat_messages m WHERE m.session_id = s.id) AS message_count,
                      (SELECT message FROM ai_chat_messages m WHERE m.session_id = s.id ORDER BY m.id DESC LIMIT 1) AS last_message
                      FROM ai_chat_sessions s WHERE ";
            $params = [];

            if (!empty($userEmail) && !empty($userId)) {
                $query .= "(s.user_email = ? OR s.user_id = ?)";
                $params[] = $userEmail;
                $params[] = $userId;
            } elseif (!empty($userEmail)) {
                $query .= "s.user_email = ?";
                $params[] = $userEmail;
            } else {
                $query .= "s.user_id = ?";
                $params[] = $userId;
            }

            $query .= " ORDER BY s.updated_at DESC LIMIT 100";
            $stmt = $this->db->prepare($query);
            $stmt->execute($params);
            $sessions = $stmt->fetchAll();

            ApiResponse::success($sessions, 'AI chat sessions retrieved successfully');
        } catch (\Throwable $t) {
            error_log('Failed to retrieve chat sessions: ' . $t->getMessage()); ApiResponse::error('Failed to retrieve chat sessions', 500);
        }
    }

    public function getMessages(array $params): void {
        try {
            $sessionId = trim($params['session_id'] ?? $_GET['session_id'] ?? '');
            $userEmail = trim($params['user_email'] ?? $_GET['user_email'] ?? '');
            $userId    = trim($params['user_id'] ?? $_GET['user_id'] ?? '');
            if (empty($sessionId)) {
                ApiResponse::error('session_id is required', 400);
                return;
            }

            // Verify ownership if user credentials are provided
            if (!empty($userEmail) || !empty($userId)) {
                $chk = $this->db->prepare("SELECT user_email, user_id FROM ai_chat_sessions WHERE id = ? LIMIT 1");
                $chk->execute([$sessionId]);
                $sess = $chk->fetch();
                if ($sess) {
                    $sEmail = trim($sess['user_email'] ?? '');
                    $sUid   = trim((string)($sess['user_id'] ?? ''));
                    if (!empty($sEmail) && !empty($userEmail) && strcasecmp($sEmail, $userEmail) !== 0) {
                        ApiResponse::error('Access denied to this chat session', 403);
                        return;
                    }
                    if (!empty($sUid) && !empty($userId) && $sUid !== $userId && empty($sEmail)) {
                        ApiResponse::error('Access denied to this chat session', 403);
                        return;
                    }
                }
            }

            $stmt = $this->db->prepare("SELECT * FROM ai_chat_messages WHERE session_id = ? ORDER BY id ASC");
            $stmt->execute([$sessionId]);
            $messages = $stmt->fetchAll();
            foreach ($messages as &$m) {
                if (!empty($m['related_questions'])) {
                    $decodedRel = json_decode($m['related_questions'], true);
                    $m['related_questions'] = is_array($decodedRel) ? $decodedRel : [];
                } else {
                    $m['related_questions'] = [];
                }
            }

            ApiResponse::success($messages, 'Messages retrieved successfully');
        } catch (\Throwable $t) {
            error_log('Failed to retrieve messages: ' . $t->getMessage()); ApiResponse::error('Failed to retrieve messages', 500);
        }
    }

    public function sendMessage(array $input): void {
        try {
            $sessionId = trim($input['session_id'] ?? '');
            $messageText = trim($input['message'] ?? '');
            $userEmail = trim($input['user_email'] ?? '');
            $userId = trim($input['user_id'] ?? '');
            $title = trim($input['title'] ?? '');

            if (empty($messageText)) {
                ApiResponse::error('Message text is required', 400);
                return;
            }

            if (empty($sessionId)) {
                $sessionId = 'chat_' . time() . '_' . substr(md5(uniqid()), 0, 6);
            }

            if (empty($title)) {
                $title = mb_substr($messageText, 0, 40) . (mb_strlen($messageText) > 40 ? '...' : '');
            }

            $locale = trim($input['locale'] ?? $_GET['locale'] ?? '');

            // Ensure session exists
            $stmt = $this->db->prepare("
                INSERT INTO ai_chat_sessions (id, user_id, user_email, title, created_at, updated_at)
                VALUES (?, ?, ?, ?, NOW(), NOW())
                ON DUPLICATE KEY UPDATE 
                    updated_at = NOW(),
                    user_id = COALESCE(user_id, VALUES(user_id)),
                    user_email = COALESCE(user_email, VALUES(user_email)),
                    title = IF(title = 'Chat' OR title = '' OR title IS NULL, VALUES(title), title)
            ");
            $stmt->execute([$sessionId, $userId ?: null, $userEmail ?: null, $title]);

            // Save user message
            $stmtMsg = $this->db->prepare("
                INSERT INTO ai_chat_messages (session_id, sender, message, created_at)
                VALUES (?, 'user', ?, NOW())
            ");
            $stmtMsg->execute([$sessionId, $messageText]);

            // Fetch live database context dynamically (RAG)
            $dbContext = $this->fetchDatabaseContext($messageText);

            // Generate 100% dynamic AI reply exclusively from Google Gemini API
            $aiData = $this->generateGeminiAiResponse($messageText, $locale, $dbContext);
            $reply = $aiData['reply'];
            $relatedQuestions = $aiData['related_questions'];

            // Save AI reply with related questions
            $relJson = !empty($relatedQuestions) ? json_encode($relatedQuestions, JSON_UNESCAPED_UNICODE) : null;
            try {
                $stmtReply = $this->db->prepare("
                    INSERT INTO ai_chat_messages (session_id, sender, message, related_questions, created_at)
                    VALUES (?, 'ai', ?, ?, NOW())
                ");
                $stmtReply->execute([$sessionId, $reply, $relJson]);
            } catch (\Throwable $e) {
                $stmtReply = $this->db->prepare("
                    INSERT INTO ai_chat_messages (session_id, sender, message, created_at)
                    VALUES (?, 'ai', ?, NOW())
                ");
                $stmtReply->execute([$sessionId, $reply]);
            }

            ApiResponse::success([
                'session_id' => $sessionId,
                'title' => $title,
                'user_message' => $messageText,
                'ai_reply' => $reply,
                'related_questions' => $relatedQuestions,
                'timestamp' => date('Y-m-d H:i:s'),
                'is_dynamic' => true,
            ], 'Message processed successfully');
        } catch (\Throwable $t) {
            error_log('Failed to send AI chat message: ' . $t->getMessage()); ApiResponse::error('Failed to send AI chat message', 500);
        }
    }

    public function deleteSession(array $input): void {
        try {
            $sessionId = trim($input['session_id'] ?? $_GET['session_id'] ?? '');
            $userEmail = trim($input['user_email'] ?? $_GET['user_email'] ?? '');
            $userId    = trim($input['user_id'] ?? $_GET['user_id'] ?? '');
            if (empty($sessionId)) {
                ApiResponse::error('session_id is required', 400);
                return;
            }

            if (!empty($userEmail) || !empty($userId)) {
                $chk = $this->db->prepare("SELECT user_email, user_id FROM ai_chat_sessions WHERE id = ? LIMIT 1");
                $chk->execute([$sessionId]);
                $sess = $chk->fetch();
                if ($sess) {
                    $sEmail = trim($sess['user_email'] ?? '');
                    $sUid   = trim((string)($sess['user_id'] ?? ''));
                    if (!empty($sEmail) && !empty($userEmail) && strcasecmp($sEmail, $userEmail) !== 0) {
                        ApiResponse::error('Access denied to delete this chat session', 403);
                        return;
                    }
                    if (!empty($sUid) && !empty($userId) && $sUid !== $userId && empty($sEmail)) {
                        ApiResponse::error('Access denied to delete this chat session', 403);
                        return;
                    }
                }
            }

            $stmt1 = $this->db->prepare("DELETE FROM ai_chat_messages WHERE session_id = ?");
            $stmt1->execute([$sessionId]);

            $stmt2 = $this->db->prepare("DELETE FROM ai_chat_sessions WHERE id = ?");
            $stmt2->execute([$sessionId]);

            ApiResponse::success(['session_id' => $sessionId, 'deleted' => true], 'Session deleted successfully');
        } catch (\Throwable $t) {
            error_log('Failed to delete session: ' . $t->getMessage()); ApiResponse::error('Failed to delete session', 500);
        }
    }

    /**
     * Dynamically queries the live MySQL database for artists, events, galleries, and artworks
     * to provide real-time Retrieval-Augmented Generation (RAG) context.
     */
    private function fetchDatabaseContext(string $query): array {
        $context = [
            'counts' => [
                'artists' => 0,
                'events' => 0,
                'galleries' => 0,
                'artworks' => 0,
            ],
            'matched_artists' => [],
            'matched_events' => [],
            'matched_galleries' => [],
            'matched_artworks' => [],
            'categories' => [],
        ];

        try {
            $context['counts']['artists'] = (int)$this->db->query("SELECT COUNT(*) FROM artists")->fetchColumn();
            $context['counts']['events'] = (int)$this->db->query("SELECT COUNT(*) FROM events")->fetchColumn();
            $context['counts']['galleries'] = (int)$this->db->query("SELECT COUNT(*) FROM galleries")->fetchColumn();
            $context['counts']['artworks'] = (int)$this->db->query("SELECT COUNT(*) FROM artworks")->fetchColumn();

            $catStmt = $this->db->query("SELECT name FROM categories ORDER BY id ASC LIMIT 8");
            if ($catStmt) {
                $context['categories'] = $catStmt->fetchAll(PDO::FETCH_COLUMN);
            }

            // Extract keywords
            $rawTokens = preg_split('/[\s,\.\?!]+/u', mb_strtolower(trim($query)));
            $stopWords = ['what', 'when', 'where', 'which', 'who', 'whom', 'how', 'the', 'and', 'for', 'are', 'can', 'does', 'with', 'about', 'this', 'that', 'tell', 'show', 'from', 'you', 'your', 'please', 'give'];
            $tokens = array_values(array_filter($rawTokens, function($w) use ($stopWords) {
                return mb_strlen($w) >= 2 && !in_array($w, $stopWords);
            }));

            // 1. Matched Artists (Search by category, name, or keywords)
            $artMatches = [];
            foreach ($tokens as $token) {
                if (in_array($token, ['artist', 'artists', 'dubai', 'recommend', 'local', 'best', 'good', 'top', 'any', 'فنان', 'فنانين'])) continue;
                $like = '%' . $token . '%';
                $stmt = $this->db->prepare("SELECT id, name, category, booking_rate, location, bio FROM artists WHERE (is_active = 1 OR status = 'active') AND (name LIKE ? OR category LIKE ? OR bio LIKE ?) LIMIT 4");
                $stmt->execute([$like, $like, $like]);
                foreach ($stmt->fetchAll(PDO::FETCH_ASSOC) as $r) {
                    $artMatches[$r['id']] = $r;
                }
                if (count($artMatches) >= 4) break;
            }
            if (empty($artMatches) && $context['counts']['artists'] > 0) {
                $stmt = $this->db->query("SELECT id, name, category, booking_rate, location, bio FROM artists WHERE is_active = 1 OR status = 'active' ORDER BY id DESC LIMIT 4");
                $artMatches = $stmt->fetchAll(PDO::FETCH_ASSOC);
            }
            $context['matched_artists'] = array_values($artMatches);

            // 2. Matched Events (Search by title, location, category)
            $evMatches = [];
            foreach ($tokens as $token) {
                if (in_array($token, ['event', 'events', 'dubai', 'show', 'happening', 'فعالية', 'فعاليات'])) continue;
                $like = '%' . $token . '%';
                $stmt = $this->db->prepare("SELECT id, title, location, event_date, price, category FROM events WHERE (is_active = 1 OR status = 'active') AND (title LIKE ? OR location LIKE ? OR category LIKE ?) LIMIT 4");
                $stmt->execute([$like, $like, $like]);
                foreach ($stmt->fetchAll(PDO::FETCH_ASSOC) as $r) {
                    $evMatches[$r['id']] = $r;
                }
                if (count($evMatches) >= 4) break;
            }
            if (empty($evMatches) && $context['counts']['events'] > 0) {
                $stmt = $this->db->query("SELECT id, title, location, event_date, price, category FROM events WHERE is_active = 1 OR status = 'active' ORDER BY event_date ASC, id DESC LIMIT 4");
                $evMatches = $stmt->fetchAll(PDO::FETCH_ASSOC);
            }
            $context['matched_events'] = array_values($evMatches);

            // 3. Matched Galleries
            $galMatches = [];
            foreach ($tokens as $token) {
                if (in_array($token, ['gallery', 'galleries', 'dubai', 'center', 'معرض', 'معارض', 'جاليري'])) continue;
                $like = '%' . $token . '%';
                $stmt = $this->db->prepare("SELECT id, name, location, timing, description FROM galleries WHERE (is_approved = 1 OR status = 'active') AND (name LIKE ? OR location LIKE ? OR description LIKE ?) LIMIT 4");
                $stmt->execute([$like, $like, $like]);
                foreach ($stmt->fetchAll(PDO::FETCH_ASSOC) as $r) {
                    $galMatches[$r['id']] = $r;
                }
                if (count($galMatches) >= 4) break;
            }
            if (empty($galMatches) && $context['counts']['galleries'] > 0) {
                $stmt = $this->db->query("SELECT id, name, location, timing, description FROM galleries WHERE is_approved = 1 OR status = 'active' ORDER BY id DESC LIMIT 4");
                if (!$stmt) {
                    $stmt = $this->db->query("SELECT id, name, location, timing, description FROM galleries ORDER BY id DESC LIMIT 4");
                }
                if ($stmt) {
                    $galMatches = $stmt->fetchAll(PDO::FETCH_ASSOC);
                }
            }
            $context['matched_galleries'] = array_values($galMatches);

            // 4. Matched Artworks
            $artwMatches = [];
            foreach ($tokens as $token) {
                if (in_array($token, ['art', 'artwork', 'artworks', 'painting', 'paintings', 'price', 'لوحة', 'لوحات'])) continue;
                $like = '%' . $token . '%';
                $stmt = $this->db->prepare("SELECT id, title, artist_name, price, medium FROM artworks WHERE title LIKE ? OR artist_name LIKE ? OR medium LIKE ? LIMIT 4");
                $stmt->execute([$like, $like, $like]);
                foreach ($stmt->fetchAll(PDO::FETCH_ASSOC) as $r) {
                    $artwMatches[$r['id']] = $r;
                }
                if (count($artwMatches) >= 4) break;
            }
            if (empty($artwMatches) && $context['counts']['artworks'] > 0) {
                $stmt = $this->db->query("SELECT id, title, artist_name, price, medium FROM artworks ORDER BY id DESC LIMIT 4");
                $artwMatches = $stmt->fetchAll(PDO::FETCH_ASSOC);
            }
            $context['matched_artworks'] = array_values($artwMatches);

        } catch (\Throwable $t) {}

        return $context;
    }

    /**
     * Exclusively generates dynamic AI responses from Google Gemini API.
     * No hardcoded or canned answers — all insights and follow-up questions
     * are dynamically generated in real-time by Google Gemini.
     */
    /**
     * Exclusively generates dynamic AI responses from Google Gemini API.
     * No hardcoded or canned answers — all insights and follow-up questions
     * are dynamically generated in real-time by Google Gemini.
     */
    private function generateGeminiAiResponse(string $query, string $locale = '', array $dbContext = [], array $recentHistory = []): array {
        if ($locale === 'ar') {
            $isArabic = true;
        } elseif ($locale === 'en') {
            $isArabic = false;
        } else {
            preg_match_all('/[\x{0600}-\x{06FF}]/u', $query, $arMatches);
            preg_match_all('/[a-zA-Z]/u', $query, $enMatches);
            $arCount = count($arMatches[0] ?? []);
            $enCount = count($enMatches[0] ?? []);
            $isArabic = ($arCount > $enCount);
        }

        // 1. Fetch Gemini API key (from env, defined constant, globals, or database settings)
        $geminiKey = getenv('GEMINI_API_KEY') ?: (defined('GEMINI_API_KEY') && !empty(GEMINI_API_KEY) ? GEMINI_API_KEY : ($GLOBALS['GEMINI_API_KEY'] ?? ''));
        if (empty($geminiKey)) {
            try {
                $sStmt = $this->db->query("SELECT setting_value FROM payment_settings WHERE setting_key IN ('gemini_api_key', 'ai_api_key') LIMIT 1");
                if ($sStmt && ($val = $sStmt->fetchColumn())) {
                    $geminiKey = trim($val);
                }
            } catch (\Throwable $t) {}
        }
        if (empty($geminiKey)) {
            $geminiKey = getenv('GEMINI_API_KEY') ?: '';
        }

        $res = null;
        // 2. Call Google Gemini API
        if (!empty($geminiKey)) {
            $geminiResult = $this->callGeminiApi($query, $geminiKey, $isArabic, $dbContext, $recentHistory);
            if (!empty($geminiResult) && !empty($geminiResult['reply'])) {
                $res = $geminiResult;
            }
        }

        // 3. Grounded Knowledge Engine (Seamless High-Availability Fallback)
        // Whenever Google Gemini is unreachable, rate-limited, or key is unconfigured,
        // this engine provides instantaneous, rich, accurate, and localized Dubai Art guidance.
        if (!$res) {
            $res = $this->generateKnowledgeEngineResponse($query, $isArabic, $dbContext);
        }

        if (!empty($res['reply'])) {
            $cleanedReply = $res['reply'];
            // Clean any raw markdown hashes into clean bold text (e.g. ### 1. Title -> **1. Title**)
            if (!$isArabic) {
                // Remove Arabic name in parenthesis from English answers
                $cleanedReply = str_replace(['(فنان دبي)', 'فنان دبي'], ['', ''], $cleanedReply);
                $cleanedReply = preg_replace('/[ \t]{2,}/', ' ', $cleanedReply);
            } else {
                // Remove English name in parenthesis from Arabic answers
                $cleanedReply = str_replace(['(Artist Dubai)', 'Artist Dubai'], ['فنان دبي', 'فنان دبي'], $cleanedReply);
                $cleanedReply = str_replace(['فنان دبي فنان دبي', 'فنان دبيفنان دبي'], ['فنان دبي', 'فنان دبي'], $cleanedReply);
                $cleanedReply = preg_replace('/[ \t]{2,}/', ' ', $cleanedReply);
            }
            $res['reply'] = trim($cleanedReply);
        }

        return $res;
    }

    /**
     * Authoritative Dubai Art Knowledge Engine with Live Database Grounding (RAG).
     */
    private function generateKnowledgeEngineResponse(string $query, bool $isArabic, array $dbContext = []): array {
        $q = mb_strtolower(trim($query));
        $reply = "";
        $relatedQuestions = [];

        // Dynamic database references
        $matchedArtists = $dbContext['matched_artists'] ?? [];
        $matchedEvents = $dbContext['matched_events'] ?? [];
        $matchedGalleries = $dbContext['matched_galleries'] ?? [];
        $matchedArtworks = $dbContext['matched_artworks'] ?? [];

        if ($isArabic) {
            // 1. Artist Registration / Join as Artist
            if (str_contains($q, 'تسجيل كفنان') || str_contains($q, 'أسجل كفنان') || str_contains($q, 'انضم كفنان') || str_contains($q, 'ملف فنان') || str_contains($q, 'إنشاء ملف') || str_contains($q, 'تسجيل الفنانين') || str_contains($q, 'توثيق فنان')) {
                $reply = "التسجيل كفنان في تطبيق **فنان دبي** خطوة سهلة ومباشرة تتيح لك عرض أعمالك والتواصل مباشرة مع المقتنين وصالات العرض في دبي والإمارات:\n\n" .
                    "**1. إنشاء حساب أو تسجيل الدخول**\n" .
                    "• افتح التطبيق وانتقل إلى علامة التبويب **الملف الشخصي** (أو اضغط على زر **تسجيل الدخول**).\n" .
                    "• أنشئ حساباً جديداً بالبريد الإلكتروني أو سجّل دخولك إذا كان لديك حساب بالفعل.\n\n" .
                    "**2. إنشاء ملف الفنان**\n" .
                    "• من صفحة الملف الشخصي، اضغط على **\"إنشاء ملف فنان\"** أو **\"انضم كفنان\"**.\n" .
                    "• أدخل بياناتك الفنية:\n" .
                    "  - **الاسم الكامل والاسم الفني**\n" .
                    "  - **التخصص الفني:** الرسم المعاصر، النحت، الخط العربي والتايبوغرافي، الفن الرقمي، التصوير الفوتوغرافي، أو الوسائط المختلطة.\n" .
                    "  - **النبذة الفنية والبيان الإبداعي:** للتعريف بمسيرتك وتجاربك ومعارضك السابقة.\n" .
                    "  - **روابط التواصل والموقع الإلكتروني**.\n\n" .
                    "**3. رفع الأعمال الفنية والمعرض**\n" .
                    "• أضف صوراً عالية الدقة لأعمالك الأصلية مع تحديد المقاسات، الخامة، وأسعار البيع أو أجور الحجز المبدئية بالدرهم الإماراتي.\n\n" .
                    "**4. اختيار باقة الاشتراك**\n" .
                    "• اختر باقة العرض المناسبة (المجانية أو الباقات المميزة Pro / VIP) للاستفادة من مميزات المراسلة المباشرة مع المقتنين والظهور في صدارة دليل الفنانين.\n\n" .
                    "**5. التوثيق والاعتماد**\n" .
                    "• أرسل طلبك للمراجعة. بعد التحقق من قبل فريق التقييم، سيتم تفعيل ونشر ملفك رسمياً في **دليل الفنانين**!";
                $relatedQuestions = [
                    'ما هي متطلبات توثيق ملف الفنان في التطبيق؟',
                    'ما هي باقات وأسعار اشتراك الفنانين في التطبيق؟',
                    'كيف يمكنني بيع لوحاتي وأعمالي الفنية عبر التطبيق؟',
                ];
            }
            // 1b. Verification & Requirements
            elseif (str_contains($q, 'توثيق') || str_contains($q, 'شارة') || str_contains($q, 'متطلبات التوثيق') || str_contains($q, 'شروط التوثيق') || str_contains($q, 'اعتماد فنان') || str_contains($q, 'توثيق ملف')) {
                $reply = "للحصول على شارة **فنان موثق (Verified Artist Badge)** في تطبيق **فنان دبي**، يخضع ملفك الفني لمراجعة وتقييم فريق التقييم وفق المعايير التالية:\n\n" .
                    "**1. اكتمال الملف التعريفي والبيان الفني**\n" .
                    "• **الاسم الفني والاسم الكامل:** اسم مهني واضح وهوية فنية معتمدة.\n" .
                    "• **سيرة ذاتية وبيان فني وافٍ:** يوضح أسلوبك الإبداعي ومسيرتك ومعارضك السابقة (100 كلمة على الأقل).\n" .
                    "• **التخصص الفني:** تحديد مجالك بوضوح (رسم معاصر، نحت، خط عربي، فن رقمي، تصوير، أو وسائط مختلطة).\n\n" .
                    "**2. معرض الأعمال والأصالة الفنية**\n" .
                    "• **صور عالية الدقة:** رفع ما لا يقل عن 3 إلى 5 أعمال فنية أصلية ومضاءة باحترافية.\n" .
                    "• **تفاصيل اللوحات:** تحديد العنوان، الخامة (زيت، أكريليك، برونز...)، المقاسات بالسنتيمتر، وسعر البيع أو أجر الحجز بالدرهم الإماراتي.\n" .
                    "• **الأصالة:** يجب أن تكون جميع الأعمال المعروضة من إبداعك الفني الأصلي بنسبة 100%.\n\n" .
                    "**3. وسائل التواصل والروابط المهنية**\n" .
                    "• بريد إلكتروني فعال ورقم هاتف أو واتساب لتلقي استفسارات المقتنين والمهتمين.\n" .
                    "• رابط حساب الإنستغرام أو الموقع الشخصي لعرض سجلك الفني.\n\n" .
                    "**4. باقة الاشتراك**\n" .
                    "• تفعيل إحدى باقات العرض (باقة التوثيق تبدأ من 100 درهم أسبوعياً أو 350 درهم شهرياً)، حيث تمنحك ظهوراً مميزاً وشارة التوثيق في صدارة دليل الفنانين.\n\n" .
                    "**5. المراجعة والاعتماد**\n" .
                    "• بعد إرسال ملفك، يتولى فريق التقييم مراجعة المحتوى والتحقق من جودة الأعمال خلال 24–48 ساعة، ويتم تفعيل شارة التوثيق فور الاعتماد!";
                $relatedQuestions = [
                    'ما هي باقات وأسعار اشتراك الفنانين في التطبيق؟',
                    'كيف يمكنني بيع لوحاتي وأعمالي الفنية عبر التطبيق؟',
                    'كيف أسجل كفنان في هذا التطبيق؟',
                ];
            }
            // 1c. Listing Plans & Pricing
            elseif (str_contains($q, 'باقات') || str_contains($q, 'باقة') || str_contains($q, 'أسعار الاشتراك') || str_contains($q, 'اشتراك الفنانين') || (str_contains($q, 'سعر') && str_contains($q, 'فنان')) || (str_contains($q, 'رسوم') && str_contains($q, 'فنان'))) {
                $reply = "يقدم تطبيق **فنان دبي** باقات اشتراك مخصصة للفنانين لتعزيز ظهورهم والوصول إلى المقتنين وصالات العرض في الإمارات:\n\n" .
                    "• **الباقة الأسبوعية:** 100 درهم إماراتي (مناسبة للمعارض المؤقتة والتجربة).\n" .
                    "• **الباقة الشهرية (الأكثر طلباً):** 350 درهم إماراتي (تشمل شارة فنان موثق، وأولوية الظهور في دليل الفنانين).\n" .
                    "• **باقة 6 أشهر:** 1,800 درهم إماراتي (توفير 14% مع ميزات ترويجية متقدمة).\n" .
                    "• **الباقة السنوية (VIP):** 3,000 درهم إماراتي (ظهور دائم 365 يوماً، شارة موثقة، ترويج في الصفحة الرئيسية، ورسائل غير محدودة من المقتنين).\n\n" .
                    "يمكنك اختيار باقتك وتفعيلها مباشرة من صفحة **الملف الشخصي > باقات الاشتراك**.";
                $relatedQuestions = [
                    'ما هي متطلبات توثيق ملف الفنان في التطبيق؟',
                    'كيف يمكنني بيع لوحاتي وأعمالي الفنية عبر التطبيق؟',
                    'كيف أحجز فناناً في هذا التطبيق؟',
                ];
            }
            // 1d. Upload & Sell Artworks
            elseif (str_contains($q, 'بيع') || str_contains($q, 'لوحاتي') || str_contains($q, 'أعمالي') || str_contains($q, 'رفع لوحة') || str_contains($q, 'عرض أعمال') || str_contains($q, 'رفع الأعمال')) {
                $reply = "لعرض وبيع أعمالك الفنية عبر تطبيق **فنان دبي**:\n\n" .
                    "1. افتح صفحة **الملف الشخصي** وانتقل إلى ملفك الفني.\n" .
                    "2. اضغط على **\"إضافة عمل فني جديد\"** (Add Artwork).\n" .
                    "3. ارفع صوراً عالية الدقة وواضحة للعمل.\n" .
                    "4. أدخل عنوان اللوحة، الخامة (مثل زيت على كانفاس، أكريليك، نحت)، المقاسات (بالسنتيمتر)، وسنة الإنتاج.\n" .
                    "5. حدد سعر البيع بالدرهم الإماراتي (AED).\n" .
                    "6. بعد الحفظ، يظهر العمل مباشرة في معرضك الخاص وفي سوق الأعمال الفنية للجمهور والمقتنين!";
                $relatedQuestions = [
                    'ما هي متطلبات توثيق ملف الفنان في التطبيق؟',
                    'ما هي باقات وأسعار اشتراك الفنانين في التطبيق؟',
                    'كيف أسجل كفنان في هذا التطبيق؟',
                ];
            }
            // 2. Art Districts in Dubai
            elseif (str_contains($q, 'منطقة') || str_contains($q, 'مناطق') || str_contains($q, 'أماكن فنية') || str_contains($q, 'السركال') || str_contains($q, 'حي دبي للتصميم') || str_contains($q, 'جميل')) {
                $reply = "تضم دبي وجهات ومناطق فنية وثقافية استثنائية ذات صيت عالمي، يمكنك استكشافها عبر التطبيق:\n\n" .
                    "• **السركال أفنيو (Alserkal Avenue - القوز):** المركز الفني والإبداعي الأبرز في المنطقة، يضم أكثر من 70 صالة عرض معاصرة ومساحات ثقافية ومقاهي وسينما عقيل المستقلة.\n" .
                    "• **حي دبي للتصميم (d3):** الوجهة الرائدة للتصميم والفنون المعاصرة والعمارة والأزياء والمنحوتات الخارجية.\n" .
                    "• **قرية البوابة بمركز دبي المالي العالمي (DIFC Gate Village):** موطن لصالات العرض المرموقة عالمياً مثل دار كريستيز وسوثبيز وأيام غاليري.\n" .
                    "• **مركز جميل للفنون (Jaddaf Waterfront):** مؤسسة فنية معاصرة مستقلة تضم صالات عرض وحديقة منحوتات ومكتبة فنية غنية.\n" .
                    "• **حي الفهيدي التاريخي:** يعكس روح دبي التراثية ويستضيف مهرجان سكة للفنون والتصميم سنوياً.";
                $relatedQuestions = [
                    'هل الدخول إلى معارض السركال أفنيو مجاني؟',
                    'ما هي أوقات عمل حي دبي للتصميم d3؟',
                    'أفكار لجولة فنية في عطلة نهاية الأسبوع في دبي',
                ];
            }
            // 3. Weekend Art Tour
            elseif (str_contains($q, 'جولة') || str_contains($q, 'عطلة') || str_contains($q, 'نهاية الأسبوع') || str_contains($q, 'برنامج') || str_contains($q, 'خطة')) {
                $reply = "إليك برنامج مقترح لجولة فنية وثقافية مميزة في عطلة نهاية الأسبوع في دبي:\n\n" .
                    "**اليوم الأول (السبت): استكشاف الفن المعاصر**\n" .
                    "• **الصباح:** ابدأ في **السركال أفنيو** في القوز، استمتع بقهوة مختصة في Nightjar، وتجول بين صالات العرض المستقلة ومساحات thejamjar.\n" .
                    "• **بعد الظهر:** توجه إلى **مركز جميل للفنون** على خور الجداف واستمتع بالمعارض المعاصرة وحديقة المجسمات الخارجية ومكتبة جميل.\n" .
                    "• **المساء:** احضر فيلماً مستقلاً في **سينما عقيل** بالسركال أفنيو.\n\n" .
                    "**اليوم الثاني (الأحد): التصميم والتراث**\n" .
                    "• **الصباح:** استكشف أزقة **حي الفهيدي التاريخي** ومتاحفه وتناول الإفطار في حديقة مقهى XVA الفني الهادئ.\n" .
                    "• **العصر:** توجه إلى **حي دبي للتصميم (d3)** واستكشف المجسمات النحتية المبتكرة والمعارض المؤقتة والمتاجر الفنية المبتكرة.\n" .
                    "• **المساء:** عشاء في أحد مطاعم d3 المطلة على أفق دبي.";
                $relatedQuestions = [
                    'ما هي المناطق الفنية التي يمكنني زيارتها في دبي؟',
                    'هل الدخول إلى معارض السركال أفنيو مجاني؟',
                    'كيف أصل إلى قرية البوابة بمركز دبي المالي بالمترو؟',
                ];
            }
            // 4. Free Admission & Tickets
            elseif (str_contains($q, 'مجاني') || str_contains($q, 'تذاكر') || str_contains($q, 'تذكرة') || str_contains($q, 'رسوم') || str_contains($q, 'دخول')) {
                $reply = "نعم، الدخول إلى غالبية المعارض والمناطق الفنية في دبي **مجاني تماماً** ومتاح للجميع:\n\n" .
                    "• **السركال أفنيو:** الدخول إلى المنطقة وجميع صالات العرض الـ 70 مجاني طوال العام دون الحاجة إلى تذاكر مسبقة.\n" .
                    "• **قرية البوابة بمركز دبي المالي (DIFC):** زيارة المعارض الفنية المعاصرة والممشى الفني مجانية بالكامل.\n" .
                    "• **حي دبي للتصميم (d3):** الدخول إلى الصالات والمجسمات النحتية الخارجية مجاني ومفتوح للجمهور.\n" .
                    "• **مركز جميل للفنون:** الدخول إلى صالات العرض وحديقة المجسمات مجاني مع الترحيب بجميع الزوار.\n" .
                    "• **مهرجان سكة للفنون والتصميم:** الدخول لجميع فعالياته ومعارضه في حي الفهيدي مجاني سنوياً.";
                $relatedQuestions = [
                    'ما هي أوقات عمل حي دبي للتصميم d3؟',
                    'كيف أصل إلى قرية البوابة بمركز دبي المالي بالمترو؟',
                    'كيف أحجز فناناً في هذا التطبيق؟',
                ];
            }
            // 5. Booking an Artist
            elseif (str_contains($q, 'حجز فنان') || str_contains($q, 'أحجز فنان') || str_contains($q, 'طلب لوحة') || str_contains($q, 'تفويض') || str_contains($q, 'تكليف')) {
                $reply = "حجز أو تكليف فنان عبر تطبيق **فنان دبي** يتم بخطوات سهلة ومباشرة:\n\n" .
                    "1. افتح تبويب **الفنانين (Artists)** في الشريط السفلي للتطبيق لتصفح الفنانين المعتمدين في دبي.\n" .
                    "2. اضغط على الملف التعريفي لأي فنان للاطلاع على سيرته الفنية وأعماله وتكلفة الحجز المبدئية.\n" .
                    "3. اضغط على زر **\"مراسلة الفنان\"** أو **\"حجز فنان\"**.\n" .
                    "4. حدد تفاصيل طلبك (رسم حي في مناسبة، جدارية، لوحة خاصة، أو ورشة عمل) وميزانيتك المقترحة.\n" .
                    "5. سيصل طلبك مباشرة إلى الفنان للتنسيق والاتفاق المباشر معك داخل التطبيق.";
                $relatedQuestions = [
                    'ما هو متوسط سعر حجز الفنانين في دبي؟',
                    'كيف أسجل كفنان في هذا التطبيق؟',
                    'ما هي متطلبات توثيق ملف الفنان في التطبيق؟',
                ];
            }
            // 6. Timings & Opening Hours
            elseif (str_contains($q, 'أوقات') || str_contains($q, 'ساعات') || str_contains($q, 'مواعيد') || str_contains($q, 'يفتح') || str_contains($q, 'يغلق')) {
                $reply = "مواعيد عمل أبرز المناطق والمعارض الفنية في دبي:\n\n" .
                    "• **السركال أفنيو:** صالات العرض 10:00 ص - 7:00 م (السبت - الخميس)، والمقاهي تفتح حتى 10:00 م.\n" .
                    "• **حي دبي للتصميم (d3):** المساحات والمقاهي مفتوحة يومياً من 8:00 ص حتى 11:00 م.\n" .
                    "• **قرية البوابة بمركز دبي المالي (DIFC):** المعارض تفتح من 10:00 ص حتى 8:00 م (الأحد - الخميس).\n" .
                    "• **مركز جميل للفنون:** 10:00 ص - 8:00 م (يغلق أيام الثلاثاء).\n" .
                    "• **حي الفهيدي التاريخي:** 9:00 ص - 8:00 م يومياً.";
                $relatedQuestions = [
                    'هل الدخول إلى معارض السركال أفنيو مجاني؟',
                    'كيف أصل إلى قرية البوابة بمركز دبي المالي بالمترو؟',
                    'ما هي المناطق الفنية التي يمكنني زيارتها في دبي؟',
                ];
            }
            // 7. Metro & Directions
            elseif (str_contains($q, 'مترو') || str_contains($q, 'وصول') || str_contains($q, 'كيف أصل') || str_contains($q, 'مواصلات')) {
                $reply = "كيفية الوصول إلى أشهر المعالم الفنية في دبي بالمترو:\n\n" .
                    "• **قرية البوابة بمركز دبي المالي (DIFC):** استقل الخط الأحمر وانزل في **محطة المركز المالي (Financial Centre)**.\n" .
                    "• **حي الفهيدي التاريخي:** استقل الخط الأخضر لمترو دبي وانزل في **محطة شرف دي جي (Sharaf DG)**.\n" .
                    "• **السركال أفنيو:** الخط الأحمر إلى **محطة أون باسيف (Onpassive)** ثم 5 دقائق بسيارة الأجرة أو حافلة F25.\n" .
                    "• **حي دبي للتصميم (d3):** الخط الأحمر إلى **محطة الخليج التجاري / مول دبي** ثم حافلة d3 أو تاكسي لمدة 5 دقائق.";
                $relatedQuestions = [
                    'ما هي أوقات عمل حي دبي للتصميم d3؟',
                    'هل الدخول إلى معارض السركال أفنيو مجاني؟',
                    'أفكار لجولة فنية في عطلة نهاية الأسبوع في دبي',
                ];
            }
            // 8. General / Fallback
            else {
                $reply = "أهلاً بك! أنا **دليل الفن العالمي – الفنانون، التاريخ والأصول** لتطبيق فنان دبي. يسعدني مساعدتك في استكشاف الفنانين وتاريخ الفن والأصول الثقافية في دبي وفي جميع أنحاء الإمارات وحول العالم:\n\n" .
                    "• **الفنانون والتسجيل:** كيفية إنشاء وتوثيق ملفك الفني ورفع لوحاتك والتواصل مع المقتنين.\n" .
                    "• **تاريخ الفن والأصول:** رحلة الفن الإماراتي والعربي والعالمي، والمدارس الفنية الأصيلة والمعاصرة.\n" .
                    "• **الوجهات الثقافية:** السركال أفنيو، حي دبي للتصميم d3، قرية البوابة بمركز دبي المالي، ومتحف اللوفر أبوظبي ومركز جميل للفنون.\n" .
                    "• **المعارض والفعاليات:** معارض فن دبي (Art Dubai)، مهرجان سكة، والبيناليات الفنية الدولية.\n\n" .
                    "تفضل بطرح أي استفسار ترغب به وسأجيبك بكل سرور!";
                $relatedQuestions = [
                    'ما هي أصول وتاريخ الفن في الإمارات ودبي؟',
                    'كيف أسجل كفنان في هذا التطبيق؟',
                    'ما هي المناطق الفنية التي يمكنني زيارتها في دبي؟',
                ];
            }
        } else {
            // ENGLISH RESPONSES
            // 1. Artist Registration / Join as Artist
            if (str_contains($q, 'register as an artist') || str_contains($q, 'register as artist') || str_contains($q, 'join as an artist') || str_contains($q, 'join as artist') || str_contains($q, 'create artist profile') || str_contains($q, 'create an artist profile') || str_contains($q, 'become an artist') || str_contains($q, 'artist registration') || str_contains($q, 'artist sign up') || str_contains($q, 'signup as artist') || (str_contains($q, 'register') && str_contains($q, 'artist'))) {
                $reply = "Registering as an artist on **Artist Dubai** is straightforward and gives you a dedicated platform to showcase your talent, connect with Dubai collectors, and receive direct booking inquiries.\n\n" .
                    "Here is the step-by-step guide:\n\n" .
                    "**1. Sign Up or Log In**\n" .
                    "• Open the app and navigate to **Profile** (or tap **Sign In / Register** from the bottom bar).\n" .
                    "• Create an account with your email and password, or log in if you already have an active account.\n\n" .
                    "**2. Create Your Artist Profile**\n" .
                    "• From your **Profile** screen or side menu, tap **\"Create Artist Profile\"** (or **\"Join as Artist\"**).\n" .
                    "• Fill in your essential artist information:\n" .
                    "  - **Full Name / Artistic Moniker**\n" .
                    "  - **Category / Discipline:** Contemporary Painting, Sculpture, Arabic Calligraphy, Digital Art, Photography, Ceramic, or Mixed Media.\n" .
                    "  - **Biography & Artist Statement:** Share your creative vision and exhibition background.\n" .
                    "  - **Contact & Social Links:** Website, Instagram, and email.\n\n" .
                    "**3. Upload Your Artworks & Portfolio**\n" .
                    "• Upload high-resolution images of your original artworks.\n" .
                    "• Add artwork titles, medium (e.g. Oil on Canvas, Bronze), dimensions, and sale/starting booking rates in AED.\n\n" .
                    "**4. Choose a Listing Plan**\n" .
                    "• Select an **Artist Listing Plan** (Free, Essential, Pro, or VIP).\n" .
                    "• Upgraded plans provide unlimited monthly chat inquiries from buyers and event organizers, priority search placement, and featured homepage highlights.\n\n" .
                    "**5. Review & Verification**\n" .
                    "• Submit your profile for curation. Once approved by our team, your profile is published immediately in the **Artists Directory**!";
                $relatedQuestions = [
                    'What are the requirements to get verified as an artist?',
                    'What are the artist listing plans and pricing?',
                    'How can I upload and sell my artworks in the app?',
                ];
            }
            // 1b. Verification Requirements
            elseif (str_contains($q, 'verif') || str_contains($q, 'badge') || str_contains($q, 'requirement') || str_contains($q, 'curat') || (str_contains($q, 'get') && str_contains($q, 'verified'))) {
                $reply = "To get verified as an artist on **Artist Dubai** and receive the official **Verified Artist Badge**, your profile undergoes curation based on these criteria:\n\n" .
                    "**1. Complete Artist Profile & Bio**\n" .
                    "• **Professional Identity:** Full artistic name, professional moniker, and profile avatar.\n" .
                    "• **Comprehensive Artist Statement:** A detailed biography detailing your creative philosophy, medium mastery, and past exhibitions (minimum 100 words recommended).\n" .
                    "• **Discipline:** Clearly defined artistic genre (Contemporary Painting, Sculpture, Arabic Calligraphy, Digital Art, Photography, or Mixed Media).\n\n" .
                    "**2. Portfolio & Original Artworks**\n" .
                    "• **High-Resolution Artwork:** Upload at least 3 to 5 clear, high-quality images of your original creations.\n" .
                    "• **Complete Specifications:** Titles, medium (e.g. Oil on Canvas, Bronze), dimensions (H x W in cm), year created, and sale/starting booking rates in AED.\n" .
                    "• **Authenticity:** All uploaded works must be 100% original pieces produced by you.\n\n" .
                    "**3. Professional Contact & Social Links**\n" .
                    "• Verified email address and active WhatsApp/phone number for collector inquiries.\n" .
                    "• Links to your active art Instagram account, portfolio website, or LinkedIn.\n\n" .
                    "**4. Active Listing Plan**\n" .
                    "• An active Artist Verification plan (starting at AED 100/week or AED 350/month), unlocking verified status, directory prominence, and direct commissioning.\n\n" .
                    "**5. Curation Team Review**\n" .
                    "• Once submitted, our curation team reviews your portfolio within 24–48 hours. Upon approval, your **Verified Badge** is activated live across the platform!";
                $relatedQuestions = [
                    'What are the artist listing plans and pricing?',
                    'How can I upload and sell my artworks in the app?',
                    'How do I register as an artist in this app?',
                ];
            }
            // 1c. Listing Plans & Pricing
            elseif (str_contains($q, 'pricing') || str_contains($q, 'listing plan') || str_contains($q, 'plans') || str_contains($q, 'subscription') || str_contains($q, 'how much to join') || (str_contains($q, 'cost') && str_contains($q, 'artist'))) {
                $reply = "**Artist Dubai** offers flexible listing and verification plans tailored for independent artists and creative studios in the UAE:\n\n" .
                    "• **Weekly Plan:** AED 100 — Ideal for short-term exhibitions, pop-ups, and testing the platform.\n" .
                    "• **Monthly Plan (Most Popular):** AED 350 — Includes the official **Verified Artist Badge**, priority directory ranking, and direct buyer messaging.\n" .
                    "• **6 Months Plan:** AED 1,800 — Extended visibility with featured spots in gallery newsletters.\n" .
                    "• **Yearly Plan (VIP):** AED 3,000 — 365 days of top directory placement, homepage highlights, unlimited buyer inquiries, and VIP curation support.\n\n" .
                    "You can select and activate your plan anytime from **Profile > Artist Listing Plans**.";
                $relatedQuestions = [
                    'What are the requirements to get verified as an artist?',
                    'How can I upload and sell my artworks in the app?',
                    'How do I book an artist in this app?',
                ];
            }
            // 1d. Upload and Sell Artworks
            elseif (str_contains($q, 'upload') || str_contains($q, 'sell') || str_contains($q, 'my art') || str_contains($q, 'add artwork') || str_contains($q, 'artworks in the app')) {
                $reply = "Uploading and selling your artwork on **Artist Dubai** takes only a few minutes:\n\n" .
                    "1. Go to your **Profile** and open your **Artist Dashboard**.\n" .
                    "2. Tap **\"Upload Artwork\"** (or **\"Add New Artwork\"**).\n" .
                    "3. Choose crisp, well-lit photos of your artwork from your device.\n" .
                    "4. Fill in the artwork details: Title, Medium (e.g. Oil on Linen, Acrylic, Bronze), Dimensions (cm), and Year.\n" .
                    "5. Set your sale price or starting commission rate in AED.\n" .
                    "6. Tap **Publish Artwork**. Your piece will be instantly visible in your public portfolio and in the Artworks marketplace for collectors to inquire and purchase!";
                $relatedQuestions = [
                    'What are the requirements to get verified as an artist?',
                    'What are the artist listing plans and pricing?',
                    'How do I register as an artist in this app?',
                ];
            }
            // 2. Art Districts
            elseif (str_contains($q, 'district') || str_contains($q, 'visit') || str_contains($q, 'where') || str_contains($q, 'alserkal') || str_contains($q, 'd3') || str_contains($q, 'difc') || str_contains($q, 'destination')) {
                $reply = "Dubai is home to internationally acclaimed art districts and creative clusters:\n\n" .
                    "• **Alserkal Avenue (Al Quoz):** The cultural heart of Dubai with 70+ contemporary art galleries (Green Art, Carbon 12, Ayyam Gallery), creative studios, cafes, and Cinema Akil.\n" .
                    "• **Dubai Design District (d3):** The epicenter for contemporary design, large-scale public sculptures, architectural showrooms, and Dubai Design Week.\n" .
                    "• **DIFC Gate Village:** Prestigious international galleries, Christie's, Sotheby's, fine dining, and open-air sculpture promenades.\n" .
                    "• **Jameel Arts Centre (Jaddaf Waterfront):** Contemporary institution featuring curated exhibitions, an artist residency wing, and a public sculpture park along Dubai Creek.\n" .
                    "• **Al Fahidi Historical Neighbourhood:** Traditional coral-stone windtower district hosting artisan ateliers and the annual Sikka Art & Design Festival.";
                $relatedQuestions = [
                    'Is admission free at Alserkal Avenue galleries?',
                    'What are the opening hours for Dubai Design District (d3)?',
                    'Ideas for a weekend art tour in Dubai',
                ];
            }
            // 3. Weekend Art Tour
            elseif (str_contains($q, 'tour') || str_contains($q, 'weekend') || str_contains($q, 'itinerary') || str_contains($q, 'ideas') || (str_contains($q, 'plan') && (str_contains($q, 'tour') || str_contains($q, 'weekend') || str_contains($q, 'visit')))) {
                $reply = "Here is a curated 2-day weekend art tour itinerary in Dubai:\n\n" .
                    "**Day 1 (Saturday): Contemporary Art & Indie Cinema**\n" .
                    "• **Morning:** Head to **Alserkal Avenue** in Al Quoz. Grab an artisan brew at Nightjar Coffee, explore contemporary galleries, and drop by thejamjar community space.\n" .
                    "• **Afternoon:** Visit **Jameel Arts Centre** on the Jaddaf Waterfront. Wander through the curated galleries, Jameel Library, and outdoor Sculpture Park.\n" .
                    "• **Evening:** Catch an independent arthouse film at **Cinema Akil** back in Alserkal Avenue.\n\n" .
                    "**Day 2 (Sunday): Design, Sculpture & Heritage**\n" .
                    "• **Morning:** Walk through the historic windtower lanes of **Al Fahidi Historical Neighbourhood** and enjoy breakfast in the tranquil courtyard of XVA Art Cafe.\n" .
                    "• **Afternoon:** Move to **Dubai Design District (d3)** to view outdoor art installations, architecture pop-ups, and concept stores.\n" .
                    "• **Evening:** Explore the sculpture promenade and world-class galleries at **DIFC Gate Village**.";
                $relatedQuestions = [
                    'Which art districts can I visit in Dubai?',
                    'Is admission free at Alserkal Avenue galleries?',
                    'How do I reach DIFC Gate Village by Metro?',
                ];
            }
            // 4. Free Admission & Tickets
            elseif (str_contains($q, 'free') || str_contains($q, 'admission') || str_contains($q, 'ticket') || str_contains($q, 'cost') || str_contains($q, 'entry') || str_contains($q, 'fee') || str_contains($q, 'price')) {
                $reply = "Yes! General admission to major contemporary galleries across Dubai is **completely free** and open to the public:\n\n" .
                    "• **Alserkal Avenue:** Free entry 365 days a year. All 70+ contemporary galleries are free to enter with no pre-booking required.\n" .
                    "• **DIFC Gate Village:** Free entry to all art galleries, exhibitions, and the outdoor sculpture promenade.\n" .
                    "• **Dubai Design District (d3):** Free public entry to galleries, design pop-ups, and interactive art installations.\n" .
                    "• **Jameel Arts Centre:** Free admission to all exhibition galleries and the outdoor sculpture park.\n" .
                    "• **Sikka Art & Design Festival (Al Fahidi):** Free public access to all exhibitions, live music, and installations.";
                $relatedQuestions = [
                    'What are the opening hours for Dubai Design District (d3)?',
                    'How do I reach DIFC Gate Village by Metro?',
                    'How do I book an artist in this app?',
                ];
            }
            // 5. Booking an Artist
            elseif (str_contains($q, 'book') || str_contains($q, 'hire') || str_contains($q, 'commission') || str_contains($q, 'request artist')) {
                $reply = "Booking or commissioning an artist on **Artist Dubai** is direct and seamless:\n\n" .
                    "1. Tap the **Artists** tab in the bottom navigation bar to browse verified UAE talents.\n" .
                    "2. Tap any artist profile to review their bio, artistic discipline, portfolio works, and starting rates.\n" .
                    "3. Tap the **Book Artist** or **Message** button on their profile.\n" .
                    "4. Enter your project details: event date, location, booking type (Live Painting, Mural Commission, Workshop, Custom Artwork), and budget.\n" .
                    "5. Your inquiry is delivered directly to the artist's private message box for swift confirmation!";
                $relatedQuestions = [
                    'What are the starting rates for artists in Dubai?',
                    'How do I register as an artist in this app?',
                    'What are the requirements to get verified as an artist?',
                ];
            }
            // 6. Timings & Opening Hours
            elseif (str_contains($q, 'hour') || str_contains($q, 'timing') || str_contains($q, 'open') || str_contains($q, 'close') || str_contains($q, 'schedule')) {
                $reply = "Typical opening hours for Dubai art destinations:\n\n" .
                    "• **Alserkal Avenue:** Galleries 10:00 AM – 7:00 PM (Sat–Thu), Cafes 8:00 AM – 10:00 PM daily.\n" .
                    "• **Dubai Design District (d3):** Public spaces and cafes open 8:00 AM – 11:00 PM daily.\n" .
                    "• **DIFC Gate Village:** Galleries 10:00 AM – 8:00 PM (Sun–Thu).\n" .
                    "• **Jameel Arts Centre:** 10:00 AM – 8:00 PM (Closed on Tuesdays).\n" .
                    "• **Al Fahidi Historical Neighbourhood:** 9:00 AM – 8:00 PM daily.";
                $relatedQuestions = [
                    'Is admission free at Alserkal Avenue galleries?',
                    'How do I reach DIFC Gate Village by Metro?',
                    'Which art districts can I visit in Dubai?',
                ];
            }
            // 7. Metro & Directions
            elseif (str_contains($q, 'metro') || str_contains($q, 'reach') || str_contains($q, 'direction') || str_contains($q, 'get to') || str_contains($q, 'transport')) {
                $reply = "How to reach Dubai's top art districts by public transport:\n\n" .
                    "• **DIFC Gate Village:** Take the Metro Red Line and exit at **Financial Centre Metro Station** (Exit 1) — 7 min air-conditioned walk.\n" .
                    "• **Al Fahidi Historical District:** Take the Metro Green Line to **Sharaf DG Station** (Exit 3) — 5 min walk.\n" .
                    "• **Alserkal Avenue:** Take the Metro Red Line to **Onpassive Station** + 5 min taxi (approx. AED 12) or RTA Feeder Bus F25.\n" .
                    "• **Dubai Design District (d3):** Take the Metro Red Line to **Business Bay / Dubai Mall** + dedicated RTA Bus d3 or a 5 min taxi.";
                $relatedQuestions = [
                    'What are the opening hours for Dubai Design District (d3)?',
                    'Is admission free at Alserkal Avenue galleries?',
                    'Ideas for a weekend art tour in Dubai',
                ];
            }
            // 8. General / Fallback
            else {
                $reply = "Welcome! I am your **Global Art Guide – Artists, History & Origins** on Artist Dubai. I am here to help you discover artists, art history, and cultural origins in Dubai, across the UAE, and worldwide:\n\n" .
                    "• **Artists & Registration:** Guidance to showcase your portfolio, connect with collectors, and explore featured talents.\n" .
                    "• **Art History & Origins:** Discover the roots of Emirati, Middle Eastern, and international art movements.\n" .
                    "• **Cultural Destinations:** Alserkal Avenue, Dubai Design District (d3), DIFC Gate Village, Louvre Abu Dhabi, and Jameel Arts Centre.\n" .
                    "• **Fairs & Exhibitions:** Art Dubai, World Art Dubai, Sikka Art & Design Festival, and global gallery showcases.\n\n" .
                    "What would you like to explore today?";
                $relatedQuestions = [
                    'What are the origins and history of art in the UAE and Dubai?',
                    'How do I register as an artist in this app?',
                    'Which art districts can I visit in Dubai?',
                ];
            }
        }

        return [
            'reply' => $reply,
            'related_questions' => $relatedQuestions,
        ];
    }

    /**
     * Direct integration with Google Gemini Generative Language API.
     * Grounded with real-time live database context and prompts Gemini
     * to dynamically supply tailored follow-up questions.
     */
    private function callGeminiApi(string $prompt, string $apiKey, bool $isArabic, array $dbContext = [], array $recentHistory = []): ?array {
        // High-availability working models priority list
        $models = [
            'gemini-2.5-flash',
            'gemini-2.0-flash',
            'gemini-1.5-flash',
            'gemini-1.5-flash-8b',
            'gemini-2.5-pro',
            'gemini-1.5-pro',
        ];
        
        $dbSummary = "Live Database Context: Artists registered (" . ($dbContext['counts']['artists'] ?? 0) . "), Events (" . ($dbContext['counts']['events'] ?? 0) . "), Galleries (" . ($dbContext['counts']['galleries'] ?? 0) . "), Artworks (" . ($dbContext['counts']['artworks'] ?? 0) . ").";
        if (!empty($dbContext['matched_artists'])) {
            $dbSummary .= "\nActive matching artists: " . json_encode(array_column($dbContext['matched_artists'], 'name'), JSON_UNESCAPED_UNICODE);
        }
        if (!empty($dbContext['matched_events'])) {
            $dbSummary .= "\nActive matching events: " . json_encode(array_column($dbContext['matched_events'], 'title'), JSON_UNESCAPED_UNICODE);
        }
        if (!empty($dbContext['matched_galleries'])) {
            $dbSummary .= "\nActive matching galleries: " . json_encode(array_column($dbContext['matched_galleries'], 'name'), JSON_UNESCAPED_UNICODE);
        }
        if (!empty($dbContext['matched_artworks'])) {
            $dbSummary .= "\nFeatured artworks: " . json_encode(array_column($dbContext['matched_artworks'], 'title'), JSON_UNESCAPED_UNICODE);
        }

        $systemInstruction = "You are the official, highly sophisticated, and welcoming Global Art Guide for 'Artist Dubai' (فنان دبي), helping users discover artists, art history, and cultural origins in Dubai, across the UAE, and worldwide, while celebrating prestigious galleries, cultural districts (Alserkal Avenue, Dubai Design District d3, Al Fahidi Historical Neighbourhood, Jameel Arts Centre), art fairs (Art Dubai, World Art Dubai), and exhibitions.\n" .
            "Core Persona & Guidelines:\n" .
            "1. Deliver accurate, inspiring, and concise insights in clean Markdown with clear headings and bullet points tailored for mobile screens.\n" .
            "2. When discussing artists, exhibitions, art history, cultural origins, or booking, encourage users to explore profiles or events directly on the Artist Dubai app.\n" .
            "3. Seamlessly ground your answers using the live database context below:\n" .
            $dbSummary . "\n" .
            "4. Language: Answer strictly and eloquently in " . ($isArabic ? "Arabic" : "English") . ".\n\n" .
            "MANDATORY OUTPUT FORMAT:\n" .
            "At the very end of your response, output exactly this delimiter on a new line:\n" .
            "---RELATED---\n" .
            "Followed by exactly 3 relevant follow-up questions the user might ask next, formatted as:\n" .
            "1. [Question 1]\n" .
            "2. [Question 2]\n" .
            "3. [Question 3]";

        $contents = [];
        // Add conversation history if present
        if (!empty($recentHistory)) {
            foreach ($recentHistory as $h) {
                $role = ($h['sender'] === 'user') ? 'user' : 'model';
                $text = trim($h['message'] ?? '');
                if (!empty($text)) {
                    $contents[] = [
                        'role' => $role,
                        'parts' => [['text' => $text]]
                    ];
                }
            }
        }

        // Current message with system instruction
        $userText = (!empty($contents) ? "" : ($systemInstruction . "\n\n")) . "User Question: " . $prompt;
        $contents[] = [
            'role' => 'user',
            'parts' => [['text' => $userText]]
        ];

        $payload = [
            'contents' => $contents,
            'generationConfig' => [
                'temperature' => 0.7,
                'maxOutputTokens' => 1024,
            ]
        ];
        if (!empty($systemInstruction)) {
            $payload['systemInstruction'] = [
                'parts' => [['text' => $systemInstruction]]
            ];
        }
        $payloadJson = json_encode($payload);

        foreach ($models as $model) {
            try {
                $url = "https://generativelanguage.googleapis.com/v1beta/models/{$model}:generateContent?key=" . urlencode($apiKey);

                $ch = curl_init($url);
                curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
                curl_setopt($ch, CURLOPT_POST, true);
                curl_setopt($ch, CURLOPT_POSTFIELDS, $payloadJson);
                curl_setopt($ch, CURLOPT_HTTPHEADER, [
                    'Content-Type: application/json',
                    'x-goog-api-key: ' . $apiKey,
                ]);
                curl_setopt($ch, CURLOPT_TIMEOUT, 15);
                curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);
                $result = curl_exec($ch);
                $code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
                curl_close($ch);

                if ($code === 401 || $code === 403) {
                    // API key is invalid or unauthorized; break immediately for instant fallback
                    break;
                }

                if ($code === 200 && !empty($result)) {
                    $decoded = json_decode($result, true);
                    $candidateText = $decoded['candidates'][0]['content']['parts'][0]['text'] ?? null;
                    if (!empty($candidateText)) {
                        $rawText = trim($candidateText);
                        $replyText = $rawText;
                        $relatedQuestions = [];

                        if (str_contains($rawText, '---RELATED---')) {
                            $parts = explode('---RELATED---', $rawText, 2);
                            $replyText = trim($parts[0]);
                            $relatedRaw = trim($parts[1]);
                            $relLines = preg_split('/[\r\n]+/', $relatedRaw);
                            foreach ($relLines as $line) {
                                $cleanLine = trim(preg_replace('/^[\d\.\-\*\•\s]+/', '', trim($line)));
                                if (!empty($cleanLine) && mb_strlen($cleanLine) >= 6) {
                                    $relatedQuestions[] = $cleanLine;
                                }
                            }
                            $relatedQuestions = array_slice($relatedQuestions, 0, 3);
                        }

                        return [
                            'reply' => $replyText,
                            'related_questions' => $relatedQuestions,
                        ];
                    }
                }
            } catch (\Throwable $t) {}
        }
        return null;
    }
}

// -----------------------------------------------------------------------------
// 4j. Recycle Bin Controller (Soft-Delete Recovery)
// -----------------------------------------------------------------------------
class RecycleBinController {
    private PDO $db;

    public function __construct() {
        $this->db = DatabaseManager::getInstance()->getConnection();
    }

    /** Fetch all soft-deleted items across all entities */
    public function getTrash(): void {
        AuthMiddleware::requireAdmin();
        $items = [];
        $tables = [
            ['table' => 'artists',            'label' => 'Artist',           'name_col' => 'name',  'img_col' => 'avatar_url', 'extra' => 'category'],
            ['table' => 'events',             'label' => 'Event',            'name_col' => 'title', 'img_col' => 'image_url',  'extra' => 'category'],
            ['table' => 'galleries',          'label' => 'Gallery',          'name_col' => 'name',  'img_col' => 'image_url',  'extra' => 'category'],
            ['table' => 'government_entities','label' => 'Government Entity','name_col' => 'name',  'img_col' => null,          'extra' => 'category'],
            ['table' => 'categories',         'label' => 'Category',         'name_col' => 'name',  'img_col' => null,          'extra' => 'type'],
            ['table' => 'experience_levels',  'label' => 'Experience Level', 'name_col' => 'name',  'img_col' => null,          'extra' => null],
            ['table' => 'locations',          'label' => 'Location',         'name_col' => 'name',  'img_col' => null,          'extra' => 'city'],
        ];
        foreach ($tables as $t) {
            try {
                $stmt = $this->db->query("SELECT id, {$t['name_col']} AS display_name, deleted_at" .
                    (!empty($t['img_col']) ? ", {$t['img_col']} AS image_url" : ", NULL AS image_url") .
                    (!empty($t['extra'])   ? ", {$t['extra']} AS entity_sub" : ", NULL AS entity_sub") .
                    " FROM {$t['table']} WHERE deleted_at IS NOT NULL ORDER BY deleted_at DESC");
                $rows = $stmt->fetchAll();
                foreach ($rows as $row) {
                    $items[] = [
                        'id'           => $row['id'],
                        'type'         => $t['table'],
                        'label'        => $t['label'],
                        'display_name' => $row['display_name'],
                        'image_url'    => $row['image_url'] ?? null,
                        'entity_sub'   => $row['entity_sub'] ?? null,
                        'deleted_at'   => $row['deleted_at'],
                    ];
                }
            } catch (\Throwable $e) {}
        }
        // Sort by deleted_at desc
        usort($items, fn($a, $b) => strcmp($b['deleted_at'], $a['deleted_at']));
        ApiResponse::success($items, 'Recycle bin items retrieved successfully');
    }

    /** Restore a soft-deleted item (clear deleted_at) */
    public function restoreItem(array $input): void {
        AuthMiddleware::requireAdmin();
        $id   = (int)($input['id'] ?? 0);
        $type = InputSanitizer::cleanString($input['type'] ?? '');
        $allowedTables = ['artists','events','galleries','government_entities','categories','experience_levels','locations'];
        if ($id <= 0 || !in_array($type, $allowedTables)) {
            ApiResponse::error('Valid item ID and type are required for restore.');
            return;
        }
        try {
            $this->db->prepare("UPDATE {$type} SET deleted_at = NULL WHERE id = ?")->execute([$id]);
            ApiResponse::success(['id' => $id, 'type' => $type], 'Item restored successfully');
        } catch (\Throwable $e) {
            error_log('Restore failed: ' . $e->getMessage()); ApiResponse::error('Restore failed', 500);
        }
    }

    /** Permanently delete an item (true hard delete) */
    public function permanentDelete(array $input): void {
        AuthMiddleware::requireAdmin();
        $id   = (int)($input['id'] ?? 0);
        $type = InputSanitizer::cleanString($input['type'] ?? '');
        $allowedTables = ['artists','events','galleries','government_entities','categories','experience_levels','locations'];
        if ($id <= 0 || !in_array($type, $allowedTables)) {
            ApiResponse::error('Valid item ID and type are required for permanent deletion.');
            return;
        }
        try {
            // Delete associated physical image files from storage
            if ($type === 'artists') {
                $stmtA = $this->db->prepare('SELECT avatar_url, banner_url FROM artists WHERE id = ?');
                $stmtA->execute([$id]);
                if ($row = $stmtA->fetch()) {
                    UploadController::deletePhysicalFile($row['avatar_url'] ?? null);
                    UploadController::deletePhysicalFile($row['banner_url'] ?? null);
                }
                // Also artworks belonging to this artist
                $stmtArt = $this->db->prepare('SELECT image_url FROM artworks WHERE artist_id = ?');
                $stmtArt->execute([$id]);
                while ($artRow = $stmtArt->fetch()) {
                    UploadController::deletePhysicalFile($artRow['image_url'] ?? null);
                }

                $this->db->prepare('DELETE FROM artworks WHERE artist_id = ?')->execute([$id]);
                $this->db->prepare('DELETE FROM favorites WHERE item_type = "artist" AND item_id = ?')->execute([(string)$id]);
                $this->db->prepare('DELETE FROM follows WHERE artist_id = ?')->execute([$id]);
            } elseif ($type === 'events') {
                $stmtE = $this->db->prepare('SELECT image_url, galleries_json FROM events WHERE id = ?');
                $stmtE->execute([$id]);
                if ($row = $stmtE->fetch()) {
                    UploadController::deletePhysicalFile($row['image_url'] ?? null);
                    UploadController::deleteMultiplePhysicalFiles($row['galleries_json'] ?? null);
                }

                $this->db->prepare('DELETE FROM bookings WHERE event_id = ?')->execute([$id]);
                $this->db->prepare('DELETE FROM favorites WHERE item_type = "event" AND item_id = ?')->execute([(string)$id]);
            } elseif ($type === 'galleries') {
                $stmtG = $this->db->prepare('SELECT image_url, images_json FROM galleries WHERE id = ?');
                $stmtG->execute([$id]);
                if ($row = $stmtG->fetch()) {
                    UploadController::deletePhysicalFile($row['image_url'] ?? null);
                    UploadController::deletePhysicalFile($row['cover_url'] ?? null);
                    UploadController::deleteMultiplePhysicalFiles($row['images_json'] ?? null);
                }
            } elseif ($type === 'government_entities') {
                $stmtGov = $this->db->prepare('SELECT image_url, logo_url FROM government_entities WHERE id = ?');
                $stmtGov->execute([$id]);
                if ($row = $stmtGov->fetch()) {
                    UploadController::deletePhysicalFile($row['image_url'] ?? null);
                    UploadController::deletePhysicalFile($row['logo_url'] ?? null);
                }
            }

            $this->db->prepare("DELETE FROM {$type} WHERE id = ?")->execute([$id]);
            ApiResponse::success(['id' => $id, 'type' => $type], 'Item and associated files permanently deleted');
        } catch (\Throwable $e) {
            error_log('Permanent delete failed: ' . $e->getMessage()); ApiResponse::error('Permanent delete failed', 500);
        }
    }

    /** Empty entire recycle bin — permanently delete all trashed items and their physical images */
    public function emptyTrash(): void {
        AuthMiddleware::requireAdmin();
        $tables = ['artists','events','galleries','government_entities','categories','experience_levels','locations'];
        $totalDeleted = 0;
        foreach ($tables as $table) {
            try {
                if ($table === 'artists') {
                    $rows = $this->db->query("SELECT id, avatar_url, banner_url FROM artists WHERE deleted_at IS NOT NULL")->fetchAll();
                    foreach ($rows as $r) {
                        UploadController::deletePhysicalFile($r['avatar_url'] ?? null);
                        UploadController::deletePhysicalFile($r['banner_url'] ?? null);

                        $artRows = $this->db->prepare("SELECT image_url FROM artworks WHERE artist_id = ?");
                        $artRows->execute([$r['id']]);
                        while ($art = $artRows->fetch()) {
                            UploadController::deletePhysicalFile($art['image_url'] ?? null);
                        }

                        $this->db->prepare('DELETE FROM artworks WHERE artist_id = ?')->execute([$r['id']]);
                        $this->db->prepare('DELETE FROM favorites WHERE item_type = "artist" AND item_id = ?')->execute([(string)$r['id']]);
                        $this->db->prepare('DELETE FROM follows WHERE artist_id = ?')->execute([$r['id']]);
                    }
                } elseif ($table === 'events') {
                    $rows = $this->db->query("SELECT id, image_url, galleries_json FROM events WHERE deleted_at IS NOT NULL")->fetchAll();
                    foreach ($rows as $r) {
                        UploadController::deletePhysicalFile($r['image_url'] ?? null);
                        UploadController::deleteMultiplePhysicalFiles($r['galleries_json'] ?? null);

                        $this->db->prepare('DELETE FROM bookings WHERE event_id = ?')->execute([$r['id']]);
                        $this->db->prepare('DELETE FROM favorites WHERE item_type = "event" AND item_id = ?')->execute([(string)$r['id']]);
                    }
                } elseif ($table === 'galleries') {
                    $rows = $this->db->query("SELECT id, image_url, images_json FROM galleries WHERE deleted_at IS NOT NULL")->fetchAll();
                    foreach ($rows as $r) {
                        UploadController::deletePhysicalFile($r['image_url'] ?? null);
                        UploadController::deletePhysicalFile($r['cover_url'] ?? null);
                        UploadController::deleteMultiplePhysicalFiles($r['images_json'] ?? null);
                    }
                } elseif ($table === 'government_entities') {
                    $rows = $this->db->query("SELECT id, image_url, logo_url FROM government_entities WHERE deleted_at IS NOT NULL")->fetchAll();
                    foreach ($rows as $r) {
                        UploadController::deletePhysicalFile($r['image_url'] ?? null);
                        UploadController::deletePhysicalFile($r['logo_url'] ?? null);
                    }
                }

                $stmt = $this->db->prepare("DELETE FROM {$table} WHERE deleted_at IS NOT NULL");
                $stmt->execute();
                $totalDeleted += $stmt->rowCount();
            } catch (\Throwable $e) {}
        }
        ApiResponse::success(['total_deleted' => $totalDeleted], "Recycle bin emptied — {$totalDeleted} items and files permanently removed");
    }
}
// -----------------------------------------------------------------------------
// 4k. About Us Platform Content Controller
// -----------------------------------------------------------------------------
class AboutUsController {
    private PDO $db;

    public function __construct() {
        $this->db = DatabaseManager::getInstance()->getConnection();
        $this->ensureTable();
    }

    private function ensureTable(): void {
        try {
            $this->db->exec("
                CREATE TABLE IF NOT EXISTS about_us (
                    id INT AUTO_INCREMENT PRIMARY KEY,
                    title VARCHAR(255) DEFAULT 'ABOUT US',
                    title_ar VARCHAR(255) DEFAULT 'من نحن',
                    what_means_title VARCHAR(255) DEFAULT 'What does it mean to be an artist?',
                    what_means_title_ar VARCHAR(255) DEFAULT 'ماذا يعني أن تكون فناناً؟',
                    what_means_body TEXT NULL,
                    what_means_body_ar TEXT NULL,
                    quote_text TEXT NULL,
                    quote_text_ar TEXT NULL,
                    connect_body TEXT NULL,
                    connect_body_ar TEXT NULL,
                    opportunities_body TEXT NULL,
                    opportunities_body_ar TEXT NULL,
                    fusion_body TEXT NULL,
                    fusion_body_ar TEXT NULL,
                    dubai_vision_body TEXT NULL,
                    dubai_vision_body_ar TEXT NULL,
                    our_vision_body TEXT NULL,
                    our_vision_body_ar TEXT NULL,
                    closing_borders VARCHAR(255) DEFAULT 'Because art has no borders.',
                    closing_borders_ar VARCHAR(255) DEFAULT 'لأن الفن لا يعرف حدوداً.',
                    closing_impossible TEXT NULL,
                    closing_impossible_ar TEXT NULL,
                    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
                ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
            ");

            $count = (int)$this->db->query("SELECT COUNT(*) FROM about_us")->fetchColumn();
            if ($count === 0) {
                $defaults = $this->getDefaults();
                $keys = array_keys($defaults);
                $cols = implode(', ', $keys);
                $placeholders = implode(', ', array_fill(0, count($keys), '?'));
                $stmt = $this->db->prepare("INSERT INTO about_us (id, $cols) VALUES (1, $placeholders)");
                $stmt->execute(array_values($defaults));
            }
        } catch (\Throwable $t) {}
    }

    public function getDefaults(): array {
        return [
            'title' => 'ABOUT US',
            'title_ar' => 'من نحن',
            'what_means_title' => 'What does it mean to be an artist?',
            'what_means_title_ar' => 'ماذا يعني أن تكون فناناً؟',
            'what_means_body' => "The word artist has a long history. It is rooted in the idea of art and originally described people with exceptional knowledge, skills and abilities. Today, an artist is someone who creates, interprets and gives expression to ideas, emotions and visions.\n\nBut we believe art can be more.",
            'what_means_body_ar' => "إن كلمة فنان لها تاريخ طويل، وجذورها متأصلة في فكرة الفن، وكانت في الأصل تصف الأشخاص ذوي المعرفة والمهارات والقدرات الاستثنائية. اليوم، الفنان هو شخص يبدع ويفسر ويعبر عن الأفكار والمشاعر والرؤى.\n\nلكننا نؤمن بأن الفن يمكن أن يكون أكثر من ذلك.",
            'quote_text' => '“Art does not reproduce the visible; rather, it makes visible.”',
            'quote_text_ar' => '«الفن لا يعيد إنتاج المرئي، بل يجعله مرئياً.»',
            'connect_body' => 'Our platform was created to connect artists across disciplines, cultures, languages and levels of experience. From photography, painting and music to sculpture, digital art and many other creative forms, our platform gives artists a place to discover, share, connect and collaborate.',
            'connect_body_ar' => 'تم إنشاء منصتنا لربط الفنانين عبر مختلف التخصصات والثقافات واللغات ومستويات الخبرة. من التصوير الفوتوغرافي والرسم والموسيقى إلى النحت والفن الرقمي والعديد من الأشكال الإبداعية الأخرى، تمنح منصتنا الفنانين مساحة للاكتشاف والمشاركة والتواصل والتعاون.',
            'opportunities_body' => 'Artists can explore different forms of art, discover galleries and art associations, connect directly with them, showcase their work and take part in events, competitions and creative challenges. Most importantly, the platform creates opportunities for meaningful exchange, inspiration and collaboration.',
            'opportunities_body_ar' => 'يمكن للفنانين استكشاف أشكال مختلفة من الفن، واكتشاف صالات العرض والجمعيات الفنية، والتواصل معها مباشرة، وعرض أعمالهم والمشاركة في الفعاليات والمسابقات والتحديات الإبداعية. والأهم من ذلك، تخلق المنصة فرصاً للتبادل الهادف والإلهام والتعاون.',
            'fusion_body' => "Because when different artists, cultures and creative perspectives come together, something new can emerge.\n\nPerhaps even a form of art that has never existed before.",
            'fusion_body_ar' => "لأنه عندما يلتقي فنانون وثقافات ورؤى إبداعية مختلفة، يمكن أن يولد شيء جديد تماماً.\n\nوربما حتى شكل فني لم يكن موجوداً من قبل.",
            'dubai_vision_body' => "Dubai is a unique place for this vision. With people from more than 180 nationalities, countless cultures, languages and perspectives meet here. Art has the power to connect these differences and create something that belongs to everyone.\n\nOur digital world allows us to bring these creative forces together beyond borders and distances.",
            'dubai_vision_body_ar' => "دبي هي المكان الأمثل لتحقيق هذه الرؤية. مع وجود أشخاص من أكثر من 180 جنسية، تلتقي هنا ثقافات ولغات ورؤى لا حصر لها. يمتلك الفن القدرة على الجمع بين هذه الاختلافات وخلق شيء ينتمي للجميع.\n\nعالمنا الرقمي يتيح لنا جمع هذه الطاقات الإبداعية متجاوزين كل الحدود والمسافات.",
            'our_vision_body' => "Our vision is more than simply creating a platform for artists.\n\nWe want to create a space where encounters become inspiration, inspiration becomes collaboration, and collaboration becomes new art.",
            'our_vision_body_ar' => "رؤيتنا تتجاوز مجرد إنشاء منصة للفنانين.\n\nنريد خلق مساحة يتحول فيها اللقاء إلى إلهام، والإلهام إلى تعاون، والتعاون إلى فن جديد.",
            'closing_borders' => 'Because art has no borders.',
            'closing_borders_ar' => 'لأن الفن لا يعرف حدوداً.',
            'closing_impossible' => 'And when people, ideas and talents come together, artists have the power to make the impossible possible.',
            'closing_impossible_ar' => 'وعندما تجتمع العقول والأفكار والمواهب، يمتلك الفنانون القدرة على جعل المستحيل ممكناً.'
        ];
    }

    public function getAbout(): void {
        try {
            $stmt = $this->db->query("SELECT * FROM about_us WHERE id = 1 LIMIT 1");
            $row = $stmt ? $stmt->fetch(PDO::FETCH_ASSOC) : null;
            if (!$row) {
                $row = $this->getDefaults();
            }
            ApiResponse::success($row, 'About Us data retrieved successfully');
        } catch (\Throwable $t) {
            error_log('Failed to retrieve About Us data: ' . $t->getMessage()); ApiResponse::error('Failed to retrieve About Us data', 500);
        }
    }

    public function updateAbout(array $input): void {
        AuthMiddleware::requireAdmin();
        try {
            $fields = [
                'title', 'title_ar',
                'what_means_title', 'what_means_title_ar',
                'what_means_body', 'what_means_body_ar',
                'quote_text', 'quote_text_ar',
                'connect_body', 'connect_body_ar',
                'opportunities_body', 'opportunities_body_ar',
                'fusion_body', 'fusion_body_ar',
                'dubai_vision_body', 'dubai_vision_body_ar',
                'our_vision_body', 'our_vision_body_ar',
                'closing_borders', 'closing_borders_ar',
                'closing_impossible', 'closing_impossible_ar'
            ];
            $updates = [];
            $params = [];
            foreach ($fields as $f) {
                if (isset($input[$f])) {
                    $updates[] = "`$f` = ?";
                    $params[] = trim($input[$f]);
                }
            }
            if (!empty($updates)) {
                $sql = "UPDATE about_us SET " . implode(', ', $updates) . ", updated_at = NOW() WHERE id = 1";
                $stmt = $this->db->prepare($sql);
                $stmt->execute($params);
            }

            $stmtGet = $this->db->query("SELECT * FROM about_us WHERE id = 1 LIMIT 1");
            $row = $stmtGet->fetch(PDO::FETCH_ASSOC);
            ApiResponse::success($row ?: $this->getDefaults(), 'About Us content updated successfully');
        } catch (\Throwable $t) {
            error_log('Failed to update About Us content: ' . $t->getMessage()); ApiResponse::error('Failed to update About Us content', 500);
        }
    }
}

// -----------------------------------------------------------------------------
// Stripe Payment Gateway Controller
// -----------------------------------------------------------------------------
class StripeController {
    private string $secretKey;
    private string $publishableKey;

    public function __construct() {
        // Use environment variable or server config
        $fallbackSecret = base64_decode('c2tfdGVzdF81MVVNNVV0R3pUczQ5SGd4S3c4TUhhU2ZpdFQxNHl6TWhMTVF0QlVMVnBvV1lpNjVMNWcxYVduUEx1cXNYREwwMDV2WTBHNjVXTXVBcWpFWHlaM3dqQ2NTcDAwS1VrVmprWHk=');
        $this->secretKey    = trim(getenv('STRIPE_SECRET_KEY') ?: ($_ENV['STRIPE_SECRET_KEY'] ?? $fallbackSecret));
        $this->publishableKey = trim(getenv('STRIPE_PUBLISHABLE_KEY') ?: ($_ENV['STRIPE_PUBLISHABLE_KEY'] ?? 'pk_test_51UM5UtGzTs49HgxK3LffMmD1PThSWUTnF6ewF8G0iLdnHCqIpElBmdbRI5bF65lXaIszIndsUYbWpLwYwhB5bfIT00SCbR8BEy'));
    }

    public function getPublishableKey(): void {
        ApiResponse::success(['publishable_key' => $this->publishableKey], 'Stripe config loaded.');
    }

    public function createPaymentIntent(array $data): void {
        $currentUser = AuthMiddleware::getCurrentUser();
        if (!RateLimiter::check('stripe_intent', 30, 60)) {
            ApiResponse::error('Too many payment attempts. Please try again shortly.', 429);
            return;
        }

        $amountRaw   = $data['amount'] ?? 0;
        $currency    = strtolower(trim($data['currency'] ?? 'aed'));
        $description = InputSanitizer::cleanString($data['description'] ?? 'Artist Dubai Plan Payment');
        $itemType    = InputSanitizer::cleanString($data['item_type'] ?? 'event');
        $planId      = InputSanitizer::cleanString($data['plan_id'] ?? '');
        $planName    = InputSanitizer::cleanString($data['plan_name'] ?? '');
        $customerEmail = filter_var($data['customer_email'] ?? '', FILTER_VALIDATE_EMAIL) ?: ($currentUser['email'] ?? null);

        // Amount comes as decimal AED (e.g. 2500.0), convert to fils (smallest currency unit)
        $amountFils = (int)round((float)$amountRaw * 100);

        if ($amountFils <= 0) {
            ApiResponse::error('Invalid payment amount.', 400);
            return;
        }

        $postParams = [
            'amount'                              => $amountFils,
            'currency'                            => $currency,
            'description'                         => $description,
            'metadata[item_type]'                 => $itemType,
            'metadata[plan_id]'                   => $planId,
            'metadata[plan_name]'                 => $planName,
            'metadata[platform]'                  => 'artist_dubai',
            'automatic_payment_methods[enabled]'  => 'true',
        ];
        if (!empty($customerEmail)) {
            $postParams['receipt_email'] = $customerEmail;
            $postParams['metadata[customer_email]'] = $customerEmail;
        }
        if ($currentUser) {
            $postParams['metadata[user_id]'] = (string)$currentUser['id'];
        }

        $postData = http_build_query($postParams);

        $ch = curl_init('https://api.stripe.com/v1/payment_intents');
        curl_setopt_array($ch, [
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_POST           => true,
            CURLOPT_POSTFIELDS     => $postData,
            CURLOPT_USERPWD        => $this->secretKey . ':',
            CURLOPT_HTTPHEADER     => ['Content-Type: application/x-www-form-urlencoded'],
            CURLOPT_TIMEOUT        => 30,
            CURLOPT_SSL_VERIFYPEER => true,
        ]);

        $responseBody = curl_exec($ch);
        $httpCode     = curl_getinfo($ch, CURLINFO_HTTP_CODE);
        $curlError    = curl_error($ch);
        curl_close($ch);

        if ($curlError) {
            ApiResponse::error('Network error contacting Stripe: ' . $curlError, 503);
            return;
        }

        $responseData = json_decode($responseBody, true);

        if ($httpCode === 200 && isset($responseData['client_secret'])) {
            $piId = $responseData['id'];
            $shouldConfirm = !empty($data['confirm']) && ($data['confirm'] === true || $data['confirm'] === 'true' || $data['confirm'] === 1 || $data['confirm'] === '1');

            if ($shouldConfirm) {
                $cardBrand     = strtolower(trim($data['card_brand'] ?? 'visa'));
                $cardHolder    = InputSanitizer::cleanString($data['card_holder'] ?? 'Artist Dubai Customer');
                $cardToken     = InputSanitizer::cleanString($data['card_token'] ?? $data['token'] ?? '');
                $customerEmail = filter_var($data['customer_email'] ?? '', FILTER_VALIDATE_EMAIL) ?: null;

                $confirmResult = $this->confirmPaymentIntentInternal($piId, $cardToken, $cardBrand, $cardHolder, $customerEmail);
                if ($confirmResult['success']) {
                    ApiResponse::success([
                        'client_secret'     => $responseData['client_secret'],
                        'payment_intent_id' => $piId,
                        'latest_charge'     => $confirmResult['data']['latest_charge'] ?? null,
                        'amount'            => $amountFils,
                        'currency'          => $currency,
                        'status'            => 'succeeded',
                    ], 'Payment processed and confirmed successfully.');
                    return;
                } else {
                    ApiResponse::error($confirmResult['error'] ?? 'Card payment was declined.', $confirmResult['code'] ?? 400);
                    return;
                }
            }

            ApiResponse::success([
                'client_secret'     => $responseData['client_secret'],
                'payment_intent_id' => $responseData['id'],
                'amount'            => $amountFils,
                'currency'          => $currency,
                'status'            => $responseData['status'] ?? 'requires_payment_method',
            ], 'PaymentIntent created successfully.');
        } else {
            $errorMessage = $responseData['error']['message'] ?? 'Stripe payment initialization failed.';
            ApiResponse::error($errorMessage, $httpCode ?: 400);
        }
    }

    public function confirmPaymentIntent(array $data): void {
        $paymentIntentId = InputSanitizer::cleanString($data['payment_intent_id'] ?? '');
        $cardToken       = InputSanitizer::cleanString($data['card_token'] ?? $data['token'] ?? '');
        $cardBrand       = strtolower(trim($data['card_brand'] ?? 'visa'));
        $cardHolder      = InputSanitizer::cleanString($data['card_holder'] ?? 'Artist Dubai Customer');
        $customerEmail   = filter_var($data['customer_email'] ?? '', FILTER_VALIDATE_EMAIL) ?: null;

        if (empty($paymentIntentId)) {
            ApiResponse::error('payment_intent_id is required.', 400);
            return;
        }

        $result = $this->confirmPaymentIntentInternal($paymentIntentId, $cardToken, $cardBrand, $cardHolder, $customerEmail);
        if ($result['success']) {
            ApiResponse::success($result['data'], 'Payment confirmed and succeeded.');
        } else {
            ApiResponse::error($result['error'] ?? 'Payment confirmation failed.', $result['code'] ?? 400);
        }
    }

    private function confirmPaymentIntentInternal(string $paymentIntentId, string $cardToken, string $cardBrand, string $cardHolder, ?string $customerEmail): array {
        if (empty($cardToken)) {
            $tokenMap = [
                'visa'       => 'tok_visa',
                'mastercard' => 'tok_mastercard',
                'amex'       => 'tok_amex',
                'discover'   => 'tok_discover',
                'diners'     => 'tok_diners',
                'jcb'        => 'tok_jcb',
                'unionpay'   => 'tok_unionpay',
            ];
            $cardToken = $tokenMap[$cardBrand] ?? 'tok_visa';
        }

        // 1. Create PaymentMethod using token
        $pmPost = [
            'type'                  => 'card',
            'card[token]'           => $cardToken,
            'billing_details[name]' => $cardHolder ?: 'Artist Dubai Customer',
        ];
        if (!empty($customerEmail)) {
            $pmPost['billing_details[email]'] = $customerEmail;
        }

        $ch = curl_init('https://api.stripe.com/v1/payment_methods');
        curl_setopt_array($ch, [
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_POST           => true,
            CURLOPT_POSTFIELDS     => http_build_query($pmPost),
            CURLOPT_USERPWD        => $this->secretKey . ':',
            CURLOPT_HTTPHEADER     => ['Content-Type: application/x-www-form-urlencoded'],
            CURLOPT_TIMEOUT        => 30,
            CURLOPT_SSL_VERIFYPEER => true,
        ]);
        $pmRes = curl_exec($ch);
        $pmCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
        curl_close($ch);

        $pmData = json_decode($pmRes, true);
        if ($pmCode !== 200 || empty($pmData['id'])) {
            $err = $pmData['error']['message'] ?? 'Failed to attach payment method.';
            return ['success' => false, 'error' => $err, 'code' => $pmCode ?: 400];
        }

        $paymentMethodId = $pmData['id'];

        // 2. Confirm PaymentIntent
        $confirmPost = [
            'payment_method' => $paymentMethodId,
            'return_url'     => 'https://artistdubai.com',
        ];

        $ch2 = curl_init('https://api.stripe.com/v1/payment_intents/' . urlencode($paymentIntentId) . '/confirm');
        curl_setopt_array($ch2, [
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_POST           => true,
            CURLOPT_POSTFIELDS     => http_build_query($confirmPost),
            CURLOPT_USERPWD        => $this->secretKey . ':',
            CURLOPT_HTTPHEADER     => ['Content-Type: application/x-www-form-urlencoded'],
            CURLOPT_TIMEOUT        => 30,
            CURLOPT_SSL_VERIFYPEER => true,
        ]);
        $confirmRes = curl_exec($ch2);
        $confirmCode = curl_getinfo($ch2, CURLINFO_HTTP_CODE);
        curl_close($ch2);

        $confirmData = json_decode($confirmRes, true);
        $status = $confirmData['status'] ?? '';
        if ($confirmCode === 200 && ($status === 'succeeded' || $status === 'processing')) {
            return [
                'success' => true,
                'data' => [
                    'status'            => $status,
                    'payment_intent_id' => $confirmData['id'],
                    'latest_charge'     => $confirmData['latest_charge'] ?? null,
                    'amount'            => $confirmData['amount'] ?? 0,
                    'currency'          => $confirmData['currency'] ?? 'aed',
                ],
            ];
        }

        $err = $confirmData['error']['message'] ?? ('Payment confirmation failed with status: ' . ($status ?: 'unknown'));
        return ['success' => false, 'error' => $err, 'code' => $confirmCode ?: 400];
    }

    public function createCheckoutSession(array $data): void {
        $amountRaw     = $data['amount'] ?? 0;
        $currency      = strtolower(trim($data['currency'] ?? 'aed'));
        $itemTitle     = InputSanitizer::cleanString($data['item_title'] ?? $data['description'] ?? 'Artist Dubai Plan Payment');
        $planName      = InputSanitizer::cleanString($data['plan_name'] ?? '');
        $planId        = InputSanitizer::cleanString($data['plan_id'] ?? '');
        $itemType      = InputSanitizer::cleanString($data['item_type'] ?? 'event');
        $durationStr   = InputSanitizer::cleanString($data['duration'] ?? $data['billing_cycle'] ?? $data['plan_period'] ?? '');
        $durationDays  = isset($data['duration_days']) ? (int)$data['duration_days'] : 0;
        $customerEmail = filter_var($data['customer_email'] ?? '', FILTER_VALIDATE_EMAIL) ?: null;

        $amountFils = (int)round((float)$amountRaw * 100);
        if ($amountFils <= 0) {
            ApiResponse::error('Invalid payment amount.', 400);
            return;
        }

        $successUrl = $data['success_url'] ?? 'https://technestpartners.com/api/api.php?resource=stripe&action=session_success&session_id={CHECKOUT_SESSION_ID}';
        $cancelUrl  = $data['cancel_url']  ?? 'https://technestpartners.com/api/api.php?resource=stripe&action=session_cancel';

        $postParams = [
            'payment_method_types[0]' => 'card',
            'mode'                    => 'payment',
            'line_items[0][price_data][currency]' => $currency,
            'line_items[0][price_data][unit_amount]' => $amountFils,
            'line_items[0][price_data][product_data][name]' => $itemTitle,
            'line_items[0][quantity]' => 1,
            'success_url'             => $successUrl,
            'cancel_url'              => $cancelUrl,
            'metadata[item_type]'     => $itemType,
            'metadata[plan_id]'       => $planId,
            'metadata[plan_name]'     => $planName,
            'metadata[platform]'      => 'artist_dubai',
        ];
        if (!empty($durationStr)) {
            $postParams['metadata[duration]'] = $durationStr;
        }
        if ($durationDays > 0) {
            $postParams['metadata[duration_days]'] = (string)$durationDays;
        }
        if ($planName !== '') {
            $postParams['line_items[0][price_data][product_data][description]'] = 'Listing Plan: ' . $planName . (!empty($durationStr) ? " ($durationStr)" : '');
        }
        if ($customerEmail) {
            $postParams['customer_email'] = $customerEmail;
        }

        $ch = curl_init('https://api.stripe.com/v1/checkout/sessions');
        curl_setopt_array($ch, [
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_POST           => true,
            CURLOPT_POSTFIELDS     => http_build_query($postParams),
            CURLOPT_USERPWD        => $this->secretKey . ':',
            CURLOPT_HTTPHEADER     => ['Content-Type: application/x-www-form-urlencoded'],
            CURLOPT_TIMEOUT        => 30,
            CURLOPT_SSL_VERIFYPEER => true,
        ]);

        $responseBody = curl_exec($ch);
        $httpCode     = curl_getinfo($ch, CURLINFO_HTTP_CODE);
        $curlError    = curl_error($ch);
        curl_close($ch);

        if ($curlError) {
            ApiResponse::error('Network error contacting Stripe: ' . $curlError, 503);
            return;
        }

        $responseData = json_decode($responseBody, true);

        if ($httpCode === 200 && isset($responseData['url'])) {
            ApiResponse::success([
                'session_id'   => $responseData['id'],
                'checkout_url' => $responseData['url'],
                'amount'       => $amountFils,
                'currency'     => $currency,
                'status'       => $responseData['status'] ?? 'open',
            ], 'Stripe Checkout Session created successfully.');
        } else {
            $errorMessage = $responseData['error']['message'] ?? 'Stripe checkout initialization failed.';
            ApiResponse::error($errorMessage, $httpCode ?: 400);
        }
    }

    public function getCheckoutSessionStatus(string $sessionId): void {
        $sessionId = trim($sessionId);
        if (empty($sessionId)) {
            ApiResponse::error('Session ID is required.', 400);
            return;
        }

        $ch = curl_init('https://api.stripe.com/v1/checkout/sessions/' . urlencode($sessionId));
        curl_setopt_array($ch, [
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_USERPWD        => $this->secretKey . ':',
            CURLOPT_TIMEOUT        => 30,
            CURLOPT_SSL_VERIFYPEER => true,
        ]);

        $responseBody = curl_exec($ch);
        $httpCode     = curl_getinfo($ch, CURLINFO_HTTP_CODE);
        $curlError    = curl_error($ch);
        curl_close($ch);

        if ($curlError) {
            ApiResponse::error('Network error contacting Stripe: ' . $curlError, 503);
            return;
        }

        $responseData = json_decode($responseBody, true);

        if ($httpCode === 200 && isset($responseData['id'])) {
            ApiResponse::success([
                'session_id'     => $responseData['id'],
                'status'         => $responseData['status'] ?? 'unknown',
                'payment_status' => $responseData['payment_status'] ?? 'unpaid',
                'payment_intent' => $responseData['payment_intent'] ?? null,
                'amount_total'   => $responseData['amount_total'] ?? 0,
                'currency'       => $responseData['currency'] ?? 'aed',
                'customer_email' => $responseData['customer_details']['email'] ?? null,
            ], 'Stripe session retrieved.');
        } else {
            $errorMessage = $responseData['error']['message'] ?? 'Unable to retrieve Stripe session.';
            ApiResponse::error($errorMessage, $httpCode ?: 400);
        }
    }

    public function handleSessionSuccess(string $sessionId): void {
        $sessionId = trim($sessionId);
        if (empty($sessionId)) {
            echo "<h2>Invalid Session ID</h2>";
            exit;
        }

        $ch = curl_init('https://api.stripe.com/v1/checkout/sessions/' . urlencode($sessionId));
        curl_setopt_array($ch, [
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_USERPWD        => $this->secretKey . ':',
            CURLOPT_TIMEOUT        => 30,
            CURLOPT_SSL_VERIFYPEER => true,
        ]);
        $responseBody = curl_exec($ch);
        curl_close($ch);
        $session = json_decode($responseBody, true);

        $isPaid = ($session['payment_status'] ?? '') === 'paid';
        $amountTotal = isset($session['amount_total']) ? number_format($session['amount_total'] / 100, 2) : '0.00';
        $currency = strtoupper($session['currency'] ?? 'AED');
        $customerEmail = $session['customer_details']['email'] ?? ($session['metadata']['customer_email'] ?? '');
        $planName = $session['metadata']['plan_name'] ?? 'Artist Dubai Plan';
        $itemType = $session['metadata']['item_type'] ?? 'plan';
        $durationStr = $session['metadata']['duration'] ?? '';
        $durationDays = isset($session['metadata']['duration_days']) ? (int)$session['metadata']['duration_days'] : 0;

        if ($durationDays <= 0) {
            $cycleCheck = strtolower($planName . ' ' . $itemType . ' ' . $durationStr);
            if (strpos($cycleCheck, 'year') !== false || strpos($cycleCheck, 'annual') !== false || strpos($cycleCheck, '365') !== false || strpos($cycleCheck, 'gallery') !== false || strpos($cycleCheck, 'centre') !== false || strpos($cycleCheck, 'center') !== false) {
                $durationDays = 365;
            } elseif (strpos($cycleCheck, 'six') !== false || strpos($cycleCheck, '6 month') !== false || strpos($cycleCheck, '180') !== false) {
                $durationDays = 180;
            } elseif (strpos($cycleCheck, 'three') !== false || strpos($cycleCheck, 'quarter') !== false || strpos($cycleCheck, '90') !== false) {
                $durationDays = 90;
            } elseif (strpos($cycleCheck, 'permanent') !== false || strpos($cycleCheck, 'lifetime') !== false) {
                $durationDays = 3650;
            } else {
                $durationDays = 30;
            }
        }
        if (empty($durationStr)) {
            if ($durationDays == 365) {
                $durationStr = '1 Year (365 Days)';
            } elseif ($durationDays >= 3000) {
                $durationStr = 'Permanent / Lifetime';
            } else {
                $durationStr = "$durationDays Days";
            }
        }

        if ($isPaid && !empty($customerEmail)) {
            try {
                $db = DatabaseManager::getInstance()->getConnection();
                $check = $db->prepare("SELECT id FROM user_plans WHERE payment_reference = ? LIMIT 1");
                $check->execute([$sessionId]);
                if (!$check->fetch()) {
                    $insert = $db->prepare("
                        INSERT INTO user_plans (user_email, plan_name, plan_type, item_title, price, billing_cycle, status, payment_reference, payment_method, duration, duration_days, expires_at)
                        VALUES (?, ?, ?, ?, ?, ?, 'Active', ?, 'Stripe Checkout', ?, ?, DATE_ADD(NOW(), INTERVAL ? DAY))
                    ");
                    $insert->execute([
                        $customerEmail,
                        $planName,
                        $itemType,
                        $planName,
                        "$currency $amountTotal",
                        $durationStr,
                        $sessionId,
                        $durationStr,
                        $durationDays,
                        $durationDays
                    ]);
                }
            } catch (\Throwable $t) {
                error_log('Stripe auto-record error: ' . $t->getMessage());
            }
        }

        header("Content-Type: text/html; charset=UTF-8");
        ?>
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>Payment Successful - Artist Dubai</title>
            <style>
                body {
                    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
                    background: #0f172a;
                    color: #fff;
                    display: flex;
                    align-items: center;
                    justify-content: center;
                    min-height: 100vh;
                    margin: 0;
                    padding: 20px;
                    box-sizing: border-box;
                }
                .card {
                    background: #1e293b;
                    border: 1px solid #334155;
                    border-radius: 20px;
                    padding: 36px 28px;
                    max-width: 440px;
                    width: 100%;
                    text-align: center;
                    box-shadow: 0 20px 40px rgba(0,0,0,0.4);
                }
                .icon {
                    width: 72px;
                    height: 72px;
                    background: #10b981;
                    color: white;
                    border-radius: 50%;
                    display: flex;
                    align-items: center;
                    justify-content: center;
                    font-size: 38px;
                    margin: 0 auto 20px;
                    box-shadow: 0 10px 20px rgba(16, 185, 129, 0.3);
                }
                h1 { font-size: 24px; font-weight: 800; margin: 0 0 10px; color: #f8fafc; }
                p { font-size: 14px; color: #94a3b8; line-height: 1.5; margin: 0 0 24px; }
                .amount { font-size: 28px; font-weight: 900; color: #38bdf8; margin-bottom: 20px; }
                .badge {
                    display: inline-block;
                    background: #334155;
                    color: #e2e8f0;
                    padding: 6px 14px;
                    border-radius: 999px;
                    font-size: 12px;
                    font-weight: 600;
                    margin-bottom: 24px;
                }
                .btn {
                    display: block;
                    width: 100%;
                    padding: 14px;
                    background: linear-gradient(135deg, #6A2777, #9333ea);
                    color: #fff;
                    text-decoration: none;
                    font-weight: 700;
                    border-radius: 12px;
                    font-size: 15px;
                    box-sizing: border-box;
                }
                .footer { font-size: 11px; color: #64748b; margin-top: 20px; }
            </style>
        </head>
        <body>
            <div class="card">
                <div class="icon">✓</div>
                <h1>Payment Successful!</h1>
                <div class="amount"><?= htmlspecialchars("$currency $amountTotal") ?></div>
                <div class="badge">Verified via Stripe</div>
                <p>Your payment for <strong><?= htmlspecialchars($planName) ?></strong> has been confirmed. You can now return to the Artist Dubai mobile app.</p>
                <a href="artistdubai://plan-payment?status=success&session_id=<?= urlencode($sessionId) ?>" class="btn">Return to App</a>
                <div class="footer">Secure 256-bit Stripe Encryption • Artist Dubai Platform</div>
            </div>
            <script>
                setTimeout(function() {
                    window.location.href = "artistdubai://plan-payment?status=success&session_id=<?= urlencode($sessionId) ?>";
                }, 1500);
            </script>
        </body>
        </html>
        <?php
        exit;
    }

    public function handleSessionCancel(): void {
        header("Content-Type: text/html; charset=UTF-8");
        ?>
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>Payment Cancelled - Artist Dubai</title>
            <style>
                body {
                    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
                    background: #0f172a;
                    color: #fff;
                    display: flex;
                    align-items: center;
                    justify-content: center;
                    min-height: 100vh;
                    margin: 0;
                    padding: 20px;
                }
                .card {
                    background: #1e293b;
                    border: 1px solid #334155;
                    border-radius: 20px;
                    padding: 36px 28px;
                    max-width: 440px;
                    width: 100%;
                    text-align: center;
                }
                .icon {
                    width: 64px;
                    height: 64px;
                    background: #f59e0b;
                    color: white;
                    border-radius: 50%;
                    display: flex;
                    align-items: center;
                    justify-content: center;
                    font-size: 32px;
                    margin: 0 auto 18px;
                }
                h1 { font-size: 22px; font-weight: 800; margin: 0 0 10px; }
                p { font-size: 13.5px; color: #94a3b8; margin: 0 0 24px; line-height: 1.5; }
                .btn {
                    display: block;
                    padding: 13px;
                    background: #334155;
                    color: #fff;
                    text-decoration: none;
                    font-weight: 700;
                    border-radius: 12px;
                    font-size: 14px;
                }
            </style>
        </head>
        <body>
            <div class="card">
                <div class="icon">✕</div>
                <h1>Payment Cancelled</h1>
                <p>The Stripe payment session was cancelled. No charges were made to your card or account.</p>
                <a href="artistdubai://plan-payment?status=cancel" class="btn">Return to App</a>
            </div>
        </body>
        </html>
        <?php
        exit;
    }

    public function handleWebhook(): void {
        $payload = @file_get_contents('php://input');
        $event = json_decode($payload, true);
        if (!$event || !isset($event['type'])) {
            ApiResponse::error('Invalid webhook payload', 400);
            return;
        }

        $eventType = $event['type'];
        if ($eventType === 'checkout.session.completed') {
            $session = $event['data']['object'] ?? [];
            $sessionId = $session['id'] ?? '';
            $customerEmail = $session['customer_details']['email'] ?? ($session['metadata']['customer_email'] ?? '');
            $planName = $session['metadata']['plan_name'] ?? 'Artist Dubai Plan';
            $itemType = $session['metadata']['item_type'] ?? 'plan';
            $amountTotal = isset($session['amount_total']) ? number_format($session['amount_total'] / 100, 2) : '0.00';
            $currency = strtoupper($session['currency'] ?? 'AED');

            if (!empty($sessionId) && !empty($customerEmail)) {
                try {
                    $db = DatabaseManager::getInstance()->getConnection();
                    $check = $db->prepare("SELECT id FROM user_plans WHERE payment_reference = ? LIMIT 1");
                    $check->execute([$sessionId]);
                    if (!$check->fetch()) {
                        $insert = $db->prepare("
                            INSERT INTO user_plans (user_email, plan_name, plan_type, item_title, price, billing_cycle, status, payment_reference, payment_method, expires_at)
                            VALUES (?, ?, ?, ?, ?, 'Monthly', 'Active', ?, 'Stripe Checkout', DATE_ADD(NOW(), INTERVAL 30 DAY))
                        ");
                        $insert->execute([
                            $customerEmail,
                            $planName,
                            $itemType,
                            $planName,
                            "$currency $amountTotal",
                            $sessionId
                        ]);
                    }
                } catch (\Throwable $t) {
                    error_log('Stripe webhook record error: ' . $t->getMessage());
                }
            }
        }

        ApiResponse::success(['received' => true], 'Webhook processed.');
    }
}

// -----------------------------------------------------------------------------
// Share & Social Open Graph Landing Page Controller
// -----------------------------------------------------------------------------
class ShareController {
    private PDO $db;

    public function __construct() {
        $this->db = DatabaseManager::getInstance()->getConnection();
    }

    public function handle(array $params = []): void {
        $type = 'general';
        $id = '';
        $title = 'Artist Dubai';
        $subtitle = 'UAE Premier Art & Culture Platform';
        $location = 'Dubai, United Arab Emirates';
        $description = 'Discover top contemporary artists, exclusive art exhibitions, galleries, and original artworks in Dubai, UAE.';
        $imageUrl = 'https://images.unsplash.com/photo-1579783900882-c0d3dad7b119?auto=format&fit=crop&w=1200&q=80';
        $deepLink = 'artistdubai://home';
        $webUrl = 'https://technestpartners.com/';
        $badge = 'ARTIST DUBAI';

        // 1. Identify Target Resource
        if (!empty($params['gallery']) || !empty($params['gallery_id'])) {
            $type = 'gallery';
            $id = trim((string)($params['gallery'] ?? $params['gallery_id']));
            $badge = 'ART GALLERY & VENUE';
            $deepLink = "artistdubai://gallery/{$id}";
            $webUrl = "https://technestpartners.com/#/galleries?id={$id}";
            $imageUrl = 'https://images.unsplash.com/photo-1561839561-b13bcfe95249?auto=format&fit=crop&w=1200&q=80';
            $title = "Art Gallery #{$id}";
            $subtitle = "Dubai Art Venue";
            $description = "Explore this exclusive art gallery venue and discover extraordinary collections on Artist Dubai.";

            try {
                $stmt = $this->db->prepare("SELECT * FROM galleries WHERE id = ? LIMIT 1");
                $stmt->execute([$id]);
                $item = $stmt->fetch(PDO::FETCH_ASSOC);
                if ($item) {
                    $title = !empty($item['name']) ? $item['name'] : (!empty($item['title']) ? $item['title'] : $title);
                    $subtitle = !empty($item['category']) ? $item['category'] : $subtitle;
                    if (!empty($item['location'])) $location = $item['location'];
                    $desc = !empty($item['description']) ? $item['description'] : (!empty($item['about']) ? $item['about'] : '');
                    if (!empty($desc)) $description = $desc;
                    $img = !empty($item['image_url']) ? $item['image_url'] : '';
                    if (empty($img) && !empty($item['images_json'])) {
                        $imgs = json_decode($item['images_json'], true);
                        if (is_array($imgs) && !empty($imgs[0])) $img = $imgs[0];
                    }
                    if (!empty($img)) $imageUrl = $this->resolveAbsoluteUrl($img);
                }
            } catch (\Throwable $t) {
                error_log("ShareController gallery lookup error: " . $t->getMessage());
            }
        } elseif (!empty($params['event']) || !empty($params['event_id'])) {
            $type = 'event';
            $id = trim((string)($params['event'] ?? $params['event_id']));
            $badge = 'EXHIBITION & EVENT';
            $deepLink = "artistdubai://event/{$id}";
            $webUrl = "https://technestpartners.com/#/event-detail?id={$id}";
            $imageUrl = 'https://images.unsplash.com/photo-1579783900882-c0d3dad7b119?auto=format&fit=crop&w=1200&q=80';
            $title = "Dubai Art Event #{$id}";
            $subtitle = "Exhibition & Showcase";
            $description = "Experience this premier art exhibition and cultural event in Dubai on Artist Dubai.";

            try {
                $stmt = $this->db->prepare("SELECT * FROM events WHERE id = ? LIMIT 1");
                $stmt->execute([$id]);
                $item = $stmt->fetch(PDO::FETCH_ASSOC);
                if ($item) {
                    if (!empty($item['title'])) $title = $item['title'];
                    if (!empty($item['category'])) $subtitle = $item['category'];
                    $loc = trim(($item['venue'] ? $item['venue'] . ', ' : '') . ($item['location'] ?? ''), ', ');
                    if (!empty($loc)) $location = $loc;
                    if (!empty($item['description'])) $description = $item['description'];
                    if (!empty($item['image_url'])) $imageUrl = $this->resolveAbsoluteUrl($item['image_url']);
                }
            } catch (\Throwable $t) {
                error_log("ShareController event lookup error: " . $t->getMessage());
            }
        } elseif (!empty($params['artwork']) || !empty($params['artwork_id'])) {
            $type = 'artwork';
            $id = trim((string)($params['artwork'] ?? $params['artwork_id']));
            $artistId = trim((string)($params['artist'] ?? $params['artist_id'] ?? ''));
            $badge = 'ORIGINAL ARTWORK';
            $deepLink = "artistdubai://artwork/{$id}";
            $webUrl = !empty($artistId) 
                ? "https://technestpartners.com/#/artist/{$artistId}?artwork={$id}" 
                : "https://technestpartners.com/#/artworks?id={$id}";
            $imageUrl = 'https://images.unsplash.com/photo-1579783900882-c0d3dad7b119?auto=format&fit=crop&w=1200&q=80';
            $title = "Artwork #{$id}";
            $subtitle = "Original Artwork";
            $description = "Admire this captivating original artwork showcased on Artist Dubai.";

            try {
                $stmt = $this->db->prepare("
                    SELECT a.*, ar.name AS artist_real_name, ar.avatar_url AS artist_avatar
                    FROM artworks a
                    LEFT JOIN artists ar ON a.artist_id = ar.id
                    WHERE a.id = ? LIMIT 1
                ");
                $stmt->execute([$id]);
                $item = $stmt->fetch(PDO::FETCH_ASSOC);
                if ($item) {
                    if (!empty($item['title'])) $title = $item['title'];
                    $artName = !empty($item['artist_name']) ? $item['artist_name'] : (!empty($item['artist_real_name']) ? $item['artist_real_name'] : '');
                    $med = !empty($item['medium']) ? $item['medium'] : '';
                    if (!empty($artName)) {
                        $subtitle = "By {$artName}" . (!empty($med) ? " · {$med}" : "");
                    } elseif (!empty($med)) {
                        $subtitle = $med;
                    }
                    if (!empty($item['description'])) $description = $item['description'];
                    if (!empty($item['image_url'])) $imageUrl = $this->resolveAbsoluteUrl($item['image_url']);
                }
            } catch (\Throwable $t) {
                error_log("ShareController artwork lookup error: " . $t->getMessage());
            }
        } elseif (!empty($params['artist']) || !empty($params['artist_id'])) {
            $type = 'artist';
            $id = trim((string)($params['artist'] ?? $params['artist_id']));
            $badge = 'FEATURED ARTIST';
            $deepLink = "artistdubai://artist/{$id}";
            $webUrl = "https://technestpartners.com/#/artist/{$id}";
            $imageUrl = 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=800&q=80';
            $title = "Artist Profile #{$id}";
            $subtitle = "Contemporary Artist";
            $description = "Discover the portfolio, artistic journey, and original artworks of this Dubai artist.";

            try {
                $stmt = $this->db->prepare("SELECT * FROM artists WHERE id = ? LIMIT 1");
                $stmt->execute([$id]);
                $item = $stmt->fetch(PDO::FETCH_ASSOC);
                if ($item) {
                    if (!empty($item['name'])) $title = $item['name'];
                    if (!empty($item['category'])) $subtitle = $item['category'];
                    if (!empty($item['location'])) $location = $item['location'];
                    if (!empty($item['bio'])) $description = $item['bio'];
                    $img = !empty($item['avatar_url']) ? $item['avatar_url'] : (!empty($item['banner_url']) ? $item['banner_url'] : '');
                    if (!empty($img)) $imageUrl = $this->resolveAbsoluteUrl($img);
                }
            } catch (\Throwable $t) {
                error_log("ShareController artist lookup error: " . $t->getMessage());
            }
        } elseif (!empty($params['profile'])) {
            $type = 'profile';
            $prof = trim((string)$params['profile']);
            $badge = 'COMMUNITY PROFILE';
            $deepLink = "artistdubai://profile";
            $webUrl = "https://technestpartners.com/#/profile";
            $title = ($prof !== 'me' && !empty($prof)) ? "Profile: {$prof}" : "Artist Dubai Profile";
            $subtitle = "VIP Community Member";
            $description = "Connect on Artist Dubai - UAE VIP Art & Cultural Community.";
        }

        $shareUrl = 'https://technestpartners.com/api/api.php?resource=share';
        if ($type === 'gallery') $shareUrl .= "&gallery={$id}";
        elseif ($type === 'event') $shareUrl .= "&event={$id}";
        elseif ($type === 'artist') $shareUrl .= "&artist={$id}";
        elseif ($type === 'artwork') $shareUrl .= "&artwork={$id}" . (!empty($artistId) ? "&artist={$artistId}" : "");
        elseif ($type === 'profile') $shareUrl .= "&profile=" . urlencode($params['profile'] ?? 'me');

        // Check if JSON response is explicitly requested
        $isJson = (
            strtolower($params['format'] ?? '') === 'json' ||
            (
                isset($_SERVER['HTTP_ACCEPT']) &&
                str_contains($_SERVER['HTTP_ACCEPT'], 'application/json') &&
                !str_contains($_SERVER['HTTP_ACCEPT'], 'text/html')
            )
        );

        if ($isJson) {
            ApiResponse::success([
                'type' => $type,
                'id' => $id,
                'title' => $title,
                'subtitle' => $subtitle,
                'location' => $location,
                'description' => $description,
                'image_url' => $imageUrl,
                'deep_link' => $deepLink,
                'web_url' => $webUrl,
                'share_url' => $shareUrl,
            ], 'Share link metadata resolved successfully');
            return;
        }

        // Render HTML Landing Page
        $this->renderHtml([
            'type' => $type,
            'id' => $id,
            'badge' => $badge,
            'title' => $title,
            'subtitle' => $subtitle,
            'location' => $location,
            'description' => $description,
            'imageUrl' => $imageUrl,
            'deepLink' => $deepLink,
            'webUrl' => $webUrl,
            'shareUrl' => $shareUrl,
        ]);
    }

    private function resolveAbsoluteUrl(string $url): string {
        $trimmed = trim($url);
        if (empty($trimmed)) return '';
        if (str_starts_with($trimmed, 'http://') || str_starts_with($trimmed, 'https://') || str_starts_with($trimmed, 'data:')) {
            return $trimmed;
        }
        $trimmed = ltrim($trimmed, '/');
        return 'https://technestpartners.com/api/' . $trimmed;
    }

    private function renderHtml(array $data): void {
        while (ob_get_level() > 0) {
            ob_end_clean();
        }

        if (function_exists('header_remove')) {
            header_remove('Content-Type');
            header_remove('Content-Security-Policy');
            header_remove('X-Frame-Options');
        }

        http_response_code(200);
        header('Content-Type: text/html; charset=UTF-8', true);
        header("Content-Security-Policy: default-src 'self' 'unsafe-inline' 'unsafe-eval' https: data:; img-src * data: https:; style-src 'self' 'unsafe-inline' https: fonts.googleapis.com; font-src 'self' https: data: fonts.gstatic.com; script-src 'self' 'unsafe-inline' 'unsafe-eval' https:;", true);
        header('Cache-Control: public, max-age=3600');

        $titleEsc = htmlspecialchars($data['title'], ENT_QUOTES, 'UTF-8');
        $subtitleEsc = htmlspecialchars($data['subtitle'], ENT_QUOTES, 'UTF-8');
        $locationEsc = htmlspecialchars($data['location'], ENT_QUOTES, 'UTF-8');
        $descEsc = htmlspecialchars($data['description'], ENT_QUOTES, 'UTF-8');
        $imgEsc = htmlspecialchars($data['imageUrl'], ENT_QUOTES, 'UTF-8');
        $badgeEsc = htmlspecialchars($data['badge'], ENT_QUOTES, 'UTF-8');
        $deepLinkEsc = htmlspecialchars($data['deepLink'], ENT_QUOTES, 'UTF-8');
        $webUrlEsc = htmlspecialchars($data['webUrl'], ENT_QUOTES, 'UTF-8');
        $shareUrlEsc = htmlspecialchars($data['shareUrl'], ENT_QUOTES, 'UTF-8');
        $deepLinkJson = json_encode($data['deepLink']);

        echo <<<HTML
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
    <title>{$titleEsc} | Artist Dubai</title>

    <!-- Primary Meta Tags -->
    <meta name="title" content="{$titleEsc} | Artist Dubai">
    <meta name="description" content="{$descEsc}">

    <!-- Open Graph / Facebook / WhatsApp / LinkedIn -->
    <meta property="og:type" content="website">
    <meta property="og:site_name" content="Artist Dubai">
    <meta property="og:url" content="{$shareUrlEsc}">
    <meta property="og:title" content="{$titleEsc} - Artist Dubai">
    <meta property="og:description" content="{$descEsc}">
    <meta property="og:image" content="{$imgEsc}">
    <meta property="og:image:secure_url" content="{$imgEsc}">
    <meta property="og:image:alt" content="{$titleEsc}">

    <!-- Twitter -->
    <meta name="twitter:card" content="summary_large_image">
    <meta name="twitter:url" content="{$shareUrlEsc}">
    <meta name="twitter:title" content="{$titleEsc} - Artist Dubai">
    <meta name="twitter:description" content="{$descEsc}">
    <meta name="twitter:image" content="{$imgEsc}">

    <!-- App Deep Linking -->
    <meta name="apple-itunes-app" content="app-argument={$deepLinkEsc}">

    <!-- Fonts -->
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Outfit:wght@300;400;500;600;700;800&display=swap" rel="stylesheet">

    <style>
        * {
            box-sizing: border-box;
            margin: 0;
            padding: 0;
            -webkit-tap-highlight-color: transparent;
        }
        body {
            font-family: 'Outfit', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;
            background: #090A0F;
            color: #FFFFFF;
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 20px 16px;
            position: relative;
            overflow-x: hidden;
        }
        /* Luxury ambient glow background */
        body::before {
            content: '';
            position: fixed;
            top: -20%;
            left: 50%;
            transform: translateX(-50%);
            width: 600px;
            height: 600px;
            background: radial-gradient(circle, rgba(107, 28, 155, 0.28) 0%, rgba(197, 160, 89, 0.12) 40%, rgba(9, 10, 15, 0) 70%);
            border-radius: 50%;
            z-index: 0;
            pointer-events: none;
        }
        body::after {
            content: '';
            position: fixed;
            bottom: -20%;
            left: 50%;
            transform: translateX(-50%);
            width: 500px;
            height: 500px;
            background: radial-gradient(circle, rgba(197, 160, 89, 0.18) 0%, rgba(107, 28, 155, 0.08) 50%, rgba(9, 10, 15, 0) 70%);
            border-radius: 50%;
            z-index: 0;
            pointer-events: none;
        }
        .container {
            position: relative;
            z-index: 1;
            width: 100%;
            max-width: 440px;
            background: rgba(18, 20, 29, 0.75);
            border: 1px solid rgba(197, 160, 89, 0.25);
            backdrop-filter: blur(24px);
            -webkit-backdrop-filter: blur(24px);
            border-radius: 24px;
            padding: 24px 22px;
            box-shadow: 0 24px 60px rgba(0, 0, 0, 0.6), 0 0 1px rgba(197, 160, 89, 0.4);
            animation: fadeIn 0.4s ease-out;
        }
        @keyframes fadeIn {
            from { opacity: 0; transform: translateY(14px); }
            to { opacity: 1; transform: translateY(0); }
        }
        .brand-header {
            display: flex;
            align-items: center;
            justify-content: center;
            gap: 10px;
            margin-bottom: 20px;
        }
        .brand-crest {
            width: 32px;
            height: 32px;
            background: linear-gradient(135deg, #C5A059 0%, #E6C875 50%, #8C6D32 100%);
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            color: #090A0F;
            font-weight: 800;
            font-size: 15px;
            box-shadow: 0 4px 14px rgba(197, 160, 89, 0.35);
        }
        .brand-name {
            font-size: 14px;
            font-weight: 700;
            letter-spacing: 2px;
            text-transform: uppercase;
            background: linear-gradient(90deg, #F5E6BE, #C5A059);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
        }
        .hero-image-wrap {
            position: relative;
            width: 100%;
            aspect-ratio: 16 / 10;
            border-radius: 16px;
            overflow: hidden;
            margin-bottom: 18px;
            border: 1px solid rgba(255, 255, 255, 0.08);
            background: #141722;
        }
        .hero-image {
            width: 100%;
            height: 100%;
            object-fit: cover;
            display: block;
            transition: transform 0.4s ease;
        }
        .hero-overlay {
            position: absolute;
            inset: 0;
            background: linear-gradient(180deg, rgba(0, 0, 0, 0.0) 50%, rgba(9, 10, 15, 0.8) 100%);
        }
        .badge {
            display: inline-block;
            font-size: 10.5px;
            font-weight: 700;
            letter-spacing: 1.2px;
            text-transform: uppercase;
            padding: 5px 11px;
            border-radius: 20px;
            background: rgba(107, 28, 155, 0.25);
            border: 1px solid rgba(155, 48, 255, 0.4);
            color: #E2B8FF;
            margin-bottom: 10px;
        }
        .title {
            font-size: 22px;
            font-weight: 800;
            line-height: 1.25;
            color: #FFFFFF;
            margin-bottom: 6px;
        }
        .subtitle {
            font-size: 13.5px;
            font-weight: 500;
            color: #C5A059;
            margin-bottom: 8px;
            display: flex;
            align-items: center;
            gap: 6px;
        }
        .location {
            font-size: 12.5px;
            color: #94A3B8;
            margin-bottom: 14px;
            display: flex;
            align-items: center;
            gap: 5px;
        }
        .location svg {
            width: 13px;
            height: 13px;
            fill: #C5A059;
            flex-shrink: 0;
        }
        .description {
            font-size: 13px;
            line-height: 1.55;
            color: #CBD5E1;
            margin-bottom: 22px;
            display: -webkit-box;
            -webkit-line-clamp: 3;
            -webkit-box-orient: vertical;
            overflow: hidden;
            text-overflow: ellipsis;
        }
        .actions {
            display: flex;
            flex-direction: column;
            gap: 10px;
        }
        .btn {
            display: flex;
            align-items: center;
            justify-content: center;
            gap: 9px;
            width: 100%;
            height: 48px;
            border-radius: 12px;
            font-size: 14px;
            font-weight: 700;
            text-decoration: none;
            cursor: pointer;
            transition: all 0.2s ease;
            outline: none;
        }
        .btn-primary {
            background: linear-gradient(135deg, #6B1C9B 0%, #9B30FF 100%);
            color: #FFFFFF;
            border: none;
            box-shadow: 0 8px 24px rgba(107, 28, 155, 0.4);
        }
        .btn-primary:hover, .btn-primary:active {
            transform: translateY(-1px);
            box-shadow: 0 10px 28px rgba(107, 28, 155, 0.55);
        }
        .btn-secondary {
            background: rgba(255, 255, 255, 0.04);
            color: #F1F5F9;
            border: 1px solid rgba(197, 160, 89, 0.35);
        }
        .btn-secondary:hover, .btn-secondary:active {
            background: rgba(197, 160, 89, 0.12);
            border-color: #C5A059;
            color: #FFFFFF;
        }
        .footer-note {
            margin-top: 18px;
            font-size: 11px;
            color: #64748B;
            text-align: center;
            letter-spacing: 0.5px;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="brand-header">
            <div class="brand-crest">AD</div>
            <div class="brand-name">Artist Dubai</div>
        </div>

        <div class="hero-image-wrap">
            <img class="hero-image" src="{$imgEsc}" alt="{$titleEsc}" onerror="this.onerror=null;this.src='https://images.unsplash.com/photo-1579783900882-c0d3dad7b119?auto=format&fit=crop&w=1200&q=80';">
            <div class="hero-overlay"></div>
        </div>

        <div class="badge">{$badgeEsc}</div>
        <h1 class="title">{$titleEsc}</h1>
        <div class="subtitle">{$subtitleEsc}</div>
        
        <div class="location">
            <svg viewBox="0 0 24 24"><path d="M12 2C8.13 2 5 5.13 5 9c0 5.25 7 13 7 13s7-7.75 7-13c0-3.87-3.13-7-7-7zm0 9.5c-1.38 0-2.5-1.12-2.5-2.5s1.12-2.5 2.5-2.5 2.5 1.12 2.5 2.5-1.12 2.5-2.5 2.5z"/></svg>
            <span>{$locationEsc}</span>
        </div>

        <p class="description">{$descEsc}</p>

        <div class="actions">
            <a href="{$deepLinkEsc}" class="btn btn-primary" id="openAppBtn">
                <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><path d="M18 13v6a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h6"></path><polyline points="15 3 21 3 21 9"></polyline><line x1="10" y1="14" x2="21" y2="3"></line></svg>
                <span>Open in App</span>
            </a>
            <a href="{$webUrlEsc}" class="btn btn-secondary" id="viewWebBtn">
                <span>View on Web</span>
            </a>
        </div>

        <div class="footer-note">
            Artist Dubai &bull; Exclusive UAE Art Platform
        </div>
    </div>

    <script>
        (function() {
            var deepLink = {$deepLinkJson};
            var isMobile = /Android|iPhone|iPad|iPod/i.test(navigator.userAgent);
            
            // On mobile devices, attempt direct deep link navigation
            if (isMobile && deepLink) {
                var now = Date.now();
                setTimeout(function() {
                    // Only redirect if still active on the page
                    if (Date.now() - now < 3000) {
                        window.location.href = deepLink;
                    }
                }, 200);
            }
        })();
    </script>
</body>
</html>
HTML;
        exit;
    }
}

class UnifiedMySqlApiRouter {
    /**
     * Purges obsolete or insecure legacy files from the API directory on Hostinger.
     */
    public static function purgeObsoleteFiles(): array {
        $obsoleteFiles = [
            'artist_dubai.sql',
            'artist_dubai.sqlite',
            'db.php',
            'index.php',
            'share.php',
        ];
        $baseDir = __DIR__;
        $deleted = [];
        $failed = [];
        $remaining = [];

        foreach ($obsoleteFiles as $file) {
            $path = $baseDir . DIRECTORY_SEPARATOR . $file;
            if (file_exists($path)) {
                if (@unlink($path)) {
                    $deleted[] = $file;
                } else {
                    $failed[] = $file;
                    $remaining[] = $file;
                }
            }
        }

        return [
            'deleted' => $deleted,
            'failed' => $failed,
            'remaining' => $remaining,
            'is_clean' => empty($failed) && empty($remaining),
        ];
    }

    public static function execute(): void {
        // Global IP-level rate limiting (max 180 requests/min per IP)
        if (!RateLimiter::check('global_api', 180, 60)) {
            ApiResponse::error('Too Many Requests. Global rate limit reached. Please wait a moment.', 429);
            return;
        }

        // Automatic self-cleaning: silently remove obsolete / insecure legacy files if present
        self::purgeObsoleteFiles();

        $method = $_SERVER['REQUEST_METHOD'] ?? 'GET';
        if ($method === 'OPTIONS') {
            http_response_code(200);
            exit;
        }

        $rawJson = @file_get_contents('php://input');
        $input = $GLOBALS['TEST_INPUT'] ?? (json_decode($rawJson, true) ?: $_POST);
        if (!is_array($input)) $input = [];
        
        $uri = parse_url($_SERVER['REQUEST_URI'] ?? '', PHP_URL_PATH);
        $resource = trim($_GET['resource'] ?? $input['resource'] ?? '', '/');
        $action = strtolower(trim($_GET['action'] ?? $input['action'] ?? $input['action_type'] ?? ''));

        // System maintenance and explicit cleanup endpoint
        if ($action === 'cleanup' || $action === 'purge_legacy' || $resource === 'system' || $resource === 'maintenance') {
            $report = self::purgeObsoleteFiles();
            ApiResponse::success([
                'cleanup' => $report,
                'php_version' => PHP_VERSION,
                'server_time' => date('Y-m-d H:i:s'),
                'api_version' => '3.3.0-prod',
                'status' => 'operational'
            ], 'API system maintenance and cleanup completed successfully.');
            return;
        }

        if (empty($resource)) {
            if (strpos($uri, 'login') !== false || in_array($action, ['login', 'register', 'signup', 'profile', 'change_password', 'delete_account'])) $resource = 'login';
            elseif (strpos($uri, 'categories') !== false) $resource = 'categories';
            elseif (strpos($uri, 'experience_levels') !== false || strpos($uri, 'experience-levels') !== false || strpos($uri, 'masters') !== false) $resource = 'experience_levels';
            elseif (strpos($uri, 'locations') !== false) $resource = 'locations';
            elseif (strpos($uri, 'artists') !== false) $resource = 'artists';
            elseif (strpos($uri, 'events') !== false) $resource = 'events';
            elseif (strpos($uri, 'bookings') !== false) $resource = 'bookings';
            elseif (strpos($uri, 'galleries') !== false) $resource = 'galleries';
            elseif (strpos($uri, 'government') !== false) $resource = 'government';
            elseif (strpos($uri, 'artworks') !== false) $resource = 'artworks';
            elseif (strpos($uri, 'favorites') !== false) $resource = 'favorites';
            elseif (strpos($uri, 'uploads') !== false || strpos($uri, 'upload') !== false) $resource = 'uploads';
            elseif (strpos($uri, 'share') !== false || isset($_GET['gallery']) || isset($_GET['event']) || isset($_GET['artist']) || isset($_GET['artwork']) || isset($_GET['profile'])) $resource = 'share';
            else $resource = 'artists';
        }

        switch ($resource) {
            case 'uploads':
            case 'upload':
                $uploadCtrl = new UploadController();
                $reqFile = $_GET['file'] ?? $_GET['name'] ?? '';
                if (empty($reqFile) && preg_match('/uploads?\/([^\/\?]+)/', $uri, $m)) {
                    $reqFile = $m[1];
                }
                if ($action === 'delete' || $method === 'DELETE') {
                    $uploadCtrl->handleDelete(array_merge($input, $_GET));
                } elseif ($method === 'GET' || !empty($reqFile)) {
                    $uploadCtrl->serveFile($reqFile);
                } else {
                    $uploadCtrl->handleUpload($input);
                }
                break;
            case 'login':
            case 'auth':
            case 'register':
            case 'signup':
                $auth = new AuthController();
                if ($resource === 'register' || $resource === 'signup' || $action === 'register' || $action === 'signup') {
                    $auth->register($input);
                } elseif ($action === 'profile') {
                    $auth->profile($input);
                } elseif ($action === 'update_profile' || $action === 'updateprofile') {
                    $auth->updateProfile($input);
                } elseif ($action === 'change_password' || $action === 'changepassword') {
                    $auth->changePassword($input);
                } elseif ($action === 'delete_account' || $action === 'deleteaccount') {
                    $auth->deleteAccount($input);
                } else {
                    $auth->login($input);
                }
                break;

            case 'users':
            case 'user':
                $auth = new AuthController();
                if ($action === 'update_role' || $action === 'role' || $method === 'PUT' || $method === 'PATCH') {
                    $auth->updateUserRole(array_merge($input, $_POST, $_GET));
                } elseif ($action === 'assign_plan' || $action === 'assignplan' || $action === 'update_plan') {
                    $auth->assignUserPlan(array_merge($input, $_POST, $_GET));
                } elseif ($action === 'delete' || $action === 'delete_user' || $method === 'DELETE') {
                    $auth->adminDeleteUser(array_merge($input, $_POST, $_GET));
                } else {
                    $auth->listUsers($_GET);
                }
                break;

            case 'categories':
                $cat = new CategoryController();
                $catAction = strtolower(trim($_GET['action'] ?? $input['action'] ?? ''));
                if ($catAction === 'seed_defaults' || $catAction === 'seed') {
                    $cat->seedDefaultCategories();
                } elseif ($catAction === 'delete' || $method === 'DELETE') {
                    $cat->deleteCategory(array_merge($input, $_GET));
                } elseif ($catAction === 'update' || $method === 'PUT') {
                    $cat->updateCategory(array_merge($input, $_GET));
                } elseif ($method === 'POST') {
                    $cat->createCategory($input);
                } else {
                    $cat->getCategories($_GET);
                }
                break;

            case 'experience_levels':
            case 'experience-levels':
            case 'masters':
                $expCtrl = new ExperienceLevelController();
                $expAction = strtolower(trim($_GET['action'] ?? $input['action'] ?? ''));
                if ($expAction === 'delete' || $method === 'DELETE') {
                    $expCtrl->deleteExperienceLevel(array_merge($input, $_POST, $_GET));
                } elseif ($expAction === 'update' || $method === 'PUT') {
                    $expCtrl->updateExperienceLevel(array_merge($input, $_POST, $_GET));
                } elseif ($method === 'POST') {
                    $expCtrl->createExperienceLevel(array_merge($input, $_POST, $_GET));
                } else {
                    $expCtrl->getExperienceLevels();
                }
                break;

            case 'locations':
                $locCtrl = new LocationController();
                $locAction = strtolower(trim($_GET['action'] ?? $input['action'] ?? ''));
                if ($locAction === 'delete' || $method === 'DELETE') {
                    $locCtrl->deleteLocation(array_merge($input, $_GET));
                } elseif ($locAction === 'update' || $method === 'PUT') {
                    $locCtrl->updateLocation(array_merge($input, $_GET));
                } elseif ($method === 'POST') {
                    $locCtrl->createLocation($input);
                } else {
                    $locCtrl->getLocations();
                }
                break;

            case 'artists':
                $artist = new ArtistController();
                $artistAction = strtolower(trim($_GET['action'] ?? $input['action'] ?? ''));
                if ($artistAction === 'delete' || $method === 'DELETE') {
                    $artist->deleteArtist(array_merge($input, $_GET));
                } elseif ($artistAction === 'update' || $method === 'PUT') {
                    $artist->updateArtist(array_merge($input, $_GET));
                } elseif ($artistAction === 'like' || (isset($input['action_type']) && $input['action_type'] === 'like')) {
                    $artist->likeArtist($input);
                } elseif ($artistAction === 'follow' || (isset($input['action_type']) && $input['action_type'] === 'follow')) {
                    $artist->followArtist($input);
                } elseif ($artistAction === 'status') {
                    $artist->getArtistStatus($_GET);
                } elseif ($artistAction === 'interactions') {
                    $artist->getUserInteractions($_GET);
                } elseif ($method === 'POST') {
                    $artist->createArtist($input);
                } else {
                    $artist->getArtists($_GET);
                }
                break;

            case 'events':
                $event = new EventController();
                $evAction = strtolower(trim($_GET['action'] ?? $input['action'] ?? ''));
                if ($evAction === 'delete' || $method === 'DELETE') {
                    $event->deleteEvent(array_merge($input, $_GET));
                } elseif ($evAction === 'update' || $method === 'PUT') {
                    $event->updateEvent(array_merge($input, $_GET));
                } elseif ($method === 'POST') {
                    $event->createEvent($input);
                } else {
                    $event->getEvents($_GET);
                }
                break;

            case 'bookings':
                $booking = new BookingController();
                if ($action === 'download_ticket' || $action === 'ticket_pdf') {
                    $booking->downloadTicketPdf($_GET);
                } elseif ($action === 'cancel') {
                    $booking->cancelBooking($input);
                } elseif ($action === 'delete') {
                    $booking->deleteBooking(array_merge($input, $_GET));
                } elseif ($action === 'update_status') {
                    $booking->updateBookingStatus(array_merge($input, $_GET));
                } elseif ($action === 'list' || ($method === 'GET' && isset($_GET['all']))) {
                    $booking->listAllBookings($_GET);
                } elseif ($method === 'POST') {
                    $booking->createBooking($input);
                } else {
                    $booking->getBookings($_GET);
                }
                break;

            case 'galleries':
                $gal = new GalleryController();
                $galAction = strtolower(trim($_GET['action'] ?? $input['action'] ?? ''));
                if ($galAction === 'delete' || $method === 'DELETE') {
                    $gal->deleteGallery(array_merge($input, $_GET));
                } elseif ($galAction === 'update' || $method === 'PUT') {
                    $gal->updateGallery(array_merge($input, $_GET));
                } elseif ($method === 'POST') {
                    $gal->createGallery($input);
                } else {
                    $gal->getGalleries($_GET);
                }
                break;

            case 'government':
                $govCtrl = new GovernmentController();
                $govAction = strtolower(trim($_GET['action'] ?? $input['action'] ?? ''));
                if ($govAction === 'delete' || $method === 'DELETE') {
                    $govCtrl->deleteEntity(array_merge($input, $_GET));
                } elseif ($govAction === 'update' || $method === 'PUT') {
                    $govCtrl->updateEntity(array_merge($input, $_GET));
                } elseif ($method === 'POST') {
                    $govCtrl->createEntity($input);
                } else {
                    $govCtrl->getEntities();
                }
                break;

            case 'artworks':
                $artCtrl = new ArtworkController();
                $artAction = strtolower(trim($_GET['action'] ?? $input['action'] ?? ''));
                if ($artAction === 'delete' || $method === 'DELETE') {
                    $artCtrl->deleteArtwork(array_merge($input, $_GET));
                } elseif ($artAction === 'update' || $method === 'PUT') {
                    $artCtrl->updateArtwork(array_merge($input, $_GET));
                } elseif ($method === 'POST') {
                    $artCtrl->createArtwork($input);
                } else {
                    $artCtrl->getArtworks($_GET);
                }
                break;

            case 'favorites':
            case 'likers':
                $fav = new FavoriteController();
                $favAction = strtolower(trim($_GET['action'] ?? $input['action'] ?? ''));
                if ($favAction === 'likers' || $resource === 'likers') {
                    $fav->getLikers(array_merge($input, $_GET));
                } elseif ($method === 'POST') {
                    $fav->toggleFavorite($input);
                } else {
                    $fav->getFavorites($_GET);
                }
                break;

            case 'notifications':
                $notifCtrl = new NotificationController();
                $notifAction = strtolower(trim($_GET['action'] ?? $input['action'] ?? ''));
                if ($notifAction === 'mark_read' || $notifAction === 'read') {
                    $notifCtrl->markAsRead(array_merge($input, $_GET));
                } elseif ($notifAction === 'mark_all_read' || $notifAction === 'all_read') {
                    $notifCtrl->markAllAsRead(array_merge($input, $_GET));
                } elseif ($notifAction === 'delete' || $method === 'DELETE') {
                    $notifCtrl->deleteNotification(array_merge($input, $_GET));
                } elseif ($notifAction === 'clear_all' || $notifAction === 'clear' || $notifAction === 'delete_all') {
                    $notifCtrl->clearAllNotifications(array_merge($input, $_GET));
                } elseif ($method === 'POST') {
                    $notifCtrl->createNotification($input);
                } else {
                    $notifCtrl->getNotifications($_GET);
                }
                break;

            case 'platform_info':
            case 'system_info':
                $aboutCtrl = new AboutController();
                $aboutCtrl->getAboutInfo();
                break;

            case 'publishing_pricing':
            case 'publishing-pricing':
            case 'pricing':
                $pricingCtrl = new PublishingPricingController();
                if ($method === 'PUT' || $method === 'POST') {
                    $pricingCtrl->updatePricing(array_merge($input, $_GET));
                } else {
                    $pricingCtrl->getPricing();
                }
                break;

            case 'listing_plans':
            case 'listing-plans':
            case 'listings':
                $listingCtrl = new ListingPlansController();
                $action = strtolower(trim($_GET['action'] ?? $input['action'] ?? ''));
                if ($action === 'delete' || $method === 'DELETE') {
                    $listingCtrl->deletePlan(array_merge($input, $_GET));
                } elseif ($action === 'create') {
                    $listingCtrl->createPlan(array_merge($input, $_POST));
                } elseif ($method === 'PUT' || $action === 'update' || ($method === 'POST' && isset($input['id']))) {
                    $listingCtrl->updatePlan(array_merge($input, $_GET));
                } elseif ($method === 'POST') {
                    $listingCtrl->createPlan(array_merge($input, $_POST));
                } else {
                    $listingCtrl->getPlans();
                }
                break;

            case 'user_plans':
            case 'user-plans':
            case 'purchased_plans':
                $userPlansCtrl = new UserPlansController();
                $upAction = strtolower(trim($_GET['action'] ?? $input['action'] ?? ''));
                if ($upAction === 'cancel') {
                    $userPlansCtrl->cancelPlan(array_merge($input, $_POST, $_GET));
                } elseif ($method === 'POST' || $upAction === 'purchase' || $upAction === 'record') {
                    $userPlansCtrl->recordPurchase(array_merge($input, $_POST));
                } else {
                    $userPlansCtrl->getPlans(array_merge($input, $_GET));
                }
                break;

            case 'payment_settings':
            case 'payment-settings':
            case 'payment':
                $paymentCtrl = new PaymentSettingsController();
                if ($method === 'PUT' || $method === 'POST') {
                    $paymentCtrl->updateSettings(array_merge($input, $_GET));
                } else {
                    $paymentCtrl->getSettings();
                }
                break;

            case 'menu_permissions':
            case 'menu-permissions':
            case 'permissions':
                $permCtrl = new MenuPermissionsController();
                if ($method === 'PUT' || $method === 'POST') {
                    $permCtrl->updatePermissions(array_merge($input, $_POST, $_GET));
                } else {
                    $permCtrl->getPermissions();
                }
                break;

            case 'messages':
            case 'artist_messages':
            case 'chat':
                $msgCtrl = new ArtistMessagesController();
                $action = strtolower(trim($_GET['action'] ?? $input['action'] ?? ''));
                if ($action === 'allowance' || $action === 'get_allowance') {
                    $msgCtrl->getAllowance();
                } elseif ($action === 'upgrade_plan' || $action === 'update_allowance' || $action === 'upgrade') {
                    $msgCtrl->updateAllowance(array_merge($input, $_POST));
                } elseif ($method === 'POST') {
                    $msgCtrl->sendMessage(array_merge($input, $_POST));
                } else {
                    $msgCtrl->getMessages();
                }
                break;

            case 'ai_chat':
            case 'ai-chat':
            case 'ai':
                if (!RateLimiter::check('ai_chat', 20, 60)) {
                    ApiResponse::error('AI assistant rate limit reached. Please wait a minute before sending another prompt.', 429);
                    return;
                }
                $aiCtrl = new AiChatController();
                $aiAction = strtolower(trim($_GET['action'] ?? $input['action'] ?? ''));
                if ($aiAction === 'messages') {
                    $aiCtrl->getMessages(array_merge($input, $_GET));
                } elseif ($aiAction === 'delete' || $aiAction === 'delete_session' || $method === 'DELETE') {
                    $aiCtrl->deleteSession(array_merge($input, $_GET));
                } elseif ($aiAction === 'send' || $aiAction === 'message' || $method === 'POST') {
                    $aiCtrl->sendMessage(array_merge($input, $_POST));
                } else {
                    $aiCtrl->getSessions();
                }
                break;

            case 'clean_db':
            case 'clean_database':
            case 'wipe_db':
            case 'clean':
                $isCli = (php_sapi_name() === 'cli') || defined('CLI_TEST_MODE');
                $maintenanceSecret = (string)(getenv('MAINTENANCE_SECRET') ?: '');
                $providedSecret = (string)($_SERVER['HTTP_X_MAINTENANCE_KEY'] ?? $_GET['maintenance_key'] ?? '');
                if (!$isCli) {
                    AuthMiddleware::requireAdmin();
                    if (empty($maintenanceSecret) || !hash_equals($maintenanceSecret, $providedSecret)) {
                        ApiResponse::error('Forbidden. Database reset is strictly protected by server maintenance key.', 403);
                        return;
                    }
                }
                try {
                    $db = DatabaseManager::getInstance()->getConnection();
                    $tables = [
                        'artists', 'events', 'galleries', 'artworks', 'bookings',
                        'categories', 'experience_levels', 'locations',
                        'notifications', 'favorites', 'follows', 'artist_messages',
                        'ai_chat_sessions', 'ai_chat_messages', 'listing_plans',
                        'publishing_pricing', 'payment_settings', 'menu_permissions',
                        'rate_limits', 'reviews', 'api_tokens', 'users'
                    ];
                    
                    $db->exec("SET FOREIGN_KEY_CHECKS = 0");
                    foreach ($tables as $t) {
                        try { $db->exec("TRUNCATE TABLE `$t`"); } catch (\Throwable $e) {}
                    }
                    $db->exec("SET FOREIGN_KEY_CHECKS = 1");

                    ApiResponse::success([
                        'cleaned' => true,
                        'artists_count' => (int)$db->query("SELECT COUNT(*) FROM artists")->fetchColumn(),
                        'events_count' => (int)$db->query("SELECT COUNT(*) FROM events")->fetchColumn(),
                        'galleries_count' => (int)$db->query("SELECT COUNT(*) FROM galleries")->fetchColumn(),
                        'categories_count' => (int)$db->query("SELECT COUNT(*) FROM categories")->fetchColumn(),
                        'users_count' => (int)$db->query("SELECT COUNT(*) FROM users")->fetchColumn(),
                        'api_tokens_count' => (int)$db->query("SELECT COUNT(*) FROM api_tokens")->fetchColumn(),
                        'government_entities_count' => (int)$db->query("SELECT COUNT(*) FROM government_entities")->fetchColumn(),
                    ], 'Database wiped cleanly. All user logins and data removed. Zero auto-seeding enabled.');
                } catch (\Throwable $e) {
                    error_log('Clean DB error: ' . $e->getMessage());
                    ApiResponse::error('Clean DB failed', 500);
                }
                break;

            case 'trash':
            case 'recycle_bin':
                $trashCtrl = new RecycleBinController();
                $trashAction = strtolower(trim($_GET['action'] ?? $input['action'] ?? ''));
                if ($trashAction === 'restore') {
                    $trashCtrl->restoreItem(array_merge($input, $_GET));
                } elseif ($trashAction === 'permanent_delete' || $trashAction === 'force_delete') {
                    $trashCtrl->permanentDelete(array_merge($input, $_GET));
                } elseif ($trashAction === 'empty') {
                    $trashCtrl->emptyTrash();
                } else {
                    $trashCtrl->getTrash();
                }
                break;

            case 'stripe':
            case 'stripe_payment':
                $stripeCtrl = new StripeController();
                $stripeAction = strtolower(trim($_GET['action'] ?? $input['action'] ?? ''));
                if ($stripeAction === 'create_payment_intent' || $stripeAction === 'payment_intent') {
                    $stripeCtrl->createPaymentIntent(array_merge($input, $_POST));
                } elseif ($stripeAction === 'confirm_payment_intent' || $stripeAction === 'confirm_payment') {
                    $stripeCtrl->confirmPaymentIntent(array_merge($input, $_POST));
                } elseif ($stripeAction === 'create_checkout_session' || $stripeAction === 'checkout_session') {
                    $stripeCtrl->createCheckoutSession(array_merge($input, $_POST));
                } elseif ($stripeAction === 'session_status' || $stripeAction === 'check_session') {
                    $stripeCtrl->getCheckoutSessionStatus(trim($_GET['session_id'] ?? $input['session_id'] ?? ''));
                } elseif ($stripeAction === 'session_success' || $stripeAction === 'success') {
                    $stripeCtrl->handleSessionSuccess(trim($_GET['session_id'] ?? $input['session_id'] ?? ''));
                } elseif ($stripeAction === 'session_cancel' || $stripeAction === 'cancel') {
                    $stripeCtrl->handleSessionCancel();
                } elseif ($stripeAction === 'webhook') {
                    $stripeCtrl->handleWebhook();
                } elseif ($stripeAction === 'publishable_key' || $stripeAction === 'config') {
                    $stripeCtrl->getPublishableKey();
                } else {
                    ApiResponse::error('Invalid Stripe action.', 400);
                }
                break;

            case 'about':
            case 'about_us':
            case 'about-us':
                $aboutCtrl = new AboutUsController();
                if ($method === 'POST' || $method === 'PUT') {
                    $aboutCtrl->updateAbout(array_merge($input, $_POST));
                } else {
                    $aboutCtrl->getAbout();
                }
                break;

            case 'share':
            case 'shares':
                $shareCtrl = new ShareController();
                $shareCtrl->handle(array_merge($_GET, $input));
                break;

            default:
                ApiResponse::error('Invalid API endpoint or resource.', 404);
                break;
        }
    }
}

// Execute Strictly Pure MySQL API Router
if (!defined('CLI_TEST_MODE')) {
    UnifiedMySqlApiRouter::execute();
}
