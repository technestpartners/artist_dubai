<?php
header('Content-Type: application/json');

$baseUrl = 'http://localhost:8000/api/v1';

$testScenarios = [
    [
        'label' => 'POST /api/v1/bookings.php (Simulated Booking Submission)',
        'url' => $baseUrl . '/bookings.php',
        'method' => 'POST',
        'payload' => [
            'full_name' => 'Automated Load Test User',
            'email' => 'loadtest@example.com',
            'phone' => '+971501234567',
            'artist_name' => 'Fatima Al Qasimi',
            'booking_type' => 'Calligraphy Performance',
            'budget_range' => 'USD 2,000 - 5,000',
            'event_date' => '2026-10-15',
            'location' => 'Dubai Opera, Dubai',
            'description' => 'Automated stress testing booking submission.',
        ]
    ],
    [
        'label' => 'POST /api/v1/categories.php (Simulated Category Creation)',
        'url' => $baseUrl . '/categories.php',
        'method' => 'POST',
        'payload' => [
            'name' => 'Load Test Category ' . rand(1000, 9999),
            'description' => 'Automated stress test category',
            'emoji' => '⚡',
            'color' => 'Primary',
            'tags' => 'LoadTest,Performance',
            'is_featured' => 0,
        ]
    ],
    [
        'label' => 'GET /api/v1/artists.php',
        'url' => $baseUrl . '/artists.php',
        'method' => 'GET',
        'payload' => null,
    ],
    [
        'label' => 'GET /api/v1/artworks.php',
        'url' => $baseUrl . '/artworks.php',
        'method' => 'GET',
        'payload' => null,
    ],
];

$iterationsPerScenario = 50;
$overallResults = [];

foreach ($testScenarios as $scenario) {
    $startTime = microtime(true);
    $success = 0;
    $errors = 0;

    for ($i = 0; $i < $iterationsPerScenario; $i++) {
        $ch = curl_init();
        curl_setopt($ch, CURLOPT_URL, $scenario['url']);
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
        curl_setopt($ch, CURLOPT_TIMEOUT, 5);

        if ($scenario['method'] === 'POST') {
            curl_setopt($ch, CURLOPT_POST, true);
            $payload = $scenario['payload'];
            if (isset($payload['name'])) {
                $payload['name'] = $payload['name'] . ' ' . microtime(true) . ' ' . $i;
            }
            curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($payload));
            curl_setopt($ch, CURLOPT_HTTPHEADER, ['Content-Type: application/json']);
        }

        $res = curl_exec($ch);
        $code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
        curl_close($ch);

        if ($code === 200 && $res !== false) {
            $success++;
        } else {
            $errors++;
        }
    }

    $elapsed = microtime(true) - $startTime;
    $avgMs = ($elapsed / $iterationsPerScenario) * 1000;
    $rps = $iterationsPerScenario / $elapsed;

    $overallResults[$scenario['label']] = [
        'iterations' => $iterationsPerScenario,
        'success_count' => $success,
        'error_count' => $errors,
        'total_time_sec' => round($elapsed, 4),
        'avg_latency_ms' => round($avgMs, 2),
        'throughput_rps' => round($rps, 2),
    ];
}

echo json_encode([
    'status' => 'High Concurrency Stress Benchmark Completed',
    'scenarios' => $overallResults,
], JSON_PRETTY_PRINT);
