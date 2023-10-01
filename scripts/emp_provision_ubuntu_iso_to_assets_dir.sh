#!/bin/sh

EMP_OP="do_provisioning"
EMP_INC_COMMON="$(dirname "$(realpath "${0}")")/emp_inc_common.sh"
if [ ! -f "$EMP_INC_COMMON" ]; then echo "Error: No common include file $EMP_INC_COMMON"; exit 1; fi
. "$EMP_INC_COMMON"



emp_remove_old_ipxe_fragment_remnants
emp_remove_old_iso_if_needed
emp_force_unmount_generic_mountpoint
emp_mount_iso
emp_analyze_linux_assets_type
emp_remove_old_existing_linux_asset_files
emp_copy_linux_asset_files
emp_copy_iso_if_needed
# Include driver copying later and especially in debian
emp_unmount_and_sync
emp_create_linux_ipxe_fragments
echo "ALL DONE"
exit 0

