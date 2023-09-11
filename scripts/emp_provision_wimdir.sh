#!/bin/sh

THISDIR="`dirname $0`"

. "$THISDIR/../conf/easy_multi_pxe.conf"

ROOT_WIM_DIR="$1"

# Given directory must exist
if [ ! -d "$ROOT_WIM_DIR" ]
then
    echo "ERROR: Wim base directory $ROOT_WIM_DIR not found"
    exit 1
fi

ERRORS=0

# Files need to exist in template directory
for ENTRY in "BCD" "boot.sdi" "boot.wim" "wimboot"
do

    if [ ! -f "$ROOT_WIM_DIR/template/$ENTRY" ]
    then
	echo "ERROR: Template file $ROOT_WIM_DIR/template/$ENTRY not found"
	ERRORS=1
    fi

done

if [ "$ERRORS" -ne 0 ]
then
    exit 1
fi
	

for WIM_ENTRY in `ls -1 "$ROOT_WIM_DIR"`
do
    if [ -d "$WIM_ENTRY/unpacked" ]
    then
	echo "Processing $WIM_ENTRY"
    fi

    
done
