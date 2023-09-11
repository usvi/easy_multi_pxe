# Easy Multi PXE

Easy Multi PXE is an iPXE-powered simple pxe server. Currently it is able to boot in 64bit BIOS mode, but in the future it will support all crisscrossses from 32/64bit and BIOS/EFI. Possibly even signed efi stuff.

## Hilights

* Easy to setup, basically just clone the repo to /opt/easy_multi_pxe and plug configuration files
* Pluggable configuration files: just include a file for dnsmasq and apache or nginx and you are ready to go
* Provisioning script for Windows: It even splitstreams drivers in without the help of Windows!
* Configurable SMB/CIFS paths and credentials

## Requirements

* Some knowledge of basic PXE, EFI and Linux concepts
* Dnsmasq
* Samba/CIFS (so Windows installer can map it and start setup.exe)
* Webserver (Apache2 or Nginx is fine)
* Windows ADK or similiar to create initial WinPE template

## Suggested/expected files and directories layout

```
Externals
/opt/windrivers/x64/board1/foo_lan.inf
/opt/windrivers/x64/board2/bar_lan.inf
/opt/windrivers/x86/board3/baz_lan.inf

External but required:
/opt/easy_multi_pxe/conf/emp_cifs_share.conf - Contains CIFS server credentials (CIFS_SERVER_IP, CIFS_PATH_PREFIX, CIFS_USER, CIFS_PASSWD)

Plugin configuration files:
/opt/easy_multi_pxe/conf/apache2_emp_inc.conf
/opt/easy_multi_pxe/conf/dnsmasq_emp_inc.conf
/opt/easy_multi_pxe/conf/nginx_emp_inc.conf

Provisioning script:
/opt/easy_multi_pxe/scripts/emp_provision_wimdir.sh

Roots:
/opt/easy_multi_pxe/tftproot - Main TFTP root
/opt/easy_multi_pxe/netbootassets - CIFS Netboot storage mount root, also configured in webservers

Boot config files:
/opt/easy_multi_pxe/tftproot/root.ipxe
/opt/easy_multi_pxe/tftproot/32bit-bios.ipxe
/opt/easy_multi_pxe/tftproot/32bit-efi.ipxe
/opt/easy_multi_pxe/tftproot/64bit-bios.ipxe
/opt/easy_multi_pxe/tftproot/64bit-efi.ipxe

Boot kernels:
/opt/easy_multi_pxe/tftproot/ipxe.386.efi (self compiled)
/opt/easy_multi_pxe/tftproot/ipxe.efi
/opt/easy_multi_pxe/tftproot/ipxe.pxe
/opt/easy_multi_pxe/tftproot/wimboot
/opt/easy_multi_pxe/tftproot/wimboot.i386


Example: Windows 10 x64 bios:
1. Go to actual WIndows x64
2. Install "Deployment and imaging Tools Environment" or similar
3. Start ELEVATED "Deployment and imaging Tools Environment" (or similar)
4. copype amd64 C:\winpe_amd64
5. Copy BCD, boot.sdi, boot.wim as follows:
/opt/easy_multi_pxe/netbootassets/x64/windows/10/template/BCD
/opt/easy_multi_pxe/netbootassets/x64/windows/10/template/boot.sdi
/opt/easy_multi_pxe/netbootassets/x64/windows/10/template/boot.wim

Mount the iso Win10_21H2_English_x64 and put the contents here:
/opt/easy_multi_pxe/netbootassets/x64/windows/Win10_21H2_English_x64-2022-02-02/unpacked

Then run /opt/easy_multi_pxe/scripts/emp_provision_wimdir.sh /opt/easy_multi_pxe/netbootassets/x64/windows/10
Script outomatically provisions all entries under /opt/easy_multi_pxe/netbootassets/x64/windows/10 
(except template, of course)
```
