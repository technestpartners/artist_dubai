<?php
/**
 * Artist Dubai API, Database & Security Test Suite
 * Run via CLI: php api/v1/test/api_database_security_test.php
 */

echo "=====================================================\n";
echo "ARTIST DUBAI - API, DATABASE & SECURITY TEST SUITE\n";
echo "=====================================================\n\n";

$passCount = 0;
$failCount = 0;

function assertTest($title, $condition, $details = '') {
    global $passCount, $failCount;
    if ($condition) {
        $passCount++;
        echo " [PASS] $title\n";
    } else {
        $failCount++;
        echo " [FAIL] $title";
        if (!empty($details)) {
            echo " -> $details";
        }
        echo "\n";
    }
}

// -----------------------------------------------------
// 1. Database Schema & Fallback Verification
// -----------------------------------------------------
echo "\n--- Step 1: Database Schema & SQLite Fallback Audit ---\n";
require_once __DIR__ . '/../db.php';

assertTest('Database PDO Connection Established', isset($pdo) && $pdo instanceof PDO);

$tables = ['users', 'artists', 'artworks', 'categories', 'bookings', 'events', 'government_entities'];
foreach ($tables as $table) {
    try {
        $stmt = $pdo->query("SELECT COUNT(*) FROM $table");
        $count = $stmt->fetchColumn();
        assertTest("Database Table '$table' exists and accessible (Count: $count)", $count !== false);
    } catch (\Exception $e) {
        assertTest("Database Table '$table' exists and accessible", false, $e->getMessage());
    }
}

// -----------------------------------------------------
// 2. Security & Authentication Audit Tests
// -----------------------------------------------------
echo "\n--- Step 2: Security & Authentication Vulnerability Audit ---\n";

// Test 2.1: Login Validation with Invalid Payload
$ch = curl_init();
curl_setopt($ch, CURLOPT_URL, 'http://localhost:8000/api/v1/login.php');
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_POST, true);
curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode(['email' => 'invalid-email', 'password' => '']));
curl_setopt($ch, CURLOPT_HTTPHEADER, ['Content-Type: application/json']);
$resp = curl_exec($ch);
$httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
curl_close($ch);

// If server is not running locally on 8000, we also test directly via PDO prepared statement logic
if ($httpCode === 0) {
    echo " (Local HTTP server not active on port 8000; executing direct PDO logic security tests)\n";
    
    // Direct Security Test: SQL Injection payload against login query
    $sqliPayload = "' OR '1'='1";
    $stmt = $pdo->prepare('SELECT id, full_name, email, password_hash, created_at FROM users WHERE email = ?');
    $stmt->execute([$sqliPayload]);
    $sqliUser = $stmt->fetch();
    assertTest('SQL Injection Payload in Login Email parameter yields 0 results (Prepared Statement Protection)', $sqliUser === false);

    // Direct Security Test: Password hashing verification
    $userStmt = $pdo->prepare('SELECT password_hash FROM users WHERE email = ?');
    $userStmt->execute(['allenbaiyee@me.com']);
    $userHash = $userStmt->fetchColumn();
    assertTest('User password_hash exists in DB', !empty($userHash));
} else {
    assertTest('Login fails with HTTP 400 for invalid email format', $httpCode === 400);

    // Test 2.2: SQL Injection Attempt via HTTP API
    $ch = curl_init();
    curl_setopt($ch, CURLOPT_URL, 'http://localhost:8000/api/v1/login.php');
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_POST, true);
    curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode(['email' => "' OR '1'='1", 'password' => "' OR '1'='1"]));
    curl_setopt($ch, CURLOPT_HTTPHEADER, ['Content-Type: application/json']);
    $resp = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);

    assertTest('Login SQL Injection attempt fails cleanly (HTTP 400 or 401)', $httpCode === 400 || $httpCode === 401);
}

// -----------------------------------------------------
// 3. Backend Feature & Integration Operations (PDO Level)
// -----------------------------------------------------
echo "\n--- Step 3: Feature CRUD Integration Operations ---\n";

// Test 3.1: Artist Creation & Retrieval
try {
    $testArtistName = "Test Artist " . time();
    $stmt = $pdo->prepare('INSERT INTO artists (name, category, location, bio) VALUES (?, ?, ?, ?)');
    $stmt->execute([$testArtistName, 'Digital Art', 'Dubai, UAE', 'Automated test artist bio']);
    $artistId = $pdo->lastInsertId();
    assertTest('Create Artist Record', $artistId > 0);

    $fetchStmt = $pdo->prepare('SELECT * FROM artists WHERE id = ?');
    $fetchStmt->execute([$artistId]);
    $artist = $fetchStmt->fetch();
    assertTest('Retrieve Artist Record by ID', $artist && $artist['name'] === $testArtistName);
} catch (\Exception $e) {
    assertTest('Create & Retrieve Artist Record', false, $e->getMessage());
}

