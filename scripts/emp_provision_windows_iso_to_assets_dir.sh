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

BOOT_OS_ISO_FILE="$1"
BOOT_OS_ASSETS_WITH_FAMILY_ARCH_PREFIX_DIR="$(dirname "$2/path_normalizer")"
BOOT_OS_ENTRY_ID="$(basename "${BOOT_OS_ISO_FILE%.*}")"
EMP_ASSETS_ROOT_DIR="$EMP_TOP_DIR/netbootassets"
EMP_BOOT_OS_ENTRY_MOUNT_POINT="$EMP_TOP_DIR/mount"
COPY_ISO="yes"

if [ "$3" = "nocopyiso" ]
then
    COPY_ISO="no"
fi

case "$BOOT_OS_ASSETS_WITH_FAMILY_ARCH_PREFIX_DIR" in
    "$EMP_ASSETS_ROOT_DIR"*)
	# Do nothing, prefix was fine
	;;
    *)
	echo "ERROR: Given assets directory $BOOT_OS_ASSETS_WITH_FAMILY_ARCH_PREFIX_DIR not under top directory $EMP_TOP_DIR"
	exit 1
	;;
esac


BOOT_OS_WITH_FAMILY_ARCH_INFIX_ID=$(echo "$BOOT_OS_ASSETS_WITH_FAMILY_ARCH_PREFIX_DIR" | sed "s|^$EMP_ASSETS_ROOT_DIR\/||")

FS_BOOT_TEMPLATE_UNIX_PATH="$EMP_ASSETS_ROOT_DIR/$BOOT_OS_WITH_FAMILY_ARCH_INFIX_ID/template"
FS_BOOT_OS_UNIX_PATH="$EMP_ASSETS_ROOT_DIR/$BOOT_OS_WITH_FAMILY_ARCH_INFIX_ID/$BOOT_OS_ENTRY_ID"
CIFS_BOOT_OS_UNIX_PATH="//$CIFS_SERVER_IP/$CIFS_SHARE_NAME/$BOOT_OS_WITH_FAMILY_ARCH_INFIX_ID/$BOOT_OS_ENTRY_ID"
CIFS_BOOT_OS_WIN_PATH=$(echo "$CIFS_BOOT_OS_UNIX_PATH" | sed 's|\/|\\\\|g')

# And start
rm -r "$FS_BOOT_OS_UNIX_PATH" > /dev/null 2>&1

if [ ! -d "$EMP_BOOT_OS_ENTRY_MOUNT_POINT" ]
then
    mkdir "$EMP_BOOT_OS_ENTRY_MOUNT_POINT"
fi

umount -f "$EMP_BOOT_OS_ENTRY_MOUNT_POINT" > /dev/null 2>&1


# Mount to template dir
mount -t auto -o loop "$BOOT_OS_ISO_FILE" "$EMP_BOOT_OS_ENTRY_MOUNT_POINT"

if [ "$?" -ne 0 ]
then
    echo "ERROR: Unable to mount iso file $BOOT_OS_ISO_FILE to $EMP_BOOT_OS_ENTRY_MOUNT_POINT"
    exit 1
fi

# Copy the iso mount dir as new path
#cp -rv "$FS_BOOT_TEMPLATE_UNIX_PATH/mount" "$FS_BOOT_OS_UNIX_PATH"

copy_dir_progress()
{
    SRC_DIR="$1"
    DEST_DIR="$2"

    SIZE_SRC=$(du --apparent-size -s "$SRC_DIR" | sed "s|\s.*||;" )

    cp -r "$SRC_DIR" "$DEST_DIR" &
    COPY_PID="$!"

    echo -n "Copying $BOOT_OS_ENTRY_ID.iso : 0%"

    while ps -p "$COPY_PID" > /dev/null 2>&1
    do
	sleep 5
	SIZE_DEST=$(du --apparent-size -s "$DEST_DIR" | sed "s|\s.*||;" )
	SIZE_PERCENTAGE=$(( ( 100 * SIZE_DEST ) / SIZE_SRC ))
	echo -n "\rCopying $BOOT_OS_ENTRY_ID.iso : ${SIZE_PERCENTAGE}%"
    done

    SIZE_PERCENTAGE=$(( ( 100 * SIZE_DEST ) / SIZE_SRC ))
    echo "\rCopying $BOOT_OS_ENTRY_ID.iso : ${SIZE_PERCENTAGE}%"
    
    wait "$COPY_PID"

    return "$?"
}

