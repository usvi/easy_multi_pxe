<?php
header('Content-Type: text/plain');
?>
#!ipxe

<?php
$main_conf_path = dirname(__FILE__, 2) . "/conf/easy_multi_pxe.conf";
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

//print_r($main_conf_db);

# Find all submenus. Lots of esoteric stuff here.

$id_lookups = [];
$submenus = [];
$submenu_names = [];

//print("$assets_prefix_dir\n");
$emp_platform_to_ipxe_native_platform = array(
    "32bit-bios" => "i386_pcbios",
    "32bit-efi" => "i386_efi",
    "64bit-bios" => "x86_64_pcbios",
    "64bit-efi" => "x86_64_efi");

$native_platform_names = array(
    "i386_pcbios" => "iPXE 32bit BIOS boot menu",
    "i386_efi" => "iPXE 32bit EFI boot menu",
    "x86_64_pcbios" => "iPXE 64bit BIOS boot menu",
    "x86_64_efi" => "iPXE 64bit EFI boot menu");
    
$default_entries = array(
    "reboot" => array("Reboot computer",
                      "reboot\n" .
                      "sleep 5\n" .
                      "goto end\n")
);
                      

$ipxe_fragment_iterator = new RecursiveIteratorIterator(new RecursiveDirectoryIterator($assets_prefix_dir));
$ipxe_fragment_iterator->setMaxDepth(3);

foreach ($ipxe_fragment_iterator as $ipxe_file_candidate)
{
    
    if ($ipxe_file_candidate->getExtension() === "ipxe")
    {
        
        list($path_with_os_label_id, $emp_platform, $ipxe_suffix) = explode(".", $ipxe_file_candidate);
        
        if (array_key_exists($emp_platform, $emp_platform_to_ipxe_native_platform))
        {
            $os_label_id = basename($path_with_os_label_id);
            $os_family = basename(dirname($path_with_os_label_id, 3));
            $os_ipxe_native_platform = $emp_platform_to_ipxe_native_platform[$emp_platform];
            $os_family_menu_label_id = "collection_" . $os_ipxe_native_platform . "-" . $os_family;
            //print("BBB " . $os_label_id . " " . $os_family_menu_label_id . "\n");

            $id_lookups[$os_family_menu_label_id] = ucfirst($os_family);
            $id_lookups[$os_label_id] = str_replace("_", " ", $os_label_id);

            if (!array_key_exists($os_ipxe_native_platform, $submenus))
            {
                $submenus[$os_ipxe_native_platform] = [];
            }
            if (!array_key_exists($os_family_menu_label_id, $submenus[$os_ipxe_native_platform]))
            {
                $submenus[$os_ipxe_native_platform][$os_family_menu_label_id] = [];
            }
            $submenus[$os_ipxe_native_platform][$os_family_menu_label_id][$os_label_id] = file_get_contents($ipxe_file_candidate);
        }
    }
}
//print_r($fragments_x86_64_pcbios);
//print_r($fragments_x86_64_efi);
//print($fragments_x86_64_efi["Win10_21H1_English_x64_2021-10-09"]);
//print_r($submenus);
//exit(0);
?>

cpuid --ext 29 && set arch x86_64 || set arch i386

# arch = i386 or x86_64
# platform = pcbios or efi

goto arch_platform_${arch}_${platform}



<?php

foreach($submenus as $os_ipxe_native_platform => $os_family_menu_label_id)
{
    print("# Main arch platform menu\n");
    print(":arch_platform_" . $os_ipxe_native_platform . "\n");
    print("menu " . $native_platform_names[$os_ipxe_native_platform] . "\n");

    foreach($default_entries as $entry_suffix => $entry_contents)
    {
        print("item " . "target_" . $os_ipxe_native_platform . "-" . $entry_suffix . " " . $entry_contents[0] . "\n");
    }
    foreach($submenus[$os_ipxe_native_platform] as $os_family_menu_label_id => $os_family_ipxe_entries)
    {
        print("item " . $os_family_menu_label_id . " " . $id_lookups[$os_family_menu_label_id] . "\n");
    }
    print("\n");
    print("choose selected\n");
    print("set menu-timeout 0\n");
    print("goto \${selected}\n");
    print("\n");

    foreach($default_entries as $entry_suffix => $entry_contents)
    {
        print(":" . "target_" . $os_ipxe_native_platform . "-" . $entry_suffix . "\n");
        print($entry_contents[1] . "\n");
    }
    print("\n");
    print("# Submenu\n");
    foreach($submenus[$os_ipxe_native_platform] as $os_family_menu_label_id => $os_family_ipxe_entries)
    {
        print(":" . $os_family_menu_label_id . "\n");
        print("menu " . $id_lookups[$os_family_menu_label_id] . "\n");

        foreach ($os_family_ipxe_entries as $target_id => $target_ipxe_script)
        {
            print("item " . $target_id . " " . $id_lookups[$target_id] . "\n");
        }
        print("item arch_platform_" . $os_ipxe_native_platform . " Back\n");

        print("\n");
        print("choose selected\n");
        print("set menu-timeout 0\n");
        print("goto \${selected}\n");
        print("\n");
        
        foreach ($os_family_ipxe_entries as $target_id => $target_ipxe_script)
        {
            print(":" . $target_id . "\n");
            print($target_ipxe_script . "\n");
        }
    }

    print("\n\n\n\n\n");
}

?>



:end

