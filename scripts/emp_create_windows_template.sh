#!/bin/sh

EMP_OP="create_windows_template"
EMP_INC_COMMON="$(dirname "$(realpath "${0}")")/emp_inc_common.sh"
if [ ! -f "$EMP_INC_COMMON" ]; then echo "Error: No common include file $EMP_INC_COMMON"; exit 1; fi
. "$EMP_INC_COMMON"

#EMP_ALL_COMMAND_LINE_PARAMS="$@"
emp_scan_for_single_parameter "--iso-file" "-i"


echo "Windows template debug exit"


exit 1


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
set http_base $EMP_BOOT_OS_ASSETS_HTTP_BASE_PATH
set http_iso \${http_base}/$EMP_BOOT_OS_ISO_FILE
kernel \${http_base}/vmlinuz nvidia.modeset=0 i915.modeset=0 nouveau.modeset=0 root=/dev/ram0 initrd=initrd ip=dhcp url=\${http_iso} cloud-config-url=/dev/null
initrd \${http_base}/initrd
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
    elif [ "$EMP_BOOT_OS_ASSETS_TYPE" = "plain" ]
    then
	# Plain variant of the Ubuntu
        cat <<EOF > "$TEMP_PARAM_IPXE_FRAGMENT"
set http_base $EMP_BOOT_OS_ASSETS_HTTP_BASE_PATH
kernel \${http_base}/linux nvidia.modeset=0 i915.modeset=0 nouveau.modeset=0 initrd=initrd.gz ip=dhcp
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
emp_remove_old_iso_if_needed
emp_force_unmount_generic_mountpoint
emp_mount_iso
emp_custom_analyze_assets_type
emp_copy_simple_asset_files
emp_copy_iso_if_needed
# Include driver copying later and especially in debian
emp_unmount_and_sync
emp_create_ipxe_fragments


echo "ALL DONE"

exit 0

