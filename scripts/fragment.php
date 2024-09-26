<?php

require_once('include_conf.php');
require_once('include_args.php');

header("Content-Type: text/plain");

print("#!ipxe\n\n");

$webserver_assets_root_url = $conf_webserver_protocol . "://" . $conf_webserver_ip . "/" . $conf_webserver_assets_path_prefix;
$webserver_drivers_root_url = $conf_webserver_protocol . "://" . $conf_webserver_ip . "/" . $conf_webserver_drivers_path_prefix;

$lookup_mac = str_replace(':', '-', strtoupper($arg_os_mac));

$fragment_file_path =
                    $conf_assets_base_dir . '/' . $arg_os_family . '/' .
                    $arg_os_version . '/' . $arg_os_arch . '/' .
                    $arg_os_id . '.' . $arg_os_arch . '-' .
                    $arg_os_method . '.ipxe';

$fragment_base_url =
                   $webserver_assets_root_url . '/' . $arg_os_family . '/' .
                   $arg_os_version . '/' . $arg_os_arch . '/' . $arg_os_id;

$webserver_os_drivers_root_url =
                               $webserver_drivers_root_url . '/lookup/mac/' . $lookup_mac . '/' .
                               $arg_os_family . '/' . $arg_os_version . '/' . $arg_os_arch;


print("set os_assets_base $fragment_base_url\n");

if ($arg_os_family == 'debian')
{
    $preseed_url = $webserver_assets_root_url . '/preseed.php?method=' . $arg_os_method . "&family=" .
                 $arg_os_family . '&version=' . $arg_os_version . '&arch=' . $arg_os_arch . '&id=' . $arg_os_id .
                 "&mac=" . $arg_os_mac;
    print("set preseed_url $preseed_url\n");
}
if ($arg_os_family == 'windows')
{
    $template_base = $webserver_assets_root_url . '/' . $arg_os_family . '/' . 'template' . '/' . $arg_os_arch;

    print("set template_base $template_base\n");

    $startnet_url = $webserver_assets_root_url . '/startnet.php?method=' . $arg_os_method . "&family=" .
                  $arg_os_family . '&version=' . $arg_os_version . '&arch=' . $arg_os_arch . '&id=' . $arg_os_id .
                  "&mac=" . $arg_os_mac;
    print("set startnet_url $startnet_url\n");
}
$fragment_core_data = file_get_contents($fragment_file_path);

print($fragment_core_data);

// Need to print drivers as initrds if drivers dir is in use for windows
if (($arg_os_family == 'windows') && ($conf_drivers_base_dir != "") && (is_dir($conf_drivers_base_dir)))
{
    $os_drivers_dir =
                    $conf_drivers_base_dir . '/lookup/mac/' .
                    $lookup_mac . '/' . $arg_os_family . '/' .
                    $arg_os_version . '/' . $arg_os_arch;

    if (is_dir($os_drivers_dir))
    {
        $driver_file_iterator = new RecursiveIteratorIterator(new RecursiveDirectoryIterator($os_drivers_dir));

        foreach ($driver_file_iterator as $driver_file)
        {
            if ((basename($driver_file) != '.') && (basename($driver_file) != '..'))
            {
                // Here we have something like /opt/drivers/windows/10/x64/Broadcom_Nextreme_64bit/b57nd60a.inf
                // Need to convert it to this:
                // initrd http://172.16.8.254/drivers/windows/10/x64/Broadcom_Nextreme_64bit/b57nd60a.inf b57nd60a.inf
                
                $driver_sub_path = str_replace($os_drivers_dir . '/', '', $driver_file);
                $driver_url = $webserver_os_drivers_root_url . '/' . $driver_sub_path;
                $driver_file_name = basename($driver_sub_path);
                print("initrd $driver_url $driver_file_name\n");
            }
        }
    }
}


print("boot\nsleep 5\n");
?>
