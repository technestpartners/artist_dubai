<?php
require_once __DIR__ . '/db.php';

$method = $_SERVER['REQUEST_METHOD'];

if ($method === 'GET') {
    $galleries = [
        [
            'id' => 'gal-1',
            'name' => 'Alserkal Avenue',
            'category' => 'Art District & Galleries Hub',
            'location' => '17th St - Al Quoz - Al Quoz Industrial Area 1 - Dubai',
            'timing' => '10:00 AM - 07:00 PM (Sat - Thu)',
            'description' => 'The vibrant cultural district of Dubai, hosting contemporary art galleries, design venues, and creative spaces.',
            'imageUrl' => 'https://images.unsplash.com/photo-1579783900882-c0d3dad7b119?q=80&w=1200&auto=format&fit=crop',
            'featuredArtistsCount' => 35,
            'upcomingEventsCount' => 8,
            'website' => 'https://alserkal.online',
            'phone' => '+971 4 333 8400'
        ],
        [
            'id' => 'gal-2',
            'name' => 'Jameel Arts Centre',
            'category' => 'Contemporary Art Museum',
            'location' => 'Jaddaf Waterfront - Dubai',
            'timing' => '10:00 AM - 08:00 PM (Daily)',
            'description' => 'An independent institution dedicated to exhibiting contemporary art and engaging communities through exhibitions and research.',
            'imageUrl' => 'https://images.unsplash.com/photo-1541701494587-cb58502866ab?q=80&w=1200&auto=format&fit=crop',
            'featuredArtistsCount' => 24,
            'upcomingEventsCount' => 5,
            'website' => 'https://jameelartscentre.org',
            'phone' => '+971 4 873 9800'
        ],
        [
            'id' => 'gal-3',
            'name' => 'The Third Line',
            'category' => 'Contemporary Middle Eastern Art Gallery',
            'location' => 'Alserkal Avenue, Warehouse 78 & 80, Al Quoz 1 - Dubai',
            'timing' => '10:00 AM - 07:00 PM (Sun - Fri)',
            'description' => 'Represents contemporary Middle Eastern artists locally, regionally, and internationally.',
            'imageUrl' => 'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?q=80&w=1200&auto=format&fit=crop',
            'featuredArtistsCount' => 18,
            'upcomingEventsCount' => 3,
            'website' => 'https://thethirdline.com',
            'phone' => '+971 4 341 1367'
        ],
        [
            'id' => 'gal-4',
            'name' => 'Cuadro Fine Art Gallery',
            'category' => 'Fine Art Gallery & Education',
            'location' => 'DIFC Gate Village 10 - Dubai',
            'timing' => '10:00 AM - 08:00 PM (Sun - Thu)',
            'description' => 'Located in DIFC, Cuadro offers four key areas: exhibitions, consultations, artist residencies, and education.',
            'imageUrl' => 'https://images.unsplash.com/photo-1579783902614-a3fb3927b675?q=80&w=1200&auto=format&fit=crop',
            'featuredArtistsCount' => 15,
            'upcomingEventsCount' => 4,
            'website' => 'https://cuadroart.com',
            'phone' => '+971 4 425 0400'
        ],
        [
            'id' => 'gal-5',
            'name' => 'Meem Gallery',
            'category' => 'Modern & Contemporary Arab Art',
            'location' => 'Umm Suqeim St - Al Quoz - Al Quoz Industrial Area 4 - Dubai',
            'timing' => '10:00 AM - 06:00 PM (Mon - Sat)',
            'description' => 'Specializes in modern and contemporary Arab and Middle Eastern art.',
            'imageUrl' => 'https://images.unsplash.com/photo-1579783900882-c0d3dad7b119?q=80&w=1200&auto=format&fit=crop',
            'featuredArtistsCount' => 20,
            'upcomingEventsCount' => 2,
            'website' => 'https://meemartgallery.com',
            'phone' => '+971 4 347 7883'
        ],
    ];

    echo json_encode([
        'status' => 'success',
        'success' => true,
        'count' => count($galleries),
        'data' => $galleries
    ]);
} elseif ($method === 'POST') {
    $input = json_decode(file_get_contents('php://input'), true) ?? $_POST;
    $galleryName = trim(htmlspecialchars($input['gallery_name'] ?? $input['name'] ?? '', ENT_QUOTES, 'UTF-8'));
    $location = trim(htmlspecialchars($input['location'] ?? 'Dubai, UAE', ENT_QUOTES, 'UTF-8'));
    $contactPerson = trim(htmlspecialchars($input['contact_person'] ?? '', ENT_QUOTES, 'UTF-8'));
    $email = trim(filter_var($input['email'] ?? '', FILTER_SANITIZE_EMAIL));

    if (empty($galleryName)) {
        http_response_code(400);
        echo json_encode(['status' => 'error', 'success' => false, 'message' => 'Gallery name is required.']);
        exit();
    }

    http_response_code(201);
    echo json_encode([
        'status' => 'success',
        'success' => true,
        'message' => 'Gallery registration submitted successfully!',
        'gallery_id' => 'gal-' . rand(100, 999)
    ]);
}
