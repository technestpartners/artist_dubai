<?php
require_once 'db.php';

$method = $_SERVER['REQUEST_METHOD'];

if ($method === 'POST') {
    $data = json_decode(file_get_contents('php://input'), true) ?? $_POST;

    $fullName = trim(htmlspecialchars($data['full_name'] ?? $data['attendeeName'] ?? '', ENT_QUOTES, 'UTF-8'));
    $email = trim(filter_var($data['email'] ?? $data['attendeeEmail'] ?? '', FILTER_SANITIZE_EMAIL));
    $phone = trim(htmlspecialchars($data['phone'] ?? $data['attendeePhone'] ?? '', ENT_QUOTES, 'UTF-8'));
    $artistName = trim(htmlspecialchars($data['artist_name'] ?? '', ENT_QUOTES, 'UTF-8'));
    $bookingType = trim(htmlspecialchars($data['booking_type'] ?? 'Artist Hire', ENT_QUOTES, 'UTF-8'));
    $budgetRange = trim(htmlspecialchars($data['budget_range'] ?? '', ENT_QUOTES, 'UTF-8'));
    $eventDate = trim(htmlspecialchars($data['event_date'] ?? '', ENT_QUOTES, 'UTF-8'));
    $endDate = trim(htmlspecialchars($data['end_date'] ?? '', ENT_QUOTES, 'UTF-8'));
    $location = trim(htmlspecialchars($data['location'] ?? 'Dubai, UAE', ENT_QUOTES, 'UTF-8'));
    $description = trim(htmlspecialchars($data['description'] ?? '', ENT_QUOTES, 'UTF-8'));
    $requirements = trim(htmlspecialchars($data['requirements'] ?? '', ENT_QUOTES, 'UTF-8'));

    if (empty($fullName) || empty($email)) {
        http_response_code(400);
        echo json_encode(['status' => 'error', 'success' => false, 'message' => 'Full name and email are required.']);
        exit();
    }

    $stmt = $pdo->prepare('
        INSERT INTO bookings 
        (full_name, email, phone, artist_name, booking_type, budget_range, event_date, end_date, location, description, requirements)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ');

    $success = $stmt->execute([
        $fullName,
        $email,
        $phone,
        $artistName,
        $bookingType,
        $budgetRange,
        $eventDate,
        $endDate,
        $location,
        $description,
        $requirements
    ]);

    if ($success) {
        http_response_code(201);
        echo json_encode([
            'status' => 'success',
            'success' => true,
            'message' => 'Booking request submitted successfully!',
            'booking_id' => (int)$pdo->lastInsertId()
        ]);
    } else {
        http_response_code(500);
        echo json_encode(['status' => 'error', 'success' => false, 'message' => 'Failed to save booking request.']);
    }
} else {
    $email = $_GET['email'] ?? null;
    if ($email) {
        $stmt = $pdo->prepare('SELECT * FROM bookings WHERE email = ? ORDER BY id DESC');
        $stmt->execute([$email]);
        $bookings = $stmt->fetchAll();
    } else {
        $stmt = $pdo->query('SELECT * FROM bookings ORDER BY id DESC');
        $bookings = $stmt->fetchAll();
    }

    echo json_encode([
        'status' => 'success',
        'success' => true,
        'count' => count($bookings),
        'data' => $bookings
    ]);
}
