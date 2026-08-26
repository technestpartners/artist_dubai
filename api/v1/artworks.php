<?php
require_once __DIR__ . '/db.php';

$method = $_SERVER['REQUEST_METHOD'];

if ($method === 'GET') {
    $artist_name = $_GET['artist_name'] ?? null;
    try {
        if ($artist_name) {
            $stmt = $pdo->prepare("SELECT * FROM artworks WHERE artist_name = :artist_name ORDER BY is_featured DESC, id DESC");
            $stmt->execute([':artist_name' => $artist_name]);
        } else {
            $stmt = $pdo->query("SELECT * FROM artworks ORDER BY is_featured DESC, id DESC");
        }
        $artworks = $stmt->fetchAll();
        echo json_encode(['success' => true, 'data' => $artworks]);
    } catch (\Exception $e) {
        http_response_code(500);
        echo json_encode(['success' => false, 'error' => $e->getMessage()]);
    }
} elseif ($method === 'POST') {
    $input = json_decode(file_get_contents('php://input'), true);

    $artist_name = trim($input['artist_name'] ?? 'Fatima Al Qasimi');
    $title = trim($input['title'] ?? '');
    $year = trim($input['year'] ?? '2024');
    $medium = trim($input['medium'] ?? 'Mixed Media');
    $dimensions = trim($input['dimensions'] ?? '120 x 80 cm');
    $description = trim($input['description'] ?? '');
    $price = trim($input['price'] ?? 'USD 1800 - 2200');
    $image_url = trim($input['image_url'] ?? '');
    $is_featured = !empty($input['is_featured']) ? 1 : 0;

    if (empty($title)) {
        http_response_code(400);
        echo json_encode(['success' => false, 'error' => 'Artwork title is required.']);
        exit();
    }

    try {
        $stmt = $pdo->prepare("
            INSERT INTO artworks (artist_name, title, year, medium, dimensions, description, price, image_url, is_featured)
            VALUES (:artist_name, :title, :year, :medium, :dimensions, :description, :price, :image_url, :is_featured)
        ");
        $stmt->execute([
            ':artist_name' => $artist_name,
            ':title' => $title,
            ':year' => $year,
            ':medium' => $medium,
            ':dimensions' => $dimensions,
            ':description' => $description,
            ':price' => $price,
            ':image_url' => $image_url,
            ':is_featured' => $is_featured,
        ]);

        $newId = $pdo->lastInsertId();
        echo json_encode(['success' => true, 'message' => 'Artwork created successfully.', 'id' => $newId]);
    } catch (\Exception $e) {
        http_response_code(500);
        echo json_encode(['success' => false, 'error' => $e->getMessage()]);
    }
}
