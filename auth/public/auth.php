<?php

require_once(__DIR__.'/../handler.php');
require_once(__DIR__.'/../db.php');

$handler = new AuthHandler($USERS);

return $handler->run();

?>
