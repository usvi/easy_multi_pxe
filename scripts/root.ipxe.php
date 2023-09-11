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
?>

cpuid --ext 29 && set arch x86_64 || set arch i386

# arch = i386 or x86_64
# platform = pcbios or efi

goto conf_${arch}_${platform}



:conf_i386_pcbios
menu iPXE 32bit BIOS boot menu

item reboot         Reboot computer
<?php

?>
choose selected
set menu-timeout 0
goto ${selected}

:reboot
reboot
goto end
<?php

?>
goto end



:conf_x86_64_pcbios
<?php

?>
goto end


:conf_i386_efi
<?php

?>
goto end



:conf_x86_64_efi
menu iPXE 64bit EFI boot menu

item reboot         Reboot computer
<?php

?>
choose selected
set menu-timeout 0
goto ${selected}

:reboot
reboot
goto end
<?php

?>
goto end

    
:end
