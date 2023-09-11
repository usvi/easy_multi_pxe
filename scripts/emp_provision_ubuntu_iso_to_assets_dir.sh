#!/bin/sh

EMP_TOP_DIR="$(dirname "$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )")"

# Check that main config file is there
if [ ! -f "$EMP_TOP_DIR/conf/easy_multi_pxe.conf" ]
then
    echo "ERROR: Main configuration file $EMP_TOP_DIR/conf/easy_multi_pxe.conf does not exist"
    exit 1
fi
# Now, get it
. "$EMP_TOP_DIR/conf/easy_multi_pxe.conf"

# Get also functions definitions
. "$EMP_TOP_DIR/scripts/emp_functions.sh"


if [ ! -f "$1" ]
then
    echo "ERROR: Given iso file $1 does not exist"
    exit 1
fi

if [ ! -d "$2" ]
then
    echo "ERROR: Given boot OS assets prefix directory $2 does not exist"
    exit 1
fi

if [ "$3" = "nocopyiso" ]
then
    COPY_ISO="no"
fi

BOOT_OS_ISO_PATH="$1"
BOOT_OS_ISO_FILE="$(basename "$BOOT_OS_ISO_PATH")"
BOOT_OS_ASSETS_WITH_FAMILY_ARCH_PREFIX_DIR="$(dirname "$2/path_normalizer")"
BOOT_OS_ENTRY_ID="$(basename "${BOOT_OS_ISO_PATH%.*}")"
EMP_ASSETS_ROOT_DIR="$EMP_TOP_DIR/netbootassets"
EMP_BOOT_OS_ENTRY_GENERIC_MOUNT_POINT="$EMP_TOP_DIR/work/mount"

case "$BOOT_OS_ASSETS_WITH_FAMILY_ARCH_PREFIX_DIR" in
    "$EMP_ASSETS_ROOT_DIR"*)
	# Do nothing, prefix was fine
	;;
    *)
	echo "ERROR: Given assets directory $BOOT_OS_ASSETS_WITH_FAMILY_ARCH_PREFIX_DIR not under top directory $EMP_TOP_DIR"
	exit 1
	;;
esac

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
WEBSERVER_HTTP_BASE="http://$WEBSERVER_IP/$WEBSERVER_PREFIX/$BOOT_OS_WITH_FAMILY_ARCH_INFIX_ID"



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
    for REMOVE_FILE in "$FS_BOOT_OS_UNIX_PATH/vmlinuz" "$FS_BOOT_OS_UNIX_PATH/initrd"
    do
	if [ -f "$REMOVE_FILE" ]
	then
	    chmod u+rw "$REMOVE_FILE"
	    rm "$REMOVE_FILE"

	    if [ "$?" -ne 0 ]
	    then
		echo "ERROR: Unable to remove old kernel or initrd file $REMOVE_FILE"
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

cp "$EMP_BOOT_OS_ENTRY_GENERIC_MOUNT_POINT/casper/vmlinuz" "$FS_BOOT_OS_UNIX_PATH/vmlinuz" &&
    pv -w 80 -N "Copying initrd" "$EMP_BOOT_OS_ENTRY_GENERIC_MOUNT_POINT/casper/initrd" > "$FS_BOOT_OS_UNIX_PATH/initrd"
    
if [ "$?" -ne 0 ]
then
    echo "ERROR: Unable to copy vmlinuz and initrd from $EMP_BOOT_OS_ENTRY_GENERIC_MOUNT_POINT/casper/ to $FS_BOOT_OS_UNIX_PATH/"
    exit 1
    umount -f "$EMP_BOOT_OS_ENTRY_GENERIC_MOUNT_POINT" > /dev/null 2>&1
    exit 1
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
    cat <<EOF > "$IPXE_FRAGMENT"
set http_base $WEBSERVER_HTTP_BASE/$BOOT_OS_ENTRY_ID
set http_iso \${http_base}/$BOOT_OS_ISO_FILE
kernel \${http_base}/vmlinuz nvidia.modeset=0 i915.modeset=0 nouveau.modeset=0 root=/dev/ram0 initrd=initrd ip=dhcp url=\${http_iso} cloud-config-url=/dev/null
initrd \${http_base}/initrd
boot
sleep 5
goto end
EOF
    
    if [ "$?" -ne 0 ]
    then
	echo "ERROR: Unable to create ipxe fragment $IPXE_FRAGMENT"
	exit 1
    fi
done



echo "ALL DONE"
exit 0

