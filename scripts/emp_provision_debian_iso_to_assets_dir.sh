#!/bin/sh

EMP_OP="do_provisioning"
EMP_INC_COMMON="$(dirname "$(realpath "${0}")")/emp_inc_common.sh"
if [ ! -f "$EMP_INC_COMMON" ]; then echo "Error: No common include file $EMP_INC_COMMON"; exit 1; fi
. "$EMP_INC_COMMON"


emp_custom_analyze_assets_type()
{
    echo -n "Analyzing assets type..."
    
    EMP_BOOT_OS_ASSETS_TYPE="netinst"
    # Note: install.amd breaks for 32bit; check 32bit iso and use $EMP_BOOT_OS_MAIN_ARCH
    
    if grep -m 1 "NETINST" "$EMP_MOUNT_POINT/README.txt" > /dev/null 2>&1
    then
	EMP_BOOT_OS_ASSETS_TYPE="netinst"
	# Note: install.amd breaks for 32bit
	EMP_BOOT_OS_ASSETS_FILES_COPY_ISO_PATHS_LIST="install.amd/vmlinuz"
	EMP_BOOT_OS_INITRD_PATH="install.amd/initrd.gz"
	
    elif grep -m 1 "DVD" "$EMP_MOUNT_POINT/README.txt" > /dev/null 2>&1
    then
	EMP_BOOT_OS_ASSETS_TYPE="dvd"
	# Note: install.amd breaks for 32bit
	EMP_BOOT_OS_ASSETS_FILES_COPY_ISO_PATHS_LIST="install.amd/vmlinuz"
	EMP_BOOT_OS_INITRD_PATH="install.amd/initrd.gz"
    else
	echo ""
        echo "ERROR: Unable to analyze assets type for  boot methodology of the iso file."
	echo "Normal Debian isos are not yet implemented."
	emp_force_unmount_generic_mountpoint
	
        exit 1
    fi

    echo "$EMP_BOOT_OS_ASSETS_TYPE"
}



emp_custom_collect_initrd_files_lists()
{
    if [ "$EMP_BOOT_OS_MAIN_VERSION" -eq 12 ]
    then
	EMP_INITRD_REMOVE_PACKAGES_LIST="load-cdrom cdrom-retriever cdrom-detect cdrom-checker"
	EMP_INITRD_ADD_SUPPORT_PACKAGES_LIST="download-installer"
	EMP_INITRD_ADD_EXTRA_PACKAGES_LIST="net-retriever netcfg ethdetect libiw30-udeb wpasupplicant-udeb rdnssd-udeb ndisc6-udeb wide-dhcpv6-client-udeb choose-mirror choose-mirror-bin gpgv-udeb libgcrypt20-udeb libgpg-error0-udeb debian-archive-keyring-udeb libnl-3-200-udeb libnl-genl-3-200-udeb"
	EMP_INITRD_ADD_MODULE_PACKAGES_LIST="nic-modules crypto-modules"
    else
        echo "ERROR: No file lists implemented for version $EMP_DEBIAN_VERSION_NUMBER"
	emp_force_unmount_generic_mountpoint
	
        exit 1
    fi
}



emp_custom_create_single_ipxe_fragment()
{
    TEMP_PARAM_IPXE_FRAGMENT="$1"

    if [ "$EMP_BOOT_OS_ASSETS_TYPE" = "netinst" ]
    then
        cat <<EOF > "$TEMP_PARAM_IPXE_FRAGMENT"
set http_base $EMP_BOOT_OS_ASSETS_HTTP_BASE_PATH
set http_iso \${http_base}/$EMP_BOOT_OS_ISO_FILE
kernel \${http_base}/vmlinuz nvidia.modeset=0 i915.modeset=0 nouveau.modeset=0 initrd=initrd.gz ip=dhcp
initrd \${http_base}/initrd.gz
boot
sleep 5
goto end
EOF
        if [ "$?" -ne 0 ]
        then
            echo ""
            echo "ERROR: Unable to create ipxe fragment $TEMP_PARAM_IPXE_FRAGMENT"

            exit 1
        fi
	
    elif [ "$EMP_BOOT_OS_ASSETS_TYPE" = "dvd" ]
    then
        cat <<EOF > "$TEMP_PARAM_IPXE_FRAGMENT"
set http_base $EMP_BOOT_OS_ASSETS_HTTP_BASE_PATH
set http_iso \${http_base}/$EMP_BOOT_OS_ISO_FILE
kernel \${http_base}/vmlinuz nvidia.modeset=0 i915.modeset=0 nouveau.modeset=0 initrd=initrd.gz ip=dhcp
initrd \${http_base}/initrd.gz
boot
sleep 5
goto end
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
#emp_copy_simple_asset_files
emp_unpack_initrd
debian_remove_initrd_packages
debian_install_support_packages
debian_install_extra_packages
debian_install_module_packages
emp_repack_initrd
emp_copy_simple_initrd_file
emp_copy_simple_asset_files
###emp_unpack_iso_if_needed
# Include driver copying later and especially in debian
emp_unmount_and_sync
emp_create_ipxe_fragments


echo "ALL DONE"

exit 0

