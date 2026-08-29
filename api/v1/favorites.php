<?php
require_once __DIR__ . '/db.php';

$method = $_SERVER['REQUEST_METHOD'];

if ($method === 'GET') {
    $favorites = [
        'artists' => [
            [
                'id' => 'fav-artist-1',
                'name' => 'Fatima Al Qasimi',
                'category' => 'Arabic Calligraphy & Fine Art',
                'location' => 'Dubai, UAE',
                'rating' => 4.9,
                'hourlyRate' => '350 AED / hr',
                'imageUrl' => 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?q=80&w=400&auto=format&fit=crop',
                'isFavorited' => true
            ],
            [
                'id' => 'fav-artist-2',
                'name' => 'Marcus Vance',
                'category' => 'NFT & Digital Art',
                'location' => 'Dubai Design District (d3)',
                'rating' => 4.8,
                'hourlyRate' => '450 AED / hr',
                'imageUrl' => 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?q=80&w=400&auto=format&fit=crop',
                'isFavorited' => true
            ]
        ],
        'events' => [
            [
                'id' => 'fav-event-1',
                'title' => 'Contemporary Arabic Calligraphy Masterclass',
                'category' => 'Art Workshop',
                'dateTime' => 'Thu, 4 Sep 2025 at 10:00 AM',
                'location' => 'Alserkal Avenue, Al Quoz, Dubai',
                'price' => '50.00 AED',
                'organizer' => 'Nizar Fahem',
                'imageUrl' => 'https://images.unsplash.com/photo-1579783900882-c0d3dad7b119?q=80&w=1200&auto=format&fit=crop',
                'isFavorited' => true
            ]
        ],
        'artworks' => [
            [
                'id' => 'fav-art-1',
                'title' => 'Sacred Verses',
                'artistName' => 'Fatima Al Qasimi',
                'medium' => 'Mixed Media on Paper',
                'dimensions' => '70 x 50 cm',
                'price' => 'USD 1,800 - 2,200',
                'imageUrl' => 'https://images.unsplash.com/photo-1579783902614-a3fb3927b675?q=80&w=1200&auto=format&fit=crop',
                'isLiked' => true
            ]
        ]
    ];

    echo json_encode([
        'status' => 'success',
        'success' => true,
        'data' => $favorites
    ]);
} elseif ($method === 'POST') {
    $input = json_decode(file_get_contents('php://input'), true) ?? $_POST;
    $targetId = trim($input['target_id'] ?? '');
    $targetType = trim($input['target_type'] ?? 'artist');

    echo json_encode([
        'status' => 'success',
        'success' => true,
        'message' => 'Favorite updated successfully',
        'target_id' => $targetId,
        'target_type' => $targetType,
        'is_favorited' => true
    ]);
}
