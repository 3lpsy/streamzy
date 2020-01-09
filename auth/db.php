<?php

$f = __DIR__ . "/db/users.json";
$lf = __DIR__ . "/log.txt";

if (! file_exists($f)) {
    $f = __DIR__ . "/db/example.json";
    file_put_contents($lf, "!! Using example file. Please set unique values for authentication !!" . "\n", FILE_APPEND);
}

$data = file_get_contents($f);

if (array_count_values(array_keys($data)) < 0) {
    $f = __DIR__ . "/db/example.json";
    $data = file_get_contents($f);
    file_put_contents($lf, "!! No users found in users.json !!" . "\n", FILE_APPEND);
    file_put_contents($lf, "!! Using example file. Please set unique values for authentication !!" . "\n", FILE_APPEND);
}

$USERS = json_decode($data, true);

?>
