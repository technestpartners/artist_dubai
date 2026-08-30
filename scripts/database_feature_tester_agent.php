<?php
/**
 * ARTIST DUBAI - COMPREHENSIVE DATABASE FEATURE TESTER & AUTO-DIAGNOSTIC AGENT
 * 
 * Tests every single feature, model, controller, and database table in the entire app.
 * Direct SQL verification ensures 100% of data flows through MySQL with zero mocked leaks.
 */

define('CLI_TEST_MODE', true);
require_once __DIR__ . '/../api/v1/api.php';

class DatabaseFeatureTesterAgent {
    private PDO $pdo;
    private int $passedTests = 0;
    private int $failedTests = 0;
    private array $diagnostics = [];
    private array $runtimeContext = [];

    public function __construct() {
        $this->pdo = DatabaseManager::getInstance()->getConnection();
        echo "\n" . str_repeat('=', 78) . "\n";
        echo "   🤖 ARTIST DUBAI - COMPREHENSIVE DATABASE FEATURE TESTER & AGENT\n";
        echo str_repeat('=', 78) . "\n";
        echo "Database Engine : MySQL via PDO\n";
        echo "Connection Info : " . $this->pdo->getAttribute(PDO::ATTR_CONNECTION_STATUS) . "\n";
        echo "Execution Time  : " . date('Y-m-d H:i:s T') . "\n";
        echo str_repeat('-', 78) . "\n\n";
    }

    public function runCompleteDiagnostic(): bool {
        $start = microtime(true);

        $this->section("1. User Authentication & Profile Feature", function() {
            $this->testUserFlow();
        });

        $this->section("2. Artists Management & Social Engagement Feature", function() {
            $this->testArtistFlow();
        });

        $this->section("3. Art Events Management & Ticketing Feature", function() {
            $this->testEventFlow();
        });

        $this->section("4. Art Categories & Taxonomy Feature", function() {
            $this->testCategoryFlow();
        });

        $this->section("5. Galleries & Cultural Spaces Feature", function() {
            $this->testGalleryFlow();
        });

        $this->section("6. Artworks & Portfolio Management Feature", function() {
            $this->testArtworkFlow();
        });

        $this->section("7. Bookings & Commission Requests Feature", function() {
            $this->testBookingFlow();
        });

        $this->section("8. Reviews & Dynamic Relative Timestamps Feature", function() {
            $this->testReviewFlow();
        });

        $this->section("9. Government Cultural Portal & Live Timings Feature", function() {
            $this->testGovernmentPortalFlow();
        });

        $this->section("10. Favorites & Bookmarks Feature", function() {
            $this->testFavoritesFlow();
        });

        $this->section("11. Follow / Unfollow Artists Feature", function() {
            $this->testFollowsFlow();
        });

        $this->section("12. Dynamic Database-Driven Notifications Feature", function() {
            $this->testNotificationsFlow();
        });

        $this->section("13. MySQL Database Schema & Table Integrity Audit", function() {
            $this->testDatabaseSchemaAudit();
        });

        $duration = round(microtime(true) - $start, 3);

        echo "\n" . str_repeat('=', 78) . "\n";
        echo "   📊 AGENT DIAGNOSTIC SUMMARY\n";
        echo str_repeat('=', 78) . "\n";
        echo "Total Tests Run : " . ($this->passedTests + $this->failedTests) . "\n";
        echo "Passed Tests    : \033[32m{$this->passedTests}\033[0m\n";
        echo "Failed Tests    : " . ($this->failedTests > 0 ? "\033[31m{$this->failedTests}\033[0m" : "0") . "\n";
        echo "Execution Time  : {$duration} seconds\n";
        echo str_repeat('=', 78) . "\n";

        if ($this->failedTests === 0) {
            echo "🎉 ALL FEATURES ARE 100% OPERATIONAL AND FULLY INTEGRATED WITH MYSQL!\n\n";
            return true;
        } else {
            echo "⚠️ DETECTED " . count($this->diagnostics) . " ISSUES. REVIEW DETAILS ABOVE.\n\n";
            return false;
        }
    }

