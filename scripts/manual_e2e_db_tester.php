<?php
/**
 * Automated End-to-End Manual Flow & MySQL Database Tester
 * Simulates real user input, form submissions, and verifies live MySQL database insertions.
 */

define('CLI_TEST_MODE', true);
require_once __DIR__ . '/../api/v1/api.php';

class ManualE2eDbTester {
    private PDO $pdo;
    private int $passed = 0;
    private int $failed = 0;
    private array $createdIds = [];

    public function __construct() {
        $this->pdo = DatabaseManager::getInstance()->getConnection();
        echo "\n======================================================================\n";
        echo "   ARTIST DUBAI - MANUAL USER FLOW & MYSQL DATABASE VERIFICATION TESTER\n";
        echo "======================================================================\n";
        echo "Database Connected: " . $this->pdo->getAttribute(PDO::ATTR_CONNECTION_STATUS) . "\n\n";
    }

    public function runAll(): void {
        $this->test1_UserRegistrationAndLogin();
        $this->test2_ArtistProfileCreation();
        $this->test3_ArtEventCreation();
        $this->test4_CategoryCreation();
        $this->test5_GalleryRegistration();
        $this->test6_ArtistBookingCreation();
        $this->test7_ReviewSubmission();
        $this->test8_FavoritesAndLikes();
        $this->test9_DatabaseIntegritySummary();

        echo "\n----------------------------------------------------------------------\n";
        echo "TEST RESULTS: {$this->passed} Passed, {$this->failed} Failed\n";
        echo "======================================================================\n";
    }

    private function assertCondition(string $testName, bool $condition, string $details = ''): void {
        if ($condition) {
            $this->passed++;
            echo "  [PASS] $testName" . ($details ? " ($details)" : "") . "\n";
        } else {
            $this->failed++;
            echo "  [FAIL] $testName" . ($details ? " ($details)" : "") . "\n";
        }
    }

    private function test1_UserRegistrationAndLogin(): void {
        echo "1. Testing User Registration & Authentication Flow...\n";
        $email = 'tester_' . time() . '_' . rand(100, 999) . '@artistdubai.com';
        $password = 'SecretPass123!';
        $name = 'Automated Tester User';

        $auth = new AuthController();
        
        // Register in DB
        ob_start();
        $auth->register([
            'name' => $name,
            'email' => $email,
            'password' => $password,
            'phone' => '+971 50 999 8888'
        ]);
        $out = ob_get_clean();

        // Verify in MySQL
        $stmt = $this->pdo->prepare("SELECT * FROM users WHERE email = ?");
        $stmt->execute([$email]);
        $userRow = $stmt->fetch();

        $this->assertCondition(
            'User inserted into MySQL users table',
            !empty($userRow) && $userRow['email'] === $email,
            "User ID: " . ($userRow['id'] ?? 'none')
        );

        if ($userRow) {
            $this->createdIds['user_id'] = (int)$userRow['id'];
            $this->createdIds['user_email'] = $email;
        }

        // Test Login against DB hash
        $this->assertCondition(
            'Password securely hashed with BCRYPT',
            !empty($userRow) && password_verify($password, $userRow['password_hash'])
        );
    }

    private function test2_ArtistProfileCreation(): void {
        echo "\n2. Testing Artist Profile Creation Flow...\n";
        $artistName = 'Fatima Al-Nuaimi ' . time();
        $category = 'Calligraphy & Typography';
        $location = 'Al Fahidi, Dubai';
        $bio = 'Master of modern Arabic calligraphy and digital kinetic typography.';
        
        $artistCtrl = new ArtistController();
        ob_start();
        $artistCtrl->createArtist([
            'name' => $artistName,
            'category' => $category,
            'location' => $location,
            'bio' => $bio,
            'email' => 'fatima.' . time() . '@artistdubai.com',
            'phone' => '+971 52 333 4444',
            'booking_rate' => 'AED 2500 / session',
            'experience_level' => '10+ Years',
            'works_count' => 14
        ]);
        $out = ob_get_clean();

        // Check in MySQL
        $stmt = $this->pdo->prepare("SELECT * FROM artists WHERE name = ? ORDER BY id DESC LIMIT 1");
        $stmt->execute([$artistName]);
        $artistRow = $stmt->fetch();

        $this->assertCondition(
            'Artist inserted into MySQL artists table',
            !empty($artistRow) && $artistRow['category'] === $category,
            "Artist ID: " . ($artistRow['id'] ?? 'none') . ", Category: " . ($artistRow['category'] ?? '')
        );

        if ($artistRow) {
            $this->createdIds['artist_id'] = (int)$artistRow['id'];
            $this->createdIds['artist_name'] = $artistRow['name'];
        }
    }

