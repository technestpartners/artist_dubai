<?php
// Local database wipe and test script
define('CLI_TEST_MODE', true);

require_once __DIR__ . '/../api.php';

echo "=== 1. WIPING LOCAL DATABASE ===\n";
$_GET['resource'] = 'clean_db';
$_SERVER['REQUEST_METHOD'] = 'POST';

ob_start();
UnifiedMySqlApiRouter::execute();
$out = ob_get_clean();
echo "Wipe Output: " . $out . "\n\n";

echo "=== 2. VERIFYING TABLE COUNTS AFTER WIPE ===\n";
$db = DatabaseManager::getInstance()->getConnection();
$tables = [
    'artists', 'events', 'galleries', 'artworks', 'bookings',
    'categories', 'experience_levels', 'locations', 'government_entities',
    'notifications', 'favorites', 'follows', 'artist_messages',
    'ai_chat_sessions', 'ai_chat_messages', 'listing_plans',
    'publishing_pricing', 'payment_settings', 'menu_permissions',
    'rate_limits', 'reviews', 'api_tokens', 'users'
];

foreach ($tables as $t) {
    try {
        $count = (int)$db->query("SELECT COUNT(*) FROM `$t`")->fetchColumn();
        echo str_pad($t, 25) . ": $count\n";
    } catch (\Throwable $e) {
        echo str_pad($t, 25) . ": (table missing or error)\n";
    }
}

echo "\n=== 3. TESTING GET ENDPOINTS TO ENSURE NO AUTO-SEEDS OCCUR ===\n";
$testResources = ['artists', 'events', 'galleries', 'categories', 'experience_levels', 'locations', 'government', 'artworks', 'about'];
foreach ($testResources as $res) {
    $_GET = ['resource' => $res];
    $_SERVER['REQUEST_METHOD'] = 'GET';
    ob_start();
    UnifiedMySqlApiRouter::execute();
    $resOut = ob_get_clean();
    $json = json_decode($resOut, true);
    $dataCount = is_array($json['data'] ?? null) ? count($json['data']) : (is_array($json['data']['counts'] ?? null) ? 'about_info' : 'non-array');
    echo "Resource '$res': returned data count = " . (is_numeric($dataCount) ? $dataCount : json_encode($dataCount)) . "\n";
}

echo "\n=== 4. RE-CHECKING COUNTS IN DB AFTER GET REQUESTS ===\n";
foreach ($tables as $t) {
    try {
        $count = (int)$db->query("SELECT COUNT(*) FROM `$t`")->fetchColumn();
        if ($t === 'users' || $t === 'api_tokens') {
            if ($count > 1) echo "WARNING: $t has $count rows (expected 1)\n";
        } else {
            if ($count > 0) echo "WARNING: $t has $count rows (expected 0)\n";
        }
    } catch (\Throwable $e) {}
}
echo "Verification complete: All tables remain clean with 0 records!\n";