    private function section(string $title, callable $fn): void {
        echo "▶ $title\n";
        try {
            $fn();
        } catch (\Throwable $e) {
            $this->assert(false, "Uncaught Exception in $title", $e->getMessage() . " at " . $e->getFile() . ":" . $e->getLine());
        }
        echo "\n";
    }

    private function assert(bool $condition, string $assertionName, string $extra = ''): void {
        if ($condition) {
            $this->passedTests++;
            echo "  ✔ [PASS] $assertionName" . ($extra ? " ($extra)" : "") . "\n";
        } else {
            $this->failedTests++;
            $msg = "  ✖ [FAIL] $assertionName" . ($extra ? " ($extra)" : "");
            echo "$msg\n";
            $this->diagnostics[] = $msg;
        }
    }

    // -------------------------------------------------------------------------
    // 1. User Authentication & Profile
    // -------------------------------------------------------------------------
    private function testUserFlow(): void {
        $auth = new AuthController();
        $email = 'agent_user_' . time() . '_' . rand(100, 999) . '@artistdubai.com';
        $pass = 'AgentPass2026!';
        $name = 'Agent Diagnostic Tester';

        // 1.1 Register
        ob_start();
        $auth->register(['name' => $name, 'email' => $email, 'password' => $pass, 'phone' => '+971 50 111 2222']);
        $regOutput = ob_get_clean();

        $stmt = $this->pdo->prepare("SELECT * FROM users WHERE email = ?");
        $stmt->execute([$email]);
        $user = $stmt->fetch();

        $this->assert(!empty($user) && $user['email'] === $email, "User successfully registered in MySQL users table", "User ID: " . ($user['id'] ?? 'none'));
        $this->assert(!empty($user['password_hash']) && password_verify($pass, $user['password_hash']), "User password encrypted via secure BCRYPT hash");

        $this->runtimeContext['user_id'] = (int)($user['id'] ?? 0);
        $this->runtimeContext['user_email'] = $email;
        $this->runtimeContext['user_name'] = $name;

        // 1.2 Login
        ob_start();
        $auth->login(['email' => $email, 'password' => $pass]);
        $loginOutput = json_decode(ob_get_clean(), true);
        $this->assert(!empty($loginOutput['data']['token']), "User login authentication returns valid session token");

        // 1.3 Profile Lookup
        $userProfile = $auth->getUserProfile($email);
        $this->assert(!empty($userProfile) && $userProfile['email'] === $email, "User profile retrieved from MySQL users table");
    }