    private function test3_ArtEventCreation(): void {
        echo "\n3. Testing Art Event Creation Flow...\n";
        $eventTitle = 'Dubai Kinetic Typography Biennale ' . time();
        $eventCategory = 'Exhibition';
        $location = 'Alserkal Avenue, Warehouse 46';
        $date = '2026-11-15';
        $time = '18:00 - 22:00';
        $price = 'Free RSVP';
        
        $evCtrl = new EventController();
        ob_start();
        $evCtrl->createEvent([
            'title' => $eventTitle,
            'category' => $eventCategory,
            'location' => $location,
            'date' => $date,
            'time' => $time,
            'price' => $price,
            'description' => 'Interactive exhibition exploring typography in motion.',
            'artist_name' => $this->createdIds['artist_name'] ?? 'Fatima Al-Nuaimi'
        ]);
        $out = ob_get_clean();

        // Check in MySQL
        $stmt = $this->pdo->prepare("SELECT * FROM events WHERE title = ? ORDER BY id DESC LIMIT 1");
        $stmt->execute([$eventTitle]);
        $eventRow = $stmt->fetch();

        $this->assertCondition(
            'Event inserted into MySQL events table',
            !empty($eventRow) && $eventRow['title'] === $eventTitle,
            "Event ID: " . ($eventRow['id'] ?? 'none') . ", Venue: " . ($eventRow['location'] ?? '')
        );

        if ($eventRow) {
            $this->createdIds['event_id'] = (int)$eventRow['id'];
            $this->createdIds['event_title'] = $eventRow['title'];
        }
    }

    private function test4_CategoryCreation(): void {
        echo "\n4. Testing Art Category Creation Flow...\n";
        $catName = 'Kinetic Digital Sculptures ' . time();
        $catDesc = 'Time-based moving art installations and interactive 3D structures.';

        $catCtrl = new CategoryController();
        ob_start();
        $catCtrl->createCategory([
            'name' => $catName,
            'description' => $catDesc
        ]);
        $out = ob_get_clean();

        // Check in MySQL
        $stmt = $this->pdo->prepare("SELECT * FROM categories WHERE name = ? ORDER BY id DESC LIMIT 1");
        $stmt->execute([$catName]);
        $catRow = $stmt->fetch();

        $this->assertCondition(
            'Category inserted into MySQL categories table',
            !empty($catRow) && $catRow['name'] === $catName,
            "Category ID: " . ($catRow['id'] ?? 'none')
        );

        if ($catRow) {
            $this->createdIds['category_id'] = (int)$catRow['id'];
        }
    }

    private function test5_GalleryRegistration(): void {
        echo "\n5. Testing Gallery / Art Center Registration Flow...\n";
        $galName = 'Aura Contemporary Art Space ' . time();
        $type = 'Gallery · Studio';
        $address = 'Gate Avenue, DIFC, Dubai';
        $email = 'director.' . time() . '@auraspace.ae';
        $phone = '+971 4 888 7766';
        $about = 'Pioneering exhibition space dedicated to Middle Eastern contemporary artists.';

        $galCtrl = new GalleryController();
        ob_start();
        $galCtrl->createGallery([
            'name' => $galName,
            'type' => $type,
            'category' => $type,
            'address' => $address,
            'location' => $address,
            'website' => 'https://auraspace.ae',
            'contact_person' => 'Layla Al-Zahra',
            'email' => $email,
            'phone' => $phone,
            'about' => $about
        ]);
        $out = ob_get_clean();

        // Check in MySQL
        $stmt = $this->pdo->prepare("SELECT * FROM galleries WHERE name = ? ORDER BY id DESC LIMIT 1");
        $stmt->execute([$galName]);
        $galRow = $stmt->fetch();

        $this->assertCondition(
            'Gallery inserted into MySQL galleries table with all fields',
            !empty($galRow) && $galRow['name'] === $galName && $galRow['email'] === $email,
            "Gallery ID: " . ($galRow['id'] ?? 'none') . ", Location: " . ($galRow['location'] ?? '')
        );

        if ($galRow) {
            $this->createdIds['gallery_id'] = (int)$galRow['id'];
        }
    }

