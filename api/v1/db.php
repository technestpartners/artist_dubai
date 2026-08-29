<?php
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

$host = 'localhost';
$db   = 'artist_dubai';
$user = 'root';
$pass = '';

try {
    // Attempt MySQL connection
    $dsn = "mysql:host=$host;dbname=$db;charset=utf8mb4";
    $pdo = new PDO($dsn, $user, $pass, [
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
    ]);
} catch (\PDOException $e) {
    // Fallback to SQLite database if MySQL server is offline
    $sqliteFile = __DIR__ . '/artist_dubai.sqlite';
    $pdo = new PDO("sqlite:" . $sqliteFile);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    $pdo->setAttribute(PDO::ATTR_DEFAULT_FETCH_MODE, PDO::FETCH_ASSOC);

    // Auto-create tables for SQLite fallback
    $pdo->exec("
        CREATE TABLE IF NOT EXISTS users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            full_name TEXT NOT NULL,
            email TEXT NOT NULL UNIQUE,
            password_hash TEXT NOT NULL,
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP
        );

        CREATE TABLE IF NOT EXISTS artists (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER,
            name TEXT NOT NULL,
            category TEXT NOT NULL,
            location TEXT NOT NULL,
            bio TEXT,
            avatar_url TEXT,
            banner_url TEXT,
            followers_count INTEGER DEFAULT 0,
            works_count INTEGER DEFAULT 0,
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP
        );

        CREATE TABLE IF NOT EXISTS bookings (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            full_name TEXT NOT NULL,
            email TEXT NOT NULL,
            phone TEXT,
            artist_name TEXT,
            booking_type TEXT,
            budget_range TEXT,
            event_date TEXT,
            end_date TEXT,
            location TEXT,
            description TEXT,
            requirements TEXT,
            status TEXT DEFAULT 'Pending',
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP
        );

        CREATE TABLE IF NOT EXISTS events (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            description TEXT,
            category TEXT,
            event_date TEXT,
            end_date TEXT,
            location TEXT,
            venue TEXT,
            is_free INTEGER DEFAULT 1,
            organizer_name TEXT,
            contact_email TEXT,
            contact_phone TEXT,
            tags TEXT,
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP
        );

        CREATE TABLE IF NOT EXISTS categories (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL UNIQUE,
            description TEXT,
            emoji TEXT DEFAULT '🎨',
            color TEXT DEFAULT 'Primary',
            tags TEXT,
            is_featured INTEGER DEFAULT 0,
            artist_count INTEGER DEFAULT 0,
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP
        );

        CREATE TABLE IF NOT EXISTS artworks (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            artist_id INTEGER,
            artist_name TEXT,
            title TEXT NOT NULL,
            year TEXT DEFAULT '2024',
            medium TEXT DEFAULT 'Mixed Media',
            dimensions TEXT DEFAULT '120 x 80 cm',
            description TEXT,
            price TEXT DEFAULT 'USD 1800 - 2200',
            image_url TEXT,
            is_featured INTEGER DEFAULT 0,
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP
        );

        CREATE TABLE IF NOT EXISTS government_entities (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            default_is_open INTEGER DEFAULT 1,
            rating REAL DEFAULT 4.5,
            review_count INTEGER DEFAULT 0,
            category TEXT NOT NULL,
            location TEXT NOT NULL,
            default_timing TEXT NOT NULL,
            website_url TEXT NOT NULL,
            directions_url TEXT NOT NULL,
            google_maps_reviews_url TEXT,
            open_hour INTEGER,
            open_minute INTEGER DEFAULT 0,
            close_hour INTEGER,
            close_minute INTEGER DEFAULT 0,
            closed_days TEXT,
            seasonal_notice TEXT,
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP
        );
    ");

    // Seed initial demo data if empty
    $check = $pdo->query("SELECT COUNT(*) FROM artists")->fetchColumn();
    if ($check == 0) {
        $pdo->exec("
            INSERT INTO users (full_name, email, password_hash) 
            VALUES ('Allen Baiyee', 'allenbaiyee@me.com', '\$2y\$10\$e.1Wq2t.7/f5N6A8G7q.ue3H1F8/q5J9Y4V2S1Z8X7C6V5B4N3M2');

            INSERT INTO artists (name, category, location, bio, followers_count, works_count) 
            VALUES ('Frankie DeChiazza', 'Mixed Media', 'USA', 'TripTrap ... international alien... alien swag... pop star', 0, 0);

            INSERT INTO artists (name, category, location, bio, followers_count, works_count) 
            VALUES ('Alexander Mollov', 'Mixed Media', 'Dubai, UAE', 'Award-winning Music Video Director and multidisciplinary creative professional', 0, 1);
        ");
    }

    $catCheck = $pdo->query("SELECT COUNT(*) FROM categories")->fetchColumn();
    if ($catCheck == 0) {
        $pdo->exec("
            INSERT INTO categories (name, description, emoji, color, tags, is_featured, artist_count) VALUES
            ('Calligraphy & Typography', 'Traditional and contemporary Arabic calligraphy and typographic art.', '✍️', 'Primary', 'Calligraphy,Typography,Arabic Art,Traditional', 1, 1),
            ('Contemporary Painting', 'Modern oil, acrylic, and mixed media paintings on canvas.', '🎨', 'Pink', 'Contemporary,Abstract,Canvas', 1, 1),
            ('Digital Art & Sculpture', 'Digital illustrations, 3D artwork, and modern sculpting.', '🗿', 'Blue', 'Digital,Sculpture,3D,Modern', 0, 1),
            ('Photography', 'Fine art, landscape, portrait, and architectural photography.', '📷', 'Purple', 'Photography,Fine Art,Portrait', 1, 6),
            ('Abstract Painting', 'Expressive abstract works exploring color, form, and emotion.', '🎨', 'Orange', 'Abstract,Color,Emotion', 0, 1),
            ('Ceramics & Pottery', 'Handcrafted pottery, clay sculptures, and ceramic installations.', '🏺', 'Yellow', 'Ceramics,Pottery,Handcrafted', 0, 1);
        ");
    }

    $artCheck = $pdo->query("SELECT COUNT(*) FROM artworks")->fetchColumn();
    if ($artCheck == 0) {
        $pdo->exec("
            INSERT INTO artworks (artist_name, title, year, medium, dimensions, description, price, image_url, is_featured) VALUES
            ('Fatima Al Qasimi', 'Sacred Verses', '2024', 'Mixed Media on Paper', '70 x 50 cm', 'Original artwork combining traditional Arabic calligraphy with classical gold leaf & ink techniques.', 'USD 1800 - 2200', 'https://images.unsplash.com/photo-1579783902614-a3fb3927b675?q=80&w=1200&auto=format&fit=crop', 1),
            ('Fatima Al Qasimi', 'Arabic Calligraphy Composition #2', '2023', 'Acrylic on Canvas', '90 x 60 cm', 'A beautiful piece showcasing calligraphy & typography techniques.', '$2,000', 'https://images.unsplash.com/photo-1541701494587-cb58502866ab?q=80&w=1200&auto=format&fit=crop', 1);
        ");
    }

    $govCheck = $pdo->query("SELECT COUNT(*) FROM government_entities")->fetchColumn();
    if ($govCheck == 0) {
        $pdo->exec("
            INSERT INTO government_entities 
            (name, default_is_open, rating, review_count, category, location, default_timing, website_url, directions_url, google_maps_reviews_url, open_hour, open_minute, close_hour, close_minute, closed_days, seasonal_notice) 
            VALUES
            ('Dubai Culture & Arts Authority', 1, 4.5, 120, 'Government · Cultural Authority', 'Al Shindagha, Dubai', 'Open · Closes at 15:00', 'https://www.dubaiculture.gov.ae/', 'https://maps.google.com/?q=Dubai+Culture+and+Arts+Authority+Al+Shindagha', 'https://maps.google.com/?q=Dubai+Culture+and+Arts+Authority+Al+Shindagha', 7, 30, 15, 0, '6,7', NULL),
            ('Ministry of Culture & Youth', 1, 4.2, 98, 'Government · Federal Ministry', 'Abu Dhabi, UAE', 'Open · Closes at 14:30', 'https://www.moccae.gov.ae/', 'https://maps.google.com/?q=Ministry+of+Climate+Change+and+Environment+Abu+Dhabi', 'https://maps.google.com/?q=Ministry+of+Climate+Change+and+Environment+Abu+Dhabi', 7, 30, 14, 30, '6,7', NULL),
            ('Dubai Design District (d3)', 1, 4.7, 215, 'Creative Hub · Design District', 'Dubai Design District, Dubai', 'Open · Closes at 22:00', 'https://dubaidesigndistrict.com/', 'https://maps.google.com/?q=Dubai+Design+District', 'https://maps.google.com/?q=Dubai+Design+District', 8, 0, 22, 0, NULL, NULL),
            ('Art Dubai', 0, 4.6, 180, 'Art Fair · Cultural Event', 'Madinat Jumeirah, Dubai', 'Closed · Opens Mar 2026', 'https://www.artdubai.ae/', 'https://maps.google.com/?q=Madinat+Jumeirah+Dubai', 'https://maps.google.com/?q=Madinat+Jumeirah+Dubai', NULL, 0, NULL, 0, NULL, 'Closed · Opens Mar 2026'),
            ('Alserkal Avenue', 1, 4.8, 310, 'Arts District · Gallery Hub', 'Al Quoz, Dubai', 'Open · Closes at 20:00', 'https://alserkal.online/', 'https://maps.google.com/?q=Alserkal+Avenue+Al+Quoz', 'https://maps.google.com/?q=Alserkal+Avenue+Al+Quoz', 10, 0, 20, 0, NULL, NULL),
            ('Dubai Opera', 1, 4.9, 450, 'Performing Arts · Venue', 'Downtown Dubai', 'Open · Next show at 19:30', 'https://www.dubaiopera.com/en', 'https://maps.google.com/?q=Dubai+Opera+Downtown', 'https://maps.google.com/?q=Dubai+Opera+Downtown', 10, 0, 23, 0, NULL, NULL);
        ");
    }
}
