<?php
/**
 * Artist Dubai - Strictly Pure MySQL Single-File REST API System
 * Version: 6.3.0
 * Database Engine: Pure MySQL (Laragon MySQL Engine)
 * Architecture: High-Performance Single-File OOP Controller-Router System
 */

ob_start();

if (!headers_sent()) {
    // ─── CORS Allowlist ───────────────────────────────────────────────────────
    // Only allow requests from known origins. Any other origin receives no
    // Access-Control-Allow-Origin header, causing the browser to block the call.
    $allowedOrigins = [
        'https://technestpartners.com',
        'https://www.technestpartners.com',
        'http://localhost',
        'http://localhost:8080',
        'http://localhost:3000',
        'http://127.0.0.1',
        'capacitor://localhost',   // Ionic/Capacitor mobile hybrid
        'http://localhost:5173',   // Vite dev server
    ];
    $requestOrigin = $_SERVER['HTTP_ORIGIN'] ?? '';
    $originAllowed = in_array($requestOrigin, $allowedOrigins, true);

    // Flutter mobile apps (no Origin header) and server-to-server calls are OK
    if (empty($requestOrigin) || $originAllowed) {
        if (!empty($requestOrigin)) {
            header("Access-Control-Allow-Origin: {$requestOrigin}");
            header("Access-Control-Allow-Credentials: true");
            header("Vary: Origin");
        }
    }

    $reqHeaders = $_SERVER['HTTP_ACCESS_CONTROL_REQUEST_HEADERS'] ?? 'Content-Type, Authorization, X-Requested-With, Accept, Origin, If-None-Match, X-Api-Key, X-Auth-Token';
    header("Access-Control-Allow-Headers: $reqHeaders");
    header("Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS, PATCH, HEAD");
    header("Access-Control-Max-Age: 86400");
    header("X-Content-Type-Options: nosniff");
    header("X-Frame-Options: DENY");
    header("X-XSS-Protection: 1; mode=block");
    header("Referrer-Policy: strict-origin-when-cross-origin");
    header("Content-Type: application/json; charset=UTF-8");
    header("Cache-Control: no-cache, no-store, must-revalidate, max-age=0");
    header("Pragma: no-cache");
    header("Expires: 0");
}

if (isset($_SERVER['REQUEST_METHOD']) && strtoupper($_SERVER['REQUEST_METHOD']) === 'OPTIONS') {
    http_response_code(200);
    exit();
}

