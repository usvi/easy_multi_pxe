#!/bin/sh

copy_dir_progress()
{
    SRC_DIR="$1"
    DEST_DIR="$2"

    if [ ! -d "$DEST_DIR" ]
    then
	mkdir "$DEST_DIR"

	if [ "$?" -ne 0 ]
	then
	    echo "ERROR: Unable to create destination dir $DEST_DIR for copy"
	    return 1
	fi
    fi
    
    SIZE_SRC=$(du --apparent-size -s "$SRC_DIR" | sed "s|\s.*||;" )

    cp -r "$SRC_DIR"/* "$DEST_DIR" &
    COPY_PID="$!"

    echo -n "Copying $BOOT_OS_ENTRY_ID.iso : 0%"

    while ps -p "$COPY_PID" > /dev/null 2>&1
    do
        sleep 5
        SIZE_DEST=$(du --apparent-size -s "$DEST_DIR" | sed "s|\s.*||;" )
        SIZE_PERCENTAGE=$(( ( 100 * SIZE_DEST ) / SIZE_SRC ))
        echo -n "\rCopying $BOOT_OS_ENTRY_ID.iso : ${SIZE_PERCENTAGE}%"
    done


    wait "$COPY_PID"
    COPY_RETVAL="$?"

    # Due to strangeties, print the 100% if copy is complete
    if [ "$COPY_RETVAL" -eq 0 ]
    then
	echo "\rCopying $BOOT_OS_ENTRY_ID.iso : 100%"
    fi

    return "$COPY_RETVAL"
}

check_iso_file()
{
    if [ ! -f "$1" ]
    then
	echo "ERROR: Given iso file $1 does not exist"

	exit 1
    fi
}

check_assets_prefix_dir()
{
    if [ ! -d "$1" ]
    then
	echo "ERROR: Given boot OS assets prefix directory $1 does not exist"

	exit 1
    fi
}

check_copy_iso()
{
    if [ "$1" = "nocopyiso" ]
    then
	COPY_ISO="no"
    fi
}
