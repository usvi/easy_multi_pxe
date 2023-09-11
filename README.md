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
* Windows ADK / WAIK or similiar to create initial templates
* wimtools (wimmount / wimunmount) for operating Windows files

## Suggested/expected files and directories layout

```
External driver dirs, not necessary but handy:
/opt/drivers/windows/10/x64//board1/foo_lan.inf
/opt/drivers/windows/10/x64/board2/bar_lan.inf
/opt/drivers/windows/10/x64/board3/baz_lan.inf

Required, our configuration script creates:
/opt/easy_multi_pxe/conf/easy_multi_pxe.conf
/opt/easy_multi_pxe/conf/apache2_emp_inc.conf
/opt/easy_multi_pxe/conf/dnsmasq_emp_inc.conf
/opt/easy_multi_pxe/conf/nginx_emp_inc.conf

Provisioning scripts:
/opt/easy_multi_pxe/scripts/emp_provision_windows_iso_to_assets_dir.sh

Main roots:
/opt/easy_multi_pxe/tftproot - Main TFTP root
/opt/easy_multi_pxe/netbootassets - CIFS Netboot assets storage mount root, also configured in webservers

OS placeholder directories:
(Examples, create manually what is needed and ALWAYS follow
this convention: netbootassets/os_family/major_version/arch)
/opt/easy_multi_pxe/netbootassets/windows/10/x64
/opt/easy_multi_pxe/netbootassets/windows/10/x86
/opt/easy_multi_pxe/netbootassets/windows/7/x64
/opt/easy_multi_pxe/netbootassets/windows/7/x86
/opt/easy_multi_pxe/netbootassets/windows/xp/x86
/opt/easy_multi_pxe/netbootassets/systemrescuecd/8/x64
/opt/easy_multi_pxe/netbootassets/systemrescuecd/8/x86
/opt/easy_multi_pxe/netbootassets/ubuntu/20.04/x86
/opt/easy_multi_pxe/netbootassets/ubuntu/20.04/x64

Boot config file:
/opt/easy_multi_pxe/scripts/root.ipxe.php - Dynamically generated ipxe root menu

Boot kernels:
/opt/easy_multi_pxe/tftproot/ipxe.386.efi (self compiled)
/opt/easy_multi_pxe/tftproot/ipxe.efi
/opt/easy_multi_pxe/tftproot/ipxe.pxe
/opt/easy_multi_pxe/tftproot/wimboot
/opt/easy_multi_pxe/tftproot/wimboot.i386
```

## On acquiring Windows Preinstallation Environment (PE) boot templates
To provision and boot Windows XP/7/10 isos, you need to get the Windows Preinstallation Environment (PE) files. This is a bit tricky. I would happily include the files here on Github but Microsoft would probably bust my ass for it, so this needs to be done manually.

### Windows 7 (and probably XP also)
1. Download Windows Automated Installation Kit for Windows 7: https://www.microsoft.com/en-US/download/details.aspx?id=5753
The .iso file will be KB3AIK_EN.iso (for english), sha1sum:  
**793f4cc4741ebad223938be0eeee708eda968daa**  KB3AIK_EN.iso
2. Profit

### Windows 10
1. Download Windows Assessment and Deployment Kit for Windows 10, version 2004: https://software-static.download.prss.microsoft.com/pr/download/20348.1.210507-1500.fe_release_amd64fre_ADK.iso , sha1sum:  
**ae34d78d1c09e68a677c84dacabfb191a76dea9d**  20348.1.210507-1500.fe_release_amd64fre_ADK.iso
2. Download Windows PE add-on for the ADK, version 2004: https://software-static.download.prss.microsoft.com/sg/download/20348.1.210507-1500.fe_release_amd64fre_ADKWINPEADDONS.iso , sha1sum:  
**35cee1e3d8afde3e40f346a694b82b03169b6a79**  20348.1.210507-1500.fe_release_amd64fre_ADKWINPEADDONS.iso
3. Profit

Example: Windows 10 x64 bios:
1. Go to actual Windows x64
2. Install "Deployment and imaging Tools Environment" or similar
3. Start ELEVATED "Deployment and imaging Tools Environment" (or similar)
4. copype amd64 C:\winpe_amd64
5. Copy BCD (from c:\amd64_template\media\boot\BCD or c:\amd64_template\boot\BCD), boot.sdi, boot.wim as follows:
/opt/easy_multi_pxe/netbootassets/x64/windows/10/template/BCD
/opt/easy_multi_pxe/netbootassets/x64/windows/10/template/boot.sdi
/opt/easy_multi_pxe/netbootassets/x64/windows/10/template/boot.wim
MAKE SURE CASES MATCH!


Then just run run:
./scripts/emp_provision_windows_iso_to_assets_dir.sh /opt/isos_ro/win10/Win10_22H2_English_x64-2023-04-08.iso /opt/easy_multi_pxe/netbootassets/windows/10/x64

And the script provisions stuff automatically:
Processing Win10_22H2_English_x64-2023-04-08 as windows/10/x64
Copying Win10_22H2_English_x64-2023-04-08.iso : 100%
Copying template files...done
Drivers found at /opt/drivers/windows/10/x64 , copying...done
Syncinc...done
ALL DONE
