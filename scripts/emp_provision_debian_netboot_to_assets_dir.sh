#!/bin/sh

EMP_OP="do_provisioning"
EMP_INC_COMMON="$(dirname "$(realpath "${0}")")/emp_inc_common.sh"
if [ ! -f "$EMP_INC_COMMON" ]; then echo "Error: No common include file $EMP_INC_COMMON"; exit 1; fi
. "$EMP_INC_COMMON"


emp_custom_analyze_assets_type()
{
    echo -n "Analyzing assets type..."
    
    if grep -m 1 "NETINST" "$EMP_MOUNT_POINT/README.txt" > /dev/null 2>&1
    then
	EMP_BOOT_OS_ASSETS_TYPE="netinst"
	# Note: install.amd breaks for 32bit
	EMP_BOOT_OS_ASSETS_FILES_COPY_ISO_PATHS_LIST="install.amd/vmlinuz install.amd/initrd.gz"
	
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
emp_unpack_iso_if_needed
# Include driver copying later and especially in debian
emp_unmount_and_sync
emp_create_ipxe_fragments


echo "ALL DONE"

exit 0

