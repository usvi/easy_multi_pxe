<?php
header('Content-Type: text/plain');

require_once('include_conf.php');
?>
#!ipxe

cpuid --ext 29 && set arch x64 || set arch x32
set method unknown
iseq ${platform} pcbios && set method bios ||
iseq ${platform} efi && set method efi ||

# arch = x32 or x64
# method = bios or efi

set nloc ${netX/busloc}
set pciid ${pci/${nloc}.0.2}:${pci/${nloc}.2.2}


<?php
# Find all submenus. Lots of esoteric stuff here.

$id_lookups = [];
$submenus = [];
$submenu_names = [];

$emp_platform_to_names = array(
    "x32-bios" => "iPXE 32bit BIOS",
    "x32-efi" => "iPXE 32bit EFI",
    "x64-bios" => "iPXE 64bit BIOS",
    "x64-efi" => "iPXE 64bit EFI");

$default_entries = array(
    "sysinfo" => array("System information",
                       "menu System Information (Generic)\n" .
                       "item \${arch}-\${method} iPXE....................\${version}\n" .
                       "item \${arch}-\${method} Boot type ..............\${arch}-\${method}\n" .
                       "item \${arch}-\${method} Network device..........\${net0/chip} / \${pciid} / \${net0/mac}\n" .
                       "item \${arch}-\${method} IP address..............\${ip} / \${netmask}\n" .
                       "item \${arch}-\${method} Gateway.................\${gateway}\n" .
                       "item \${arch}-\${method} DNS.....................\${dns}\n" .
                       "item \${arch}-\${method} Back\n" .
                       "choose --default \${arch}-\${method} selected\n" .
                       "set menu-timeout 0\n" .
                       "goto \${selected}\n"),

    "reboot" => array("Reboot computer",
                      "reboot\n" .
                      "sleep 5\n" .
                      "goto end\n"),
);


$ipxe_fragment_iterator = new RecursiveIteratorIterator(new RecursiveDirectoryIterator($assets_prefix_dir));
$ipxe_fragment_iterator->setMaxDepth(3);

foreach ($ipxe_fragment_iterator as $ipxe_file_candidate)
{
    if ($ipxe_file_candidate->getExtension() === "ipxe" && $ipxe_file_candidate->getFilename() != "root.ipxe")
    {
        $dot_parts = explode(".", $ipxe_file_candidate);
        $ipxe_suffix = array_pop($dot_parts);
        $emp_platform = array_pop($dot_parts);
        list($os_arch, $os_method) = explode("-", $emp_platform);
        $path_with_os_label_id = str_replace("." . $emp_platform . "." . $ipxe_suffix, "", $ipxe_file_candidate);
        
        if (array_key_exists($emp_platform, $emp_platform_to_names))
        {
            $os_family = basename(dirname($path_with_os_label_id, 3));
            $os_major_version = basename(dirname($path_with_os_label_id, 2));
            $os_family_menu_label_id = $emp_platform . "-" . $os_family;
            $os_family_with_major_menu_label_id = $os_family_menu_label_id . "-" . $os_major_version;
            $os_target_base_label_id = basename($path_with_os_label_id);
            $os_target_full_label_id = $os_family_with_major_menu_label_id . "-" . $os_target_base_label_id;

            $id_lookups[$os_family_menu_label_id] = ucfirst($os_family);
            $id_lookups[$os_family_with_major_menu_label_id] = ucfirst($os_family) . " " . $os_major_version;
            $id_lookups[$os_target_full_label_id] = ucfirst(str_replace(["_","-"], " ", $os_target_base_label_id));

            if (!array_key_exists($emp_platform, $submenus))
            {
                $submenus[$emp_platform] = [];
            }
            if (!array_key_exists($os_family_menu_label_id, $submenus[$emp_platform]))
            {
                $submenus[$emp_platform][$os_family_menu_label_id] = [];
            }
            if (!array_key_exists($os_family_with_major_menu_label_id, $submenus[$emp_platform][$os_family_menu_label_id]))
            {
                $submenus[$emp_platform][$os_family_menu_label_id][$os_family_with_major_menu_label_id] = [];
            }
            $submenus[$emp_platform][$os_family_menu_label_id][$os_family_with_major_menu_label_id][$os_target_full_label_id] =
              array
              (
                  'METHOD' => $os_method,
                  'FAMILY' => $os_family,
                  'VERSION' => $os_major_version,
                  'ARCH' => $os_arch,
                  'ID' => $os_target_base_label_id,
              );
        }
    }
}
?>

    
goto ${arch}-${method}