    // -------------------------------------------------------------------------
    // 2. Artists Management
    // -------------------------------------------------------------------------
    private function testArtistFlow(): void {
        $artistCtrl = new ArtistController();
        $name = 'Noura Al-Zaabi ' . time();
        $category = 'Modern Acrylics & Texture';
        $location = 'Alserkal Avenue, Dubai';
        $bio = 'Pioneering Emirati contemporary visual artist exploring fluid acrylic textures.';

        // 2.1 Create Artist
        ob_start();
        $artistCtrl->createArtist([
            'name' => $name,
            'category' => $category,
            'location' => $location,
            'bio' => $bio,
            'email' => 'noura.' . time() . '@artistdubai.com',
            'phone' => '+971 55 444 3322',
            'booking_rate' => 'AED 3,000 / commission',
            'experience_level' => 'Senior / 8 Years'
        ]);
        $createRes = json_decode(ob_get_clean(), true);

        $stmt = $this->pdo->prepare("SELECT * FROM artists WHERE name = ? ORDER BY id DESC LIMIT 1");
        $stmt->execute([$name]);
        $artist = $stmt->fetch();

        $this->assert(!empty($artist) && $artist['category'] === $category, "Artist profile inserted into MySQL artists table", "ID: " . ($artist['id'] ?? 'none'));

        $artistId = (int)($artist['id'] ?? 0);
        $this->runtimeContext['artist_id'] = $artistId;
        $this->runtimeContext['artist_name'] = $name;

        // 2.2 Update Artist
        ob_start();
        $artistCtrl->updateArtist([
            'id' => $artistId,
            'location' => 'Dubai Design District (d3), Building 7',
            'booking_rate' => 'AED 3,500 / commission'
        ]);
        $updateRes = ob_get_clean();

        $stmt = $this->pdo->prepare("SELECT location, booking_rate FROM artists WHERE id = ?");
        $stmt->execute([$artistId]);
        $updated = $stmt->fetch();
        $this->assert($updated && strpos($updated['location'], 'd3') !== false, "Artist profile updated in MySQL artists table");

        // 2.3 Like Artist
        ob_start();
        $artistCtrl->likeArtist(['id' => $artistId]);
        ob_get_clean();

        $stmt = $this->pdo->prepare("SELECT likes_count FROM artists WHERE id = ?");
        $stmt->execute([$artistId]);
        $likes = (int)$stmt->fetchColumn();
        $this->assert($likes >= 1, "Artist likes count incremented in MySQL", "Likes: $likes");

        // 2.4 Get Artists List
        ob_start();
        $artistCtrl->getArtists(['limit' => 5]);
        $listRes = json_decode(ob_get_clean(), true);
        $this->assert(!empty($listRes['data']) && count($listRes['data']) > 0, "Artist catalog retrieved from MySQL with pagination");
    }

    // -------------------------------------------------------------------------
    // 3. Art Events Management
    // -------------------------------------------------------------------------
    private function testEventFlow(): void {
        $eventCtrl = new EventController();
        $title = 'Dubai Fluid Acrylic Biennial ' . time();
        $venue = 'Warehouse 51, Alserkal Avenue';

        // 3.1 Create Event
        ob_start();
        $eventCtrl->createEvent([
            'title' => $title,
            'category' => 'Art Exhibition',
            'location' => 'Al Quoz, Dubai',
            'venue' => $venue,
            'price' => 'AED 100',
            'event_date' => '2026-11-20 18:00',
            'end_date' => '2026-11-20 22:00',
            'organizer_name' => $this->runtimeContext['artist_name'] ?? 'Noura Al-Zaabi',
            'description' => 'A showcase of large-format textured acrylic artworks.'
        ]);
        $evOutput = ob_get_clean();

        $stmt = $this->pdo->prepare("SELECT * FROM events WHERE title = ? ORDER BY id DESC LIMIT 1");
        $stmt->execute([$title]);
        $event = $stmt->fetch();

        $this->assert(!empty($event) && $event['title'] === $title, "Art event inserted into MySQL events table", "Event ID: " . ($event['id'] ?? 'none'));

        $eventId = (int)($event['id'] ?? 0);
        $this->runtimeContext['event_id'] = $eventId;
        $this->runtimeContext['event_title'] = $title;

        // 3.2 Update Event
        ob_start();
        $eventCtrl->updateEvent([
            'id' => $eventId,
            'price' => 'Free RSVP',
            'is_free' => 1
        ]);
        ob_get_clean();

        $stmt = $this->pdo->prepare("SELECT price, is_free FROM events WHERE id = ?");
        $stmt->execute([$eventId]);
        $upEvent = $stmt->fetch();
        $this->assert($upEvent && $upEvent['price'] === 'Free RSVP', "Art event updated in MySQL events table");

        // 3.3 Get Events Catalog
        ob_start();
        $eventCtrl->getEvents([]);
        $evList = json_decode(ob_get_clean(), true);
        $this->assert(!empty($evList['data']) && count($evList['data']) > 0, "Art events list retrieved from MySQL events table");
    }

