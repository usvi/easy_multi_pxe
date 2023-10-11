#!/bin/sh

EMP_OP="create_windows_template"
EMP_INC_COMMON="$(dirname "$(realpath "${0}")")/emp_inc_common.sh"
if [ ! -f "$EMP_INC_COMMON" ]; then echo "Error: No common include file $EMP_INC_COMMON"; exit 1; fi
. "$EMP_INC_COMMON"



emp_custom_analyze_assets()
{
    echo -n "Analyzing assets..."

    EMP_WIN_TEMPLATE_WIM_ARCH="$(wiminfo "$EMP_WIN_TEMPLATE_SOURCE_BOOT_WIM_PATH" 1 | grep "Architecture" | sed 's/Architecture:\s*//')"

    if [ "$EMP_WIN_TEMPLATE_WIM_ARCH" = "x86_64" ]
    then
	EMP_WIN_TEMPLATE_WIM_ARCH="x64"
    fi

    if [ "$EMP_WIN_TEMPLATE_MAIN_ARCH" != "$EMP_WIN_TEMPLATE_WIM_ARCH" ]
    then
	echo ""
	echo "ERROR: Wim architecture $EMP_WIN_TEMPLATE_MAIN_ARCH differs from what was given as path ( $EMP_WIN_TEMPLATE_WIM_ARCH )"
	emp_force_unmount_generic_mountpoint

	exit 1
    fi

    TEMP_TOTAL_BYTES="$(wiminfo "$EMP_WIN_TEMPLATE_SOURCE_BOOT_WIM_PATH" 1 | grep "Total Bytes" | sed 's/[[:alnum:] ]*:\s*//')"
    TEMP_HARD_LINK_BYTES="$(wiminfo "$EMP_WIN_TEMPLATE_SOURCE_BOOT_WIM_PATH" 1 | grep "Hard Link Bytes" | sed 's/[[:alnum:] ]*:\s*//')"
    EMP_WIN_TEMPLATE_SIZE_BYTES_FIRST="$((TEMP_TOTAL_BYTES - TEMP_HARD_LINK_BYTES))"

    TEMP_TOTAL_BYTES="$(wiminfo "$EMP_WIN_TEMPLATE_SOURCE_BOOT_WIM_PATH" 2 | grep "Total Bytes" | sed 's/[[:alnum:] ]*:\s*//')"
    TEMP_HARD_LINK_BYTES="$(wiminfo "$EMP_WIN_TEMPLATE_SOURCE_BOOT_WIM_PATH" 2 | grep "Hard Link Bytes" | sed 's/[[:alnum:] ]*:\s*//')"
    
    EMP_WIN_TEMPLATE_SIZE_BYTES_SECOND="$((TEMP_TOTAL_BYTES - TEMP_HARD_LINK_BYTES))"
    echo "$EMP_WIN_TEMPLATE_WIM1_SIZE_BYTES $EMP_WIN_TEMPLATE_WIM2_SIZE_BYTES"
}





# Actual start
emp_remove_old_wim_remnants
emp_force_unmount_generic_mountpoint
emp_mount_iso
emp_custom_analyze_assets
emp_extract_wims
#emp_unmount_and_sync

echo "ALL DONE"

exit 0

