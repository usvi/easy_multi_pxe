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

BOOT_OS_ISO_FILE="$1"
BOOT_OS_ASSETS_WITH_FAMILY_ARCH_PREFIX_DIR="$(dirname "$2/path_normalizer")"
BOOT_OS_ENTRY_ID="$(basename "${BOOT_OS_ISO_FILE%.*}")"
EMP_ASSETS_ROOT_DIR="$EMP_TOP_DIR/netbootassets"
EMP_BOOT_OS_ENTRY_GENERIC_MOUNT_POINT="$EMP_TOP_DIR/work/mount"
EMP_WIM_GENERIC_MOUNT_POINT="$EMP_TOP_DIR/work/wimmount"

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

if [ ! -d "$EMP_WIM_GENERIC_MOUNT_POINT" ]
then
    mkdir "$EMP_WIM_GENERIC_MOUNT_POINT"

    if [ "$?" -ne 0 ]
    then
	echo "ERROR: Failed creating mount point $EMP_WIM_GENERIC_MOUNT_POINT"
	exit 1
    fi
fi

sync
umount -f "$EMP_BOOT_OS_ENTRY_GENERIC_MOUNT_POINT" > /dev/null 2>&1
sleep 5
wimunmount --commit --force "$EMP_WIM_GENERIC_MOUNT_POINT" > /dev/null 2>&1



# Mount to generic mountpoint
mount -t auto -o loop "$BOOT_OS_ISO_FILE" "$EMP_BOOT_OS_ENTRY_GENERIC_MOUNT_POINT"

if [ "$?" -ne 0 ]
then
    echo "ERROR: Unable to mount iso file $BOOT_OS_ISO_FILE to $EMP_BOOT_OS_ENTRY_GENERIC_MOUNT_POINT"
    exit 1
fi



# Copy the iso mount dir as new path if not forbidden
if [ -z "$COPY_ISO" -o "$COPY_ISO" != "no" ]
then
    # Old has been removed in the beginning
    copy_dir_progress "$EMP_BOOT_OS_ENTRY_GENERIC_MOUNT_POINT" "$FS_BOOT_OS_UNIX_PATH"

    if [ "$?" -ne 0 ]
    then
	echo "ERROR: Failed copying iso contents from $EMP_BOOT_OS_ENTRY_GENERIC_MOUNT_POINT to $FS_BOOT_OS_UNIX_PATH"
	umount -f "$EMP_BOOT_OS_ENTRY_GENERIC_MOUNT_POINT" > /dev/null 2>&1
	exit 1
    fi
fi



# Copying done, so unmount the iso already
sync
umount "$EMP_BOOT_OS_ENTRY_GENERIC_MOUNT_POINT" > /dev/null 2>&1

if [ "$?" -ne 0 ]
then
    echo "ERROR: Unable to unmount $EMP_BOOT_OS_ENTRY_GENERIC_MOUNT_POINT"
    exit 1
fi



# Necessary files need to be copied from template directory
echo -n "Copying template files..."
ERRORS=0

for DIR_ENTRY in "BCD" "boot.sdi" "boot.wim"
do
    if [ ! -f "$FS_BOOT_TEMPLATE_UNIX_PATH/$DIR_ENTRY" ]
    then
	echo "error"
	echo "ERROR: Template file $FS_BOOT_TEMPLATE_UNIX_PATH/$DIR_ENTRY not found"
	ERRORS=1
    else
	cp "$FS_BOOT_TEMPLATE_UNIX_PATH/$DIR_ENTRY" "$FS_BOOT_OS_UNIX_PATH"

	if [ "$?" -ne 0 ]
	then
	    echo "error"
	    echo "ERROR: Unable to copy template file $FS_BOOT_TEMPLATE_UNIX_PATH/$DIR_ENTRY to $FS_BOOT_OS_UNIX_PATH"
	    ERRORS=1
	fi
    fi
done

if [ "$ERRORS" -ne 0 ]
then
    umount -f "$EMP_BOOT_OS_ENTRY_GENERIC_MOUNT_POINT" > /dev/null 2>&1
    exit 1
fi

echo "done"


# Mount wim
wimmountrw "$FS_BOOT_OS_UNIX_PATH/boot.wim" "$EMP_WIM_GENERIC_MOUNT_POINT"

if [ "$?" -ne 0 ]
then
    echo "ERROR: Unable to mount $FS_BOOT_OS_UNIX_PATH/boot.wim to $EMP_WIM_GENERIC_MOUNT_POINT"
    exit 1
