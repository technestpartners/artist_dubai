<?php
$zipFile = __DIR__ . '/../artist_dubai_api_hostinger.zip';
if (file_exists($zipFile)) {
    unlink($zipFile);
}

$zip = new ZipArchive();
if ($zip->open($zipFile, ZipArchive::CREATE | ZipArchive::OVERWRITE) !== true) {
    die("Failed to create ZIP archive\n");
}

$files = [
    '.htaccess' => '.htaccess',
    'api.php' => 'api.php',
    'index.php' => 'index.php',
    'api/.htaccess' => 'api/.htaccess',
    'api/api.php' => 'api/api.php',
    'api/index.php' => 'api/index.php',
    'api/uploads/.htaccess' => 'api/uploads/.htaccess',
    'api/v1/.htaccess' => 'api/v1/.htaccess',
    'api/v1/api.php' => 'api/v1/api.php',
    'api/v1/uploads/.htaccess' => 'api/v1/uploads/.htaccess',
];

$baseDir = realpath(__DIR__ . '/..');

foreach ($files as $zipPath => $localPath) {
    $fullPath = $baseDir . DIRECTORY_SEPARATOR . str_replace('/', DIRECTORY_SEPARATOR, $localPath);
    if (file_exists($fullPath)) {
        $zip->addFile($fullPath, $zipPath);
        echo "Added: $zipPath\n";
    } else {
        echo "WARNING: File not found: $fullPath\n";
    }
}

$zip->close();
echo "Successfully created " . basename($zipFile) . " (Size: " . filesize($zipFile) . " bytes)\n";
