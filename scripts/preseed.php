<?php
require_once('include_conf.php');
require_once('include_args.php');

header("Content-Type: text/plain");

if ($arg_os_family == 'debian')
{
    print("#_preseed_V1\n");
    print("d-i mirror/country string manual\n");
    print("d-i mirror/protocol string $conf_webserver_protocol\n");
    print("d-i mirror/http/hostname string $conf_webserver_ip\n");
    // This magic unpacked is a bit dodgy but lets leave it for now
    print("d-i mirror/http/directory string /$conf_webserver_assets_path_prefix/$arg_os_family/$arg_os_version/$os_arch/$arg_os_id/unpacked\n");
    print("d-i debian-installer/allow_unauthenticated boolean true\n");
}

?>
