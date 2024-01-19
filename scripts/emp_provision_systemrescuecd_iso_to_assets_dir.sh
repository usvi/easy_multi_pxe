#!/bin/sh

EMP_OP="do_provisioning"
EMP_INC_COMMON="$(dirname "$(realpath "${0}")")/emp_inc_common.sh"
if [ ! -f "$EMP_INC_COMMON" ]; then echo "Error: No common include file $EMP_INC_COMMON"; exit 1; fi
. "$EMP_INC_COMMON"


emp_custom_analyze_assets_type()
{
    echo -n "Analyzing assets type..."

    # Lets just call it regular and use empty path list.
    # We will enhance this in the future as we learn the
    # systemrescuecd architecture.
    EMP_BOOT_OS_ASSETS_TYPE="regular"
    EMP_BOOT_OS_ASSETS_FILES_COPY_ISO_PATHS_LIST=""

    echo "$EMP_BOOT_OS_ASSETS_TYPE"
}



emp_custom_create_single_ipxe_fragment()
{
    TEMP_PARAM_IPXE_FRAGMENT="$1"

    if [ "$EMP_BOOT_OS_ASSETS_TYPE" = "regular" ]
    then
        cat <<EOF > "$TEMP_PARAM_IPXE_FRAGMENT"
set http_base $EMP_BOOT_OS_ASSETS_HTTP_BASE_PATH/unpacked
kernel \${http_base}/sysresccd/boot/x86_64/vmlinuz nvidia.modeset=0 i915.modeset=0 nouveau.modeset=0 nofirewall archisobasedir=sysresccd initrd=sysresccd.img ip=dhcp checksum archiso_http_srv=\${http_base}/
initrd \${http_base}/sysresccd/boot/intel_ucode.img
initrd \${http_base}/sysresccd/boot/amd_ucode.img
initrd \${http_base}/sysresccd/boot/x86_64/sysresccd.img
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
emp_unpack_iso_if_needed
# Include driver copying later and especially in debian
emp_unmount_and_sync
emp_create_ipxe_fragments


echo "ALL DONE"

exit 0

