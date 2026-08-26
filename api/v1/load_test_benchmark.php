<?php
header('Content-Type: application/json');

$endpoints = [
    'GET /api/v1/artists.php' => 'http://localhost:8000/api/v1/artists.php',
    'GET /api/v1/categories.php' => 'http://localhost:8000/api/v1/categories.php',
    'GET /api/v1/artworks.php' => 'http://localhost:8000/api/v1/artworks.php',
    'GET /api/v1/events.php' => 'http://localhost:8000/api/v1/events.php',
    'GET /api/v1/government.php' => 'http://localhost:8000/api/v1/government.php',
];

$results = [];
$totalIterations = 50;

foreach ($endpoints as $label => $url) {
    $startTime = microtime(true);
    $successCount = 0;
    $bytesReceived = 0;

    for ($i = 0; $i < $totalIterations; $i++) {
        $ch = curl_init();
        curl_setopt($ch, CURLOPT_URL, $url);
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
        curl_setopt($ch, CURLOPT_TIMEOUT, 5);
        $response = curl_exec($ch);
        $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
        curl_close($ch);

        if ($httpCode === 200 && $response !== false) {
            $successCount++;
            $bytesReceived += strlen($response);
        }
    }

    $endTime = microtime(true);
    $totalTime = $endTime - $startTime;
    $avgLatencyMs = ($totalTime / $totalIterations) * 1000;
    $rps = $totalIterations / $totalTime;

    $results[$label] = [
        'total_requests' => $totalIterations,
        'successful_requests' => $successCount,
        'failed_requests' => $totalIterations - $successCount,
        'total_time_seconds' => round($totalTime, 4),
        'avg_latency_ms' => round($avgLatencyMs, 2),
        'requests_per_second' => round($rps, 2),
        'total_bytes_transferred' => $bytesReceived,
    ];
}

echo json_encode(['status' => 'Benchmark Completed', 'metrics' => $results], JSON_PRETTY_PRINT);
