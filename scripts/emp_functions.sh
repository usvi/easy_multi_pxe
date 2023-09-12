#!/bin/sh

emp_print_call_help()
{
    echo ""
    echo "Example run:"
    echo "./emp_provision_ubuntu_iso_to_assets_dir.sh "
    echo "--isofile=/opt/isos_ro/ubuntu/20.04/ubuntu-20.04-mini-amd64.iso "
    echo "--assetsparent=/opt/easy_multi_pxe/netbootassets/ubuntu/20.04/x64 "
    echo "[--copyiso=no] "
    echo ""
    echo "Or with short forms:"
    echo "./emp_provision_ubuntu_iso_to_assets_dir.sh "
    echo "-i /opt/isos_ro/ubuntu/20.04/ubuntu-20.04-mini-amd64.iso "
    echo "-a /opt/easy_multi_pxe/netbootassets/ubuntu/20.04/x64 "
    echo "[-c no] "
    echo ""
}



emp_posix_shell_string_replace()
{
    TAIL="$1"
    SEARCH="$2"
    REPLACEMENT="$3"

    RESULT=""

    if [ -z "$TAIL" ]
    then
        echo ""

        return
    fi

    while [ -n "$TAIL" ]
    do
        HEAD="${TAIL%%$SEARCH*}"

        if [ "$HEAD" = "$TAIL" ]
        then
            RESULT="$RESULT$TAIL"
            echo "$RESULT"

            return
        fi

        RESULT="$RESULT$HEAD$REPLACEMENT"
        TAIL="${TAIL#*$SEARCH}"

    done
}



