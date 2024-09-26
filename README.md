# Easy Multi PXE 1.1

Easy Multi PXE is an iPXE-powered simple pxe server. Currently it is able to boot in 64bit BIOS mode, but in the future it will support all crisscrossses from 32/64bit and BIOS/EFI.

## Hilights

* Easy to setup, basically just clone the repo to /opt/easy_multi_pxe and plug configuration files (CIFS backing store needed)
* Configurable SMB/CIFS paths and credentials
* Configuration creation script (emp_create_configs.sh) asks necessary stuff in a user-friendly manner
* Pluggable configuration files: just include a file for dnsmasq and apache or nginx and you are ready to go
* Windows boot process automatically slipstreams drop-in-drivers during boot process
* Windows Preboot Environment boot template creation from regular iso files without WAIK or ADK
* Debian iso provisioning as local http repository
* Precalculated root.ipxe based on individually provisioned ipxe fragments
* Dynamic runtime-generators for ipxe fragments (hybrid with base fragments), Debian preseed url and windows startnet.cmd, enabling changing values without bothersome regeneration of assets

## Requirements

* Some knowledge of basic PXE, EFI and Linux concepts
* Basic shell tools
* Dnsmasq
* Samba/CIFS (so that Windows installer can map it and start setup.exe)
* Webserver (Apache2 or Nginx is fine)
* wimtools (wimmount / wimunmount and friends) for operating Windows files