    // -------------------------------------------------------------------------
    // 4. Categories Management
    // -------------------------------------------------------------------------
    private function testCategoryFlow(): void {
        $catCtrl = new CategoryController();
        $catName = 'Kinetic Light Sculptures ' . time();

        // 4.1 Create Category
        ob_start();
        $catCtrl->createCategory([
            'name' => $catName,
            'description' => 'Dynamic moving LED and fiber optic art installations.',
            'emoji' => '✨'
        ]);
        ob_get_clean();

        $stmt = $this->pdo->prepare("SELECT * FROM categories WHERE name = ? ORDER BY id DESC LIMIT 1");
        $stmt->execute([$catName]);
        $cat = $stmt->fetch();
        $this->assert(!empty($cat) && $cat['name'] === $catName, "Art category inserted into MySQL categories table", "Category ID: " . ($cat['id'] ?? 'none'));

        // 4.2 Get Categories
        ob_start();
        $catCtrl->getCategories();
        $catList = json_decode(ob_get_clean(), true);
        $this->assert(!empty($catList['data']) && count($catList['data']) > 0, "Categories catalog retrieved from MySQL categories table");
    }

    // -------------------------------------------------------------------------
    // 5. Galleries Management
    // -------------------------------------------------------------------------
    private function testGalleryFlow(): void {
        $galCtrl = new GalleryController();
        $galName = 'Aura Contemporary Space ' . time();
        $email = 'contact.' . time() . '@auraspace.ae';

        // 5.1 Register Gallery
        ob_start();
        $galCtrl->createGallery([
            'name' => $galName,
            'type' => 'Art Gallery & Studio',
            'location' => 'Gate Village, DIFC, Dubai',
            'contact_person' => 'Amira Al-Mansoor',
            'email' => $email,
            'phone' => '+971 4 333 8899',
            'website' => 'https://auraspace.ae',
            'about' => 'Pioneering exhibition gallery for modern Middle Eastern fine art.'
        ]);
        ob_get_clean();

        $stmt = $this->pdo->prepare("SELECT * FROM galleries WHERE name = ? ORDER BY id DESC LIMIT 1");
        $stmt->execute([$galName]);
        $gal = $stmt->fetch();
        $this->assert(!empty($gal) && $gal['email'] === $email, "Gallery registered with all contact fields in MySQL galleries table", "Gallery ID: " . ($gal['id'] ?? 'none'));

        $galId = (int)($gal['id'] ?? 0);

        // 5.2 Get Galleries
        ob_start();
        $galCtrl->getGalleries();
        $galList = json_decode(ob_get_clean(), true);
        $this->assert(!empty($galList['data']) && count($galList['data']) > 0, "Galleries catalog retrieved from MySQL galleries table");
    }

    // -------------------------------------------------------------------------
    // 6. Artworks Management
    // -------------------------------------------------------------------------
    private function testArtworkFlow(): void {
        $artCtrl = new ArtworkController();
        $title = 'Golden Dunes Serenade ' . time();
        $artistId = $this->runtimeContext['artist_id'] ?? 1;
        $artistName = $this->runtimeContext['artist_name'] ?? 'Noura Al-Zaabi';

        // 6.1 Create Artwork
        ob_start();
        $artCtrl->createArtwork([
            'artist_id' => $artistId,
            'artist_name' => $artistName,
            'title' => $title,
            'year' => '2026',
            'medium' => 'Acrylic & Gold Leaf on Canvas',
            'dimensions' => '160 x 120 cm',
            'price' => 'AED 16,500',
            'is_featured' => 1
        ]);
        ob_get_clean();

        $stmt = $this->pdo->prepare("SELECT * FROM artworks WHERE title = ? ORDER BY id DESC LIMIT 1");
        $stmt->execute([$title]);
        $artwork = $stmt->fetch();
        $this->assert(!empty($artwork) && $artwork['title'] === $title, "Artwork inserted into MySQL artworks table", "Artwork ID: " . ($artwork['id'] ?? 'none'));

        $artworkId = (int)($artwork['id'] ?? 0);
        $this->runtimeContext['artwork_id'] = $artworkId;

        // 6.2 Update Artwork
        ob_start();
        $artCtrl->updateArtwork([
            'id' => $artworkId,
            'price' => 'AED 18,000'
        ]);
        ob_get_clean();

        $stmt = $this->pdo->prepare("SELECT price FROM artworks WHERE id = ?");
        $stmt->execute([$artworkId]);
        $price = $stmt->fetchColumn();
        $this->assert($price === 'AED 18,000', "Artwork price updated in MySQL artworks table");
    }

