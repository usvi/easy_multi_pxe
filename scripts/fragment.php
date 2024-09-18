<?php

require_once('include_conf.php');
require_once('include_args.php');

header("Content-Type: text/plain");

$fragment_file_path =
                    $assets_prefix_dir . '/' . $os_family . '/' . $os_version . '/' . $os_arch . '/' . $os_id .
                    $fragment_base_path . '.' . $os_arch . '-' . $os_method . '.ipxe';
$fragment_base_url =
                   $webserver_root_url . '/' . $os_family . '/' . $os_version . '/' . $os_arch . '/' . $os_id;

print("set http_base $fragment_base_url\n");

if ($os_family == 'debian')
{
    $preseed_url = $webserver_root_url . '/preseed.php&method=' . $os_method . "&family=" .
                 $os_family . '&version=' . $os_version . '&arch=' . $os_arch . '&id=' . $os_id;
    print("set preseed_url $preseed_url\n");
}
$fragment_core_data = file_get_contents($fragment_file_path);

print($fragment_core_data);

?>
