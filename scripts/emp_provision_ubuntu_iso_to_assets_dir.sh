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
echo "Debug exit"
exit 1








for IPXE_FRAGMENT in "$FIRST_FRAGMENT" "$SECOND_FRAGMENT"
do
    if [ "$OS_BOOT_ASSETS_TYPE" = "casper" ]
    then
	cat <<EOF > "$IPXE_FRAGMENT"
set http_base $WEBSERVER_HTTP_BASE/$BOOT_OS_ENTRY_ID
set http_iso \${http_base}/$BOOT_OS_ISO_FILE
kernel \${http_base}/vmlinuz nvidia.modeset=0 i915.modeset=0 nouveau.modeset=0 root=/dev/ram0 initrd=initrd ip=dhcp url=\${http_iso} cloud-config-url=/dev/null
initrd \${http_base}/initrd
boot
sleep 5
goto end
EOF
	
    elif [ "$OS_BOOT_ASSETS_TYPE" = "plain" ]
    then
	cat <<EOF > "$IPXE_FRAGMENT"
set http_base $WEBSERVER_HTTP_BASE/$BOOT_OS_ENTRY_ID
kernel \${http_base}/linux nvidia.modeset=0 i915.modeset=0 nouveau.modeset=0 initrd=initrd.gz ip=dhcp
initrd \${http_base}/initrd.gz
boot
sleep 5
goto end
EOF
	
    else
	echo "ERROR: Unknown boot assets type $OS_BOOT_ASSETS_TYPE"
	exit 1
    fi
    
    if [ "$?" -ne 0 ]
    then
	echo "ERROR: Unable to create ipxe fragment $IPXE_FRAGMENT"
	exit 1
    fi
done



echo "ALL DONE"
exit 0

