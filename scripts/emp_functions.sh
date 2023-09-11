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


emp_search_php_fpm_location()
{
    EMP_PHP_FPM_RUN_SOCK=""

    if [ -d /run/php ]
    then
	for TEMP_FILE in /run/php/*.sock
	do
	    EMP_PHP_FPM_RUN_SOCK="$TEMP_FILE"

	    case "$TEMP_FILE" in
		*"/php-fpm.sock")
		    # Got proper, we can return
		    return
		    ;;
	    esac
	done
    fi

    # If not found in loop, inspect another directory
    if [ -d /var/run/php-fpm ]
    then
	for TEMP_FILE in /var/run/php-fpm/*.sock
	do
	    EMP_PHP_FPM_RUN_SOCK="$TEMP_FILE"

	    case "$TEMP_FILE" in
		*"/php-fpm.sock")
		    # Got proper, we can return
		    return
		    ;;
	    esac
	done
    fi
}


# Add more validation later
emp_validate_php_fpm_location()
{
    if [ -S "$EMP_PHP_FPM_RUN_SOCK" ]
    then
	return 0
    fi

    return 1
}


emp_collect_provisioning_parameters()
{
    EMP_ISO_PATH=""
    EMP_ASSETS_DIR=""
    EMP_COPY_ISO="Y" # Default value
    
    TEMP_OPEN=""
    # Example run (wrapped):
    # root@gw:/opt/easy_multi_pxe# ./scripts/emp_provision_ubuntu_iso_to_assets_dir.sh
    # --isofile /opt/isos_ro/ubuntu/ubuntu-20.04.3-desktop-amd64.iso (mandatory)
    # --assetsdir /opt/easy_multi_pxe/netbootassets/ubuntu/20.04/x64 (mandatory)
    # --nocopyiso (optional)

    # Interchangeable params
    # --isofile -i
    # --assetsdir -a
    # --nocopyiso -n

    for TEMP_PARAM in "$@"
    do
	if [ -z "$TEMP_OPEN" ]
	then
	    # Nothing open
	    if [ "$TEMP_PARAM" = "--isofile" -o "$TEMP_PARAM" = "-i" ]
	    then
		TEMP_OPEN="EMP_ISO_PATH"

	    elif [ "$TEMP_PARAM" = "--assetsdir" -o "$TEMP_PARAM" = "-a" ]
	    then
		TEMP_OPEN="EMP_ASSETS_DIR"

	    elif [ "$TEMP_PARAM" = "--nocopyiso" -o "$TEMP_PARAM" = "-n" ]
	    then
		EMP_COPY_ISO="N"
	    fi
	else
	    if [ "$TEMP_OPEN" = "EMP_ISO_PATH" ]
	    then
		EMP_ISO_PATH="$(realpath $TEMP_PARAM)"
		TEMP_OPEN=""
		
	    elif [ "$TEMP_OPEN" = "EMP_ASSETS_DIR" ]
	    then
		EMP_ASSETS_DIR="$(realpath "${TEMP_PARAM}")"
		TEMP_OPEN=""
	    fi
	fi
    done

    echo "EMP_ISO_PATH: $EMP_ISO_PATH"
    echo "EMP_ASSETS_DIR: $EMP_ASSETS_DIR"
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
