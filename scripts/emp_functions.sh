#!/bin/sh


emp_print_call_help()
{
    echo ""
    echo "Example run:"
    echo "./emp_provision_ubuntu_iso_to_assets_dir.sh "
    echo "--isofile=/opt/isos_ro/ubuntu/20.04/ubuntu-20.04-mini-amd64.iso "
    echo "--assetsparent=/opt/easy_multi_pxe/netbootassets/ubuntu/20.04/x64 "
    echo "[--copyiso=no] "
    echo "[--unpackiso=no] "
    echo ""
    echo "Or with short forms:"
    echo "./emp_provision_ubuntu_iso_to_assets_dir.sh "
    echo "-i /opt/isos_ro/ubuntu/20.04/ubuntu-20.04-mini-amd64.iso "
    echo "-a /opt/easy_multi_pxe/netbootassets/ubuntu/20.04/x64 "
    echo "[-c no] "
    echo "[-u no] "
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


emp_copy_file()
{
    TEMP_SOURCE="$1"
    TEMP_FULL_DESTINATION="$2"

    TEMP_SOURCE_FILE_NAME="$(basename ${TEMP_SOURCE})"
    TEMP_SIZE="$(stat --printf=%s ${TEMP_SOURCE})"
    
    if [ "$TEMP_SIZE" -lt "$EMP_COPY_WITH_PROGRESS_SIZE" ]
    then
	# Normal copy
	cp "$TEMP_SOURCE" "$TEMP_FULL_DESTINATION" > /dev/null 2>&1
    else
	# Progress copy
	pv -w 80 -N "$TEMP_SOURCE_FILE_NAME" "$TEMP_SOURCE" > "$TEMP_FULL_DESTINATION"
    fi

    return "$?"
}


emp_copy_directory()
{
    TEMP_SOURCE="$1"
    TEMP_FULL_DESTINATION="$2"

    # We can add later fancy progress thingy here
    cp -r "$TEMP_SOURCE" "$TEMP_FULL_DESTINATION" > /dev/null 2>&1

    if [ "$?" -ne 0 ]
    then
	return "$?"
    fi

    echo "DOING chmod -r $EMP_ASSETS_DIRS_CHMOD_PERMS $TEMP_FULL_DESTINATION"
    chmod -R "$EMP_ASSETS_DIRS_CHMOD_PERMS" "$TEMP_FULL_DESTINATION" > /dev/null 2>&1

    return "$?"
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
    EMP_UNPACK_ISO="Y" # Default value
    
    TEMP_OPEN=""
    # Example run (wrapped):
    # ./emp_provision_ubuntu_iso_to_assets_dir.sh
    # --isofile=/opt/isos_ro/ubuntu/20.04/ubuntu-20.04-mini-amd64.iso
    # --assetsparent=/opt/easy_multi_pxe/netbootassets/ubuntu/20.04/x64
    # --copyiso=no
    # --unpackiso=no

    # Or the same:
    # ./emp_provision_ubuntu_iso_to_assets_dir.sh
    # -i /opt/isos_ro/ubuntu/20.04/ubuntu-20.04-mini-amd64.iso
    # -a /opt/easy_multi_pxe/netbootassets/ubuntu/20.04/x64
    # -c no
    # -u no

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
		--unpackiso=*)
		    TEMP_UNPACK_ISO="${TEMP_PARAM##--unpackiso=}"
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
			
		    elif [ "$TEMP_PARAM" = "-u" ]
		    then
			TEMP_OPEN="EMP_UNPACK_ISO"
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
		TEMP_COPY_ISO="$TEMP_PARAM"
		TEMP_OPEN=""
		
	    elif [ "$TEMP_OPEN" = "EMP_UNPACK_ISO" ]
	    then
		TEMP_UNPACK_ISO="$TEMP_PARAM"
		TEMP_OPEN=""
	    fi
	fi
    done
    # Rudimentary checks for some values here after dereferencing
    # Separate function checks that params are fine in all ways

    EMP_BOOT_OS_ISO_PATH="$(realpath "${TEMP_ISO_PATH}" > /dev/null 2>&1)"
    # If path is garbage, variable is empty. In this
    # case assign the original, even if it was erroneous.
    if [ -z "$EMP_BOOT_OS_ISO_PATH" ]
    then
	EMP_BOOT_OS_ISO_PATH="${TEMP_ISO_PATH}"
    fi
    
    EMP_BOOT_OS_ASSETS_PARENT="$(realpath "${TEMP_ASSETS_PARENT}" > /dev/null 2>&1)"
    # Ditto
    if [ -z "$EMP_BOOT_OS_ASSETS_PARENT" ]
    then
	EMP_BOOT_OS_ASSETS_PARENT="${TEMP_ASSETS_PARENT}"
    fi
    
    # Default is Y, so scan only for no in some forms
    if [ "$TEMP_COPY_ISO" = "no" -o "$TEMP_COPY_ISO" = "NO" -o "$TEMP_COPY_ISO" = "n" -o "$TEMP_COPY_ISO" = "N" ]
    then
	EMP_COPY_ISO="N"
    fi
    # Same
    if [ "$TEMP_UNPACK_ISO" = "no" -o "$TEMP_UNPACK_ISO" = "NO" -o "$TEMP_UNPACK_ISO" = "n" -o "$TEMP_UNPACK_ISO" = "N" ]
    then
	EMP_UNPACK_ISO="N"
    fi
}


