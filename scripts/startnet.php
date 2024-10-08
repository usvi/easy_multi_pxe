<?php
require_once('include_conf.php');
require_once('include_args.php');

header("Content-Type: text/dos");

// Assuming this is always windows

$lookup_mac = str_replace(':', '-', strtoupper($arg_os_mac));

$os_cifs_path =
              '\\\\' . $main_conf_db['CIFS_SERVER_IP'] . '\\' . $arg_os_family . '\\' .
              $arg_os_arch . '\\' . $arg_os_id;

$os_cifs_path =
              "\\\\$conf_cifs_server_ip\\$conf_cifs_share_name\\$arg_os_family" .
              "\\$arg_os_version\\$arg_os_arch\\$arg_os_id\\unpacked";

$os_cifs_auth_string = "";

if (strlen($conf_cifs_user) > 0)
{
    $os_cifs_auth_string .= " /user:$conf_cifs_user";
}
if (strlen($conf_cifs_passwd) > 0)
{
    $os_cifs_auth_string .= " $conf_cifs_passwd";
}


$driver_inf_files_array = array();

if (($conf_drivers_base_dir != "") && (is_dir($conf_drivers_base_dir)))
{
    $os_drivers_dir = $conf_drivers_base_dir . '/lookup/mac/' . $lookup_mac . '/' . $arg_os_family . '/' . $arg_os_version . '/' . $arg_os_arch;

    if (is_dir($os_drivers_dir))
    {
        $driver_file_iterator = new RecursiveIteratorIterator(new RecursiveDirectoryIterator($os_drivers_dir));

        foreach ($driver_file_iterator as $driver_file)
        {
            if ($driver_file->getExtension() == "inf")
            {
                $driver_inf_files_array[] = $driver_file->getFilename();
            }
        }
    }
}

if (count($driver_inf_files_array) > 0)
{
    print("echo Loading extra drivers...\n");

    foreach($driver_inf_files_array as $driver_inf_file)
    {
        print("drvload " . $driver_inf_file . "\n");
    }
}

print("wpeinit\n");
print("net use j: $os_cifs_path$os_cifs_auth_string\n");
print("j:\\setup.exe /noreboot\n");

if (count($driver_inf_files_array) > 0)
{
    print("echo Saving extra drivers to new installation...\n");

    print("@echo off\n");
    print("for %%X in (C D E F G H I J K L M N O P Q R S T U V W Y Z) DO (\n");
    print("    if EXIST %%X:\\\$WINDOWS.~BT\\ SET INDRIVE=%%X\n");
    print(")\n");

    foreach($driver_inf_files_array as $driver_inf_file)
    {
        print("dism /Image:%INDRIVE%:\\ /Add-Driver /Driver:$driver_inf_file\n");
    }
    print("echo on\n");
}

print("@timeout 5 \n");
print("@exit\n");


?>
