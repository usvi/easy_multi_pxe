#!/bin/sh

THISDIR="`dirname $0`"

. "$THISDIR/../conf/easy_multi_pxe.conf"

# Load password file if exists
if [ -f "$THISDIR/../conf/passwords.conf" ]
then
    . "$THISDIR/../conf/passwords.conf"
fi

ROOT_WIM_DIR="$1"

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

# We need to see our arch. If we are run with argument
# /opt/easy_multi_pxe/netbootassets/x64/windows/10
# we need to get the x64.

TEMP_ENTRY="`dirname $ROOT_WIM_DIR`"
TEMP_ENTRY="`dirname $TEMP_ENTRY`"
ARCH_ID="`basename $TEMP_ENTRY`"

for WIM_ENTRY in `ls -1 $ROOT_WIM_DIR`
do
    if [ -d "$WIM_ENTRY/unpacked" ]
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

	    if [ -d "$DRIVERS_BASE_DIR/$ARCH_ID" ]
	    then
		echo "Drivers found at $DRIVERS_BASE_DIR/$ARCH_ID , copying..."
		# Drivers dir exists for this architecture, copy them
		cp -r "$DRIVERS_BASE_DIR/$ARCH_ID" "$ROOT_WIM_DIR/$WIM_ENTRY/mount/Windows/System32/extradrivers" &>/dev/null
		DRIVERS=1
	    fi

	    # Startned.cmd to be processed
	    STARTNET="$ROOT_WIM_DIR/$WIM_ENTRY/mount/Windows/System32/startnet.cmd"
	    echo -n "" > "$STARTNET"
	    # Need to do rest with printf because ehco just does not work with redirects
	    printf "for /R extradrivers %%%%i in (*.inf) do drvload %%%%i\r\n" >> "$STARTNET"
	    printf "wpeinit\r\n" >> "$STARTNET"
	    cat "$STARTNET"

	    # Need strange sleep here on mounted cifs for some reason
	    sleep 5
	    wimunmount --commit "$ROOT_WIM_DIR/$WIM_ENTRY/mount"
	fi

    fi
done

echo "ALL DONE"
