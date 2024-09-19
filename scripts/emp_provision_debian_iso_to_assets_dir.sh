#!/bin/sh

EMP_OP="do_provisioning"
EMP_INC_COMMON="$(dirname "$(realpath "${0}")")/emp_inc_common.sh"
if [ ! -f "$EMP_INC_COMMON" ]; then echo "Error: No common include file $EMP_INC_COMMON"; exit 1; fi
. "$EMP_INC_COMMON"

# Note: Wireless nics support has been deprecated because of initrd bloat
# and the feeling that very small amount of systems are able to boot pxe
# over wifi.
# To re-enable support, uncomment the lines about wireless nics, firmware
# and firmware installation.

emp_custom_analyze_assets_type()
{
    echo -n "Analyzing assets type..."
    
    EMP_BOOT_OS_ASSETS_TYPE=""
    # Note: install.amd breaks for 32bit; check 32bit iso and use $EMP_BOOT_OS_MAIN_ARCH
    
    if grep -m 1 "DVD" "$EMP_MOUNT_POINT/README.txt" > /dev/null 2>&1
    then
	EMP_BOOT_OS_ASSETS_TYPE="dvd"
	# Note: install.amd breaks for 32bit
	if [ "$EMP_BOOT_OS_MAIN_ARCH" = "x32" ]
	then
	    EMP_BOOT_OS_ASSETS_FILES_COPY_ISO_PATHS_LIST="install.386/vmlinuz"
	    EMP_BOOT_OS_INITRD_PATH="install.386/initrd.gz"
	    
	elif [ "$EMP_BOOT_OS_MAIN_ARCH" = "x64" ]
	then
	    EMP_BOOT_OS_ASSETS_FILES_COPY_ISO_PATHS_LIST="install.amd/vmlinuz"
	    EMP_BOOT_OS_INITRD_PATH="install.amd/initrd.gz"

	else
	    echo ""
            echo "ERROR: Unsupported arch type $EMP_BOOT_OS_MAIN_ARCH ."
	    emp_force_unmount_generic_mountpoint
	
            exit 1
	fi
	
    else
	echo ""
        echo "ERROR: Unable to analyze assets type for  boot methodology of the iso file."
	echo "Note: Netinst isos are not supported."
	emp_force_unmount_generic_mountpoint
	
        exit 1
    fi

    echo "$EMP_BOOT_OS_ASSETS_TYPE"
}



emp_custom_collect_initrd_files_lists()
{
    if [ "$EMP_BOOT_OS_MAIN_VERSION" -eq 12 ]
    then
	EMP_INITRD_REMOVE_PACKAGES_LIST="cdrom-retriever cdrom-detect cdrom-checker media-retriever mountmedia file-preseed initrd-preseed"
	EMP_INITRD_ADD_EXTRA_PACKAGES_LIST="network-preseed net-retriever netcfg ethdetect libiw30-udeb wpasupplicant-udeb rdnssd-udeb ndisc6-udeb wide-dhcpv6-client-udeb choose-mirror choose-mirror-bin gpgv-udeb libgcrypt20-udeb libgpg-error0-udeb debian-archive-keyring-udeb libnl-3-200-udeb libnl-genl-3-200-udeb apt-setup-udeb apt-mirror-setup"
	EMP_INITRD_ADD_MODULE_PACKAGES_LIST="nic-modules nic-shared-modules crypto-modules"
	#EMP_INITRD_ADD_MODULE_PACKAGES_LIST="$EMP_INITRD_ADD_MODULE_PACKAGES_LIST nic-wireless-modules"
	#EMP_INITRD_ADD_FIRMWARE_PACKAGES_LIST="firmware-iwlwifi"
    else
        echo "ERROR: No file lists implemented for version $EMP_DEBIAN_VERSION_NUMBER"
	emp_force_unmount_generic_mountpoint
	
        exit 1
    fi
}



emp_custom_create_single_ipxe_fragment()
{
    TEMP_PARAM_IPXE_FRAGMENT="$1"

    if [ "$EMP_BOOT_OS_ASSETS_TYPE" = "dvd" ]
    then
        cat <<EOF > "$TEMP_PARAM_IPXE_FRAGMENT"
kernel \${http_base}/vmlinuz nvidia.modeset=0 i915.modeset=0 nouveau.modeset=0 initrd=initrd.gz ip=dhcp preseed/url=\${preseed_url}
initrd \${http_base}/initrd.gz
EOF
        if [ "$?" -ne 0 ]
        then
            echo ""
            echo "ERROR: Unable to create ipxe fragment $TEMP_PARAM_IPXE_FRAGMENT"

            exit 1
        fi
    else
	echo ""
        echo "ERROR: Unable to determine boot methodology of the iso file"

        exit 1
    fi
}

# Actual start
emp_remove_old_ipxe_fragment_remnants
emp_force_unmount_generic_mountpoint
emp_mount_iso
emp_custom_analyze_assets_type
emp_custom_collect_initrd_files_lists
emp_unpack_initrd
emp_dpkg_remove_initrd_packages
emp_dpkg_install_extra_packages
emp_dpkg_install_module_packages
#emp_dpkg_install_firmware_packages
#emp_create_initrd_preseed
emp_patch_apt_mirror_generator_deb_trusted
emp_patch_load_cdrom_as_download_installer
emp_repack_initrd
emp_unpack_iso_if_needed
emp_copy_simple_initrd_file
emp_copy_simple_asset_files
# Include driver copying later and especially in debian
emp_unmount_and_sync
emp_create_ipxe_fragments
emp_compile_root_ipxe


echo "ALL DONE"

exit 0

