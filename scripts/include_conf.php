<?php
$main_conf_path = dirname(__FILE__, 2) . "/conf/easy_multi_pxe.conf";
// /netbootassets is "hardcoded" because directory is enforced (exists in git)
$conf_assets_base_dir = dirname(__FILE__, 2) . "/netbootassets";

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

$conf_webserver_protocol = '';
$conf_webserver_ip = '';
$conf_webserver_assets_path_prefix = '';
$conf_drivers_base_dir = '';
$conf_webserver_drivers_path_prefix = '';
$conf_cifs_server_ip = '';
$conf_cifs_share_name = '';
$conf_cifs_user = '';
$conf_cifs_passwd = '';

if (array_key_exists('WEBSERVER_PROTOCOL', $main_conf_db))
{
    $conf_webserver_protocol =  $main_conf_db['WEBSERVER_PROTOCOL'];
}
if (array_key_exists('WEBSERVER_IP', $main_conf_db))
{
    $conf_webserver_ip =  $main_conf_db['WEBSERVER_IP'];
}
if (array_key_exists('WEBSERVER_ASSETS_PATH_PREFIX', $main_conf_db))
{
    $conf_webserver_assets_path_prefix =  $main_conf_db['WEBSERVER_ASSETS_PATH_PREFIX'];
}
if (array_key_exists('DRIVERS_BASE_DIR', $main_conf_db))
{
    $conf_drivers_base_dir =  $main_conf_db['DRIVERS_BASE_DIR'];
}
if (array_key_exists('WEBSERVER_DRIVERS_PATH_PREFIX', $main_conf_db))
{
    $conf_webserver_drivers_path_prefix =  $main_conf_db['WEBSERVER_DRIVERS_PATH_PREFIX'];
}
if (array_key_exists('CIFS_SERVER_IP', $main_conf_db))
{
    $conf_cifs_server_ip =  $main_conf_db['CIFS_SERVER_IP'];
}
if (array_key_exists('CIFS_SHARE_NAME', $main_conf_db))
{
    $conf_cifs_share_name =  $main_conf_db['CIFS_SHARE_NAME'];
}
if (array_key_exists('CIFS_USER', $main_conf_db))
{
    $conf_cifs_user =  $main_conf_db['CIFS_USER'];
}
if (array_key_exists('CIFS_PASSWD', $main_conf_db))
{
    $conf_cifs_passwd =  $main_conf_db['CIFS_PASSWD'];
}


?>
