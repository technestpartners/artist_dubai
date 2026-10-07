<?php
$token = "019a086200f8a3e200457f36313e8288a451741fe0d2e60dc9ebe2f8e76c5928";
$url = "https://technestpartners.com/api/api.php?resource=login&action=profile";
$ch = curl_init($url);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_HTTPHEADER, ["Authorization: Bearer $token"]);
curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);
$res = curl_exec($ch);
curl_close($ch);
echo "PROFILE RESULT:\n$res\n";
