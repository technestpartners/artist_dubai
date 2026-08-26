<?php
require_once __DIR__ . '/db.php';

$method = $_SERVER['REQUEST_METHOD'];

if ($method === 'GET') {
    try {
        $stmt = $pdo->query("SELECT * FROM categories ORDER BY is_featured DESC, name ASC");
        $categories = $stmt->fetchAll();
        echo json_encode(['success' => true, 'data' => $categories]);
    } catch (\Exception $e) {
        http_response_code(500);
        echo json_encode(['success' => false, 'error' => $e->getMessage()]);
    }
} elseif ($method === 'POST') {
    $input = json_decode(file_get_contents('php://input'), true);

    $name = trim($input['name'] ?? '');
    $description = trim($input['description'] ?? '');
    $emoji = trim($input['emoji'] ?? '🎨');
    $color = trim($input['color'] ?? 'Primary');
    $tags = trim($input['tags'] ?? '');
    $is_featured = !empty($input['is_featured']) ? 1 : 0;

    if (empty($name)) {
        http_response_code(400);
        echo json_encode(['success' => false, 'error' => 'Category name is required.']);
        exit();
    }

    try {
        $stmt = $pdo->prepare("
            INSERT INTO categories (name, description, emoji, color, tags, is_featured)
            VALUES (:name, :description, :emoji, :color, :tags, :is_featured)
        ");
        $stmt->execute([
            ':name' => $name,
            ':description' => $description,
            ':emoji' => $emoji,
            ':color' => $color,
            ':tags' => $tags,
            ':is_featured' => $is_featured,
        ]);

        $newId = $pdo->lastInsertId();
        echo json_encode(['success' => true, 'message' => 'Category created successfully.', 'id' => $newId]);
    } catch (\Exception $e) {
        http_response_code(500);
        echo json_encode(['success' => false, 'error' => $e->getMessage()]);
    }
}