# We need config functions to read the variables we want
# and assign them with program prefix. We dont want to put
# strange prefixes to config files to confuse the user. Yes,
# this adds some complexity but is worth the effort.
# Also, this way we do not need to be using confusing quotes
# in the file.
emp_process_config_line()
{
    case "$1" in
	"WEBSERVER_PROTOCOL="*)
	    EMP_WEBSERVER_PROTOCOL=${1#"WEBSERVER_PROTOCOL="}
	    ;;
        "WEBSERVER_IP="*)
            EMP_WEBSERVER_IP=${1#"WEBSERVER_IP="}
	    ;;
        "WEBSERVER_PATH_PREFIX="*)
            EMP_WEBSERVER_PATH_PREFIX=${1#"WEBSERVER_PATH_PREFIX="}
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
    # Set to defaults
    EMP_WEBSERVER_PROTOCOL="http"
    EMP_WEBSERVER_IP=""
    EMP_WEBSERVER_PATH_PREFIX="netbootassets"
    EMP_DRIVERS_BASE_DIR=""
    EMP_CIFS_SERVER_IP=""
    EMP_CIFS_SHARE_NAME="Netboot"
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
    EMP_BOOT_OS_ASSETS_PARENT=""
    EMP_COPY_ISO="Y" # Default value
    
    TEMP_OPEN=""
    # Example run (wrapped):
    # ./emp_provision_ubuntu_iso_to_assets_dir.sh
    # --isofile=/opt/isos_ro/ubuntu/20.04/ubuntu-20.04-mini-amd64.iso
    # --assetsparent=/opt/easy_multi_pxe/netbootassets/ubuntu/20.04/x64
    # --copyiso=no

    # Or the same:
    # ./emp_provision_ubuntu_iso_to_assets_dir.sh
    # -i /opt/isos_ro/ubuntu/20.04/ubuntu-20.04-mini-amd64.iso
    # -a /opt/easy_multi_pxe/netbootassets/ubuntu/20.04/x64
    # -c no

    # copyiso is not mandatory, others are.

    for TEMP_PARAM in "$@"
    do
	if [ -z "$TEMP_OPEN" ]
	then
	    # Nothing open

	    # Check first if long forms
	    case "$TEMP_PARAM" in
		--isofile=*)
		    TEMP_ISO_PATH="${TEMP_PARAM##--isofile=}"
		    ;;
		--assetsparent=*)
		    TEMP_ASSETS_PARENT="${TEMP_PARAM##--assetsparent=}"
		    ;;
		--copyiso=*)
		    TEMP_COPY_ISO="${TEMP_PARAM##--copyiso=}"
		    ;;
		*)
		    # Here short form opening checks
		    if [ "$TEMP_PARAM" = "-i" ]
		    then
			TEMP_OPEN="EMP_BOOT_OS_ISO_PATH"

		    elif [ "$TEMP_PARAM" = "-a" ]
		    then
			TEMP_OPEN="EMP_BOOT_OS_ASSETS_PARENT"

		    elif [ "$TEMP_PARAM" = "-c" ]
		    then
			TEMP_OPEN="EMP_COPY_ISO"
		    fi
		    ;;
	    esac

	else
	    if [ "$TEMP_OPEN" = "EMP_BOOT_OS_ISO_PATH" ]
	    then
		TEMP_ISO_PATH="$TEMP_PARAM"
		TEMP_OPEN=""
		
	    elif [ "$TEMP_OPEN" = "EMP_BOOT_OS_ASSETS_PARENT" ]
	    then
		TEMP_ASSETS_PARENT="$TEMP_PARAM"
		TEMP_OPEN=""
		
	    elif [ "$TEMP_OPEN" = "EMP_COPY_ISO" ]
	    then
		TEMP_COPYISO="$TEMP_PARAM"
		TEMP_OPEN=""
	    fi
	fi
    done
    # Rudimentary checks for some values here after dereferencing
    # Separate function checks that params are fine in all ways

    EMP_BOOT_OS_ISO_PATH="$(realpath "${TEMP_ISO_PATH}" 2>/dev/null)"
    # If path is garbage, variable is empty. In this
    # case assign the original, even if it was erroneous.
    if [ -z "$EMP_BOOT_OS_ISO_PATH" ]
    then
	EMP_BOOT_OS_ISO_PATH="${TEMP_ISO_PATH}"
    fi
    
    EMP_BOOT_OS_ASSETS_PARENT="$(realpath "${TEMP_ASSETS_PARENT}" 2>/dev/null)"
    # Ditto
    if [ -z "$EMP_BOOT_OS_ASSETS_PARENT" ]
    then
	EMP_BOOT_OS_ASSETS_PARENT="${TEMP_ASSETS_PARENT}"
    fi
    
    # Default is Y, so scan only for no in some forms
    if [ "$TEMP_COPYISO" = "no" -o "$TEMP_COPYISO" = "NO" -o "$TEMP_COPYISO" = "n" -o "$TEMP_COPYISO" = "N" ]
    then
	EMP_COPY_ISO="N"
    fi
}


