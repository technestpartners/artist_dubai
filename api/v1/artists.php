<?php
require_once 'db.php';

$method = $_SERVER['REQUEST_METHOD'];

if ($method === 'POST') {
    $data = json_decode(file_get_contents('php://input'), true) ?? $_POST;

    $name = trim(htmlspecialchars($data['name'] ?? $data['full_name'] ?? '', ENT_QUOTES, 'UTF-8'));
    $category = trim(htmlspecialchars($data['category'] ?? 'Contemporary Art', ENT_QUOTES, 'UTF-8'));
    $location = trim(htmlspecialchars($data['location'] ?? 'Dubai, UAE', ENT_QUOTES, 'UTF-8'));
    $bio = trim(htmlspecialchars($data['bio'] ?? '', ENT_QUOTES, 'UTF-8'));
    $avatarUrl = filter_var($data['avatar_url'] ?? null, FILTER_VALIDATE_URL) ? $data['avatar_url'] : null;
    $bannerUrl = filter_var($data['banner_url'] ?? null, FILTER_VALIDATE_URL) ? $data['banner_url'] : null;

    if (empty($name)) {
        http_response_code(400);
        echo json_encode(['status' => 'error', 'success' => false, 'message' => 'Artist name is required.']);
        exit();
    }

    $stmt = $pdo->prepare('
        INSERT INTO artists 
        (name, category, location, bio, avatar_url, banner_url, followers_count, works_count)
        VALUES (?, ?, ?, ?, ?, ?, 0, 0)
    ');

    $success = $stmt->execute([
        $name,
        $category,
        $location,
        $bio,
        $avatarUrl,
        $bannerUrl
    ]);

    if ($success) {
        http_response_code(201);
        echo json_encode([
            'status' => 'success',
            'success' => true,
            'message' => 'Artist profile created successfully!',
            'artist_id' => (int)$pdo->lastInsertId()
        ]);
    } else {
        http_response_code(500);
        echo json_encode(['status' => 'error', 'success' => false, 'message' => 'Failed to create artist profile.']);
    }
} else {
    $id = $_GET['id'] ?? null;
    $category = $_GET['category'] ?? null;
    $search = $_GET['search'] ?? null;

    if ($id) {
        $stmt = $pdo->prepare('SELECT * FROM artists WHERE id = ?');
        $stmt->execute([$id]);
        $artist = $stmt->fetch();
        if ($artist) {
            echo json_encode([
                'status' => 'success',
                'success' => true,
                'data' => $artist
            ]);
        } else {
            http_response_code(404);
            echo json_encode(['status' => 'error', 'success' => false, 'message' => 'Artist not found.']);
        }
    } else {
        $sql = 'SELECT * FROM artists WHERE 1=1';
        $params = [];

        if ($category && $category !== 'All Categories' && $category !== 'All') {
            $sql .= ' AND category LIKE ?';
            $params[] = '%' . $category . '%';
        }

        if ($search) {
            $sql .= ' AND (name LIKE ? OR bio LIKE ? OR location LIKE ?)';
            $params[] = '%' . $search . '%';
            $params[] = '%' . $search . '%';
            $params[] = '%' . $search . '%';
        }

        $sql .= ' ORDER BY id DESC';
        $stmt = $pdo->prepare($sql);
        $stmt->execute($params);
        $artists = $stmt->fetchAll();

        echo json_encode([
            'status' => 'success',
            'success' => true,
            'count' => count($artists),
            'data' => $artists
        ]);
    }
}