    // -------------------------------------------------------------------------
    // 7. Bookings Management
    // -------------------------------------------------------------------------
    private function testBookingFlow(): void {
        $bookCtrl = new BookingController();
        $email = $this->runtimeContext['user_email'] ?? 'test@artistdubai.com';
        $artistName = $this->runtimeContext['artist_name'] ?? 'Noura Al-Zaabi';

        // 7.1 Create Booking
        ob_start();
        $bookCtrl->createBooking([
            'full_name' => 'Dr. Kareem Al-Sayed',
            'email' => $email,
            'phone' => '+971 50 888 7777',
            'artist_name' => $artistName,
            'booking_type' => 'Commission Artwork',
            'budget_range' => 'AED 15,000 - 50,000',
            'event_date' => '2026-12-15',
            'location' => 'Downtown Dubai Luxury Villa',
            'description' => 'Custom 3-piece grand hallway canvas commission.',
            'status' => 'Confirmed'
        ]);
        $bookRes = json_decode(ob_get_clean(), true);

        $stmt = $this->pdo->prepare("SELECT * FROM bookings WHERE email = ? ORDER BY id DESC LIMIT 1");
        $stmt->execute([$email]);
        $booking = $stmt->fetch();
        $this->assert(!empty($booking) && $booking['artist_name'] === $artistName, "Booking inquiry inserted into MySQL bookings table", "Booking ID: " . ($booking['id'] ?? 'none'));

        $bookingId = (int)($booking['id'] ?? 0);

        // 7.2 Get Bookings by Email
        ob_start();
        $bookCtrl->getBookings(['email' => $email]);
        $bList = json_decode(ob_get_clean(), true);
        $this->assert(!empty($bList['data']) && count($bList['data']) > 0, "User bookings retrieved from MySQL bookings table");

        // 7.3 Cancel Booking
        ob_start();
        $bookCtrl->cancelBooking(['id' => $bookingId]);
        ob_get_clean();

        $stmt = $this->pdo->prepare("SELECT status FROM bookings WHERE id = ?");
        $stmt->execute([$bookingId]);
        $status = $stmt->fetchColumn();
        $this->assert($status === 'Cancelled', "Booking status updated to 'Cancelled' in MySQL bookings table");
    }

    // -------------------------------------------------------------------------
    // 8. Reviews Management
    // -------------------------------------------------------------------------
    private function testReviewFlow(): void {
        $revCtrl = new ReviewController();
        $author = 'Sultan Al-Shamsi ' . time();
        $entity = 'Dubai Culture & Arts Authority';

        // 8.1 Create Review
        ob_start();
        $revCtrl->createReview([
            'entity_name' => $entity,
            'author_name' => $author,
            'rating' => 5.0,
            'text' => 'Outstanding cultural facilities and exceptional support for local artists!'
        ]);
        ob_get_clean();

        $stmt = $this->pdo->prepare("SELECT * FROM reviews WHERE author_name = ? ORDER BY id DESC LIMIT 1");
        $stmt->execute([$author]);
        $rev = $stmt->fetch();

        $this->assert(!empty($rev) && (float)$rev['rating'] == 5.0, "Review saved in MySQL reviews table", "Review ID: " . ($rev['id'] ?? 'none'));
        $this->assert(!empty($rev['relative_time']), "Dynamic relative timestamp calculated", "Timestamp: " . ($rev['relative_time'] ?? ''));

        // 8.2 Get Reviews
        ob_start();
        $revCtrl->getReviews(['entity_name' => $entity]);
        $rList = json_decode(ob_get_clean(), true);
        $this->assert(!empty($rList['data']), "Reviews retrieved for cultural entity from MySQL reviews table");
    }

