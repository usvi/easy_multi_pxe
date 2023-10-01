# Easy Multi PXE

Easy Multi PXE is an iPXE-powered simple pxe server. Currently it is able to boot in 64bit BIOS mode, but in the future it will support all crisscrossses from 32/64bit and BIOS/EFI. Possibly even signed efi stuff.

## Status
As of 2023-09-12 doing heavy refactoring. Everything will break.

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
/opt/easy_multi_pxe/netbootassets - CIFS Netboot assets storage mount root, also configured in webservers, THIS NEEDS TO BE MOUNTED TO CIFS!

OS placeholder directories:
(Examples, create manually what is needed and ALWAYS follow
this convention: netbootassets/os_family/major_version/arch)
/opt/easy_multi_pxe/netbootassets/windows/10/x64
/opt/easy_multi_pxe/netbootassets/windows/10/x86
/opt/easy_multi_pxe/netbootassets/windows/7/x64
/opt/easy_multi_pxe/netbootassets/windows/7/x86
/opt/easy_multi_pxe/netbootassets/windows/xp/x86
/opt/easy_multi_pxe/netbootassets/windows/xp/x64
/opt/easy_multi_pxe/netbootassets/systemrescuecd/8/x64
/opt/easy_multi_pxe/netbootassets/systemrescuecd/8/x86
/opt/easy_multi_pxe/netbootassets/ubuntu/20.04/x86
/opt/easy_multi_pxe/netbootassets/ubuntu/20.04/x64

Windows template files (whatever is needed, explained below how to get them)
/opt/easy_multi_pxe/netbootassets/windows/10/x64/template
/opt/easy_multi_pxe/netbootassets/windows/10/x86/template
/opt/easy_multi_pxe/netbootassets/windows/7/x64/template
/opt/easy_multi_pxe/netbootassets/windows/7/x86/template
/opt/easy_multi_pxe/netbootassets/windows/xp/x86/template
/opt/easy_multi_pxe/netbootassets/windows/xp/x64/template

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

### For Windows 7 (and probably XP also)
1. Download Windows Automated Installation Kit for Windows 7: https://www.microsoft.com/en-US/download/details.aspx?id=5753
The .iso file will be KB3AIK_EN.iso (for english), sha1sum:  
**793f4cc4741ebad223938be0eeee708eda968daa**  KB3AIK_EN.iso
2. Mount the .iso (this works even in Windows 10), then run StartCD.exe from the DVD.
3. If you don't have .NET 2.0 there are 2 options:  
Option 1: Run StartCD.exe from the DVD, then install the .NET 2.0 by selecting ".NET Framework Setup"  
Option 2: Hit Start, write "Turn Windows features on or off", run it and install ".NET Framework 3.5 (includes .NET 2.0 and 3.0)", then select "Let Windows Update download the files for you".
4. Install the WAIK by selecting from menu "Windows AIK Setup".
5. Hit Start, type **EXACTLY THE FOLLOWING**: Deployment Tools Command Prompt  
Right-click on it an run as Administrator
6. Run the following commands:  
```copype.cmd x86 c:\winpe_xp_7_x86```  
```copype.cmd amd64 c:\winpe_xp_7_amd64```
7. Copy files as follows from Windows to Easy Multi Pxe installation mounted assets directory (**MAKE SURE THE CASES MATCH!**):  
Windows XP 32bit:  
C:\winpe_xp_7_x86\ISO\boot\bcd => /opt/easy_multi_pxe/netbootassets/windows/xp/x86/BCD  
C:\winpe_xp_7_x86\ISO\boot\boot.sdi => /opt/easy_multi_pxe/netbootassets/windows/xp/x86/boot.sdi  
C:\winpe_xp_7_x86\winpe.wim => /opt/easy_multi_pxe/netbootassets/windows/xp/x86/boot.wim  
Windows XP 64bit:  
C:\winpe_xp_7_amd64\ISO\boot\bcd => /opt/easy_multi_pxe/netbootassets/windows/xp/x64/BCD  
C:\winpe_xp_7_amd64\ISO\boot\boot.sdi => /opt/easy_multi_pxe/netbootassets/windows/xp/x64/boot.sdi  
C:\winpe_xp_7_amd64\winpe.wim => /opt/easy_multi_pxe/netbootassets/windows/xp/x64/boot.wim  
Windows 7 32bit:  
C:\winpe_xp_7_x86\ISO\boot\bcd => /opt/easy_multi_pxe/netbootassets/windows/7/x86/BCD  
C:\winpe_xp_7_x86\ISO\boot\boot.sdi => /opt/easy_multi_pxe/netbootassets/windows/7/x86/boot.sdi  
C:\winpe_xp_7_x86\winpe.wim => /opt/easy_multi_pxe/netbootassets/windows/7/x86/boot.wim  
Windows 7 64bit:  
C:\winpe_xp_7_amd64\ISO\boot\bcd => /opt/easy_multi_pxe/netbootassets/windows/7/x64/BCD  
C:\winpe_xp_7_amd64\ISO\boot\boot.sdi => /opt/easy_multi_pxe/netbootassets/windows/7/x64/boot.sdi  
C:\winpe_xp_7_amd64\winpe.wim => /opt/easy_multi_pxe/netbootassets/windows/7/x64/boot.wim  
8. Done!

