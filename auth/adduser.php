<?php

// php script to add a new user to users.json

$f = __DIR__ . "/db/users.json";
$lf = __DIR__ . "/log.txt";

if ($argc < 3 || $argc > 4) {
    echo "!!! Incorrect number of arguments passed to adduser.php !!!\n";
    echo "usage > adduser.php [username] [psk]\n";
    exit(1);
}

$username = $argv[1];
$psk = $argv[2];

if (file_exists($f)) {
    echo "Db users.json already exists. Entering append mode\n";
    $content = file_get_contents($f);
    $data = json_decode($content, true);
} else {
    echo "Db users.json does not exist. Creating first user.\n";
    $data = [];
}

if (array_key_exists($username, $data)) {
    echo "Username already exists in data. Entering user change psk mode.\n";
    $endMsg = "User updated successfully\n";
    $badMsg = "User update failure\n";

} else {
    echo "Adding user to database.\n";
    $endMsg = "User added successfully\n";
    $badMsg = "User add failure\n";

}

$data[$username] = ["psk" => $psk];

$json = json_encode($data, JSON_PRETTY_PRINT);

if (file_put_contents($f, $json)) {
    echo $endMsg;
} else {
    echo $badMsg;
}

?>