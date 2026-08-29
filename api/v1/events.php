<?php
require_once 'db.php';

$method = $_SERVER['REQUEST_METHOD'];

if ($method === 'POST') {
    $data = json_decode(file_get_contents('php://input'), true) ?? $_POST;

    $title = trim(htmlspecialchars($data['title'] ?? '', ENT_QUOTES, 'UTF-8'));
    $description = trim(htmlspecialchars($data['description'] ?? '', ENT_QUOTES, 'UTF-8'));
    $category = trim(htmlspecialchars($data['category'] ?? 'Art Workshop', ENT_QUOTES, 'UTF-8'));
    $eventDate = trim(htmlspecialchars($data['event_date'] ?? $data['dateTime'] ?? '', ENT_QUOTES, 'UTF-8'));
    $endDate = trim(htmlspecialchars($data['end_date'] ?? '', ENT_QUOTES, 'UTF-8'));
    $location = trim(htmlspecialchars($data['location'] ?? 'Dubai, UAE', ENT_QUOTES, 'UTF-8'));
    $venue = trim(htmlspecialchars($data['venue'] ?? '', ENT_QUOTES, 'UTF-8'));
    $isFree = isset($data['is_free']) ? ($data['is_free'] ? 1 : 0) : 1;
    $organizer = trim(htmlspecialchars($data['organizer_name'] ?? $data['organizer'] ?? 'Nizar Fahem', ENT_QUOTES, 'UTF-8'));
    $contactEmail = trim(filter_var($data['contact_email'] ?? $data['organizerEmail'] ?? 'nizar@artistdubai.com', FILTER_SANITIZE_EMAIL));
    $contactPhone = trim(htmlspecialchars($data['contact_phone'] ?? '', ENT_QUOTES, 'UTF-8'));
    $tags = is_array($data['tags'] ?? null) ? implode(',', $data['tags']) : trim(htmlspecialchars($data['tags'] ?? '', ENT_QUOTES, 'UTF-8'));

    if (empty($title)) {
        http_response_code(400);
        echo json_encode(['status' => 'error', 'success' => false, 'message' => 'Event title is required.']);
        exit();
    }

    $stmt = $pdo->prepare('
        INSERT INTO events 
        (title, description, category, event_date, end_date, location, venue, is_free, organizer_name, contact_email, contact_phone, tags)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ');

    $success = $stmt->execute([
        $title,
        $description,
        $category,
        $eventDate,
        $endDate,
        $location,
        $venue,
        $isFree,
        $organizer,
        $contactEmail,
        $contactPhone,
        $tags
    ]);

    if ($success) {
        http_response_code(201);
        echo json_encode([
            'status' => 'success',
            'success' => true,
            'message' => 'Art Event created successfully!',
            'event_id' => (int)$pdo->lastInsertId()
        ]);
    } else {
        http_response_code(500);
        echo json_encode(['status' => 'error', 'success' => false, 'message' => 'Failed to create art event.']);
    }
} else {
    $id = $_GET['id'] ?? null;
    $category = $_GET['category'] ?? null;
    $search = $_GET['search'] ?? null;

    if ($id) {
        $stmt = $pdo->prepare('SELECT * FROM events WHERE id = ?');
        $stmt->execute([$id]);
        $event = $stmt->fetch();
        if ($event) {
            echo json_encode(['status' => 'success', 'success' => true, 'data' => $event]);
        } else {
            http_response_code(404);
            echo json_encode(['status' => 'error', 'success' => false, 'message' => 'Event not found.']);
        }
    } else {
        $sql = 'SELECT * FROM events WHERE 1=1';
        $params = [];

        if ($category) {
            $sql .= ' AND category LIKE ?';
            $params[] = '%' . $category . '%';
        }

        if ($search) {
            $sql .= ' AND (title LIKE ? OR description LIKE ? OR location LIKE ?)';
            $params[] = '%' . $search . '%';
            $params[] = '%' . $search . '%';
            $params[] = '%' . $search . '%';
        }

        $sql .= ' ORDER BY id DESC';
        $stmt = $pdo->prepare($sql);
        $stmt->execute($params);
        $events = $stmt->fetchAll();

        echo json_encode([
            'status' => 'success',
            'success' => true,
            'count' => count($events),
            'data' => $events
        ]);
    }
}