#copy_dir_progress "$EMP_BOOT_OS_ENTRY_MOUNT_POINT" "$FS_BOOT_OS_UNIX_PATH"

if [ "$COPY_ISO" = "yes" ]
then
    copy_dir_progress "$EMP_BOOT_OS_ENTRY_MOUNT_POINT" "$FS_BOOT_OS_UNIX_PATH"

    echo "Return code of function $?"
fi

#rsync -aHv "$EMP_BOOT_OS_ENTRY_MOUNT_POINT/" "$FS_BOOT_OS_UNIX_PATH"
exit 0

ERRORS=0

if [ ! -d "$ROOT_WIM_DIR/template/mount" ]
then
    mkdir "$ROOT_WIM_DIR/template/mount"
fi

# Files need to exist in template directory
for DIR_ENTRY in "BCD" "boot.sdi" "boot.wim"
do

    if [ ! -f "$ROOT_WIM_DIR/template/$DIR_ENTRY" ]
    then
	echo "ERROR: Template file $ROOT_WIM_DIR/template/$DIR_ENTRY not found"
	ERRORS=1
    fi

done

if [ "$ERRORS" -ne 0 ]
then
    exit 1
fi


for WIM_ENTRY in `ls -1 $ROOT_WIM_DIR`
do
    if [ -d "$ROOT_WIM_DIR/$WIM_ENTRY/unpacked" ]
    then
	echo "Processing $WIM_ENTRY"

	# Delete old stuff, just in case
	for DIR_ENTRY in "BCD" "boot.sdi" "boot.wim"
	do
	    rm -f "$ROOT_WIM_DIR/$WIM_ENTRY/$DIR_ENTRY"
	done

	# And copy the same
	for DIR_ENTRY in "BCD" "boot.sdi" "boot.wim"
	do
	    cp "$ROOT_WIM_DIR/template/$DIR_ENTRY" "$ROOT_WIM_DIR/$WIM_ENTRY/$DIR_ENTRY"
	done

	# Ensure mountdir exists
	mkdir -p "$ROOT_WIM_DIR/$WIM_ENTRY/mount" 2>&1

	# Mount wim
	wimmountrw "$ROOT_WIM_DIR/$WIM_ENTRY/boot.wim" "$ROOT_WIM_DIR/$WIM_ENTRY/mount"
	DRIVERS=0

	if [ "$?" -eq 0 ]
	then
	    # Mount ok

	    if [ -d "$DRIVERS_BASE_DIR/$DRIVER_DIR_ID" ]
	    then
		echo "Drivers found at $DRIVERS_BASE_DIR/$DRIVER_DIR_ID , copying..."
		# Drivers dir exists for this architecture, copy them
		cp -r "$DRIVERS_BASE_DIR/$DRIVER_DIR_ID" "$ROOT_WIM_DIR/$WIM_ENTRY/mount/Windows/System32/extradrivers" &>/dev/null
		DRIVERS=1
	    fi

	    # Startned.cmd to be processed
	    STARTNET="$ROOT_WIM_DIR/$WIM_ENTRY/mount/Windows/System32/startnet.cmd"
	    echo -n "" > "$STARTNET"
	    # Need to do rest with printf because ehco just does not work with redirects

	    echo -n "wpeinit\r\n" >> "$STARTNET"
	    echo -n "for /R extradrivers %%i in (*.inf) do drvload %%i\r\n" >> "$STARTNET"

	    # Could be with or without a password

	    if [ -n "$CIFS_USER" -a -n "$CIFS_PASSWD" ]
	    then
		echo -n "net use j: $CIFS_PREFIX_PATH\\\\$WIM_ENTRY\\\\unpacked /user:$CIFS_USER $CIFS_PASSWD\r\n" >> "$STARTNET"
	    else
		echo -n "net use j: $CIFS_PREFIX_PATH\\\\$WIM_ENTRY\\\\unpacked\r\n" >> "$STARTNET"
	    fi
	    echo -n "j:\\setup.exe\r\n" >> "$STARTNET"
		
	    # Need strange sleep here on mounted cifs for some reason
	    sleep 5
	    wimunmount --commit "$ROOT_WIM_DIR/$WIM_ENTRY/mount"
	fi
    fi
done

echo "ALL DONE"
