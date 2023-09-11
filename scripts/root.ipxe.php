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

# Find all fragments
$fragments_i386_pcbios = [];
$fragments_i386_efi = [];
$fragments_x86_64_pcbios = [];
$fragments_x86_64_efi = [];

//print("$assets_prefix_dir\n");

$ipxe_fragment_iterator = new RecursiveIteratorIterator(new RecursiveDirectoryIterator($assets_prefix_dir));
$ipxe_fragment_iterator->setMaxDepth(3);

foreach ($ipxe_fragment_iterator as $ipxe_file_candidate)
{
    if ($ipxe_file_candidate->getExtension() === "ipxe")
    {
        $ipxe_file = $ipxe_file_candidate->getBasename(".ipxe");
        #print("$ipxe_file\n");
        list($entry_id, $entry_class) = explode(".", $ipxe_file);

        //print("$entry_id\n");
        //print("$entry_class\n");

        switch($entry_class)
        {
            case "32bit-bios":
                $fragments_i386_pcbios[$entry_id] = file_get_contents($ipxe_file_candidate);
                break;

            case "32bit-efi":
                $fragments_i386_efi[$entry_id] = file_get_contents($ipxe_file_candidate);
                break;
                
            case "64bit-bios":
                $fragments_x86_64_pcbios[$entry_id] = file_get_contents($ipxe_file_candidate);
                break;

            case "64bit-efi":
                $fragments_x86_64_efi[$entry_id] = file_get_contents($ipxe_file_candidate);
                break;
        }

    }
}
//print_r($fragments_x86_64_pcbios);
//print_r($fragments_x86_64_efi);
//print($fragments_x86_64_efi["Win10_21H1_English_x64_2021-10-09"]);

?>

cpuid --ext 29 && set arch x86_64 || set arch i386

# arch = i386 or x86_64
# platform = pcbios or efi

goto menu_${arch}_${platform}



:menu_i386_pcbios
menu iPXE 32bit BIOS boot menu
item reboot         Reboot computer
<?php
foreach ($fragments_i386_pcbios as $key => $value)
{
    print("item " . $key . "\n");
}
?>
choose selected
set menu-timeout 0
goto ${selected}

:reboot
reboot
sleep 5
goto end

<?php
foreach ($fragments_i386_pcbios as $key => $value)
{
    print($value . "\n");
}
?>







:menu_i386_efi
menu iPXE 32bit EFI boot menu
item reboot         Reboot computer
<?php
foreach ($fragments_i386_efi as $key => $value)
{
    print("item " . $key . "\n");
}
?>

choose selected
set menu-timeout 0
goto ${selected}

:reboot
reboot
sleep 5
goto end

<?php
foreach ($fragments_i386_efi as $key => $value)
{
    print($value . "\n");
}
?>







:menu_x86_64_pcbios
menu iPXE 64bit BIOS boot menu
item reboot         Reboot computer
<?php
foreach ($fragments_x86_64_pcbios as $key => $value)
{
    print("item " . $key . "\n");
}
?>

choose selected
set menu-timeout 0
goto ${selected}

:reboot
reboot
sleep 5
goto end

<?php
foreach ($fragments_x86_64_pcbios as $key => $value)
{
    print($value . "\n");
}
?>







:menu_x86_64_efi
menu iPXE 64bit EFI boot menu
item reboot         Reboot computer
<?php
foreach ($fragments_x86_64_efi as $key => $value)
{
    print("item " . $key . "\n");
}
?>

choose selected
set menu-timeout 0
goto ${selected}

:reboot
reboot
sleep 5
goto end

<?php
foreach ($fragments_x86_64_efi as $key => $value)
{
    print($value . "\n");
}
?>


    
:end
