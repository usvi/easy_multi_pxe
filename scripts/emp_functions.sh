#!/bin/sh

# We need config functions to read the variables we want
# and assign them with program prefix. We dont want to put
# strange prefixes to config files to confuse the user. Yes,
# this adds some complexity but is worth the effort.
# Also, this way we do not need to be using confusing quotes
# in the file.
emp_process_config_line()
{
    case "$1" in
        "WEBSERVER_IP="*)
            EMP_WEBSERVER_IP=${1#"WEBSERVER_IP="}
	    ;;
        "WEBSERVER_PREFIX="*)
            EMP_WEBSERVER_PREFIX=${1#"WEBSERVER_PREFIX="}
	    ;;
        "DRIVERS_BASE_DIR="*)
            EMP_DRIVERS_BASE_DIR=${1#"DRIVERS_BASE_DIR="}
	    ;;
        "CIFS_SERVER_IP="*)
            EMP_CIFS_SERVER_IP=${1#"CIFS_SERVER_IP="}
	    ;;
        "CIFS_SHARE_NAME="*)
            EMP_CIFS_SHARE_NAME=${1#"CIFS_SHARE_NAME="}
	    ;;
        "CIFS_USER="*)
            EMP_CIFS_USER=${1#"CIFS_USER="}
	    ;;
        "CIFS_PASSWD="*)
            EMP_CIFS_PASSWD=${1#"CIFS_PASSWD="}
	    ;;
    esac
}

 
emp_read_config()
{
    # Zero existing
    EMP_WEBSERVER_IP=""
    EMP_WEBSERVER_PREFIX=""
    EMP_DRIVERS_BASE_DIR=""
    EMP_CIFS_SERVER_IP=""
    EMP_CIFS_SHARE_NAME=""
    EMP_CIFS_USER=""
    EMP_CIFS_PASSWD=""

    if [ -f "$1" ]
    then
	while read -r EMP_LINE;
	do
            emp_process_config_line "$EMP_LINE"
	done < "$1"
    fi
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
