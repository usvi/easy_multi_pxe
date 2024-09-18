<?php
require_once('include_conf.php');
require_once('include_args.php');

header("Content-Type: text/plain");

if ($os_family == 'debian')
{
    print("#_preseed_V1\n");
    print("d-i mirror/country string manual\n");
    print("d-i mirror/protocol string $webserver_protocol\n");
    print("d-i mirror/http/hostname string $webserver_ip\n");
    // This magic unpacked is a bit dodgy but lets leave it for now
    print("d-i mirror/http/directory string /$webserver_path_prefix/$os_family/$os_version/$os_arch/$os_id/unpacked\n");
    print("d-i debian-installer/allow_unauthenticated boolean true\n");
}

?>
