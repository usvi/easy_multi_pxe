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
    EMP_BOOT_OS_ISO_PATH=""
    EMP_BOOT_OS_ASSETS_DIR=""
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
		TEMP_OPEN="EMP_BOOT_OS_ISO_PATH"

	    elif [ "$TEMP_PARAM" = "--assetsdir" -o "$TEMP_PARAM" = "-a" ]
	    then
		TEMP_OPEN="EMP_BOOT_OS_ASSETS_DIR"

	    elif [ "$TEMP_PARAM" = "--nocopyiso" -o "$TEMP_PARAM" = "-n" ]
	    then
		EMP_COPY_ISO="N"
	    fi
	else
	    if [ "$TEMP_OPEN" = "EMP_BOOT_OS_ISO_PATH" ]
	    then
		EMP_BOOT_OS_ISO_PATH="$(realpath "${TEMP_PARAM}" 2>/dev/null)"

		# If path is garbage, variable is empty. In this
		# case assign the original, even if it was erroneous.
		if [ -z "$EMP_BOOT_OS_ISO_PATH" ]
		then
		    EMP_BOOT_OS_ISO_PATH="${TEMP_PARAM}"
		fi
		TEMP_OPEN=""
		
	    elif [ "$TEMP_OPEN" = "EMP_BOOT_OS_ASSETS_DIR" ]
	    then
		EMP_BOOT_OS_ASSETS_DIR="$(realpath "${TEMP_PARAM}" 2>/dev/null)"

		if [ -z "$EMP_BOOT_OS_ASSETS_DIR" ]
		then
		    EMP_BOOT_OS_ASSETS_DIR="${TEMP_PARAM}"
		fi
		TEMP_OPEN=""
	    fi
	fi
    done

    # Separate function checks that params are fine
}


emp_verify_provisioning_parameters()
{
    TEMP_RETVAL="0"
    TEMP_OS_FAMILY="$(basename ${0})"
    TEMP_OS_FAMILY="${TEMP_OS_FAMILY##emp_provision_}"
    TEMP_OS_FAMILY="${TEMP_OS_FAMILY%%_*}"
    EMP_SCRIPT_OS_FAMILY="$TEMP_OS_FAMILY"

    if [ ! -f "$EMP_BOOT_OS_ISO_PATH" ]
    then
	echo "ERROR: Cannot find iso file $EMP_BOOT_OS_ISO_PATH"
	TEMP_RETVAL="1"
    fi
    
    # Can be:
    #
    # $EMP_SCRIPT_OS_FAMILY=ubuntu
    # $EMP_BOOT_OS_ASSETS_DIR=/opt/easy_multi_pxe/netbootassets/ubuntu/20.04/x64
    # $EMP_ASSETS_ROOT_DIR=/opt/easy_multi_pxe/netbootassets
    #
    # Conclusion:
    # $EMP_ASSETS_ROOT_DIR/$EMP_SCRIPT_OS_FAMILY must be the beginning
    # of $EMP_BOOT_OS_ASSETS_DIR

    case "$EMP_BOOT_OS_ASSETS_DIR" in
	"$EMP_ASSETS_ROOT_DIR/$EMP_SCRIPT_OS_FAMILY"*)
	    EMP_BOOT_OS_FAMILY="$EMP_SCRIPT_OS_FAMILY"	    
	    ;;
	*)
	    echo "ERROR: Wrong family given in assets directory $EMP_BOOT_OS_ASSETS_DIR , expected $EMP_SCRIPT_OS_FAMILY"
	    TEMP_RETVAL="1"
	    ;;
    esac

    # Can be:
    #
    # $EMP_BOOT_OS_ASSETS_DIR=/opt/easy_multi_pxe/netbootassets/ubuntu/20.04/x64
    #
    # Conclusion:
    # Must validate the last fragment to have correct arch.
    
    EMP_BOOT_OS_MAIN_ARCH="${EMP_BOOT_OS_ASSETS_DIR##*/}"
    echo "EMP_BOOT_OS_MAIN_ARCH $EMP_BOOT_OS_MAIN_ARCH"

    if [ "$EMP_BOOT_OS_MAIN_ARCH" != "x32" -a "$EMP_BOOT_OS_MAIN_ARCH" != "x64" ]
    then
	echo "ERROR: Wrong main architecture given in assets directory $EMP_BOOT_OS_ASSETS_DIR , x32 or x64"
	TEMP_RETVAL="1"
    fi

    # Can be:
    #
    # $EMP_BOOT_OS_FAMILY=ubuntu
    # $EMP_BOOT_OS_ASSETS_DIR=/opt/easy_multi_pxe/netbootassets/ubuntu/20.04/x64
    # $EMP_ASSETS_ROOT_DIR=/opt/easy_multi_pxe/netbootassets
    # $EMP_BOOT_OS_MAIN_ARCH=x64
    #
    # Conclusion:
    # Must check that only 20.04 remains, so strip from
    # $EMP_BOOT_OS_ASSETS_DIR beginning $EMP_ASSETS_ROOT_DIR/$EMP_BOOT_OS_FAMILY/
    # and from end /$EMP_BOOT_OS_MAIN_ARCH
    # Then check that it is nonzero and does not contains slashes
    EMP_BOOT_OS_MAIN_VERSION="${EMP_BOOT_OS_ASSETS_DIR##$EMP_ASSETS_ROOT_DIR/$EMP_BOOT_OS_FAMILY/}"
    EMP_BOOT_OS_MAIN_VERSION="${EMP_BOOT_OS_MAIN_VERSION%%/$EMP_BOOT_OS_MAIN_ARCH}"

    echo "EMP_BOOT_OS_MAIN_VERSION $EMP_BOOT_OS_MAIN_VERSION"

    case "$EMP_BOOT_OS_MAIN_VERSION" in
	*/*)
	    echo "ERROR: Wrong main version given in assets directory $EMP_BOOT_OS_ASSETS_DIR ; contains extra directory"
	    TEMP_RETVAL="1"
	    ;;
	*)
	    if [ -z "$EMP_BOOT_OS_MAIN_VERSION" ]
	    then
		echo "ERROR: Empty main version given in assets directory $EMP_BOOT_OS_ASSETS_DIR"
		TEMP_RETVAL="1"
	    fi
	    ;;
    esac
    
    return "$TEMP_RETVAL"
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
