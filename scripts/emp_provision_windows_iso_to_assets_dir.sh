#!/bin/sh

EMP_OP="do_provisioning"
EMP_INC_COMMON="$(dirname "$(realpath "${0}")")/emp_inc_common.sh"
if [ ! -f "$EMP_INC_COMMON" ]; then echo "Error: No common include file $EMP_INC_COMMON"; exit 1; fi
. "$EMP_INC_COMMON"


emp_custom_analyze_assets_type()
{
    echo -n "Analyzing assets type..."

    TEMP_WIM_INDEX=1
    TEMP_SOURCE_BOOT_WIM_PATH="$EMP_MOUNT_POINT/$EMP_WIM_FILE_ISO_SUBDIR/$EMP_WIM_INSTALL_FILE_NAME"
    TEMP_SOURCE_BOOT_WIM_ARCH="$(wiminfo "$TEMP_SOURCE_BOOT_WIM_PATH" "$TEMP_WIM_INDEX" | grep "Architecture" | sed 's/[[:alnum:] ]*:\s*//')"

    if [ "$TEMP_SOURCE_BOOT_WIM_ARCH" = "x86_64" -a "$EMP_BOOT_OS_MAIN_ARCH" = "x64" ]
    then
	echo "done"
	
    elif [ "$TEMP_SOURCE_BOOT_WIM_ARCH" = "x86" -a "$EMP_BOOT_OS_MAIN_ARCH" = "x32" ]
    then
	echo "done"

    else
	echo ""
	echo "ERROR: Source arch not consistent with parameters"
	emp_force_unmount_generic_mountpoint
	
	exit 1
    fi
    
}

emp_custom_create_single_ipxe_fragment()
{
    TEMP_PARAM_IPXE_FRAGMENT="$1"
    TEMP_TEMPLATE_FILE_NAME="$(basename "$EMP_TEMPLATE_PATH")"

    cat <<EOF > "$TEMP_PARAM_IPXE_FRAGMENT"
kernel wimboot
initrd --name boot.wim \${template_base}/$TEMP_TEMPLATE_FILE_NAME boot.wim
initrd --name startnet.cmd \${startnet_url} startnet.cmd
EOF
}




# Actual start
emp_remove_old_ipxe_fragment_remnants
emp_force_unmount_generic_mountpoint
emp_mount_iso
emp_custom_analyze_assets_type
emp_unpack_iso_if_needed
emp_unmount_and_sync
emp_create_ipxe_fragments
emp_compile_root_ipxe
