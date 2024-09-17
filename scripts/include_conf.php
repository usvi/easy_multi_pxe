<?php
$main_conf_path = dirname(__FILE__, 2) . "/conf/easy_multi_pxe.conf";
// /netbootassets is "hardcoded" because directory is enforced (exists in git)
$assets_prefix_dir = dirname(__FILE__, 2) . "/netbootassets";

$main_conf_db = [];

$main_conf_file = fopen($main_conf_path, "r");

while(($main_conf_file !== false) && !feof($main_conf_file))
{
    $line = trim(fgets($main_conf_file));
    $line_parts = explode("=", $line, 2);

    if (count($line_parts) === 2)
    {
        $main_conf_db[$line_parts[0]] = $line_parts[1];
    }
}
fclose($main_conf_file);


# Helper variables
$webserver_root_url = "";
$webserver_root_url .= $main_conf_db['WEBSERVER_PROTOCOL'] . "://";
$webserver_root_url .= $main_conf_db['WEBSERVER_IP'] . "/";
$webserver_root_url .= $main_conf_db['WEBSERVER_PATH_PREFIX'];
?>