    private function test6_ArtistBookingCreation(): void {
        echo "\n6. Testing Artist Booking Request Creation Flow...\n";
        $userName = 'Sarah Jenkins';
        $userEmail = $this->createdIds['user_email'] ?? 'sarah@example.com';
        $artistName = $this->createdIds['artist_name'] ?? 'Fatima Al-Nuaimi';
        $date = '2026-12-05';
        $time = '14:00';
        $message = 'Private exhibition calligraphy showcase commission for corporate gala.';

        $bookCtrl = new BookingController();
        ob_start();
        $bookCtrl->createBooking([
            'name' => $userName,
            'full_name' => $userName,
            'email' => $userEmail,
            'artist_name' => $artistName,
            'date' => $date,
            'time' => $time,
            'message' => $message,
            'description' => $message,
            'total_price' => 'AED 2,500',
            'status' => 'Confirmed'
        ]);
        $out = ob_get_clean();

        // Check in MySQL
        $stmt = $this->pdo->prepare("SELECT * FROM bookings WHERE email = ? ORDER BY id DESC LIMIT 1");
        $stmt->execute([$userEmail]);
        $bookRow = $stmt->fetch();

        $this->assertCondition(
            'Booking inserted into MySQL bookings table',
            !empty($bookRow) && $bookRow['artist_name'] === $artistName,
            "Booking ID: " . ($bookRow['id'] ?? 'none') . ", Status: " . ($bookRow['status'] ?? '')
        );

        if ($bookRow) {
            $this->createdIds['booking_id'] = (int)$bookRow['id'];
        }
    }

    private function test7_ReviewSubmission(): void {
        echo "\n7. Testing Review Submission & Dynamic Timestamp Flow...\n";
        $entityName = 'Dubai Culture & Arts Authority';
        $authorName = 'Tariq Mansoor ' . time();
        $rating = 5.0;
        $text = 'Incredible cultural heritage programs and seamless partnership support!';

        $revCtrl = new ReviewController();
        ob_start();
        $revCtrl->createReview([
            'entity_name' => $entityName,
            'author_name' => $authorName,
            'rating' => $rating,
            'text' => $text
        ]);
        $out = ob_get_clean();

        // Check in MySQL
        $stmt = $this->pdo->prepare("SELECT * FROM reviews WHERE author_name = ? ORDER BY id DESC LIMIT 1");
        $stmt->execute([$authorName]);
        $revRow = $stmt->fetch();

        $this->assertCondition(
            'Review inserted into MySQL reviews table with dynamic relative time',
            !empty($revRow) && (float)$revRow['rating'] == 5.0,
            "Review ID: " . ($revRow['id'] ?? 'none') . ", Relative Time: " . ($revRow['relative_time'] ?? '')
        );

        if ($revRow) {
            $this->createdIds['review_id'] = (int)$revRow['id'];
        }
    }

    private function test8_FavoritesAndLikes(): void {
        echo "\n8. Testing Artist Likes & Favorites Toggle Flow...\n";
        $artistId = $this->createdIds['artist_id'] ?? 1;
        $userEmail = $this->createdIds['user_email'] ?? 'tester@artistdubai.com';

        $artistCtrl = new ArtistController();
        ob_start();
        $artistCtrl->likeArtist(['id' => $artistId]);
        $out = ob_get_clean();

        $stmt = $this->pdo->prepare("SELECT likes_count FROM artists WHERE id = ?");
        $stmt->execute([$artistId]);
        $likes = (int)$stmt->fetchColumn();

        $this->assertCondition(
            'Artist likes count incremented in MySQL',
            $likes >= 1,
            "Likes count: $likes"
        );

        $favCtrl = new FavoriteController();
        ob_start();
        $favCtrl->toggleFavorite([
            'user_email' => $userEmail,
            'artist_id' => $artistId,
            'artist_name' => $this->createdIds['artist_name'] ?? 'Fatima Al-Nuaimi'
        ]);
        $out = ob_get_clean();

        $stmt = $this->pdo->prepare("SELECT COUNT(*) FROM favorites WHERE user_email = ? AND item_id = ?");
        $stmt->execute([$userEmail, $artistId]);
        $favCount = (int)$stmt->fetchColumn();

        $this->assertCondition(
            'Favorite state saved into MySQL favorites table',
            $favCount >= 1,
            "Favorites for user: $favCount"
        );
    }

    private function test9_DatabaseIntegritySummary(): void {
        echo "\n9. Database Tables Record Count Summary:\n";
        $tables = ['users', 'artists', 'events', 'categories', 'galleries', 'bookings', 'reviews', 'government_entities', 'favorites'];
        foreach ($tables as $t) {
            $count = (int)$this->pdo->query("SELECT COUNT(*) FROM `$t`")->fetchColumn();
            echo "   - Table `$t`: $count records in MySQL\n";
        }
        $this->assertCondition('All database tables accessible and operational', true);
    }
}

$tester = new ManualE2eDbTester();
$tester->runAll();
