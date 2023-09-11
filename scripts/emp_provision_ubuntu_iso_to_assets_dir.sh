#!/bin/sh

EMP_OP="do_provisioning"
EMP_INC_COMMON="$(dirname "$(realpath "${0}")")/emp_inc_common.sh"
if [ ! -f "$EMP_INC_COMMON" ]; then echo "Error: No common include file $EMP_INC_COMMON"; exit 1; fi
. "$EMP_INC_COMMON"



#BOOT_OS_ISO_PATH="$1"
#BOOT_OS_ISO_FILE="$(basename "$BOOT_OS_ISO_PATH")"

# following is now $EMP_BOOT_OS_ASSETS_DIR
#BOOT_OS_ASSETS_WITH_FAMILY_ARCH_PREFIX_DIR="$(dirname "$2/path_normalizer")"

# follwing is now EMP_BOOT_OS_ISO_NAME
#BOOT_OS_ENTRY_ID="$(basename "${BOOT_OS_ISO_PATH%.*}")"

# fowllowing is now EMP_MOUNT_POINT
#EMP_BOOT_OS_ENTRY_GENERIC_MOUNT_POINT="$EMP_TOP_DIR/work/mount"

# Not needed, emp_verify_provisioning_parameters checks
#case "$BOOT_OS_ASSETS_WITH_FAMILY_ARCH_PREFIX_DIR" in
#    "$EMP_ASSETS_ROOT_DIR"*)
#	# Do nothing, prefix was fine
#	;;
#    *)
#	echo "ERROR: Given assets directory $BOOT_OS_ASSETS_WITH_FAMILY_ARCH_PREFIX_DIR not under top directory $EMP_TOP_DIR"
#	exit 1
#	;;
#esac


# Just to get bearings, earlier run before overhaul
#
# root@gw:/opt/easy_multi_pxe# ./scripts/emp_provision_ubuntu_iso_to_assets_dir.sh /opt/isos_ro/ubuntu/ubuntu-20.04.3-desktop-amd64.iso /opt/easy_multi_pxe/netbootassets/ubuntu/20.04/x64
# Processing ubuntu-20.04.3-desktop-amd64 as ubuntu/20.04/x64
# Copying iso: 2.86GiB 0:01:09 [41.9MiB/s] [===================>] 100%
# Copying initrd: 94.5MiB 0:00:12 [7.83MiB/s] [================>] 100%
# Syncinc...done
# ALL DONE
#
# This creates the following resources
# Assets directory:
# /opt/easy_multi_pxe/netbootassets/ubuntu/20.04/x64/
# Core fragments
# /opt/easy_multi_pxe/netbootassets/ubuntu/20.04/x64/ubuntu-20.04.3-desktop-amd64.64bit-efi.ipxe
# /opt/easy_multi_pxe/netbootassets/ubuntu/20.04/x64/ubuntu-20.04.3-desktop-amd64.64bit-bios.ipxe
#
# Example of one such core fragment, which in at least this case were the same
# set http_base http://172.16.8.254/netbootassets/ubuntu/20.04/x64/ubuntu-20.04.3-desktop-amd64
# set http_iso ${http_base}/ubuntu-20.04.3-desktop-amd64.iso
# kernel ${http_base}/vmlinuz nvidia.modeset=0 i915.modeset=0 nouveau.modeset=0 root=/dev/ram0 initrd=initrd ip=dhcp url=${http_iso} cloud-config-url=/dev/null
# initrd ${http_base}/initrd
# boot
# sleep 5
# goto end



echo "Debug exit"
exit 1

BOOT_OS_WITH_FAMILY_ARCH_INFIX_ID="$(echo "$BOOT_OS_ASSETS_WITH_FAMILY_ARCH_PREFIX_DIR" | sed "s|^$EMP_ASSETS_ROOT_DIR\/||")"
BOOT_OS_ARCH="$(basename "$BOOT_OS_WITH_FAMILY_ARCH_INFIX_ID")"
FS_BOOT_TEMPLATE_UNIX_PATH="$EMP_ASSETS_ROOT_DIR/$BOOT_OS_WITH_FAMILY_ARCH_INFIX_ID/template"
FS_BOOT_OS_UNIX_PATH="$EMP_ASSETS_ROOT_DIR/$BOOT_OS_WITH_FAMILY_ARCH_INFIX_ID/$BOOT_OS_ENTRY_ID"
CIFS_BOOT_OS_UNIX_PATH="//$CIFS_SERVER_IP/$CIFS_SHARE_NAME/$BOOT_OS_WITH_FAMILY_ARCH_INFIX_ID/$BOOT_OS_ENTRY_ID"
CIFS_BOOT_OS_WIN_PATH="$(echo "$CIFS_BOOT_OS_UNIX_PATH" | sed 's|\/|\\\\|g')"
FS_BOOT_OS_32BIT_BIOS_FRAGMENT_UNIX_PATH="$FS_BOOT_OS_UNIX_PATH.32bit-bios.ipxe"
FS_BOOT_OS_32BIT_EFI_FRAGMENT_UNIX_PATH="$FS_BOOT_OS_UNIX_PATH.32bit-efi.ipxe"
FS_BOOT_OS_64BIT_BIOS_FRAGMENT_UNIX_PATH="$FS_BOOT_OS_UNIX_PATH.64bit-bios.ipxe"
FS_BOOT_OS_64BIT_EFI_FRAGMENT_UNIX_PATH="$FS_BOOT_OS_UNIX_PATH.64bit-efi.ipxe"
WEBSERVER_HTTP_BASE="http://$WEBSERVER_IP/$WEBSERVER_PATH_PREFIX/$BOOT_OS_WITH_FAMILY_ARCH_INFIX_ID"



