<?php

// function dump($var)
// {
//     ob_start();
//     var_dump($var);
//     return ob_get_clean();
// }

// file_put_contents(__DIR__ . "/debug.txt", dump($_POST), FILE_APPEND);
// file_put_contents(__DIR__ . "/debug.txt", dump($_GET), FILE_APPEND);

class AuthHandler {

    public function __construct($users) {
        $this->users = $users;
        $this->logFile = __DIR__ . "/log.txt";
    }

    protected function log($msg){
        file_put_contents($this->logFile, $msg . "\n", FILE_APPEND);
    }

    protected function getSwfUrl() {
        if (! isset($_POST["swfurl"])) {
            return "";
        }
        // $this->log("geting swfurl " . $_POST["swfurl"]);
        return $_POST["swfurl"];
    }
    
    protected function getFromSwfUrl($key) {
        $swfUrl = $this->getSwfUrl();
        if (strlen($swfUrl) < strlen($key) + 3) {
            $this->log("swfurl was less than required to parse out key " . $key);
            return "";
        }
        if (strpos($swfUrl, "?") === false) {
            $this->log("swfurl did not have any arguments/parameters");
            return "";
        }

        $swfUrlParamString = explode("?", $swfUrl)[1];
        // $this->log("Parsing swfurl: " . $swfUrlParamString);
    
        parse_str($swfUrlParamString, $extraParams);
        
        if (! array_key_exists($key, $extraParams)) {
            $this->log("parsed swfurl did not contain key " . $key);
            return "";
        }
        return $extraParams[$key];
    }
    protected function getUsername() {
        $username = $this->getFromSwfUrl("username");
        if (strlen($username) < 1) {
            $this->log("No username submitted in data in URL");
            return "";
        }
        return $username;
    }

    protected function getPsk() {
        $psk = $this->getFromSwfUrl("psk");
        if (strlen($psk) < 1) {
            $this->log("No psk ('name') submitted in data");
            return "";
        }
        return $psk;
    }

    public function run() {
        $username = $this->getUsername();
        if (! array_key_exists($username, $this->users)) {
            $this->log("Username " . $username . " not found in users db");
            return $this->failure();
        }
        $this->log("Attempting authentication for " . $username);
        $candidate = $this->getPsk();
        $psk = $this->users[$username]["psk"];
        if ($candidate !== $psk) {
            $this->log("Candidate does not match psk");
            return $this->failure();
        }
        $this->log("Authentication success for " . $username);
        return $this->success();
    }

    public function success() {
        http_response_code(201);
        return true;
    }

    public function failure() {
        http_response_code(404);
        return false;
    }
}
?>
