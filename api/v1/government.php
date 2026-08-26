<?php
require_once 'db.php';

$stmt = $pdo->query('SELECT * FROM government_entities ORDER BY id ASC');
$entities = $stmt->fetchAll();

// Format numbers and array fields
foreach ($entities as &$item) {
    $item['default_is_open'] = (bool)$item['default_is_open'];
    $item['rating'] = (float)$item['rating'];
    $item['review_count'] = (int)$item['review_count'];
    $item['open_hour'] = $item['open_hour'] !== null ? (int)$item['open_hour'] : null;
    $item['open_minute'] = $item['open_minute'] !== null ? (int)$item['open_minute'] : 0;
    $item['close_hour'] = $item['close_hour'] !== null ? (int)$item['close_hour'] : null;
    $item['close_minute'] = $item['close_minute'] !== null ? (int)$item['close_minute'] : 0;
    
    if (!empty($item['closed_days'])) {
        $item['closed_days'] = array_map('intval', explode(',', $item['closed_days']));
    } else {
        $item['closed_days'] = null;
    }
}

echo json_encode([
    'success' => true,
    'data' => $entities
]);