/**
 * -----------------------------------------------------------------------------
 * 1. PRODUCTION DATABASE CONFIGURATION
 * -----------------------------------------------------------------------------
 * Strictly configured for the production database.
 * If deploying to another server or modifying credentials, simply update the
 * constants below, or set environment variables (DB_HOST, DB_NAME, DB_USER, DB_PASS).
 */
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
        $forceMigrate = (php_sapi_name() === 'cli' && in_array('migrate', $_SERVER['argv'] ?? []))
                     || (isset($_GET['action']) && $_GET['action'] === 'migrate');
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
                six_month_price VARCHAR(100) DEFAULT 'AED 2,500',
                yearly_price VARCHAR(100) DEFAULT 'AED 4,500',
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
            if ($catCount === 0) {
                $categories = [
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
                    ['Calligraphy & Typography', 'artist', 'Arabic calligraphy, modern lettering and typography', '✍️'],
                    ['Contemporary Painting', 'artist', 'Modern and contemporary canvas and acrylic painting', '🎨'],
                    ['Digital Art & Sculpture', 'artist', 'Digital 3D installations, sculptures and generative art', '🗿'],
                    ['Photography', 'artist', 'Landscape, architectural and fine art photography across UAE', '📷'],
                    ['Abstract Painting', 'artist', 'Abstract expressions, mixed media and vibrant color palettes', '🎨'],
                    ['Ceramics & Pottery', 'artist', 'Handcrafted ceramics, clay sculptures and pottery', '🏺'],
                ];
                $stmt = $this->pdo->prepare("INSERT IGNORE INTO categories (name, type, description, emoji) VALUES (?, ?, ?, ?)");
                foreach ($categories as $cat) {
                    $stmt->execute($cat);
                }
            }

            // 2. Experience Levels (Auto-seed if empty)
            $expCount = (int)$this->pdo->query("SELECT COUNT(*) FROM experience_levels WHERE deleted_at IS NULL")->fetchColumn();
            if ($expCount === 0) {
                $levels = [
                    ['Emerging Artist', '1-3 years', 1],
                    ['Mid-Career Artist', '4-8 years', 2],
                    ['Established Master', '9+ years', 3],
                ];
                $stmt = $this->pdo->prepare("INSERT IGNORE INTO experience_levels (name, years_range, display_order) VALUES (?, ?, ?)");
                foreach ($levels as $l) {
                    $stmt->execute($l);
                }
            }

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
                    INSERT INTO publishing_pricing (item_type, item_name, description, weekly_price, monthly_price, six_month_price, yearly_price, six_month_badge, yearly_badge, currency, is_active) VALUES
                    ('event', 'Event Publishing', 'Publish art events and exhibitions across Dubai', 'AED 150', 'AED 500', 'AED 2,500', 'AED 4,500', 'Save 17%', 'Best Value', 'AED', 1),
                    ('artist', 'Artist Verification', 'Verified artist badge and premium listing showcase', 'AED 100', 'AED 350', 'AED 1,800', 'AED 3,200', 'Save 14%', 'Featured', 'AED', 1),
                    ('gallery', 'Gallery Space Spotlight', 'Feature your gallery on curated maps and event calendars', 'AED 250', 'AED 800', 'AED 4,000', 'AED 7,200', 'Save 16%', 'Premium', 'AED', 1);
                ");
            }

            // 6. Listing Plans (Auto-seed if empty)
            $planCount = (int)$this->pdo->query("SELECT COUNT(*) FROM listing_plans")->fetchColumn();
            if ($planCount === 0) {
                $this->pdo->exec("
                    INSERT INTO listing_plans (item_type, title, category, badge, price, description, button_text, is_active, sort_order) VALUES
                    ('event', 'Standard Event Listing', 'Exhibitions & Openings', 'Popular', 'AED 500', '30-day verified event showcase across mobile app and website', 'Pay from My Listings', 1, 1),
                    ('artist', 'Pro Artist Portfolio', 'Visual Arts', 'Best Choice', 'AED 350', 'Unlimited artwork uploads, custom bio, direct buyer messaging', 'Upgrade Artist Profile', 1, 2);
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
        if (!empty($_SERVER['HTTP_CF_CONNECTING_IP'])) {
            $candidate = trim($_SERVER['HTTP_CF_CONNECTING_IP']);
            if (filter_var($candidate, FILTER_VALIDATE_IP)) return $candidate;
        }
        if (!empty($_SERVER['HTTP_X_FORWARDED_FOR'])) {
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

                $isAdminRole = in_array($dbRole, ['admin', 'superadmin', 'super_admin']) || ($dbRole === 'admin');
                $isAdminEmail = in_array($cleanEmail, ['admin@artistdubai.com', 'admin@dubaiart.ae', 'admin@admin.com', 'admin@technestpartners.com'], true);

                $isAdmin = $isAdminRole || $isAdminEmail;
                $role = $isAdmin ? ($isAdminRole ? $dbRole : 'admin') : ($dbRole ?: 'user');

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

        $cleanLower = strtolower(trim($email));
        $isAdminEmail = in_array($cleanLower, ['admin@artistdubai.com', 'admin@dubaiart.ae', 'admin@admin.com', 'admin@technestpartners.com'], true);

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

        $cleanLower = strtolower(trim($user['email'] ?? ''));
        $isAdminEmail = in_array($cleanLower, ['admin@artistdubai.com', 'admin@dubaiart.ae', 'admin@admin.com', 'admin@technestpartners.com'], true);
        if ($isAdminEmail) {
            $userRole = 'admin';
            $isAdmin = true;
        } else {
            $userRole = !empty($user['role']) ? strtolower($user['role']) : 'user';
            $isAdmin = in_array($userRole, ['admin', 'superadmin', 'super_admin']) || ($userRole === 'admin');
        }

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

        // Prevent unauthorized privilege escalation: only allow admin role if authenticated as admin
        $currentUser = AuthMiddleware::getCurrentUser();
        $requestedRole = strtolower(trim($input['role'] ?? 'user'));
        $role = 'user';
        if ($currentUser && !empty($currentUser['is_admin']) && in_array($requestedRole, ['admin', 'artist', 'user'])) {
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
        $currentUser = AuthMiddleware::getCurrentUser();
        $email = InputSanitizer::cleanEmail($input['email'] ?? $input['current_email'] ?? $_GET['email'] ?? '');
        $newName = InputSanitizer::cleanString($input['full_name'] ?? $input['name'] ?? '');

        if (empty($email) || empty($newName)) {
            ApiResponse::error('Email and full name are required to update profile.', 400);
            return;
        }

        // Authorization check: User must own profile or be admin
        if ($currentUser) {
            if (!$currentUser['is_admin'] && strtolower($currentUser['email']) !== strtolower($email)) {
                ApiResponse::error('Forbidden. You can only update your own profile.', 403);
                return;
            }
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
            $maxAllowance = !empty($user['chat_max_allowance']) ? (int)$user['chat_max_allowance'] : 10;

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
        // 2. Be authenticated as account owner (and provide correct current password if provided)
        // 3. Unauthenticated requests must provide correct current password verified via bcrypt
        $isAuthorized = false;
        if ($currentUser && !empty($currentUser['is_admin'])) {
            $isAuthorized = true;
        } elseif ($currentUser && strtolower($currentUser['email']) === strtolower($email)) {
            if (!empty($currentPassword)) {
                $isAuthorized = password_verify($currentPassword, $user['password_hash']);
                if (!$isAuthorized) {
                    ApiResponse::error('Current password is incorrect.', 401);
                    return;
                }
            } else {
                $isAuthorized = true;
            }
        } elseif (!empty($currentPassword)) {
            $isAuthorized = password_verify($currentPassword, $user['password_hash']);
            if (!$isAuthorized) {
                ApiResponse::error('Current password is incorrect.', 401);
                return;
            }
        } else {
            ApiResponse::error('Authentication or current password required to change password.', 401);
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
            $usr['is_admin'] = in_array(strtolower($usr['role']), ['admin', 'superadmin']) || str_starts_with(strtolower($usr['email']), 'admin@');
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

        // 2. Also update chat_plan on users table for unified display
        if (!empty($email)) {
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
        $type = InputSanitizer::cleanString($query['type'] ?? '');
        $sql = "SELECT c.*, 
                (SELECT COUNT(*) FROM artists a WHERE a.category = c.name) AS artist_count,
                (SELECT COUNT(*) FROM events e WHERE e.category = c.name) AS event_count
                FROM categories c ";
        if (!empty($type) && $type !== 'all') {
            $stmt = $this->db->prepare($sql . 'WHERE c.type = ? OR c.type = "general" AND c.deleted_at IS NULL ORDER BY c.id ASC');
            $stmt->execute([$type]);
        } else {
            $stmt = $this->db->query($sql . 'ORDER BY c.id ASC');
        }
        $categories = $stmt->fetchAll();
        ApiResponse::success($categories, 'Categories retrieved successfully');
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
}

class ExperienceLevelController {
    private PDO $db;

    public function __construct() {
        $this->db = DatabaseManager::getInstance()->getConnection();
    }

    public function getExperienceLevels(): void {
        $stmt = $this->db->query('SELECT * FROM experience_levels WHERE deleted_at IS NULL ORDER BY display_order ASC, id ASC');
        $levels = $stmt->fetchAll();
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
        $contactEmail = InputSanitizer::cleanEmail($input['contact_email'] ?? '');
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
        $id = (int)($input['id'] ?? $input['event_id'] ?? 0);
        if ($id <= 0) {
            ApiResponse::error('Valid event ID is required.', 400);
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
        if (isset($input['status'])) { $fields[] = 'status = ?'; $params[] = InputSanitizer::cleanString((string)$input['status']); }
        if (isset($input['is_active'])) { $fields[] = 'is_active = ?'; $params[] = (int)$input['is_active']; }

        if (empty($fields)) {
            ApiResponse::error('No fields provided to update.', 400);
            return;
        }

        if (isset($input['image_url'])) {
            $evStmt = $this->db->prepare('SELECT image_url FROM events WHERE id = ?');
            $evStmt->execute([$id]);
            $currentImg = $evStmt->fetchColumn();
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

        if (!$currentUser['is_admin'] && strtolower($ev['contact_email'] ?? '') !== strtolower($currentUser['email'])) {
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

        // Soft-delete: move to recycle bin
        $this->db->prepare('UPDATE events SET deleted_at = NOW() WHERE id = ?')->execute([$id]);
        ApiResponse::success(['id' => $id], 'Event moved to recycle bin and image(s) deleted from storage');
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
                ApiResponse::error('Booking save error: ' . $t->getMessage(), 500);
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

        $currentUser = AuthMiddleware::getCurrentUser();
        if ($currentUser && !$currentUser['is_admin'] && strtolower($currentUser['email']) !== strtolower($b['email'])) {
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
        $status = InputSanitizer::cleanString($input['status'] ?? 'pending');
        $isPublic = isset($input['is_public']) ? (int)$input['is_public'] : ($status === 'approved' ? 1 : 0);
        $isApproved = isset($input['is_approved']) ? (int)$input['is_approved'] : ($status === 'approved' ? 1 : 0);

        if (empty($name)) {
            ApiResponse::error('Gallery / center name is required.');
            return;
        }

        $stmt = $this->db->prepare('INSERT INTO galleries (name, category, location, website, contact_person, email, phone, about, image_url, artist_id, artist_name, description, photo_count, images_json, status, is_public, is_approved, event_name, event_id) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)');
        $stmt->execute([$name, $category, $location, $website, $contactPerson, $email, $phone, $about, $imageUrl, $artistId, $artistName, $description, $photoCount, $imagesJson, $status, $isPublic, $isApproved, $eventName, $eventId]);

        $newId = (int)$this->db->lastInsertId();

        ApiResponse::success([
            'id' => $newId,
            'name' => $name,
            'title' => $name,
            'category' => $category,
            'type' => $category,
            'location' => $location,
            'address' => $location,
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
        $currentUser = AuthMiddleware::requireAuth();
        $id = (int)($input['id'] ?? $input['gallery_id'] ?? 0);
        if ($id <= 0) { ApiResponse::error('Gallery ID is required.'); return; }

        $stmt = $this->db->prepare('SELECT id, email, image_url, cover_url FROM galleries WHERE id = ?');
        $stmt->execute([$id]);
        $gal = $stmt->fetch();
        if (!$gal) { ApiResponse::error('Gallery not found', 404); return; }

        if (!$currentUser['is_admin'] && strtolower($gal['email'] ?? '') !== strtolower($currentUser['email'])) {
            ApiResponse::error('Forbidden. You do not have permission to update this gallery.', 403);
            return;
        }

        // If new image_url or cover_url is provided and differs from old, clean up old file from storage
        if (isset($input['image_url']) && !empty($gal['image_url']) && $input['image_url'] !== $gal['image_url']) {
            UploadController::deletePhysicalFile($gal['image_url']);
        }
        if (isset($input['cover_url']) && !empty($gal['cover_url']) && $input['cover_url'] !== $gal['cover_url']) {
            UploadController::deletePhysicalFile($gal['cover_url']);
        }

        $fields = [];
        $params = [];
        $allowed = ['name','title','description','category','location','image_url','cover_url','status','is_public','is_approved','about','website','timing','currently_open','display_order','event_name','event_id'];
        foreach ($allowed as $f) {
            if (isset($input[$f])) { $fields[] = "$f = ?"; $params[] = InputSanitizer::cleanString((string)$input[$f]); }
        }
        if (empty($fields)) { ApiResponse::error('No fields to update.'); return; }
        $params[] = $id;
        $this->db->prepare('UPDATE galleries SET ' . implode(', ', $fields) . ' WHERE id = ?')->execute($params);
        ApiResponse::success(['id' => $id], 'Gallery updated successfully');
    }

    public function deleteGallery(array $input): void {
        $currentUser = AuthMiddleware::requireAuth();
        $id = (int)($input['id'] ?? $input['gallery_id'] ?? $_GET['id'] ?? 0);
        if ($id <= 0) { ApiResponse::error('Gallery ID is required.'); return; }

        $stmt = $this->db->prepare('SELECT id, email, image_url, cover_url, images_json FROM galleries WHERE id = ?');
        $stmt->execute([$id]);
        $gal = $stmt->fetch();
        if (!$gal) { ApiResponse::error('Gallery not found', 404); return; }

        if (!$currentUser['is_admin'] && strtolower($gal['email'] ?? '') !== strtolower($currentUser['email'])) {
            ApiResponse::error('Forbidden. You do not have permission to delete this gallery.', 403);
            return;
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

        // Soft-delete: move to recycle bin
        $this->db->prepare('UPDATE galleries SET deleted_at = NOW() WHERE id = ?')->execute([$id]);
        ApiResponse::success(['id' => $id], 'Gallery moved to recycle bin and image(s) deleted from storage');
    }
}

class GovernmentController {
    private PDO $db;

    public function __construct() {
        $this->db = DatabaseManager::getInstance()->getConnection();
    }

    public function getEntities(): void {
        try {
            // Fetch all active records from database
            $stmtGov = $this->db->query("SELECT * FROM government_entities WHERE deleted_at IS NULL ORDER BY id ASC");
            $dbEntities = $stmtGov->fetchAll();
        } catch (\Throwable $e) {
            $dbEntities = [];
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
            ApiResponse::error('Failed to create government entity: ' . $e->getMessage(), 500);
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
            ApiResponse::error('Failed to update government entity: ' . $e->getMessage(), 500);
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
            ApiResponse::error('Failed to move government entity to recycle bin: ' . $e->getMessage(), 500);
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
        $artistId = !empty($input['artist_id']) ? (int)$input['artist_id'] : null;
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
        $email = InputSanitizer::cleanEmail($query['email'] ?? $query['user_email'] ?? '');
        $page = max(1, (int)($query['page'] ?? 1));
        $limit = isset($query['limit']) ? min(100, max(1, (int)$query['limit'])) : 50;
        $offset = ($page - 1) * $limit;

        if (!empty($email)) {
            $sql = 'SELECT * FROM notifications WHERE user_email = ? OR user_email IS NULL OR user_email = "" ORDER BY id DESC LIMIT ' . $limit . ' OFFSET ' . $offset;
            $stmt = $this->db->prepare($sql);
            $stmt->execute([$email]);
            $notifs = $stmt->fetchAll();

            $countStmt = $this->db->prepare('SELECT COUNT(*) FROM notifications WHERE user_email = ? OR user_email IS NULL OR user_email = ""');
            $countStmt->execute([$email]);
            $total = (int)$countStmt->fetchColumn();

            $unreadStmt = $this->db->prepare('SELECT COUNT(*) FROM notifications WHERE (user_email = ? OR user_email IS NULL OR user_email = "") AND is_read = 0');
            $unreadStmt->execute([$email]);
            $unreadCount = (int)$unreadStmt->fetchColumn();
        } else {
            $sql = 'SELECT * FROM notifications ORDER BY id DESC LIMIT ' . $limit . ' OFFSET ' . $offset;
            $stmt = $this->db->query($sql);
            $notifs = $stmt->fetchAll();

            $total = (int)$this->db->query('SELECT COUNT(*) FROM notifications')->fetchColumn();
            $unreadCount = (int)$this->db->query('SELECT COUNT(*) FROM notifications WHERE is_read = 0')->fetchColumn();
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
        if (!empty($email)) {
            $stmt = $this->db->prepare('UPDATE notifications SET is_read = 1 WHERE user_email = ? OR user_email IS NULL OR user_email = ""');
            $stmt->execute([$email]);
        } else {
            $this->db->exec('UPDATE notifications SET is_read = 1');
        }
        ApiResponse::success(null, 'All notifications marked as read');
    }

    public function createNotification(array $input): void {
        $title = InputSanitizer::cleanString($input['title'] ?? '');
        $body = InputSanitizer::cleanString($input['body'] ?? $input['message'] ?? '');
        $type = InputSanitizer::cleanString($input['type'] ?? 'general');
        $route = InputSanitizer::cleanString($input['route'] ?? '');
        $userEmail = InputSanitizer::cleanEmail($input['user_email'] ?? $input['email'] ?? '');

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
        $stmt = $this->db->prepare('DELETE FROM notifications WHERE id = ?');
        $stmt->execute([$id]);
        ApiResponse::success(['id' => $id], 'Notification deleted successfully');
    }

    public function clearAllNotifications(array $input): void {
        $email = InputSanitizer::cleanEmail($input['email'] ?? $input['user_email'] ?? '');
        if (!empty($email)) {
            $stmt = $this->db->prepare('DELETE FROM notifications WHERE user_email = ? OR user_email IS NULL OR user_email = ""');
            $stmt->execute([$email]);
        } else {
            $this->db->exec('DELETE FROM notifications');
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
        $mimes = [
            'jpg' => 'image/jpeg',
            'jpeg' => 'image/jpeg',
            'png' => 'image/png',
            'gif' => 'image/gif',
            'webp' => 'image/webp',
            'svg' => 'image/svg+xml',
            'pdf' => 'application/pdf',
        ];
        $mime = $mimes[$ext] ?? 'application/octet-stream';

        header('Content-Type: ' . $mime, true);
        header('Content-Length: ' . filesize($filePath));
        header('Cache-Control: public, max-age=604800');
        if (function_exists('header_remove')) {
            header_remove('Pragma');
            header_remove('Expires');
        }
        readfile($filePath);
        exit;
    }

    public function handleUpload(array $input): void {
        // Rate limiting for uploads
        if (!RateLimiter::check('upload', 30, 60)) {
            ApiResponse::error('Upload rate limit reached. Please wait a moment.', 429);
            return;
        }

        $uploadDir = __DIR__ . '/uploads';
        if (!is_dir($uploadDir)) {
            @mkdir($uploadDir, 0755, true);
        }

        // Hardened .htaccess inside uploads/ to strictly block script execution
        $htaccess = $uploadDir . '/.htaccess';
        $secureHtaccess = "# Hardened security configuration - Strictly disable script execution\n" .
            "<IfModule mod_php.c>\n    php_flag engine off\n</IfModule>\n" .
            "<IfModule mod_php7.c>\n    php_flag engine off\n</IfModule>\n" .
            "<IfModule mod_php8.c>\n    php_flag engine off\n</IfModule>\n" .
            "<FilesMatch \"(?i)\\.(php|php3|php4|php5|php7|php8|phtml|phar|phps|cgi|pl|py|sh|bash|exe|bat|cmd|hta)$\">\n" .
            "    <IfModule mod_authz_core.c>\n        Require all denied\n    </IfModule>\n" .
            "    <IfModule !mod_authz_core.c>\n        Order deny,allow\n        Deny from all\n    </IfModule>\n" .
            "</FilesMatch>\n" .
            "Options -ExecCGI -Indexes\n" .
            "Header set X-Content-Type-Options \"nosniff\"\n";
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
            ApiResponse::error('Failed to retrieve platform info: ' . $t->getMessage(), 500);
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
            ApiResponse::success($rows, 'Publishing pricing retrieved successfully');
        } catch (\Throwable $t) {
            ApiResponse::error('Failed to retrieve publishing pricing: ' . $t->getMessage(), 500);
        }
    }

    public function seedInitialPricing(): void {
        try {
            $count = (int)$this->db->query("SELECT COUNT(*) FROM publishing_pricing")->fetchColumn();
            if ($count === 0) {
                $stmt = $this->db->prepare("
                    INSERT INTO publishing_pricing 
                    (id, item_type, item_name, description, weekly_price, monthly_price, six_month_price, yearly_price, six_month_badge, yearly_badge, currency, is_active)
                    VALUES 
                    (1, 'event', 'Event Publishing', 'Publishing events is a paid service on Artist Dubai. Select your preferred promotion duration. Once reviewed and approved by the admin, your event will be broadcasted to art enthusiasts across Dubai.', 'AED 150', 'AED 500', 'AED 2,500', 'AED 4,500', '180 days active', '365 days active', 'AED', 1),
                    (2, 'gallery', 'Gallery Listing & Showcase', 'Premier directory listing, verified status badge, and spotlight showcase for Dubai art galleries.', 'AED 200', 'AED 750', 'AED 3,800', 'AED 6,500', '180 days active', '365 days active', 'AED', 1),
                    (3, 'artist', 'Artist Verification & Listing', 'Get verified badge, priority placement in artist directory, and direct commissioning channel.', 'AED 100', 'AED 350', 'AED 1,800', 'AED 3,000', '180 days active', '365 days active', 'AED', 1)
                    ON DUPLICATE KEY UPDATE item_name = VALUES(item_name)
                ");
                $stmt->execute();
            }
        } catch (\Throwable $t) {}
    }

    public function updatePricing(array $input): void {
        AuthMiddleware::requireAdmin();

        $id = (int)($input['id'] ?? 0);
        $itemName = InputSanitizer::cleanString($input['item_name'] ?? $input['name'] ?? '');
        $description = InputSanitizer::cleanString($input['description'] ?? '');
        $weeklyPrice = InputSanitizer::cleanString($input['weekly_price'] ?? $input['weekly'] ?? '');
        $monthlyPrice = InputSanitizer::cleanString($input['monthly_price'] ?? $input['monthly'] ?? '');
        $sixMonthPrice = InputSanitizer::cleanString($input['six_month_price'] ?? $input['six_month'] ?? '');
        $yearlyPrice = InputSanitizer::cleanString($input['yearly_price'] ?? $input['yearly'] ?? '');
        $sixMonthBadge = InputSanitizer::cleanString($input['six_month_badge'] ?? $input['sixMonthBadge'] ?? '');
        $yearlyBadge = InputSanitizer::cleanString($input['yearly_badge'] ?? $input['yearlyBadge'] ?? '');
        $isActive = isset($input['is_active']) ? (int)$input['is_active'] : 1;

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
            if (!empty($sixMonthPrice)) { $fields[] = 'six_month_price = ?'; $params[] = $sixMonthPrice; }
            if (!empty($yearlyPrice)) { $fields[] = 'yearly_price = ?'; $params[] = $yearlyPrice; }
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
            ApiResponse::error('Failed to update publishing pricing: ' . $t->getMessage(), 500);
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
                $features = [];
                if (!empty($row['features_json'])) {
                    $decoded = json_decode($row['features_json'], true);
                    if (is_array($decoded)) {
                        $features = $decoded;
                    }
                }
                $row['features'] = $features;
            }
            ApiResponse::success($rows, 'Listing plans retrieved successfully');
        } catch (\Throwable $t) {
            ApiResponse::error('Failed to retrieve listing plans: ' . $t->getMessage(), 500);
        }
    }

    public function seedInitialPlans(): void {
        try {
            $count = (int)$this->db->query("SELECT COUNT(*) FROM listing_plans")->fetchColumn();
            if ($count === 0) {
                $plans = [
                    [
                        'item_type' => 'event',
                        'title' => 'Event Listing',
                        'category' => 'Events',
                        'badge' => 'One-time',
                        'price' => '99 AED',
                        'description' => 'Publish a single event on Artist Dubai.',
                        'features_json' => json_encode(['One event listing', 'Visible in Events and calendar', 'Gallery photos included']),
                        'button_text' => 'Pay from My Listings',
                        'sort_order' => 1
                    ],
                    [
                        'item_type' => 'gallery',
                        'title' => 'Gallery Listing',
                        'category' => 'Galleries',
                        'badge' => 'One-time',
                        'price' => '149 AED',
                        'description' => 'Publish a single gallery on Artist Dubai.',
                        'features_json' => json_encode(['One gallery listing', 'Unlimited images', 'Shareable gallery page']),
                        'button_text' => 'Pay from My Listings',
                        'sort_order' => 2
                    ],
                    [
                        'item_type' => 'art_centre',
                        'title' => 'Art Centre Listing',
                        'category' => 'Art Centres',
                        'badge' => 'One-time',
                        'price' => '299 AED',
                        'description' => 'Publish a single art centre on Artist Dubai.',
                        'features_json' => json_encode(['One art centre listing', 'Verified venue badge', 'Direct booking inquiry button']),
                        'button_text' => 'Pay from My Listings',
                        'sort_order' => 3
                    ],
                ];
                $stmt = $this->db->prepare("
                    INSERT INTO listing_plans 
                    (item_type, title, category, badge, price, description, features_json, button_text, is_active, sort_order)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, 1, ?)
                ");
                foreach ($plans as $p) {
                    $stmt->execute([
                        $p['item_type'], $p['title'], $p['category'], $p['badge'],
                        $p['price'], $p['description'], $p['features_json'],
                        $p['button_text'], $p['sort_order']
                    ]);
                }
            }
        } catch (\Throwable $t) {}
    }

    public function updatePlan(array $input): void {
        AuthMiddleware::requireAdmin();

        $id = (int)($input['id'] ?? 0);
        $itemType = trim($input['item_type'] ?? '');
        $title = InputSanitizer::cleanString($input['title'] ?? '');
        $category = InputSanitizer::cleanString($input['category'] ?? '');
        $badge = InputSanitizer::cleanString($input['badge'] ?? 'One-time');
        $price = InputSanitizer::cleanString($input['price'] ?? '');
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
            ApiResponse::error('Failed to update listing plan: ' . $t->getMessage(), 500);
        }
    }

    public function createPlan(array $input): void {
        AuthMiddleware::requireAdmin();

        $itemType = strtolower(trim(InputSanitizer::cleanString($input['item_type'] ?? 'custom')));
        $title = InputSanitizer::cleanString($input['title'] ?? 'Listing Plan');
        $category = InputSanitizer::cleanString($input['category'] ?? 'Listings');
        $badge = InputSanitizer::cleanString($input['badge'] ?? 'One-time');
        $price = InputSanitizer::cleanString($input['price'] ?? '199 AED');
        $description = InputSanitizer::cleanString($input['description'] ?? '');
        $buttonText = InputSanitizer::cleanString($input['button_text'] ?? 'Pay from My Listings');
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
                (item_type, title, category, badge, price, description, features_json, button_text, is_active, sort_order) 
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            ");
            $stmt->execute([$itemType, $title, $category, $badge, $price, $description, $featuresJson, $buttonText, $isActive, $sortOrder]);
            $newId = (int)$this->db->lastInsertId();

            ApiResponse::success(['id' => $newId, 'created' => true], 'Listing plan created successfully');
        } catch (\Throwable $t) {
            ApiResponse::error('Failed to create listing plan: ' . $t->getMessage(), 500);
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
            ApiResponse::error('Failed to delete listing plan: ' . $t->getMessage(), 500);
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
            $this->db->exec("ALTER TABLE user_plans ADD COLUMN payment_proof_url VARCHAR(500) NULL");
        } catch (\Throwable $t) {}
    }

    public function getPlans(array $input = []): void {
        try {
            $currentUser = AuthMiddleware::getCurrentUser();
            $email = InputSanitizer::cleanEmail($input['email'] ?? $input['user_email'] ?? $_GET['email'] ?? $_GET['user_email'] ?? '');
            if (empty($email) && $currentUser) {
                $email = $currentUser['email'];
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
            $maxAllowance = !empty($userRow['chat_max_allowance']) ? (int)$userRow['chat_max_allowance'] : 10;
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
                        'billing_cycle' => !empty($ep['publishing_plan']) ? ucfirst($ep['publishing_plan']) : 'Listing',
                        'status' => strtolower($ep['payment_status'] ?? '') === 'paid' ? 'Active' : (ucfirst($ep['payment_status'] ?? 'Active')),
                        'payment_reference' => $ep['payment_reference'] ?? null,
                        'payment_method' => 'Online',
                        'features' => ['Featured Event Listing', 'Calendar & Push Visibility', 'RSVP & Ticketing Access'],
                        'start_date' => $ep['created_at'],
                        'expires_at' => null,
                        'days_left' => null,
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
                        'billing_cycle' => !empty($gp['publishing_plan']) ? ucfirst($gp['publishing_plan']) : 'Listing',
                        'status' => strtolower($gp['payment_status'] ?? '') === 'paid' ? 'Active' : (ucfirst($gp['payment_status'] ?? 'Active')),
                        'payment_reference' => $gp['payment_reference'] ?? null,
                        'payment_method' => 'Online',
                        'features' => ['Verified Gallery Badge', 'Exhibition Space Listing', 'Direct Collector Inquiries'],
                        'start_date' => $gp['created_at'],
                        'expires_at' => null,
                        'days_left' => null,
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
            ApiResponse::error('Failed to get user plans: ' . $t->getMessage(), 500);
        }
    }

    public function recordPurchase(array $input): void {
        try {
            $currentUser = AuthMiddleware::getCurrentUser();
            $email = InputSanitizer::cleanEmail($input['email'] ?? $input['user_email'] ?? ($currentUser['email'] ?? ''));
            $planName = trim(InputSanitizer::cleanString($input['plan_name'] ?? 'Custom Plan'));
            $planType = trim(InputSanitizer::cleanString($input['plan_type'] ?? 'Subscription'));
            $itemTitle = trim(InputSanitizer::cleanString($input['item_title'] ?? $planName));
            $price = trim(InputSanitizer::cleanString($input['price'] ?? $input['plan_amount'] ?? 'AED 0'));
            $billingCycle = trim(InputSanitizer::cleanString($input['billing_cycle'] ?? $input['plan_period'] ?? 'Monthly'));
            $paymentRef = trim(InputSanitizer::cleanString($input['payment_reference'] ?? $input['transaction_id'] ?? ''));
            $paymentMethod = trim(InputSanitizer::cleanString($input['payment_method'] ?? 'Online'));
            $paymentProofUrl = trim(InputSanitizer::cleanUrl($input['payment_proof_url'] ?? $input['receipt_url'] ?? ''));
            $features = isset($input['features']) && is_array($input['features']) ? json_encode($input['features']) : null;

            if (empty($email)) {
                ApiResponse::error('user_email is required', 400);
                return;
            }

            // Calculate duration and expiration
            $durationDays = 30;
            $cycleCheck = strtolower($billingCycle . ' ' . $planName . ' ' . ($input['badge'] ?? ''));
            if (strpos($cycleCheck, 'year') !== false || strpos($cycleCheck, 'annual') !== false || strpos($cycleCheck, '365') !== false) {
                $durationDays = 365;
            } elseif (strpos($cycleCheck, 'six') !== false || strpos($cycleCheck, '6 month') !== false || strpos($cycleCheck, '180') !== false) {
                $durationDays = 180;
            } elseif (strpos($cycleCheck, 'three') !== false || strpos($cycleCheck, 'quarter') !== false || strpos($cycleCheck, '90') !== false) {
                $durationDays = 90;
            } elseif (isset($input['duration_days']) && (int)$input['duration_days'] > 0) {
                $durationDays = (int)$input['duration_days'];
            }
            $expiresAt = date('Y-m-d H:i:s', strtotime("+$durationDays days"));

            // Look up user
            $uStmt = $this->db->prepare("SELECT id, role, chat_plan FROM users WHERE email = ? LIMIT 1");
            $uStmt->execute([$email]);
            $userRow = $uStmt->fetch();
            $userId = $userRow ? (int)$userRow['id'] : null;

            $stmt = $this->db->prepare("
                INSERT INTO user_plans 
                (user_id, user_email, plan_name, plan_type, item_title, price, billing_cycle, status, payment_reference, payment_method, payment_proof_url, features_json, start_date, expires_at, created_at) 
                VALUES (?, ?, ?, ?, ?, ?, 'Active', ?, ?, ?, ?, NOW(), ?, NOW())
            ");
            $stmt->execute([
                $userId,
                $email,
                $planName,
                $planType,
                $itemTitle,
                $price,
                $billingCycle,
                $paymentRef,
                $paymentMethod,
                $paymentProofUrl ?: null,
                $features,
                $expiresAt
            ]);
            $newId = (int)$this->db->lastInsertId();

            // Automatically upgrade user chat_plan and allowance, and promote role if artist plan
            if ($userRow) {
                $newChatPlan = $planName;
                $maxAllowance = 25;
                if (stripos($planName, 'VIP') !== false || stripos($planName, 'Unlimited') !== false) {
                    $maxAllowance = 9999;
                } elseif (stripos($planName, 'Pro') !== false || stripos($planName, 'Elite') !== false) {
                    $maxAllowance = 100;
                }

                $newRole = $userRow['role'] ?? 'user';
                if ($newRole === 'user' && (stripos($planName, 'Artist') !== false || stripos($planType, 'artist') !== false)) {
                    $newRole = 'artist';
                }

                $this->db->prepare("UPDATE users SET chat_plan = ?, chat_max_allowance = ?, role = ? WHERE email = ?")
                         ->execute([$newChatPlan, $maxAllowance, $newRole, $email]);
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
            ApiResponse::error('Failed to record plan purchase: ' . $t->getMessage(), 500);
        }
    }

    public function cancelPlan(array $input): void {
        try {
            $currentUser = AuthMiddleware::getCurrentUser();
            $planId = (int)($input['plan_id'] ?? $input['id'] ?? 0);
            $email = InputSanitizer::cleanEmail($input['email'] ?? $input['user_email'] ?? ($currentUser['email'] ?? ''));
            if ($planId <= 0 || empty($email)) {
                ApiResponse::error('Valid plan ID and email required', 400);
                return;
            }
            $stmt = $this->db->prepare("UPDATE user_plans SET status = 'Cancelled' WHERE id = ? AND (user_email = ? OR ? = 1)");
            $stmt->execute([$planId, $email, !empty($currentUser['is_admin']) ? 1 : 0]);
            ApiResponse::success(['id' => $planId, 'status' => 'Cancelled'], 'Plan cancelled successfully');
        } catch (\Throwable $t) {
            ApiResponse::error('Failed to cancel plan: ' . $t->getMessage(), 500);
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
                    'qr_code_url' => 'https://images.unsplash.com/photo-1595079672139-545c0ecac12a?auto=format&fit=crop&w=400&q=80',
                    'account_name' => 'Artist Dubai Cultural Services LLC',
                    'account_number' => 'AE28 0330 0000 0001 2345 678',
                    'bank_name' => 'Emirates NBD, Dubai',
                    'instructions' => 'Please scan the QR code with your banking app or transfer via IBAN. Once completed, enter the transaction reference and upload your receipt screenshot.',
                    'is_active' => 1,
                ];
            }
            ApiResponse::success($row, 'Payment settings retrieved successfully');
        } catch (\Throwable $t) {
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
            ApiResponse::error('Failed to update payment settings: ' . $t->getMessage(), 500);
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
                    ['key' => 'galleries_art_center', 'title' => 'GALLERIES ART CENTER', 'subtitle' => 'ART CENTER', 'route_name' => '/galleries', 'image_path' => 'assets/images/galleries-DjK8LuXg.jpg', 'is_enabled' => 1],
                    ['key' => 'events_photos', 'title' => 'EVENTS PHOTOS', 'subtitle' => 'PHOTOS', 'route_name' => '/events-photos', 'image_path' => 'assets/images/events-photos-CckY-T_x.jpg', 'is_enabled' => 1],
                    ['key' => 'gallery_registration', 'title' => 'GALLERIES | ART CENTERS REGISTRATION', 'subtitle' => 'REGISTRATION', 'route_name' => '/gallery-registration', 'image_path' => 'assets/images/gallery-registration-DU8u0zfk.jpg', 'is_enabled' => 1],
                    ['key' => 'login_portal', 'title' => 'LOGIN', 'subtitle' => 'PORTAL', 'route_name' => '/login', 'image_path' => 'assets/images/login-portal.png', 'is_enabled' => 1],
                    ['key' => 'ai_art', 'title' => 'AI', 'subtitle' => 'Art | Artist', 'route_name' => '/ai', 'image_path' => 'assets/images/ai-hub.png', 'is_enabled' => 1],
                ];
            }
            ApiResponse::success($rows, 'Menu permissions retrieved successfully');
        } catch (\Throwable $t) {
            ApiResponse::error('Failed to retrieve menu permissions: ' . $t->getMessage(), 500);
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
            ApiResponse::error('Failed to update menu permissions: ' . $t->getMessage(), 500);
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
            $userEmail = trim($_GET['user_email'] ?? $_GET['sender_email'] ?? $_GET['email'] ?? '');
            $recipientId = trim($_GET['recipient_id'] ?? $_GET['artist_id'] ?? '');

            // Ensure sender_avatar_url column exists in MySQL table
            try {
                $this->db->exec("ALTER TABLE artist_messages ADD COLUMN sender_avatar_url VARCHAR(500) NULL AFTER sender_email");
            } catch (\Throwable $t) {}

            $query = "SELECT * FROM artist_messages WHERE 1=1";
            $params = [];

            $userId = trim($_GET['user_id'] ?? '');

            if (!empty($userEmail) || !empty($recipientId) || !empty($userId)) {
                $targetIds = [];
                if (!empty($recipientId)) {
                    $targetIds[] = $recipientId;
                }
                if (!empty($userId)) {
                    $targetIds[] = $userId;
                    $targetIds[] = 'user_' . $userId;
                }
                if (!empty($userEmail)) {
                    $targetIds[] = $userEmail;
                    $targetIds[] = strtolower($userEmail);
                    // Look up any artist IDs registered with this email
                    try {
                        $aStmt = $this->db->prepare("SELECT id FROM artists WHERE LOWER(email) = LOWER(?)");
                        $aStmt->execute([$userEmail]);
                        $matchedIds = $aStmt->fetchAll(PDO::FETCH_COLUMN);
                        foreach ($matchedIds as $mId) {
                            $targetIds[] = (string)$mId;
                        }
                    } catch (\Throwable $e) {}

                    // Also look up user ID from users table
                    try {
                        $uStmt = $this->db->prepare("SELECT id FROM users WHERE LOWER(email) = LOWER(?)");
                        $uStmt->execute([$userEmail]);
                        $foundUId = $uStmt->fetchColumn();
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
                $targetIds = array_values(array_unique(array_filter($targetIds)));

                if (!empty($targetIds)) {
                    $inPlaceholders = implode(',', array_fill(0, count($targetIds), '?'));
                    $query .= " AND (LOWER(sender_email) = LOWER(?) OR sender_id IN ($inPlaceholders) OR recipient_id IN ($inPlaceholders) OR LOWER(recipient_id) = LOWER(?))";
                    $params[] = $userEmail;
                    foreach ($targetIds as $tid) {
                        $params[] = $tid;
                    }
                    foreach ($targetIds as $tid) {
                        $params[] = $tid;
                    }
                    $params[] = $userEmail;
                }
            }

            $query .= " ORDER BY id DESC LIMIT 100";
            $stmt = $this->db->prepare($query);
            $stmt->execute($params);
            $rows = $stmt->fetchAll();

            ApiResponse::success($rows, 'Messages retrieved successfully');
        } catch (\Throwable $t) {
            ApiResponse::error('Failed to retrieve messages: ' . $t->getMessage(), 500);
        }
    }

    public function getAllowance(): void {
        try {
            $userEmail = trim($_GET['user_email'] ?? $_GET['email'] ?? '');
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
                    if (!empty($userRow['chat_max_allowance'])) {
                        $maxAllowance = (int)$userRow['chat_max_allowance'];
                    }
                    if (!empty($userRow['chat_plan'])) {
                        $planName = $userRow['chat_plan'];
                    }
                }
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
            ApiResponse::error('Failed to get allowance: ' . $t->getMessage(), 500);
        }
    }

    public function updateAllowance(array $input): void {
        try {
            $userEmail = trim($input['user_email'] ?? $input['email'] ?? $_GET['user_email'] ?? '');
            $planName = trim($input['plan_name'] ?? 'Pro Artist');
            $maxAllowance = (int)($input['max_allowance'] ?? 50);

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
            ApiResponse::error('Failed to update chat plan: ' . $t->getMessage(), 500);
        }
    }

    public function sendMessage(array $input): void {
        try {
            $senderName = InputSanitizer::cleanString($input['sender_name'] ?? 'User');
            $senderEmail = InputSanitizer::cleanString($input['sender_email'] ?? 'user@artistdubai.com');
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
                $uStmt = $this->db->prepare("SELECT chat_max_allowance FROM users WHERE email = ? LIMIT 1");
                $uStmt->execute([$senderEmail]);
                $userRow = $uStmt->fetch();
                if ($userRow && !empty($userRow['chat_max_allowance'])) {
                    $maxAllowance = (int)$userRow['chat_max_allowance'];
                }
            }

            if ($maxAllowance < 9000 && $used >= $maxAllowance) {
                ApiResponse::error('Monthly message limit reached. Upgrade your plan for more.', 403);
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
                if (!empty($recipientId)) {
                    $rStmt = $this->db->prepare("SELECT email FROM artists WHERE id = ? LIMIT 1");
                    $rStmt->execute([(int)$recipientId]);
                    $rRow = $rStmt->fetch();
                    if ($rRow && !empty($rRow['email'])) {
                        $recipientEmail = $rRow['email'];
                    }
                }
                $notifTitle = "New Message from $senderName";
                $notifBody = mb_substr($message, 0, 80) . (mb_strlen($message) > 80 ? '...' : '');
                $this->db->prepare("INSERT INTO notifications (title, body, type, route, user_email, is_read) VALUES (?, ?, 'message', '/artist-chat', ?, 0)")
                         ->execute([$notifTitle, $notifBody, $recipientEmail]);
            } catch (\Throwable $notifErr) {}

            ApiResponse::success([
                'id' => $newId,
                'status' => 'sent',
                'used_messages' => $used + 1,
                'max_allowance' => $maxAllowance,
                'remaining_messages' => $remaining,
            ], 'Message sent successfully');
        } catch (\Throwable $t) {
            ApiResponse::error('Failed to send message: ' . $t->getMessage(), 500);
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
            ApiResponse::error('Failed to retrieve chat sessions: ' . $t->getMessage(), 500);
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
            ApiResponse::error('Failed to retrieve messages: ' . $t->getMessage(), 500);
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
            ApiResponse::error('Failed to send AI chat message: ' . $t->getMessage(), 500);
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
            ApiResponse::error('Failed to delete session: ' . $t->getMessage(), 500);
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

        // 2. Call Google Gemini API
        if (!empty($geminiKey)) {
            $geminiResult = $this->callGeminiApi($query, $geminiKey, $isArabic, $dbContext, $recentHistory);
            if (!empty($geminiResult) && !empty($geminiResult['reply'])) {
                return $geminiResult;
            }
        }

        // 3. If Gemini is unreachable or encounters a network issue, return an honest notice
        $unavailableMsg = $isArabic
            ? "عذراً، تعذر الاتصال بمحرك الذكاء الاصطناعي (Google Gemini) في الوقت الحالي. يرجى التحقق من اتصال الإنترنت أو المحاولة مجدداً بعد لحظات."
            : "We are currently unable to reach the Google Gemini AI service. Please verify your connection or try again in a moment.";

        return [
            'reply' => $unavailableMsg,
            'related_questions' => [],
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
            'gemini-3.5-flash',
            'gemini-3.5-flash-lite',
            'gemini-3.1-flash-lite',
            'gemini-3.8-flash',
            'gemini-3.7-flash',
            'gemini-3.6-flash',
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

        $systemInstruction = "You are the official, highly sophisticated, and welcoming AI Art Guide for 'Artist Dubai' (فنان دبي), the premier cultural and visual arts platform celebrating artists, prestigious galleries, cultural districts (Alserkal Avenue, Dubai Design District d3, Al Fahidi Historical Neighbourhood, Jameel Arts Centre), art fairs (Art Dubai, World Art Dubai), and exhibitions across Dubai and the UAE.\n" .
            "Core Persona & Guidelines:\n" .
            "1. Deliver accurate, inspiring, and concise insights in clean Markdown with clear headings and bullet points tailored for mobile screens.\n" .
            "2. When discussing artists, exhibitions, or booking, encourage users to explore profiles or events directly on the Artist Dubai app.\n" .
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
                curl_setopt($ch, CURLOPT_HTTPHEADER, ['Content-Type: application/json']);
                curl_setopt($ch, CURLOPT_TIMEOUT, 12);
                curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);
                $result = curl_exec($ch);
                $code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
                curl_close($ch);

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
            ApiResponse::error('Restore failed: ' . $e->getMessage(), 500);
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
                $stmtG = $this->db->prepare('SELECT image_url, cover_url, images_json FROM galleries WHERE id = ?');
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
            ApiResponse::error('Permanent delete failed: ' . $e->getMessage(), 500);
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
                    $rows = $this->db->query("SELECT id, image_url, cover_url, images_json FROM galleries WHERE deleted_at IS NOT NULL")->fetchAll();
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
// 5. Strictly Pure MySQL API Router Class
// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------
// Stripe Payment Gateway Controller
// -----------------------------------------------------------------------------
class StripeController {
    private string $secretKey;
    private string $publishableKey;

    public function __construct() {
        // Use environment variable if set, otherwise use test mode key
        $this->secretKey    = getenv('STRIPE_SECRET_KEY')    ?: 'sk_test_51UM5UtReplaceWithYourLiveSecretKey';
        $this->publishableKey = getenv('STRIPE_PUBLISHABLE_KEY') ?: 'pk_live_51UM5UtDBfdT00Nk0l3Jzf';
    }

    public function getPublishableKey(): void {
        ApiResponse::success(['publishable_key' => $this->publishableKey], 'Stripe config loaded.');
    }

    public function createPaymentIntent(array $data): void {
        $amountRaw   = $data['amount'] ?? 0;
        $currency    = strtolower(trim($data['currency'] ?? 'aed'));
        $description = InputSanitizer::cleanString($data['description'] ?? 'Artist Dubai Plan Payment');
        $itemType    = InputSanitizer::cleanString($data['item_type'] ?? 'event');
        $planId      = InputSanitizer::cleanString($data['plan_id'] ?? '');
        $planName    = InputSanitizer::cleanString($data['plan_name'] ?? '');

        // Amount comes as decimal AED (e.g. 2500.0), convert to fils (smallest currency unit)
        $amountFils = (int)round((float)$amountRaw * 100);

        if ($amountFils <= 0) {
            ApiResponse::error('Invalid payment amount.', 400);
            return;
        }

        $postData = http_build_query([
            'amount'                              => $amountFils,
            'currency'                            => $currency,
            'description'                         => $description,
            'metadata[item_type]'                 => $itemType,
            'metadata[plan_id]'                   => $planId,
            'metadata[plan_name]'                 => $planName,
            'metadata[platform]'                  => 'artist_dubai',
            'automatic_payment_methods[enabled]'  => 'true',
        ]);

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
}

class UnifiedMySqlApiRouter {
    public static function execute(): void {
        header('Access-Control-Allow-Origin: *');
        header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
        header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With');

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
                if ($catAction === 'delete' || $method === 'DELETE') {
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
                    $expCtrl->deleteExperienceLevel(array_merge($input, $_GET));
                } elseif ($expAction === 'update' || $method === 'PUT') {
                    $expCtrl->updateExperienceLevel(array_merge($input, $_GET));
                } elseif ($method === 'POST') {
                    $expCtrl->createExperienceLevel($input);
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
                if ($artistAction === 'delete') {
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
                if ($evAction === 'delete') {
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
                if ($galAction === 'delete') {
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
                if ($govAction === 'delete') {
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
                if ($artAction === 'delete') {
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
                $fav = new FavoriteController();
                if ($method === 'POST') $fav->toggleFavorite($input);
                else $fav->getFavorites($_GET);
                break;

            case 'notifications':
                $notifCtrl = new NotificationController();
                $notifAction = strtolower(trim($_GET['action'] ?? $input['action'] ?? ''));
                if ($notifAction === 'mark_read' || $notifAction === 'read') {
                    $notifCtrl->markAsRead(array_merge($input, $_GET));
                } elseif ($notifAction === 'mark_all_read' || $notifAction === 'all_read') {
                    $notifCtrl->markAllAsRead(array_merge($input, $_GET));
                } elseif ($notifAction === 'delete') {
                    $notifCtrl->deleteNotification(array_merge($input, $_GET));
                } elseif ($notifAction === 'clear_all' || $notifAction === 'clear' || $notifAction === 'delete_all') {
                    $notifCtrl->clearAllNotifications(array_merge($input, $_GET));
                } elseif ($method === 'POST') {
                    $notifCtrl->createNotification($input);
                } else {
                    $notifCtrl->getNotifications($_GET);
                }
                break;

            case 'about':
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
                if ($method === 'PUT' || ($method === 'POST' && ($action === 'update' || isset($input['id']) || isset($input['item_type'])))) {
                    $listingCtrl->updatePlan(array_merge($input, $_GET));
                } elseif ($method === 'POST') {
                    $listingCtrl->createPlan(array_merge($input, $_POST));
                } elseif ($method === 'DELETE' || $action === 'delete') {
                    $listingCtrl->deletePlan(array_merge($input, $_GET));
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
                if (!defined('CLI_TEST_MODE')) {
                    AuthMiddleware::requireAdmin();
                }
                try {
                    $db = DatabaseManager::getInstance()->getConnection();
                    $tables = [
                        'artists', 'events', 'galleries', 'artworks', 'bookings',
                        'categories', 'experience_levels', 'locations', 'government_entities',
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
                    ApiResponse::error('Clean DB error: ' . $e->getMessage(), 500);
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
                } elseif ($stripeAction === 'publishable_key' || $stripeAction === 'config') {
                    $stripeCtrl->getPublishableKey();
                } else {
                    ApiResponse::error('Invalid Stripe action.', 400);
                }
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