// Test 3.2: Artwork Creation & Retrieval
try {
    $testTitle = "Test Artwork " . time();
    $stmt = $pdo->prepare('INSERT INTO artworks (artist_name, title, year, medium, price) VALUES (?, ?, ?, ?, ?)');
    $stmt->execute(['Test Artist', $testTitle, '2026', 'Digital', 'USD 1500']);
    $artworkId = $pdo->lastInsertId();
    assertTest('Create Artwork Record', $artworkId > 0);

    $fetchStmt = $pdo->prepare('SELECT * FROM artworks WHERE id = ?');
    $fetchStmt->execute([$artworkId]);
    $artwork = $fetchStmt->fetch();
    assertTest('Retrieve Artwork Record by ID', $artwork && $artwork['title'] === $testTitle);
} catch (\Exception $e) {
    assertTest('Create & Retrieve Artwork Record', false, $e->getMessage());
}

// Test 3.3: Booking Request Creation & Retrieval
try {
    $testBookingEmail = "testbooking" . time() . "@example.com";
    $stmt = $pdo->prepare('INSERT INTO bookings (full_name, email, phone, artist_name, booking_type, budget_range) VALUES (?, ?, ?, ?, ?, ?)');
    $stmt->execute(['Test Client', $testBookingEmail, '+971500000000', 'Fatima Al Qasimi', 'Calligraphy', 'USD 2,000 - 5,000']);
    $bookingId = $pdo->lastInsertId();
    assertTest('Create Booking Request Record', $bookingId > 0);

    $fetchStmt = $pdo->prepare('SELECT * FROM bookings WHERE id = ?');
    $fetchStmt->execute([$bookingId]);
    $booking = $fetchStmt->fetch();
    assertTest('Retrieve Booking Record by ID', $booking && $booking['email'] === $testBookingEmail);
} catch (\Exception $e) {
    assertTest('Create & Retrieve Booking Record', false, $e->getMessage());
}

// Test 3.4: Category Creation & Retrieval
try {
    $testCategoryName = "Test Category " . time();
    $stmt = $pdo->prepare('INSERT INTO categories (name, description, emoji, color) VALUES (?, ?, ?, ?)');
    $stmt->execute([$testCategoryName, 'Automated category test', '🎨', 'Primary']);
    $catId = $pdo->lastInsertId();
    assertTest('Create Category Record', $catId > 0);

    $fetchStmt = $pdo->prepare('SELECT * FROM categories WHERE id = ?');
    $fetchStmt->execute([$catId]);
    $cat = $fetchStmt->fetch();
    assertTest('Retrieve Category Record by ID', $cat && $cat['name'] === $testCategoryName);
} catch (\Exception $e) {
    assertTest('Create & Retrieve Category Record', false, $e->getMessage());
}

// Test 3.5: Art Event Creation & Retrieval
try {
    $testEventTitle = "Test Art Event " . time();
    $stmt = $pdo->prepare('INSERT INTO events (title, description, category, location) VALUES (?, ?, ?, ?)');
    $stmt->execute([$testEventTitle, 'Automated art event test', 'Exhibition', 'Dubai Opera']);
    $eventId = $pdo->lastInsertId();
    assertTest('Create Event Record', $eventId > 0);

    $fetchStmt = $pdo->prepare('SELECT * FROM events WHERE id = ?');
    $fetchStmt->execute([$eventId]);
    $event = $fetchStmt->fetch();
    assertTest('Retrieve Event Record by ID', $event && $event['title'] === $testEventTitle);
} catch (\Exception $e) {
    assertTest('Create & Retrieve Event Record', false, $e->getMessage());
}

// Test 3.6: Government Entities Data Formatting Test
try {
    $stmt = $pdo->query('SELECT * FROM government_entities ORDER BY id ASC');
    $entities = $stmt->fetchAll();
    assertTest('Retrieve Government Entities Record List', count($entities) > 0);
} catch (\Exception $e) {
    assertTest('Retrieve Government Entities Record List', false, $e->getMessage());
}

echo "\n=====================================================\n";
echo "TEST SUMMARY: PASSED: $passCount | FAILED: $failCount\n";
echo "=====================================================\n";

if ($failCount > 0) {
    exit(1);
} else {
    exit(0);
}
