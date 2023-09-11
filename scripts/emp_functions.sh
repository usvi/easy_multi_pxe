#!/bin/sh

copy_dir_progress()
{
    SRC_DIR="$1"
    DEST_DIR="$2"

    SIZE_SRC=$(du --apparent-size -s "$SRC_DIR" | sed "s|\s.*||;" )

    if [ ! -d "$DEST_DIR" ]
    then
	mkdir "$DEST_DIR"

	if [ "$?" -ne 0 ]
	then
	    echo "ERROR: Unable to create destination dir $DEST_DIR for copy"
	    return 1
	fi
    fi

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

    SIZE_PERCENTAGE=$(( ( 100 * SIZE_DEST ) / SIZE_SRC ))
    echo "\rCopying $BOOT_OS_ENTRY_ID.iso : ${SIZE_PERCENTAGE}%"

    wait "$COPY_PID"

    return "$?"
}
