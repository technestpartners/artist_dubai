<?php
$token = 'admin_auth_token_secure_dubai';
$endpoints = [
    'artists',
    'events',
    'galleries',
    'categories',
    'experience_levels',
    'locations',
    'artworks',
    'government',
    'notifications',
    'bookings',
    'listing_plans',
    'publishing_pricing',
    'payment_settings',
    'trash'
];

echo "=== CHECKING ALL LIVE ENDPOINTS ON HOSTINGER ===\n";
foreach ($endpoints as $ep) {
    $ch = curl_init("https://technestpartners.com/api/api.php?resource=$ep");
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_HTTPHEADER, [
        'Authorization: Bearer ' . $token,
        'Content-Type: application/json'
    ]);
    curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);
    curl_setopt($ch, CURLOPT_TIMEOUT, 10);
    $res = curl_exec($ch);
    curl_close($ch);
    $json = json_decode($res, true);
    $count = is_array($json['data'] ?? null) ? count($json['data']) : (isset($json['data']) ? 'object' : 'null');
    echo str_pad($ep, 22) . ": count = $count (status: " . ($json['status'] ?? 'err') . ")\n";
}
