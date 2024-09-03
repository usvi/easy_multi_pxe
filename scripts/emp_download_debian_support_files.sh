#!/bin/sh

EMP_OP="download_debian_support_files"
EMP_INC_COMMON="$(dirname "$(realpath "${0}")")/emp_inc_common.sh"
if [ ! -f "$EMP_INC_COMMON" ]; then echo "Error: No common include file $EMP_INC_COMMON"; exit 1; fi
. "$EMP_INC_COMMON"



debian_mirror_selection
debian_download_support_files
echo "ALL DONE"

exit 0

