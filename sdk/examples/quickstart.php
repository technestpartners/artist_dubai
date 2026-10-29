<?php
/**
 * Artist Dubai SDK - External Integration Quickstart Example
 *
 * Demonstrates how external systems (WordPress plugins, Laravel applications,
 * microservices, or custom PHP scripts) integrate seamlessly using the OOP Base API.
 */

require_once __DIR__ . '/../ArtistDubai.php';

use ArtistDubai\Sdk\ArtistDubai;
use ArtistDubai\Sdk\Exceptions\ApiException;
use ArtistDubai\Sdk\Exceptions\AuthenticationException;
use ArtistDubai\Sdk\Exceptions\ValidationException;

// 1. Initialize the OOP Client
$api = new ArtistDubai([
    // Local development endpoint or production endpoint:
    'base_url' => 'http://localhost/artist_dubai/api/api.php',
    // Optional Master API Key or User Token:
    'api_key' => 'YOUR_MASTER_API_KEY_OR_TOKEN',
    'timeout' => 15,
    'verify_ssl' => false, // Set to true in production with HTTPS
]);

echo "====================================================\n";
echo "🎨 Artist Dubai - OOP Base API Integration Example\n";
echo "====================================================\n\n";

try {
    // 2. Query Categories & Locations via CategoryService
    echo "1. Fetching Art Categories & Locations...\n";
    $categories = $api->categories->all();
    echo "   Found " . count($categories) . " categories.\n";

    $locations = $api->categories->locations();
    echo "   Found " . count($locations) . " configured locations.\n\n";

    // 3. Query Galleries / Art Centers via GalleryService
    echo "2. Querying Art Galleries...\n";
    $galleries = $api->galleries->all(['limit' => 3]);
    echo "   Retrieved " . count($galleries) . " galleries:\n";
    foreach ($galleries as $g) {
        $name = $g['name'] ?? $g['title'] ?? 'Unnamed';
        $location = $g['location'] ?? 'Dubai';
        $timing = !empty($g['timing']) ? " | Timing: {$g['timing']}" : '';
        echo "   - {$name} ({$location}){$timing}\n";
    }
    echo "\n";

    // 4. Query Artists via ArtistService
    echo "3. Querying Featured Artists...\n";
    $artists = $api->artists->all(['limit' => 3]);
    echo "   Retrieved " . count($artists) . " artists:\n";
    foreach ($artists as $a) {
        $name = $a['name'] ?? 'Unnamed';
        $cat = $a['category'] ?? 'Artist';
        echo "   - {$name} [{$cat}]\n";
    }
    echo "\n";

    // 5. Query Events via EventService
    echo "4. Querying Upcoming Art Events...\n";
    $events = $api->events->all(['limit' => 3]);
    echo "   Retrieved " . count($events) . " events.\n\n";

    // 6. Demonstrate Safe Error Handling
    echo "5. Testing Error Handling (simulating invalid ID lookup)...\n";
    try {
        $nonExistent = $api->galleries->find(99999999);
        echo "   Lookup result: " . ($nonExistent ? "Found" : "Not Found (handled gracefully)") . "\n";
    } catch (ApiException $e) {
        echo "   Caught ApiException: " . $e->getMessage() . " (Code: " . $e->getStatusCode() . ")\n";
    }

    echo "\n Integration demo completed successfully!\n";

} catch (AuthenticationException $e) {
    echo "❌ Authentication Failed: " . $e->getMessage() . "\n";
} catch (ValidationException $e) {
    echo "❌ Validation Error: " . $e->getMessage() . "\n";
    print_r($e->getErrors());
} catch (ApiException $e) {
    echo "❌ API Exception: " . $e->getMessage() . " (Status: " . $e->getStatusCode() . ")\n";
} catch (\Throwable $t) {
    echo "❌ General Error: " . $t->getMessage() . "\n";
}
