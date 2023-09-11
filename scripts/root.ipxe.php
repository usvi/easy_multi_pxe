#!ipxe

:start
menu iPXE 64bit EFI boot menu

item reboot         Reboot computer

choose selected
set menu-timeout 0
goto ${selected}

:reboot
reboot
goto end

<?php



?>