emp_assert_provisioning_parameters()
{
    TEMP_RETVAL="0"
    TEMP_SCRIPT_OS_FAMILY="$(basename ${0})"
    TEMP_SCRIPT_OS_FAMILY="${TEMP_SCRIPT_OS_FAMILY##emp_provision_}"
    TEMP_SCRIPT_OS_FAMILY="${TEMP_SCRIPT_OS_FAMILY%%_*}"
    TEMP_SCRIPT_OS_FAMILY="$TEMP_SCRIPT_OS_FAMILY"

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
	emp_print_call_help
	
	exit "$TEMP_RETVAL"
    fi

    # Then the actual checks
    if [ ! -f "$EMP_BOOT_OS_ISO_PATH" ]
    then
	echo "ERROR: Cannot find iso file $EMP_BOOT_OS_ISO_PATH"
	TEMP_RETVAL="1"
    fi
    
    # Can be:
    #
    # $TEMP_SCRIPT_OS_FAMILY=ubuntu
    # $EMP_BOOT_OS_ASSETS_PARENT=/opt/easy_multi_pxe/netbootassets/ubuntu/20.04/x64
    # $EMP_ASSETS_ROOT_DIR=/opt/easy_multi_pxe/netbootassets
    #
    # Conclusion:
    # $EMP_ASSETS_ROOT_DIR/$TEMP_SCRIPT_OS_FAMILY must be the beginning
    # of $EMP_BOOT_OS_ASSETS_PARENT

    case "$EMP_BOOT_OS_ASSETS_PARENT" in
	"$EMP_ASSETS_ROOT_DIR/$TEMP_SCRIPT_OS_FAMILY"*)
	    EMP_BOOT_OS_FAMILY="$TEMP_SCRIPT_OS_FAMILY"
	    ;;
	*)
	    echo "ERROR: Wrong family given in assets directory $EMP_BOOT_OS_ASSETS_PARENT , expected $TEMP_SCRIPT_OS_FAMILY"
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
    TEMP_OS_MAIN_VERSION="${EMP_BOOT_OS_ASSETS_PARENT##$EMP_ASSETS_ROOT_DIR/$EMP_BOOT_OS_FAMILY/}"
    EMP_BOOT_OS_MAIN_VERSION="${TEMP_OS_MAIN_VERSION%%/$EMP_BOOT_OS_MAIN_ARCH}"

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

    if [ "$TEMP_RETVAL" -ne 0 ]
    then
	emp_print_call_help
	
	exit 1
    fi
}


emp_ensure_general_directories()
{
    # Check the mount directory
    if [ ! -d "$EMP_MOUNT_POINT" ]
    then
	mkdir -p "$EMP_MOUNT_POINT"
	
	if [ "$?" -ne 0 ]
	then
	    echo "ERROR: Unable to create monut point directory $EMP_MOUNT_POINT"

	    exit 1
	fi

	chmod "$EMP_MOUNT_POINT_CHMOD_PERMS" "$EMP_MOUNT_POINT"

	if [ "$?" -ne 0 ]
	then
	    echo "ERROR: Unable to ensure chmod permissions for mouny point directory $EMP_MOUNT_POINT"

	    exit 1
	fi

    fi
}


