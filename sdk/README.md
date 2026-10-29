# Artist Dubai - OOP Base API & Service Layer SDK

A standalone, zero-dependency, enterprise-grade Object-Oriented PHP SDK and Service Layer for integrating external systems (WordPress plugins, Laravel applications, custom PHP portals, mobile/desktop backends) with the **Artist Dubai** platform.

---

## 🚀 Features

- **Zero External Dependencies**: Works out-of-the-box on PHP 7.4 through 8.4+ using standard cURL and JSON extensions.
- **Fluent Facade & Service Architecture**: Access domain services through clean OOP properties (`$client->artists`, `$client->galleries`, `$client->events`, etc.).
- **Strong Exception Handling**: Typed exceptions (`AuthenticationException`, `NotFoundException`, `ValidationException`, `RateLimitException`, `ServerException`).
- **Flexible Authentication**: Supports Master API Keys (`X-Api-Key` or `.env` `MASTER_API_KEY`) and dynamic User Bearer Tokens.
- **Pagination & Response Parsing**: Automated response unboxing, HTTP status validation, and pagination metadata.

---

## 📦 Quick Installation

Simply copy `ArtistDubai.php` into your project and require it:

```php
require_once __DIR__ . '/sdk/ArtistDubai.php';

use ArtistDubai\Sdk\ArtistDubai;
use ArtistDubai\Sdk\Exceptions\ApiException;

$client = new ArtistDubai([
    'base_url' => 'https://technestpartners.com/api/api.php',
    'api_key'  => 'YOUR_MASTER_API_KEY_OR_TOKEN',
    'timeout'  => 30, // seconds
]);
```

---

## 🎨 Domain Services & Examples

### 1. Galleries & Art Centers
```php
// List galleries (paginated)
$galleries = $client->galleries->all(['limit' => 10, 'page' => 1]);

// Find single gallery by ID
$gallery = $client->galleries->find(42);

// Create a new gallery
$newGallery = $client->galleries->create([
    'name'           => 'Dubai Modern Art Space',
    'category'       => 'Art Gallery',
    'location'       => 'Alserkal Avenue, Dubai, UAE',
    'timing'         => 'Sat–Thu 10:00 AM – 8:00 PM',
    'website'        => 'https://example.com',
    'contact_person' => 'Sarah Al Mahmoud',
    'email'          => 'contact@example.com',
    'phone'          => '+971 4 123 4567',
    'about'          => 'Contemporary art exhibition space.',
]);

// Update a gallery
$client->galleries->update(42, [
    'timing' => 'Daily 10:00 AM – 10:00 PM',
]);

// Delete a gallery (soft-delete / recycle bin)
$client->galleries->delete(42);
```

### 2. Artists
```php
// Get artists with optional filtering
$artists = $client->artists->all(['category' => 'Contemporary', 'limit' => 20]);

// Find artist
$artist = $client->artists->find(15);

// Get artworks for an artist
$artworks = $client->artists->artworks(15);

// Like an artist profile
$client->artists->like(15);
```

### 3. Events & Exhibitions
```php
// List events
$events = $client->events->all(['limit' => 10]);

// Find event
$event = $client->events->find(5);

// Get associated galleries
$eventGalleries = $client->events->galleries(5);
```

### 4. Artworks
```php
// Query artworks
$artworks = $client->artworks->all(['limit' => 12]);

// Like artwork
$client->artworks->like(88);
```

### 5. Categories & Locations
```php
// Get all art categories
$categories = $client->categories->all();

// Get experience levels
$experienceLevels = $client->categories->experienceLevels();

// Get Dubai locations
$locations = $client->categories->locations();
```

### 6. Bookings
```php
// Submit an artist booking
$booking = $client->bookings->create([
    'artist_id'   => 15,
    'artist_name' => 'Fatima Al Marri',
    'name'        => 'Corporate Event Planner LLC',
    'email'       => 'planner@corporate.ae',
    'phone'       => '+971 50 987 6543',
    'event_title' => 'Annual Art Gala 2026',
    'date'        => '2026-11-15',
    'notes'       => 'Live portrait painting session.',
]);
```

### 7. User Authentication & Profile
```php
// Login with user credentials
$authResult = $client->auth->login('artist@dubai.com', 'secret_password');
// $client->getToken() is now automatically set for subsequent calls!

// Fetch logged-in user profile
$profile = $client->auth->profile();

// Change user password
$client->auth->changePassword('old_pass', 'new_secure_pass');
```

### 8. File Uploads
```php
// Upload local physical image
$imageUrl = $client->uploads->uploadFile('/path/to/artwork.jpg');

// Upload base64 encoded image
$imageUrl = $client->uploads->uploadBase64($base64Data, 'png');
```

---

## 🛡️ Error Handling

The SDK throws descriptive OOP exceptions matching standard HTTP response codes:

```php
use ArtistDubai\Sdk\Exceptions\AuthenticationException;
use ArtistDubai\Sdk\Exceptions\NotFoundException;
use ArtistDubai\Sdk\Exceptions\ValidationException;
use ArtistDubai\Sdk\Exceptions\RateLimitException;
use ArtistDubai\Sdk\Exceptions\ApiException;

try {
    $gallery = $client->galleries->find(99999);
} catch (AuthenticationException $e) {
    // 401 / 403: Invalid API key or expired token
    echo "Auth Error: " . $e->getMessage();
} catch (NotFoundException $e) {
    // 404: Resource not found
    echo "Not Found: " . $e->getMessage();
} catch (ValidationException $e) {
    // 400 / 422: Input validation failed
    echo "Validation Error: " . $e->getMessage();
    print_r($e->getErrors());
} catch (RateLimitException $e) {
    // 429: Too Many Requests
    echo "Rate limited. Retry after " . $e->getRetryAfter() . " seconds.";
} catch (ApiException $e) {
    // General API error
    echo "API Error [{$e->getStatusCode()}]: " . $e->getMessage();
}
```

---

## 🌐 External Integration Use Cases

- **WordPress / WooCommerce**: Sync gallery venues or artist profiles from an existing WordPress site into Artist Dubai via custom actions/hooks.
- **Laravel Services**: Register as a service provider or call `$artistDubai->galleries->all()` inside Laravel controllers.
- **Custom CRM / Admin Portals**: Automatically synchronize event bookings and client inquiries into your internal management dashboard.
