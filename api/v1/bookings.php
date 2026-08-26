<?php
require_once 'db.php';

$method = $_SERVER['REQUEST_METHOD'];

if ($method === 'POST') {
    $data = json_decode(file_get_contents('php://input'), true);

    $stmt = $pdo->prepare('
        INSERT INTO bookings 
        (full_name, email, phone, artist_name, booking_type, budget_range, event_date, end_date, location, description, requirements)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ');

    $success = $stmt->execute([
        $data['full_name'] ?? '',
        $data['email'] ?? '',
        $data['phone'] ?? '',
        $data['artist_name'] ?? '',
        $data['booking_type'] ?? '',
        $data['budget_range'] ?? '',
        $data['event_date'] ?? '',
        $data['end_date'] ?? '',
        $data['location'] ?? '',
        $data['description'] ?? '',
        $data['requirements'] ?? ''
    ]);

    if ($success) {
        echo json_encode([
            'success' => true,
            'message' => 'Booking request submitted successfully!',
            'booking_id' => $pdo->lastInsertId()
        ]);
    } else {
        http_response_code(500);
        echo json_encode(['error' => 'Failed to save booking request.']);
    }
} else {
    $stmt = $pdo->query('SELECT * FROM bookings ORDER BY id DESC');
    $bookings = $stmt->fetchAll();
    echo json_encode([
        'success' => true,
        'data' => $bookings
    ]);
}
