<?php
require_once 'db.php';

$method = $_SERVER['REQUEST_METHOD'];

if ($method === 'POST') {
    $data = json_decode(file_get_contents('php://input'), true);

    $stmt = $pdo->prepare('
        INSERT INTO artists 
        (name, category, location, bio, avatar_url, banner_url, followers_count, works_count)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    ');

    $success = $stmt->execute([
        $data['name'] ?? '',
        $data['category'] ?? 'Mixed Media',
        $data['location'] ?? 'Dubai, UAE',
        $data['bio'] ?? '',
        $data['avatar_url'] ?? null,
        $data['banner_url'] ?? null,
        0,
        0
    ]);

    if ($success) {
        echo json_encode([
            'success' => true,
            'message' => 'Artist Profile created successfully!',
            'artist_id' => $pdo->lastInsertId()
        ]);
    } else {
        http_response_code(500);
        echo json_encode(['error' => 'Failed to create artist profile.']);
    }
} else {
    $id = $_GET['id'] ?? null;
    $category = $_GET['category'] ?? null;

    if ($id) {
        $stmt = $pdo->prepare('SELECT * FROM artists WHERE id = ?');
        $stmt->execute([$id]);
        $artist = $stmt->fetch();
        echo json_encode([
            'success' => true,
            'data' => $artist
        ]);
    } elseif ($category && $category !== 'All Categories') {
        $stmt = $pdo->prepare('SELECT * FROM artists WHERE category LIKE ? ORDER BY id DESC');
        $stmt->execute(['%' . $category . '%']);
        $artists = $stmt->fetchAll();
        echo json_encode([
            'success' => true,
            'data' => $artists
        ]);
    } else {
        $stmt = $pdo->query('SELECT * FROM artists ORDER BY id DESC');
        $artists = $stmt->fetchAll();
        echo json_encode([
            'success' => true,
            'data' => $artists
        ]);
    }
}
