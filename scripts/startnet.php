<?php
require_once('include_conf.php');
require_once('include_args.php');

header("Content-Type: text/dos");

// Assuming this is always windows

print("wpeinit\n");
$os_cifs_path = '\\\\' . $main_conf_db['CIFS_SERVER_IP'] . '\\' . $os_family . '\\' .
              $os_arch . '\\' . $os_id;

//print("$os_cifs_path\n");
$os_cifs_password_string = "";

if ((strlen($main_conf_db['CIFS_USER']) > 0) && (strlen($main_conf_db['CIFS_PASSWD'])))
{
    $os_cifs_password_string = '/user:' . $main_conf_db['CIFS_USER'] . ' ' . $main_conf_db['CIFS_PASSWD'];
}

print("net use j: $os_cifs_path $os_cifs_password_string\n");
print("j:\\setup.exe\n");
print("pause\n");


?>
