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
	
    elif [ "$EMP_WIN_TEMPLATE_WIM_ARCH" = "x86" ]
    then
	EMP_WIN_TEMPLATE_WIM_ARCH="x32"
    fi

    if [ "$EMP_WIN_TEMPLATE_MAIN_ARCH" != "$EMP_WIN_TEMPLATE_WIM_ARCH" ]
    then
	echo ""
	echo "ERROR: Wim architecture $EMP_WIN_TEMPLATE_MAIN_ARCH differs from what was given as path ( $EMP_WIN_TEMPLATE_WIM_ARCH )"
	emp_force_unmount_generic_mountpoint

	exit 1
    fi

    echo "done"
}





# Actual start
emp_remove_old_wim_remnants
emp_force_unmount_generic_mountpoint
emp_mount_iso
emp_custom_analyze_assets
emp_copy_work_wim
emp_remove_setup_from_wim
emp_extract_base_wims
emp_collect_trim_list_of_base_wim_files
emp_trim_base_wim
emp_export_final_wim

echo "ALL DONE"

exit 0