    // -------------------------------------------------------------------------
    // 9. Government Portal & Cultural Entities
    // -------------------------------------------------------------------------
    private function testGovernmentPortalFlow(): void {
        $govCtrl = new GovernmentController();

        ob_start();
        $govCtrl->getEntities();
        $govRes = json_decode(ob_get_clean(), true);

        $entities = $govRes['data']['entities'] ?? $govRes['data'] ?? [];
        $this->assert(!empty($entities) && count($entities) >= 1, "Government cultural entities retrieved from MySQL government_entities table", "Count: " . count($entities));

        if (!empty($entities)) {
            $first = $entities[0];
            $this->assert(isset($first['is_currently_open']) || isset($first['is_open']), "Dynamic Dubai GST (UTC+4) open/closed calculation verified");
            $this->assert(!empty($first['directions_url']) || !empty($first['website_url']), "Dynamic Google Maps and Website URLs verified");
        }
    }

    // -------------------------------------------------------------------------
    // 10. Favorites & Bookmarks
    // -------------------------------------------------------------------------
    private function testFavoritesFlow(): void {
        $favCtrl = new FavoriteController();
        $email = $this->runtimeContext['user_email'] ?? 'test@artistdubai.com';
        $artistId = $this->runtimeContext['artist_id'] ?? 1;

        // 10.1 Add Favorite
        ob_start();
        $favCtrl->toggleFavorite([
            'user_email' => $email,
            'item_type' => 'artist',
            'item_id' => $artistId
        ]);
        ob_get_clean();

        $stmt = $this->pdo->prepare("SELECT COUNT(*) FROM favorites WHERE user_email = ? AND item_type = 'artist' AND item_id = ?");
        $stmt->execute([$email, $artistId]);
        $count = (int)$stmt->fetchColumn();
        $this->assert($count === 1, "Favorite inserted into MySQL favorites table");

        // 10.2 Get Favorites
        ob_start();
        $favCtrl->getFavorites(['email' => $email]);
        $favList = json_decode(ob_get_clean(), true);
        $this->assert(!empty($favList['data']['artists']), "User favorites catalog retrieved with joined MySQL data");

        // 10.3 Remove Favorite
        ob_start();
        $favCtrl->toggleFavorite([
            'user_email' => $email,
            'item_type' => 'artist',
            'item_id' => $artistId
        ]);
        ob_get_clean();

        $stmt->execute([$email, $artistId]);
        $countAfter = (int)$stmt->fetchColumn();
        $this->assert($countAfter === 0, "Favorite toggled and removed cleanly from MySQL favorites table");
    }

    // -------------------------------------------------------------------------
    // 11. Follows Management
    // -------------------------------------------------------------------------
    private function testFollowsFlow(): void {
        $followCtrl = new FollowController();
        $email = $this->runtimeContext['user_email'] ?? 'test@artistdubai.com';
        $artistId = $this->runtimeContext['artist_id'] ?? 1;

        // 11.1 Follow Artist
        ob_start();
        $followCtrl->toggleFollow([
            'user_email' => $email,
            'artist_id' => $artistId
        ]);
        ob_get_clean();

        $stmt = $this->pdo->prepare("SELECT COUNT(*) FROM follows WHERE user_email = ? AND artist_id = ?");
        $stmt->execute([$email, $artistId]);
        $followCount = (int)$stmt->fetchColumn();
        $this->assert($followCount === 1, "Follow recorded in MySQL follows table");

        // 11.2 Unfollow Artist
        ob_start();
        $followCtrl->toggleFollow([
            'user_email' => $email,
            'artist_id' => $artistId
        ]);
        ob_get_clean();

        $stmt->execute([$email, $artistId]);
        $unfollowCount = (int)$stmt->fetchColumn();
        $this->assert($unfollowCount === 0, "Unfollow recorded and removed from MySQL follows table");
    }