<?php

foreach($submenus as $emp_platform => $os_family_menu_label_id)
{
    print("# Main arch platform menu\n");
    print(":" . $emp_platform . "\n");
    print("menu " . $emp_platform_to_names[$emp_platform] . " boot menu\n");
    print("item --gap -- Operating system families\n");
    
    foreach($submenus[$emp_platform] as $os_family_menu_label_id => $os_family_ipxe_entries)
    {
        print("item " . $os_family_menu_label_id . " " . $id_lookups[$os_family_menu_label_id] . "\n");
    }
    print("item --gap -- Tools and utilities\n");
    
    foreach($default_entries as $entry_suffix => $entry_contents)
    {
        print("item " . $emp_platform . "-" . $entry_suffix . " " . $entry_contents[0] . "\n");
    }
    print("\n");
    print("choose selected\n");
    print("set menu-timeout 0\n");
    print("goto \${selected}\n");
    print("\n");

    print("# Os family submenu\n");
    
    foreach($submenus[$emp_platform] as $os_family_menu_label_id => $os_family_with_major_menu_label_ids_array)
    {
        print(":" . $os_family_menu_label_id . "\n");
        print("menu " . $id_lookups[$os_family_menu_label_id] . " major versions (" . $emp_platform_to_names[$emp_platform] . ")\n");

        foreach ($os_family_with_major_menu_label_ids_array as $os_family_with_major_menu_label_id => $os_target_full_label_ids_array)
        {
            print("item " . $os_family_with_major_menu_label_id . " " . $id_lookups[$os_family_with_major_menu_label_id] . "\n");
        }
        print("item " . $emp_platform . " Back\n");

        print("\n");
        print("choose selected\n");
        print("set menu-timeout 0\n");
        print("goto \${selected}\n");
        print("\n");

        foreach ($os_family_with_major_menu_label_ids_array as $os_family_with_major_menu_label_id => $os_target_full_label_ids_array)
        {
            print("# Os family and major submenu\n");
            print(":" . $os_family_with_major_menu_label_id . "\n");
            print("menu " . $id_lookups[$os_family_with_major_menu_label_id] . " variants (" . $emp_platform_to_names[$emp_platform] . ")\n");

            foreach ($os_target_full_label_ids_array as $os_target_full_label_id => $target_ipxe_script)
            {
                print("item " . $os_target_full_label_id . " " . $id_lookups[$os_target_full_label_id] . "\n");
            }
            print("item " . $os_family_menu_label_id . " Back\n");
            
            print("\n");
            print("choose selected\n");
            print("set menu-timeout 0\n");
            print("goto \${selected}\n");
            print("\n");
            
            foreach ($os_target_full_label_ids_array as $os_target_full_label_id => $target_metadata)
            {
                print(":" . $os_target_full_label_id . "\n");
                print("chain --replace " . $webserver_assets_root_url . "/fragment.php?" .
                      "method=" . $target_metadata['METHOD'] . "&" .
                      "family=" . $target_metadata['FAMILY'] . "&" .
                      "version=" . $target_metadata['VERSION'] . "&" .
                      "arch=" . $target_metadata['ARCH'] . "&" .
                      "id=" . $target_metadata['ID'] .
                      "\n");
                print("\n");
            }
        }
    }
    foreach($default_entries as $entry_suffix => $entry_contents)
    {
        print(":" . $emp_platform . "-" . $entry_suffix . "\n");
        print($entry_contents[1] . "\n");
    }

    print("\n\n\n\n\n");
}

?>



:end

