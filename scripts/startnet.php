<?php
require_once('include_conf.php');
require_once('include_args.php');

header("Content-Type: text/dos");

// Assuming this is always windows

print("wpeinit\n");
$os_cifs_path =
              '\\\\' . $main_conf_db['CIFS_SERVER_IP'] . '\\' . $arg_os_family . '\\' .
              $arg_os_arch . '\\' . $arg_os_id;

$os_cifs_path =
              "\\\\$conf_cifs_server_ip\\$conf_cifs_share_name\\$arg_os_family" .
              "\\$arg_os_version\\$arg_os_arch\\$arg_os_id\\unpacked";

$os_cifs_auth_string = "";

if (strlen($conf_cifs_user) > 0)
{
    $os_cifs_auth_string .= "/user:$conf_cifs_user";
}
if (strlen($conf_cifs_passwd) > 0)
{
    $os_cifs_auth_string .= " $conf_cifs_passwd";
}

print("net use j: $os_cifs_path $os_cifs_auth_string\n");
print("j:\\setup.exe\n");
print("pause\n");


?>