fi



# Copy drivers if they exist
DRIVERS=0

if [ -d "$DRIVERS_BASE_DIR/$BOOT_OS_WITH_FAMILY_ARCH_INFIX_ID" ]
then
    echo -n "Drivers found at $DRIVERS_BASE_DIR/$BOOT_OS_WITH_FAMILY_ARCH_INFIX_ID , copying..."
    # Drivers dir exists for this architecture, copy them
    cp -r "$DRIVERS_BASE_DIR/$BOOT_OS_WITH_FAMILY_ARCH_INFIX_ID" "$EMP_WIM_GENERIC_MOUNT_POINT/Windows/System32/extradrivers" > /dev/null 2>&1

    if [ "$?" -ne 0 ]
    then
	echo ""
	echo -n "ERROR: Failed copying drivers from"
	echo -n "$DRIVERS_BASE_DIR/$BOOT_OS_WITH_FAMILY_ARCH_INFIX_ID to "
	echo "$EMP_WIM_GENERIC_MOUNT_POINT/Windows/System32/extradrivers"

	sync
	sleep 5
	wimunmount --commit --force "$EMP_WIM_GENERIC_MOUNT_POINT" > /dev/null 2>&1
    fi
    
    DRIVERS=1
    echo "done"
fi




# Startned.cmd to be processed
STARTNET="$EMP_WIM_GENERIC_MOUNT_POINT/Windows/System32/startnet.cmd"
echo -n "" > "$STARTNET"
# Need to do rest with printf because ehco just does not work with redirects

echo -n "wpeinit\r\n" >> "$STARTNET"
echo -n "for /R extradrivers %%i in (*.inf) do drvload %%i\r\n" >> "$STARTNET"

# Could be with or without a password

if [ -n "$CIFS_USER" -a -n "$CIFS_PASSWD" ]
then
    echo -n "net use j: $CIFS_BOOT_OS_WIN_PATH /user:$CIFS_USER $CIFS_PASSWD\r\n" >> "$STARTNET"
else
    echo -n "net use j: $CIFS_BOOT_OS_WIN_PATH\r\n" >> "$STARTNET"
fi
echo -n "j:\\setup.exe\r\n" >> "$STARTNET"


echo -n "Syncinc..."
sync
# Need strange sleep here on mounted cifs for some reason
sleep 5
wimunmount --commit "$EMP_WIM_GENERIC_MOUNT_POINT" > /dev/null 2>&1

if [ "$?" -ne 0 ]
then
    echo "error"
    echo "ERROR: Unable to unmount wim from $EMP_WIM_GENERIC_MOUNT_POINT"
    wimunmount --commit --force "$EMP_WIM_GENERIC_MOUNT_POINT" > /dev/null 2>&1
    exit 1
fi

echo "done"


# Finally, create entries. Entries are pairwise: every arch has bios and efi variant.
FIRST_FRAGMENT=""
SECOND_FRAGMENT=""
WIMBOOT_VARIANT=""

if [ "$BOOT_OS_ARCH" = "x86" ]
then
    FIRST_FRAGMENT="$FS_BOOT_OS_32BIT_BIOS_FRAGMENT_UNIX_PATH"
    SECOND_FRAGMENT="$FS_BOOT_OS_32BIT_EFI_FRAGMENT_UNIX_PATH"
    WIMBOOT_VARIANT="wimboot.i386"

elif [ "$BOOT_OS_ARCH" = "x64" ]
then
    FIRST_FRAGMENT="$FS_BOOT_OS_64BIT_BIOS_FRAGMENT_UNIX_PATH"
    SECOND_FRAGMENT="$FS_BOOT_OS_64BIT_EFI_FRAGMENT_UNIX_PATH"
    WIMBOOT_VARIANT="wimboot"
else
    echo "ERROR: Unrecognized boot OS arch $BOOT_OS_ARCH"
    exit 1
fi


for IPXE_FRAGMENT in "$FIRST_FRAGMENT" "$SECOND_FRAGMENT"
do
    cat <<EOF > "$IPXE_FRAGMENT"
kernel $WIMBOOT_VARIANT
set http_base $WEBSERVER_HTTP_BASE/$BOOT_OS_ENTRY_ID
initrd \${http_base}/BCD BCD
initrd \${http_base}/boot.sdi boot.sdi
initrd \${http_base}/boot.wim boot.wim
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