ensure_assets_dirs()
{
    # Try to make the assets parent dir, like
    # /opt/easy_multi_pxe/netbootassets/ubuntu/20.04/x64
    if [ ! -d "$EMP_BOOT_OS_ASSETS_PARENT" ]
    then
	mkdir -p "$EMP_BOOT_OS_ASSETS_PARENT"

	if [ "$?" -ne 0 ]
	then
	    echo "ERROR: Unable to create assets parent directory $EMP_BOOT_OS_ASSETS_PARENT"

	    exit 1
	fi
	
	chmod "$EMP_ASSETS_DIRS_CHMOD_PERMS" "$EMP_BOOT_OS_ASSETS_PARENT"

	if [ "$?" -ne 0 ]
	then
	    echo "ERROR: Unable to ensure chmod permissions for assets parent directory $EMP_BOOT_OS_ASSETS_PARENT"

	    exit 1
	fi
    fi
    
    # Then the actual specific assets directory, like
    # /opt/easy_multi_pxe/netbootassets/ubuntu/20.04/x64/ubuntu-20.04-mini-amd64
    if [ ! -d "$EMP_BOOT_OS_ASSETS_FS_BASE_PATH" ]
    then
	mkdir "$EMP_BOOT_OS_ASSETS_FS_BASE_PATH"

	if [ "$?" -ne 0 ]
	then
	    echo "ERROR: Unable to create the assets base path $EMP_BOOT_OS_ASSETS_FS_BASE_PATH"

	    exit 1
	fi

	chmod "$EMP_ASSETS_DIRS_CHMOD_PERMS" "$EMP_BOOT_OS_ASSETS_FS_BASE_PATH"

	if [ "$?" -ne 0 ]
	then
	    echo "ERROR: Unable to ensure chmod permissions for assets base path $EMP_BOOT_OS_ASSETS_FS_BASE_PATH"

	    exit 1
	fi
    fi
}



# This functions removes fragment we are going to remove if
# they exist. We are also going to remove other fragments of
# the same "base" because if they happen to exist in current
# directory, they are in the wrong place anyways
emp_remove_old_ipxe_fragment_remnants()
{
    echo -n "Removing old ipxe fragment remnants..."
    
    for TEMP_FRAGMENT in "$EMP_BOOT_OS_FRAGMENT_PATH_FIRST" \
			 "$EMP_BOOT_OS_FRAGMENT_PATH_SECOND" \
			 "$EMP_NONMATCHING_BOOT_OS_FRAGMENT_PATH_FIRST" \
			 "$EMP_NONMATCHING_BOOT_OS_FRAGMENT_PATH_SECOND"
    do
	if [ -f "$TEMP_FRAGMENT" ]
	then
	    rm "$TEMP_FRAGMENT" > /dev/null 2>&1

	    if [ "$?" -ne 0 ]
	    then
		echo ""
		echo "ERROR: Unable to remove old ipxe fragment $TEMP_FRAGMENT"

		exit 1
	    fi
	fi
    done

    echo "done"
}


emp_remove_old_iso_if_needed()
{
    if [ "$EMP_COPY_ISO" = "Y" ]
    then
	# Remove only if iso exists
	if [ -f "$EMP_BOOT_OS_ASSETS_FS_BASE_PATH/$EMP_BOOT_OS_ISO_FILE" ]
	then
	    echo -n "Removing old iso before copying new..."
	    rm "$EMP_BOOT_OS_ASSETS_FS_BASE_PATH/$EMP_BOOT_OS_ISO_FILE" > /dev/null 2>&1

	    if [ "$?" -ne 0 ]
	    then
		echo ""
		echo "ERROR: Unable to remove old iso file $EMP_BOOT_OS_ASSETS_FS_BASE_PATH/$EMP_BOOT_OS_ISO_FILE"

		exit 1
	    fi
	    echo "done"
	fi
    fi
}


emp_remove_old_unpacked_if_needed()
{
    if [ "$EMP_UNPACK_ISO" = "Y" ]
    then
	# Remove only if iso exists
	if [ -d "$EMP_BOOT_OS_ASSETS_FS_BASE_PATH/$EMP_BOOT_OS_ASSETS_UNPACKED_ISO_SUBDIR" ]
	then
	    echo -n "Removing old unpacked dir before copying new..."
	    rm -r "$EMP_BOOT_OS_ASSETS_FS_BASE_PATH/$EMP_BOOT_OS_ASSETS_UNPACKED_ISO_SUBDIR"  > /dev/null 2>&1
	    
	    if [ "$?" -ne 0 ]
	    then
		echo ""
		echo "ERROR: Unable to remove old unpacked dir $EMP_BOOT_OS_ASSETS_FS_BASE_PATH/$EMP_BOOT_OS_ASSETS_UNPACKED_ISO_SUBDIR"

		exit 1
	    fi
	    echo "done"
	fi
    fi
}



emp_force_unmount_generic_mountpoint()
{
    sync
    umount -f "$EMP_MOUNT_POINT" > /dev/null 2>&1
    sleep 5
}


emp_mount_iso()
{
    echo -n "Mounting iso via loop device..."
    mount -t auto -o loop "$EMP_BOOT_OS_ISO_PATH" "$EMP_MOUNT_POINT" > /dev/null 2>&1
    
    if [ "$?" -ne 0 ]
    then
	echo ""
	echo "ERROR: Unable to mount the iso file $EMP_BOOT_OS_ISO_PATH to $EMP_MOUNT_POINT"
	emp_force_unmount_generic_mountpoint

	exit 1
    fi
    echo "done"
}