emp_assert_provisioning_parameters()
{
    TEMP_RETVAL="0"
    TEMP_OS_FAMILY="$(basename ${0})"
    TEMP_OS_FAMILY="${TEMP_OS_FAMILY##emp_provision_}"
    TEMP_OS_FAMILY="${TEMP_OS_FAMILY%%_*}"
    EMP_SCRIPT_OS_FAMILY="$TEMP_OS_FAMILY"

    if [ -z "$EMP_BOOT_OS_ISO_PATH" ]
    then
	echo "ERROR: No iso path given at all"
	TEMP_RETVAL="1"
    fi

    if [ -z "$EMP_BOOT_OS_ASSETS_PARENT" ]
    then
	echo "ERROR: No assets dir given at all"
	TEMP_RETVAL="1"
    fi

    # Bailing out already on errors because would create too many messages
    if [ "$TEMP_RETVAL" -ne 0 ]
    then
	return "$TEMP_RETVAL"
    fi

    # Then the actual checks
    if [ ! -f "$EMP_BOOT_OS_ISO_PATH" ]
    then
	echo "ERROR: Cannot find iso file $EMP_BOOT_OS_ISO_PATH"
	TEMP_RETVAL="1"
    fi
    
    # Can be:
    #
    # $EMP_SCRIPT_OS_FAMILY=ubuntu
    # $EMP_BOOT_OS_ASSETS_PARENT=/opt/easy_multi_pxe/netbootassets/ubuntu/20.04/x64
    # $EMP_ASSETS_ROOT_DIR=/opt/easy_multi_pxe/netbootassets
    #
    # Conclusion:
    # $EMP_ASSETS_ROOT_DIR/$EMP_SCRIPT_OS_FAMILY must be the beginning
    # of $EMP_BOOT_OS_ASSETS_PARENT

    case "$EMP_BOOT_OS_ASSETS_PARENT" in
	"$EMP_ASSETS_ROOT_DIR/$EMP_SCRIPT_OS_FAMILY"*)
	    EMP_BOOT_OS_FAMILY="$EMP_SCRIPT_OS_FAMILY"	    
	    ;;
	*)
	    echo "ERROR: Wrong family given in assets directory $EMP_BOOT_OS_ASSETS_PARENT , expected $EMP_SCRIPT_OS_FAMILY"
	    TEMP_RETVAL="1"
	    ;;
    esac

    # Can be:
    #
    # $EMP_BOOT_OS_ASSETS_PARENT=/opt/easy_multi_pxe/netbootassets/ubuntu/20.04/x64
    #
    # Conclusion:
    # Must validate the last fragment to have correct arch.
    
    EMP_BOOT_OS_MAIN_ARCH="${EMP_BOOT_OS_ASSETS_PARENT##*/}"

    if [ "$EMP_BOOT_OS_MAIN_ARCH" != "x32" -a "$EMP_BOOT_OS_MAIN_ARCH" != "x64" ]
    then
	echo "ERROR: Wrong main architecture given in assets directory $EMP_BOOT_OS_ASSETS_PARENT , x32 or x64"
	TEMP_RETVAL="1"
    fi

    # Can be:
    #
    # $EMP_BOOT_OS_FAMILY=ubuntu
    # $EMP_BOOT_OS_ASSETS_PARENT=/opt/easy_multi_pxe/netbootassets/ubuntu/20.04/x64
    # $EMP_ASSETS_ROOT_DIR=/opt/easy_multi_pxe/netbootassets
    # $EMP_BOOT_OS_MAIN_ARCH=x64
    #
    # Conclusion:
    # Must check that only 20.04 remains, so strip from
    # $EMP_BOOT_OS_ASSETS_PARENT beginning $EMP_ASSETS_ROOT_DIR/$EMP_BOOT_OS_FAMILY/
    # and from end /$EMP_BOOT_OS_MAIN_ARCH
    # Then check that it is nonzero and does not contains slashes
    EMP_BOOT_OS_MAIN_VERSION="${EMP_BOOT_OS_ASSETS_PARENT##$EMP_ASSETS_ROOT_DIR/$EMP_BOOT_OS_FAMILY/}"
    EMP_BOOT_OS_MAIN_VERSION="${EMP_BOOT_OS_MAIN_VERSION%%/$EMP_BOOT_OS_MAIN_ARCH}"

    case "$EMP_BOOT_OS_MAIN_VERSION" in
	*/*)
	    echo "ERROR: Wrong main version given in assets directory $EMP_BOOT_OS_ASSETS_PARENT ; contains extra directory"
	    TEMP_RETVAL="1"
	    ;;
	*)
	    if [ -z "$EMP_BOOT_OS_MAIN_VERSION" ]
	    then
		echo "ERROR: Empty main version given in assets directory $EMP_BOOT_OS_ASSETS_PARENT"
		TEMP_RETVAL="1"
	    fi
	    ;;
    esac

    # Try to make the assets dir
    mkdir -p "$EMP_BOOT_OS_ASSETS_PARENT"

    if [ "$?" -ne 0 ]
    then
	echo "ERROR: Unable to create assets directory $EMP_BOOT_OS_ASSETS_PARENT"
	TEMP_RETVAL=1
    fi

    if [ "$TEMP_RETVAL" -ne 0 ]
    then
	emp_print_call_help
	
	exit 1
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
