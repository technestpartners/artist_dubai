<?php
function testQuery($msg) {
    $url = 'https://technestpartners.com/api/api.php?resource=ai_chat';
    $ch = curl_init($url);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_POST, true);
    curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode([
        'action' => 'send',
        'message' => $msg,
        'locale' => 'en'
    ]));
    curl_setopt($ch, CURLOPT_HTTPHEADER, [
        'Content-Type: application/json'
    ]);
    curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);
    $res = curl_exec($ch);
    curl_close($ch);
    $data = json_decode($res, true);
    echo "Query: $msg\n";
    echo "Reply:\n" . ($data['data']['ai_reply'] ?? 'ERROR: ' . $res) . "\n\n";
}

testQuery("Tell me about calligraphy in Dubai");
testQuery("Hello");
testQuery("How can I book an artist?");
