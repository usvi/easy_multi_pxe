# Easy Multi PXE

Easy Multi PXE is an iPXE-powered simple pxe server. Currently it is able to boot in 64bit BIOS mode, but in the future it will support all crisscrossses from 32/64bit and BIOS/EFI. Possibly even signed efi stuff.

## Hilights

* Easy to setup, basically just clone the repo to /opt/easy_multi_pxe and plug configuration files
* Configurable SMB/CIFS paths and credentials
* Configuration creation script (emp_create_configs.sh) asks necessary stuff in a user-friendly manner
* Pluggable configuration files: just include a file for dnsmasq and apache or nginx and you are ready to go
* Provisioning script for Windows: It even splitstreams drivers in without the help of Windows!
* Dynamic creation of master root.ipxe file based on fragments created by provisioning scripts

## Requirements

* Some knowledge of basic PXE, EFI and Linux concepts
* Dnsmasq
* Samba/CIFS (so that Windows installer can map it and start setup.exe)
* Webserver (Apache2 or Nginx is fine)
* Windows ADK / WAIK or similiar to create initial template

## Suggested/expected files and directories layout

```
External driver dirs, not necessary but handy:
/opt/drivers/windows/10/x64//board1/foo_lan.inf
/opt/drivers/windows/10/x64/board2/bar_lan.inf
/opt/drivers/windows/10/x64/board3/baz_lan.inf

Required, our configuration scrip creates:
/opt/easy_multi_pxe/conf/easy_multi_pxe.conf
/opt/easy_multi_pxe/conf/apache2_emp_inc.conf
/opt/easy_multi_pxe/conf/dnsmasq_emp_inc.conf
/opt/easy_multi_pxe/conf/nginx_emp_inc.conf

Provisioning scripts:
/opt/easy_multi_pxe/scripts/emp_provision_windows_iso_to_assets_dir.sh

Roots:
/opt/easy_multi_pxe/tftproot - Main TFTP root
/opt/easy_multi_pxe/netbootassets - CIFS Netboot assets storage mount root, also configured in webservers

Boot config file:
/opt/easy_multi_pxe/scripts/root.ipxe.php - Dynamically generated ipxe root menu

Boot kernels:
/opt/easy_multi_pxe/tftproot/ipxe.386.efi (self compiled)
/opt/easy_multi_pxe/tftproot/ipxe.efi
/opt/easy_multi_pxe/tftproot/ipxe.pxe
/opt/easy_multi_pxe/tftproot/wimboot
/opt/easy_multi_pxe/tftproot/wimboot.i386


Example: Windows 10 x64 bios:
1. Go to actual Windows x64
2. Install "Deployment and imaging Tools Environment" or similar
3. Start ELEVATED "Deployment and imaging Tools Environment" (or similar)
4. copype amd64 C:\winpe_amd64
5. Copy BCD, boot.sdi, boot.wim as follows:
/opt/easy_multi_pxe/netbootassets/x64/windows/10/template/BCD
/opt/easy_multi_pxe/netbootassets/x64/windows/10/template/boot.sdi
/opt/easy_multi_pxe/netbootassets/x64/windows/10/template/boot.wim


Then just run run:
./scripts/emp_provision_windows_iso_to_assets_dir.sh /opt/isos_ro/win10/Win10_22H2_English_x64-2023-04-08.iso /opt/easy_multi_pxe/netbootassets/windows/10/x64

And the script provisions stuff automatically:
Processing Win10_22H2_English_x64-2023-04-08 as windows/10/x64
Copying Win10_22H2_English_x64-2023-04-08.iso : 100%
Copying template files...done
Drivers found at /opt/drivers/windows/10/x64 , copying...done
Syncinc...done
ALL DONE


```