emp_copy_simple_asset_files()
{
    echo "Copying simple asset files"
    
    TEMP_LIST_TAIL="$EMP_BOOT_OS_ASSETS_FILES_COPY_ISO_PATHS_LIST"

    while [ -n "$TEMP_LIST_TAIL" ]
    do
	TEMP_FILE_ISOPATH="${TEMP_LIST_TAIL%% *}"
	TEMP_LIST_TAIL="${TEMP_LIST_TAIL#* }"

	if [ "$TEMP_FILE_ISOPATH" = "$TEMP_LIST_TAIL" ]
	then
	    TEMP_LIST_TAIL=""
	fi
	TEMP_FILE_NAME="$(basename ${TEMP_FILE_ISOPATH})"

	# Need to remove them first from assets if existing
	if [ -f "$EMP_BOOT_OS_ASSETS_FS_BASE_PATH/$TEMP_FILE_NAME" ]
	then
	    rm "$EMP_BOOT_OS_ASSETS_FS_BASE_PATH/$TEMP_FILE_NAME" > /dev/null 2>&1
	    
	    if [ "$?" -ne 0 ]
	    then
		echo ""
		echo "ERROR: Unable to remove old asset file $EMP_BOOT_OS_ASSETS_FS_BASE_PATH/$TEMP_FILE_NAME"
		emp_force_unmount_generic_mountpoint
		
		exit 1
	    fi
	fi

	# Next actually copy from path to file
	# Decide by stat
	emp_copy_file "$EMP_MOUNT_POINT/$TEMP_FILE_ISOPATH" "$EMP_BOOT_OS_ASSETS_FS_BASE_PATH/$TEMP_FILE_NAME"

	if [ "$?" -ne 0 ]
	then
	    echo ""
	    echo "ERROR: Unable to copy asset file from $EMP_MOUNT_POINT/$TEMP_FILE_ISOPATH to $EMP_BOOT_OS_ASSETS_FS_BASE_PATH/$TEMP_FILE_NAME "
	    emp_force_unmount_generic_mountpoint
	    
	    exit 1
	fi
    done

    echo "Done copying simple asset files"
}


emp_copy_iso_if_needed()
{
    if [ "$EMP_COPY_ISO" = "Y" ]
    then
	pv -w 80 -N "Copying iso" "$EMP_BOOT_OS_ISO_PATH" > "$EMP_BOOT_OS_ASSETS_FS_BASE_PATH/$EMP_BOOT_OS_ISO_FILE"

	if [ "$?" -ne 0 ]
	then
	    echo "ERROR: Unable to copy iso file $EMP_BOOT_OS_ISO_PATH to $EMP_BOOT_OS_ASSETS_FS_BASE_PATH"
	    emp_force_unmount_generic_mountpoint

	    exit 1
	fi
    fi
}


emp_unpack_iso()
{
    if [ "$EMP_UNPACK_ISO" = "Y" ]
    then
	echo "Unpacking iso..."

	# Need to remove old if existing

	emp_copy_directory "$EMP_MOUNT_POINT" "$EMP_BOOT_OS_ASSETS_FS_BASE_PATH/$EMP_BOOT_OS_ASSETS_UNPACKED_ISO_SUBDIR"

	if [ "$?" -ne 0 ]
	then
	    echo "ERROR: Unable to unpack iso mounted at $EMP_MOUNT_POINT to $EMP_BOOT_OS_ASSETS_FS_BASE_PATH/$EMP_BOOT_OS_ASSETS_UNPACKED_ISO_SUBDIR"
	    emp_force_unmount_generic_mountpoint

	    exit 1
	fi
	echo "Done unpacking iso"
    fi
} 


emp_unmount_and_sync()
{
    echo -n "Unmounting and syncinc..."
    sync > /dev/null 2>&1
    umount "$EMP_MOUNT_POINT" > /dev/null 2>&1

    if [ "$?" -ne 0 ]
    then
	echo ""
	echo "ERROR: Unable to unmount generic mount point $EMP_MOUNT_POINT"
	emp_force_unmount_generic_mountpoint

	exit 1
    fi

    sync > /dev/null 2>&1
    sleep 5 > /dev/null 2>&1
    sync > /dev/null 2>&1
    echo "done"
}


# Every provisioning script defines their own
# emp_custom_create_single_ipxe_fragment()
emp_create_ipxe_fragments()
{
    echo -n "Creating ipxe fragments..."
    
    for TEMP_IPXE_FRAGMENT in "$EMP_BOOT_OS_FRAGMENT_PATH_FIRST" "$EMP_BOOT_OS_FRAGMENT_PATH_SECOND"
    do
	emp_custom_create_single_ipxe_fragment "$TEMP_IPXE_FRAGMENT"
    done
    echo "done"
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
