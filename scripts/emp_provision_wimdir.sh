#!/bin/sh

ROOT_WIM_DIR="$1"

THISDIR="`dirname $0`"

. "$THISDIR/../conf/easy_multi_pxe.conf"

# Check that share credentials file exists
if [ ! -f "$THISDIR/../conf/emp_cifs_share.conf" ]
then
    echo "ERROR: CIFS config file $THISDIR/../conf/emp_cifs_share.conf does not exist"
    exit 1
fi
# Now, get it
. "$THISDIR/../conf/emp_cifs_share.conf"

if [ -z "$CIFS_SERVER_IP" ]
then
    echo "ERROR: No CIFS_SERVER_IP defined in $THISDIR/../conf/emp_cifs_share.conf"
    exit 1
fi
# CIFS path, user and password are optional

# We need to see our arch. If we are run with argument
# /opt/easy_multi_pxe/netbootassets/x64/windows/10
# we need to get the x64.

TEMP_DIR="`dirname $ROOT_WIM_DIR`"
TEMP_DIR="`dirname $TEMP_DIR`"
ARCH_ID="`basename $TEMP_DIR`"

# We need to mangle our path to correct part split off
# and for the rest slashes converted.
# $ROOT_WIM_DIR has :
# /opt/easy_multi_pxe/netbootassets/x64/windows/10
# We need to have it first x64/windows/10 and then
# we need to fiddle the amount of backslashes correct.

TEMP_DIR=$(echo "$ROOT_WIM_DIR" | sed "s/.*$WEB_SERVER_PREFIX\///")
CIFS_PATH=$(echo "$TEMP_DIR" | sed 's.\/.\\\\.g')

# Might have prefix
if [ -n "$CIFS_PATH_PREFIX" ]
then
    CIFS_PATH="$CIFS_PATH_PREFIX\\\\$CIFS_PATH"
fi


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
	    # Could be with or without a password

	    if [ -n "$CIFS_USER" -a -n "$CIFS_PASSWD" ]
	    then
		printf "net use j: \\\\\\\\$CIFS_SERVER_IP\\\\$CIFS_PATH\\\\$WIM_ENTRY\\\\unpacked /user:$CIFS_USER $CIFS_PASSWD\r\n" >> "$STARTNET"
	    else
		printf "net use j: \\\\\\\\$CIFS_SERVER_IP\\\\$CIFS_PATH\\\\$WIM_ENTRY\\\\unpacked\r\n" >> "$STARTNET"
	    fi
	    printf "j:\setup.exe\r\n" >> "$STARTNET"
		
	    cat "$STARTNET"

	    # Need strange sleep here on mounted cifs for some reason
	    sleep 5
	    wimunmount --commit "$ROOT_WIM_DIR/$WIM_ENTRY/mount"
	fi

    fi
done

echo "ALL DONE"
