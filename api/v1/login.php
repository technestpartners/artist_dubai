<?php
require_once 'db.php';

$data = json_decode(file_get_contents('php://input'), true);

$email = $data['email'] ?? '';
$password = $data['password'] ?? '';

if (empty($email) || empty($password)) {
    http_response_code(400);
    echo json_encode(['error' => 'Email and password are required.']);
    exit();
}

$stmt = $pdo->prepare('SELECT id, full_name, email, password_hash, created_at FROM users WHERE email = ?');
$stmt->execute([$email]);
$user = $stmt->fetch();

if ($user) {
    // For demo purposes accept '12345678' or password_verify
    if ($password === '12345678' || password_verify($password, $user['password_hash'])) {
        echo json_encode([
            'success' => true,
            'message' => 'Login successful',
            'user' => [
                'id' => $user['id'],
                'full_name' => $user['full_name'],
                'email' => $user['email'],
                'created_at' => $user['created_at']
            ],
            'token' => bin2hex(random_bytes(16))
        ]);
        exit();
    }
}

http_response_code(401);
echo json_encode(['error' => 'Invalid email or password']);
