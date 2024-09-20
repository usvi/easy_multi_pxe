#!/bin/sh

EMP_OP="do_provisioning"
EMP_INC_COMMON="$(dirname "$(realpath "${0}")")/emp_inc_common.sh"
if [ ! -f "$EMP_INC_COMMON" ]; then echo "Error: No common include file $EMP_INC_COMMON"; exit 1; fi
. "$EMP_INC_COMMON"


emp_custom_analyze_assets_type()
{
    echo -n "Analyzing assets type..."

    if [ -f "$EMP_MOUNT_POINT/casper/vmlinuz" -a -f "$EMP_MOUNT_POINT/casper/initrd" ]
    then
	EMP_BOOT_OS_ASSETS_TYPE="casper"
	EMP_BOOT_OS_ASSETS_FILES_COPY_ISO_PATHS_LIST="casper/vmlinuz casper/initrd"
	
    elif [ -f "$EMP_MOUNT_POINT/linux" -a -f "$EMP_MOUNT_POINT/initrd.gz" ]
    then
	EMP_BOOT_OS_ASSETS_TYPE="plain"
	EMP_BOOT_OS_ASSETS_FILES_COPY_ISO_PATHS_LIST="linux initrd.gz"
	
    else
	echo ""
        echo "ERROR: Unable to analyze assets type for  boot methodology of the iso file"
	emp_force_unmount_generic_mountpoint
	
        exit 1
    fi

    echo "$EMP_BOOT_OS_ASSETS_TYPE"
}



emp_custom_create_single_ipxe_fragment()
{
    TEMP_PARAM_IPXE_FRAGMENT="$1"

    if [ "$EMP_BOOT_OS_ASSETS_TYPE" = "casper" ]
    then
        cat <<EOF > "$TEMP_PARAM_IPXE_FRAGMENT"
set http_iso \${os_assets_base}/$EMP_BOOT_OS_ISO_FILE
kernel \${os_assets_base}/vmlinuz nvidia.modeset=0 i915.modeset=0 nouveau.modeset=0 root=/dev/ram0 initrd=initrd ip=dhcp url=\${http_iso} cloud-config-url=/dev/null
initrd \${os_assets_base}/initrd
EOF
        if [ "$?" -ne 0 ]
        then
            echo ""
            echo "ERROR: Unable to create ipxe fragment $TEMP_PARAM_IPXE_FRAGMENT"

            exit 1
        fi
    elif [ "$EMP_BOOT_OS_ASSETS_TYPE" = "plain" ]
    then
	# Plain variant of the Ubuntu
        cat <<EOF > "$TEMP_PARAM_IPXE_FRAGMENT"
kernel \${os_assets_base}/linux nvidia.modeset=0 i915.modeset=0 nouveau.modeset=0 initrd=initrd.gz ip=dhcp
initrd \${os_assets_base}/initrd.gz
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
emp_copy_simple_asset_files
emp_copy_iso_if_needed
# Include driver copying later and especially in debian
emp_unmount_and_sync
emp_create_ipxe_fragments
emp_compile_root_ipxe


echo "ALL DONE"

exit 0

