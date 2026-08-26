<?php
require_once 'db.php';

$method = $_SERVER['REQUEST_METHOD'];

if ($method === 'POST') {
    $data = json_decode(file_get_contents('php://input'), true);

    $stmt = $pdo->prepare('
        INSERT INTO events 
        (title, description, category, event_date, end_date, location, venue, is_free, organizer_name, contact_email, contact_phone, tags)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ');

    $success = $stmt->execute([
        $data['title'] ?? '',
        $data['description'] ?? '',
        $data['category'] ?? '',
        $data['event_date'] ?? '',
        $data['end_date'] ?? '',
        $data['location'] ?? '',
        $data['venue'] ?? '',
        isset($data['is_free']) ? ($data['is_free'] ? 1 : 0) : 1,
        $data['organizer_name'] ?? '',
        $data['contact_email'] ?? '',
        $data['contact_phone'] ?? '',
        $data['tags'] ?? ''
    ]);

    if ($success) {
        echo json_encode([
            'success' => true,
            'message' => 'Art Event created successfully!',
            'event_id' => $pdo->lastInsertId()
        ]);
    } else {
        http_response_code(500);
        echo json_encode(['error' => 'Failed to create art event.']);
    }
} else {
    $stmt = $pdo->query('SELECT * FROM events ORDER BY id DESC');
    $events = $stmt->fetchAll();
    echo json_encode([
        'success' => true,
        'data' => $events
    ]);
}