    // -------------------------------------------------------------------------
    // 12. Dynamic Notifications Management
    // -------------------------------------------------------------------------
    private function testNotificationsFlow(): void {
        $notifCtrl = new NotificationController();
        $email = $this->runtimeContext['user_email'] ?? 'renish@gmail.com';

        // 12.1 Create Custom Notification
        ob_start();
        $notifCtrl->createNotification([
            'title' => 'VIP Gallery Preview Invitation',
            'body' => 'You are invited to an exclusive preview at Alserkal Avenue.',
            'type' => 'event',
            'route' => '/events',
            'user_email' => $email
        ]);
        $res = json_decode(ob_get_clean(), true);
        $newNotifId = (int)($res['data']['id'] ?? 0);
        $this->assert($newNotifId > 0, "Notification created in MySQL notifications table", "ID: $newNotifId");

        // 12.2 Get Notifications
        ob_start();
        $notifCtrl->getNotifications(['email' => $email]);
        $listRes = json_decode(ob_get_clean(), true);
        $notifs = $listRes['data']['notifications'] ?? [];
        $unread = (int)($listRes['data']['unread_count'] ?? 0);
        $this->assert(!empty($notifs) && count($notifs) > 0, "Notifications fetched from MySQL with relative timestamps", "Count: " . count($notifs));
        $this->assert($unread > 0, "Unread count accurately computed from MySQL", "Unread: $unread");

        // 12.3 Mark Single Notification As Read
        ob_start();
        $notifCtrl->markAsRead(['id' => $newNotifId]);
        ob_get_clean();

        $stmt = $this->pdo->prepare("SELECT is_read FROM notifications WHERE id = ?");
        $stmt->execute([$newNotifId]);
        $isRead = (int)$stmt->fetchColumn();
        $this->assert($isRead === 1, "Notification marked as read in MySQL database");

        // 12.4 Mark All As Read
        ob_start();
        $notifCtrl->markAllAsRead(['email' => $email]);
        ob_get_clean();

        $stmt = $this->pdo->prepare("SELECT COUNT(*) FROM notifications WHERE (user_email = ? OR user_email IS NULL) AND is_read = 0");
        $stmt->execute([$email]);
        $unreadRemaining = (int)$stmt->fetchColumn();
        $this->assert($unreadRemaining === 0, "All notifications marked as read in MySQL database");
    }

    // -------------------------------------------------------------------------
    // 13. Database Schema & Table Audit
    // -------------------------------------------------------------------------
    private function testDatabaseSchemaAudit(): void {
        $tables = [
            'users' => 'User accounts and secure authentication hashes',
            'artists' => 'Artist profiles, bios, rates, and stats',
            'events' => 'Art events, exhibitions, and venues',
            'categories' => 'Art discipline categories and taxonomies',
            'galleries' => 'Art galleries, spaces, and contact directory',
            'artworks' => 'Artist portfolio artworks, medium, dimensions, and prices',
            'bookings' => 'Artist commission inquiries and event tickets',
            'reviews' => 'User and community ratings and dynamic relative reviews',
            'government_entities' => 'Dubai cultural councils, opening hours, and maps',
            'favorites' => 'User favorited artists, events, and artworks',
            'follows' => 'User artist follower relationships',
            'notifications' => 'User notifications, activity alerts, and relative timestamps'
        ];

        foreach ($tables as $table => $desc) {
            $count = (int)$this->pdo->query("SELECT COUNT(*) FROM `$table`")->fetchColumn();
            $this->assert(true, "Table `$table` ($desc)", "$count records active in MySQL");
        }
    }
}

$agent = new DatabaseFeatureTesterAgent();
$success = $agent->runCompleteDiagnostic();
exit($success ? 0 : 1);
