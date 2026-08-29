<?php
// Artist Dubai API Server Index / Status Endpoint
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

$acceptHeader = $_SERVER['HTTP_ACCEPT'] ?? '';

if (strpos($acceptHeader, 'text/html') !== false) {
    header("Content-Type: text/html; charset=UTF-8");
    ?>
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Artist Dubai API - Server Status</title>
        <style>
            body {
                font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
                background-color: #F8FAFC;
                color: #0F172A;
                margin: 0;
                padding: 40px 20px;
                display: flex;
                justify-content: center;
            }
            .card {
                background: #FFFFFF;
                border-radius: 16px;
                box-shadow: 0 10px 25px -5px rgba(0, 0, 0, 0.08);
                max-width: 600px;
                width: 100%;
                padding: 32px;
                border: 1px solid #E2E8F0;
            }
            .header {
                display: flex;
                align-items: center;
                gap: 12px;
                border-bottom: 2px solid #F1F5F9;
                padding-bottom: 20px;
                margin-bottom: 24px;
            }
            .badge {
                background: #DCFCE7;
                color: #15803D;
                font-weight: 700;
                font-size: 12px;
                padding: 4px 10px;
                border-radius: 20px;
                display: inline-flex;
                align-items: center;
                gap: 6px;
            }
            .badge-dot {
                width: 8px;
                height: 8px;
                background: #16A34A;
                border-radius: 50%;
            }
            h1 {
                font-size: 22px;
                margin: 0;
                color: #5E227A;
            }
            p {
                color: #64748B;
                font-size: 14px;
                line-height: 1.5;
            }
            .endpoints-title {
                font-weight: 700;
                font-size: 15px;
                margin-top: 24px;
                margin-bottom: 12px;
                color: #1E1E1E;
            }
            ul {
                list-style: none;
                padding: 0;
                margin: 0;
            }
            li {
                padding: 10px 14px;
                background: #F8FAFC;
                border: 1px solid #E2E8F0;
                border-radius: 8px;
                margin-bottom: 8px;
                display: flex;
                justify-content: space-between;
                align-items: center;
            }
            a {
                color: #5E227A;
                text-decoration: none;
                font-weight: 600;
                font-size: 13.5px;
            }
            a:hover {
                text-decoration: underline;
            }
            .method {
                font-size: 11px;
                font-weight: 800;
                background: #F3E8FF;
                color: #6A2777;
                padding: 2px 8px;
                border-radius: 4px;
            }
        </style>
    </head>
    <body>
        <div class="card">
            <div class="header">
                <div>
                    <h1>🎨 Artist Dubai REST API</h1>
                    <p style="margin: 4px 0 0 0;">Backend Database API Service Status</p>
                </div>
                <div style="margin-left: auto;">
                    <span class="badge"><span class="badge-dot"></span> Online</span>
                </div>
            </div>
            
            <p>The Artist Dubai API is running cleanly on PHP PDO database backend.</p>

            <div class="endpoints-title">Available Endpoints</div>
            <ul>
                <li>
                    <a href="artists.php" target="_blank">/api/v1/artists.php</a>
                    <span class="method">GET / POST</span>
                </li>
                <li>
                    <a href="categories.php" target="_blank">/api/v1/categories.php</a>
                    <span class="method">GET / POST</span>
                </li>
                <li>
                    <a href="events.php" target="_blank">/api/v1/events.php</a>
                    <span class="method">GET / POST</span>
                </li>
                <li>
                    <a href="bookings.php" target="_blank">/api/v1/bookings.php</a>
                    <span class="method">GET / POST</span>
                </li>
                <li>
                    <a href="government.php" target="_blank">/api/v1/government.php</a>
                    <span class="method">GET</span>
                </li>
                <li>
                    <a href="artworks.php" target="_blank">/api/v1/artworks.php</a>
                    <span class="method">GET / POST</span>
                </li>
                <li>
                    <a href="login.php" target="_blank">/api/v1/login.php</a>
                    <span class="method">POST</span>
                </li>
            </ul>
        </div>
    </body>
    </html>
    <?php
    exit();
}

header("Content-Type: application/json; charset=UTF-8");
echo json_encode([
    'status' => 'success',
    'message' => 'Artist Dubai REST API Server is running.',
    'version' => '1.0.0',
    'endpoints' => [
        'artists' => '/api/v1/artists.php',
        'categories' => '/api/v1/categories.php',
        'events' => '/api/v1/events.php',
        'bookings' => '/api/v1/bookings.php',
        'government' => '/api/v1/government.php',
        'artworks' => '/api/v1/artworks.php',
        'login' => '/api/v1/login.php'
    ]
]);
