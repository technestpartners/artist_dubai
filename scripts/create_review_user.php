<?php

$email = 'allenbaiyee@gmail.com';
$password = '#1q2w3e4r!';
$name = 'Allen Baiyee';
$role = 'user';

echo "=== 1. Checking / Creating user via Live API ===\n";

$url = 'https://technestpartners.com/api/api.php?resource=register';
$data = json_encode([
    'name' => $name,
    'full_name' => $name,
    'email' => $email,
    'password' => $password,
    'role' => $role
]);

$ch = curl_init($url);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_POST, true);
curl_setopt($ch, CURLOPT_POSTFIELDS, $data);
curl_setopt($ch, CURLOPT_HTTPHEADER, [
    'Content-Type: application/json',
    'Accept: application/json'
]);
curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);
$response = curl_exec($ch);
$httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
curl_close($ch);

echo "Register HTTP Code: $httpCode\n";
echo "Register Response: $response\n\n";

// Now test Login on Live API
echo "=== 2. Testing Login on Live API ===\n";
$loginUrl = 'https://technestpartners.com/api/api.php?resource=login';
$loginData = json_encode([
    'email' => $email,
    'password' => $password
]);

$ch = curl_init($loginUrl);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_POST, true);
curl_setopt($ch, CURLOPT_POSTFIELDS, $loginData);
curl_setopt($ch, CURLOPT_HTTPHEADER, [
    'Content-Type: application/json',
    'Accept: application/json'
]);
curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);
$loginResponse = curl_exec($ch);
$loginCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
curl_close($ch);

echo "Login HTTP Code: $loginCode\n";
echo "Login Response: $loginResponse\n\n";

// 3. Also check local database if running
echo "=== 3. Checking Local Database ===\n";
try {
    $pdo = new PDO("mysql:host=127.0.0.1;dbname=artist_dubai;charset=utf8mb4", 'root', '', [
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC
    ]);
    
    $hash = password_hash($password, PASSWORD_BCRYPT);
    $stmt = $pdo->prepare("SELECT id FROM users WHERE email = ?");
    $stmt->execute([$email]);
    $existing = $stmt->fetch();
    
    if ($existing) {
        $update = $pdo->prepare("UPDATE users SET password_hash = ?, full_name = ?, role = ? WHERE email = ?");
        $update->execute([$hash, $name, $role, $email]);
        echo "Local DB: Updated user {$email} (ID: {$existing['id']})\n";
    } else {
        $insert = $pdo->prepare("INSERT INTO users (full_name, email, password_hash, role) VALUES (?, ?, ?, ?)");
        $insert->execute([$name, $email, $hash, $role]);
        $newId = $pdo->lastInsertId();
        echo "Local DB: Inserted user {$email} (ID: {$newId})\n";
    }
} catch (Exception $e) {
    echo "Local DB Note: " . $e->getMessage() . "\n";
}