# And start
echo "Processing $BOOT_OS_ENTRY_ID as $BOOT_OS_WITH_FAMILY_ARCH_INFIX_ID"

for IPXE_FRAGMENT in "$FS_BOOT_OS_32BIT_BIOS_FRAGMENT_UNIX_PATH" "$FS_BOOT_OS_32BIT_EFI_FRAGMENT_UNIX_PATH" "$FS_BOOT_OS_64BIT_BIOS_FRAGMENT_UNIX_PATH" "$FS_BOOT_OS_64BIT_EFI_FRAGMENT_UNIX_PATH"
do
    if [ -f "$IPXE_FRAGMENT" ]
    then
	rm "$IPXE_FRAGMENT"

	if [ "$?" -ne 0 ]
	then
	    echo "ERROR: Unable to remove old ipxe fragment $IPXE_FRAGMENT"
	    exit 1
	fi
    fi
done
		     
		     



# Try to remove only if copying iso
if [ -z "$COPY_ISO" -o "$COPY_ISO" != "no" ]
then
    chmod u+rwX "$FS_BOOT_OS_UNIX_PATH"/ -R > /dev/null 2>&1
    rm -r "$FS_BOOT_OS_UNIX_PATH"/* > /dev/null 2>&1

    # Check that old has been removed
    ls "$FS_BOOT_OS_UNIX_PATH"/* > /dev/null 2>&1
    
    if [ "$?" -eq 0 ]
    then
	echo "ERROR: Unable to remove old files from $FS_BOOT_OS_UNIX_PATH"
	exit 1
    fi

else
    # Remove the non-iso files anyways
    for REMOVE_FILE in "vmlinuz" "initrd" "kernel" "initrd.gz"
    do
	if [ -f "$FS_BOOT_OS_UNIX_PATH/$REMOVE_FILE" ]
	then
	    chmod u+rw "$FS_BOOT_OS_UNIX_PATH/$REMOVE_FILE"
	    rm "$FS_BOOT_OS_UNIX_PATH/$REMOVE_FILE"

	    if [ "$?" -ne 0 ]
	    then
		echo "ERROR: Unable to remove old kernel or initrd file $FS_BOOT_OS_UNIX_PATH/$REMOVE_FILE"
		exit 1
	    fi
	fi
    done
fi


if [ ! -d "$EMP_BOOT_OS_ENTRY_GENERIC_MOUNT_POINT" ]
then
    mkdir "$EMP_BOOT_OS_ENTRY_GENERIC_MOUNT_POINT"

    if [ "$?" -ne 0 ]
    then
	echo "ERROR: Failed creating mount point $EMP_BOOT_OS_ENTRY_GENERIC_MOUNT_POINT"
	exit 1
    fi
fi


sync
umount -f "$EMP_BOOT_OS_ENTRY_GENERIC_MOUNT_POINT" > /dev/null 2>&1
sleep 5


if [ ! -d "$FS_BOOT_OS_UNIX_PATH" ]
then
    mkdir "$FS_BOOT_OS_UNIX_PATH"

    if [ "$?" -ne 0 ]
    then
	echo "ERROR: Unable to create boot OS path $FS_BOOT_OS_UNIX_PATH"
	exit 1
    fi
fi

 
# Mount to generic mountpoint
mount -t auto -o loop "$BOOT_OS_ISO_PATH" "$EMP_BOOT_OS_ENTRY_GENERIC_MOUNT_POINT"

if [ "$?" -ne 0 ]
then
    echo "ERROR: Unable to mount iso file $BOOT_OS_ISO_PATH to $EMP_BOOT_OS_ENTRY_GENERIC_MOUNT_POINT"
    exit 1
fi



# Copy the iso mount dir as new path if not forbidden
if [ -z "$COPY_ISO" -o "$COPY_ISO" != "no" ]
then
    # Old has been removed in the beginning
    pv -w 80 -N "Copying iso" "$BOOT_OS_ISO_PATH" > "$FS_BOOT_OS_UNIX_PATH/$BOOT_OS_ISO_FILE"

    if [ "$?" -ne 0 ]
    then
	echo "ERROR: Failed copying iso contents from $EMP_BOOT_OS_ENTRY_GENERIC_MOUNT_POINT to $FS_BOOT_OS_UNIX_PATH"
	umount -f "$EMP_BOOT_OS_ENTRY_GENERIC_MOUNT_POINT" > /dev/null 2>&1
	exit 1
    fi
fi

# Need to copy a couple of extra files
OS_BOOT_ASSETS_TYPE="unknown"

if [ -f "$EMP_BOOT_OS_ENTRY_GENERIC_MOUNT_POINT/casper/vmlinuz" -a -f "$EMP_BOOT_OS_ENTRY_GENERIC_MOUNT_POINT/casper/initrd" ]
then
    cp "$EMP_BOOT_OS_ENTRY_GENERIC_MOUNT_POINT/casper/vmlinuz" "$FS_BOOT_OS_UNIX_PATH/vmlinuz" &&
	pv -w 80 -N "Copying initrd" "$EMP_BOOT_OS_ENTRY_GENERIC_MOUNT_POINT/casper/initrd" > "$FS_BOOT_OS_UNIX_PATH/initrd"
    
    if [ "$?" -ne 0 ]
    then
	echo "ERROR: Unable to copy vmlinuz and initrd from $EMP_BOOT_OS_ENTRY_GENERIC_MOUNT_POINT/casper/ to $FS_BOOT_OS_UNIX_PATH/"
	exit 1
	umount -f "$EMP_BOOT_OS_ENTRY_GENERIC_MOUNT_POINT" > /dev/null 2>&1
	exit 1
    fi
    OS_BOOT_ASSETS_TYPE="casper"

elif [ "$EMP_BOOT_OS_ENTRY_GENERIC_MOUNT_POINT/linux" -a -f "$EMP_BOOT_OS_ENTRY_GENERIC_MOUNT_POINT/initrd.gz" ]
then

    cp "$EMP_BOOT_OS_ENTRY_GENERIC_MOUNT_POINT/linux" "$FS_BOOT_OS_UNIX_PATH/linux" &&
	pv -w 80 -N "Copying initrd.gz" "$EMP_BOOT_OS_ENTRY_GENERIC_MOUNT_POINT/initrd.gz" > "$FS_BOOT_OS_UNIX_PATH/initrd.gz"
    
    if [ "$?" -ne 0 ]
    then
	echo "ERROR: Unable to copy linux and initrd.gz from $EMP_BOOT_OS_ENTRY_GENERIC_MOUNT_POINT/ to $FS_BOOT_OS_UNIX_PATH/"
	exit 1
	umount -f "$EMP_BOOT_OS_ENTRY_GENERIC_MOUNT_POINT" > /dev/null 2>&1
	exit 1
    fi
    OS_BOOT_ASSETS_TYPE="plain"
fi


# Copying done, so unmount the iso already
sync
umount "$EMP_BOOT_OS_ENTRY_GENERIC_MOUNT_POINT" > /dev/null 2>&1

if [ "$?" -ne 0 ]
then
    echo "ERROR: Unable to unmount $EMP_BOOT_OS_ENTRY_GENERIC_MOUNT_POINT"
    exit 1
fi


# Include driver copying later and especially in debian

echo -n "Syncinc..."
sync
sleep 5
sync
echo "done"


# Finally, create entries. Entries are pairwise: every arch has bios and efi variant.
FIRST_FRAGMENT=""
SECOND_FRAGMENT=""

if [ "$BOOT_OS_ARCH" = "x86" ]
then
    FIRST_FRAGMENT="$FS_BOOT_OS_32BIT_BIOS_FRAGMENT_UNIX_PATH"
    SECOND_FRAGMENT="$FS_BOOT_OS_32BIT_EFI_FRAGMENT_UNIX_PATH"

elif [ "$BOOT_OS_ARCH" = "x64" ]
then
    FIRST_FRAGMENT="$FS_BOOT_OS_64BIT_BIOS_FRAGMENT_UNIX_PATH"
    SECOND_FRAGMENT="$FS_BOOT_OS_64BIT_EFI_FRAGMENT_UNIX_PATH"
else
    echo "ERROR: Unrecognized boot OS arch $BOOT_OS_ARCH"
    exit 1
fi


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