### For Windows 10
1. Download Windows Assessment and Deployment Kit for Windows 10, version 2004: https://software-static.download.prss.microsoft.com/pr/download/20348.1.210507-1500.fe_release_amd64fre_ADK.iso , sha1sum:  
**ae34d78d1c09e68a677c84dacabfb191a76dea9d**  20348.1.210507-1500.fe_release_amd64fre_ADK.iso
2. Download Windows PE add-on for the ADK, version 2004: https://software-static.download.prss.microsoft.com/sg/download/20348.1.210507-1500.fe_release_amd64fre_ADKWINPEADDONS.iso , sha1sum:  
**35cee1e3d8afde3e40f346a694b82b03169b6a79**  20348.1.210507-1500.fe_release_amd64fre_ADKWINPEADDONS.iso
3. First mount the ADK.iso, then run adksetup.exe to install the ADK, pick only the "Deployment Tool".
4. Then mount the ADKWINPEADDONS.iso, then run adkwinpesetup.exe to install the PE Addons
5. Hit Start, type **EXACTLY THE FOLLOWING**: Deployment and Imaging Tools Environment  
Right-click on it an run as Administrator
6. Run the following commands:  
```copype.cmd x86 c:\winpe_10_x86```  
```copype.cmd amd64 c:\winpe_10_amd64```
7. Copy files as follows from Windows to Easy Multi Pxe installation mounted assets directory (**MAKE SURE THE CASES MATCH!**):  
Windows 10 32bit:  
C:\winpe_10_x86\media\Boot\BCD => /opt/easy_multi_pxe/netbootassets/windows/10/x86/BCD  
C:\winpe_10_x86\media\Boot\boot.sdi => /opt/easy_multi_pxe/netbootassets/windows/10/x86/boot.sdi  
C:\winpe_10_x86\media\sources\boot.wim => /opt/easy_multi_pxe/netbootassets/windows/10/x86/boot.wim  
Windows 10 64bit:  
C:\winpe_10_amd64\media\Boot\BCD => /opt/easy_multi_pxe/netbootassets/windows/10/x64/BCD  
C:\winpe_10_amd64\media\Boot\boot.sdi => /opt/easy_multi_pxe/netbootassets/windows/10/x64/boot.sdi  
C:\winpe_10_amd64\media\sources\boot.wim => /opt/easy_multi_pxe/netbootassets/windows/10/x64/boot.wim  
8. Done!


## Provisioning examples

### Windows 7 32bit:
Acquire the template files described above, then run (currently full path to netbootassets directory is needed):
```
root@gw:/opt/easy_multi_pxe# ./scripts/emp_provision_windows_iso_to_assets_dir.sh /opt/isos_ro/win7/Win7_Ult_SP1_English_x32.iso /opt/easy_multi_pxe/netbootassets/windows/7/x86
Processing Win7_Ult_SP1_English_x32 as windows/7/x86
Copying Win7_Ult_SP1_English_x32.iso : 100%
Copying template files...done
Syncinc...done
ALL DONE
```

### Windows 10 64bit:
Acquire the template files described above, then run (currently full path to netbootassets directory is needed):
```
root@gw:/opt/easy_multi_pxe# ./scripts/emp_provision_windows_iso_to_assets_dir.sh /opt/isos_ro/win10/Win10_22H2_English_x64-2023-04-08.iso /opt/easy_multi_pxe/netbootassets/windows/10/x64
Processing Win10_22H2_English_x64-2023-04-08 as windows/10/x64
Copying Win10_22H2_English_x64-2023-04-08.iso : 100%
Copying template files...done
Drivers found at /opt/drivers/windows/10/x64 , copying...done
Syncinc...done
ALL DONE
```
Note: As you can see above, the script picked up drivers from a directory and slipped those in.


### Ubuntu 20.04 64bit:
```
root@gw:/opt/easy_multi_pxe# ./scripts/emp_provision_ubuntu_iso_to_assets_dir.sh /opt/isos_ro/ubuntu/ubuntu-20.04.3-desktop-amd64.iso /opt/easy_multi_pxe/netbootassets/ubuntu/20.04/x64
Processing ubuntu-20.04.3-desktop-amd64 as ubuntu/20.04/x64
Copying iso: 2.86GiB 0:01:09 [41.9MiB/s] [===================>] 100%
Copying initrd: 94.5MiB 0:00:12 [7.83MiB/s] [================>] 100%
Syncinc...done
ALL DONE
```
