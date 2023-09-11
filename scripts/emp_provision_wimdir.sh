#!/bin/sh

SCRIPTPATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
MAIN_EMP_DIR="`dirname $SCRIPTPATH`"
MAIN_CONFIG="$MAIN_EMP_DIR/conf/easy_multi_pxe.conf"
ASSETS_DIR="$MAIN_EMP_DIR/netbootassets"

ROOT_WIM_DIR="$1"

if [ ! -d "$ROOT_WIM_DIR" ]
then
    echo "ERROR: Given root wim dir $ROOT_WIM_DIR does not exist"
    exit 1
fi


# Check that main config file is there
if [ ! -f "$MAIN_CONFIG" ]
then
    echo "ERROR: Main configuration file $MAIN_CONFIG does not exist"
    exit 1
fi
# Now, get it
. "$MAIN_CONFIG"

# If file exists at all, it has what we need

# We need to see our arch. If we are run with argument
####### /opt/easy_multi_pxe/netbootassets/x64/windows/10
# /opt/easy_multi_pxe/netbootassets/windows/10/x64
# we need to get the windows/10/x64

TEMP_DIR="$ROOT_WIM_DIR"
#OS_VER_ID="`basename $TEMP_DIR`"
OS_ARCH_ID="`basename $TEMP_DIR`"
TEMP_DIR="`dirname $TEMP_DIR`"
#OS_FAMILY_ID="`basename $TEMP_DIR`"
OS_VER_ID="`basename $TEMP_DIR`"
TEMP_DIR="`dirname $TEMP_DIR`"
#OS_ARCH_ID="`basename $TEMP_DIR`"
OS_FAMILY_ID="`basename $TEMP_DIR`"

#DRIVER_DIR_ID="$OS_ARCH_ID/$OS_FAMILY_ID/$OS_VER_ID"
DRIVER_DIR_ID="$OS_FAMILY_ID/$OS_VER_ID/$OS_ARCH_ID"

# We need to mangle our path to correct part split off
# and for the rest slashes converted.
# $ROOT_WIM_DIR has :
##### /opt/easy_multi_pxe/netbootassets/x64/windows/10
# /opt/easy_multi_pxe/netbootassets/windows/10/x64
# $ASSETS_DIR usually has:
# /opt/easy_multi_pxe/netbootassets
# We need to have it first windows/10/x64 and then WHAT?


CIFS_ASSETS_UNIX_ID=$(echo "$ROOT_WIM_DIR" | sed "s|.*$ASSETS_DIR\/||")
CIFS_PREFIX_UNIX_PATH="//$CIFS_SERVER_IP/$CIFS_SHARE_NAME/$CIFS_ASSETS_UNIX_ID"
CIFS_PREFIX_PATH=$(echo "$CIFS_PREFIX_UNIX_PATH" | sed 's.\/.\\\\.g')

# Given directory must exist
if [ ! -d "$ROOT_WIM_DIR" ]
then
    echo "ERROR: Wim base directory $ROOT_WIM_DIR not found"
    exit 1
fi

ERRORS=0

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
	mkdir -p "$ROOT_WIM_DIR/$WIM_ENTRY/mount" &> /dev/null

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
