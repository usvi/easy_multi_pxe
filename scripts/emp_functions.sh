#!/bin/sh


emp_print_provisioning_help()
{
    echo ""
    echo "Example run:"
    echo "./emp_provision_ubuntu_iso_to_assets_dir.sh "
    echo "--iso-file=/opt/isos_ro/ubuntu/20.04/ubuntu-20.04-mini-amd64.iso "
    echo "--assets-parent=/opt/easy_multi_pxe/netbootassets/ubuntu/20.04/x64 "
    echo "[--copy-iso=no] "
    echo "[--unpack-iso=no] "
    echo ""
    echo "Or with short forms:"
    echo "./emp_provision_ubuntu_iso_to_assets_dir.sh "
    echo "-i /opt/isos_ro/ubuntu/20.04/ubuntu-20.04-mini-amd64.iso "
    echo "-a /opt/easy_multi_pxe/netbootassets/ubuntu/20.04/x64 "
    echo "[-c no] "
    echo "[-u no] "
    echo ""
}



emp_print_windows_template_creation_help()
{
    echo ""
    echo "Example run:"
    echo "./emp_create_windows_template.sh "
    echo "--iso-file=/opt/isos_ro/win10/Win10_22H2_English_x64-2023-04-08.iso "
    echo "--template-dir=/opt/easy_multi_pxe/netbootassets/windows/template/x64 "
    echo ""
    echo "Or with short forms:"
    echo "./emp_create_windows_template.sh "
    echo "-i /opt/isos_ro/win10/Win10_22H2_English_x64-2023-04-08.iso "
    echo "-t /opt/easy_multi_pxe/netbootassets/windows/template/x64 "
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


emp_count_dir_data_size()
{
    TEMP_DU_DIR="$1"

    TEMP_DU_OUT="$(du --apparent-size -s "${TEMP_DU_DIR}" 2>/dev/null)"
    TEMP_SIZE="${TEMP_DU_OUT%%	*}" # Literal tab!!
    echo "$TEMP_SIZE"
}


emp_copy_directory()
{
    TEMP_SOURCE="$1"
    TEMP_FULL_DESTINATION="$2"
    TEMP_DESTINATION_CHMOD_PERMS="$3"
    TEMP_PRINT_PREFIX="$4"

    TEMP_SIZE_SOURCE="$(emp_count_dir_data_size "$TEMP_SOURCE")"
    # We can add later fancy progress thingy here
    cp -r "$TEMP_SOURCE" "$TEMP_FULL_DESTINATION" > /dev/null 2>&1 &
    TEMP_CP_PID="$!"
    TEMP_STEP=0

    while [ "$TEMP_STEP" -lt "$EMP_PROGRESS_MAX_STEPS" ]
    do
	sleep "$EMP_PROGRESS_INTERVAL_SECS" > /dev/null 2>&1
	ps -p "$TEMP_CP_PID" > /dev/null 2>&1

	if [ "$?" -eq 0 ]
	then
	    #echo "Still running"
	    TEMP_SIZE_DESTINATION="$(emp_count_dir_data_size "$TEMP_FULL_DESTINATION")"
	    #echo "$TEMP_SIZE_DESTINATION / $TEMP_SIZE_SOURCE"
	    TEMP_PERCENTAGE="$(( 100 * TEMP_SIZE_DESTINATION / TEMP_SIZE_SOURCE))"
	    #echo "$TEMP_PERCENTAGE"
	    echo -n "\r${TEMP_PRINT_PREFIX}${TEMP_PERCENTAGE}%"
	else
	    wait "$TEMP_CP_PID"
	    TEMP_CP_RETVAL="$?"

	    if [ "$TEMP_CP_RETVAL" -ne 0 ]
	    then
		# Fail case. End the no-endline echo. Caller writes
		# more specific error info.
		echo ""

		return "$TEMP_CP_RETVAL"
	    fi

	    echo -n "\r${TEMP_PRINT_PREFIX}done\n"

	    TEMP_STEP="$((EMP_PROGRESS_MAX_STEPS + 1))"
	fi

	TEMP_STEP="$((TEMP_STEP + 1))"
    done

    if [ "$?" -ne 0 ]
    then
	return "$?"
    fi

    chmod -R "$TEMP_DESTINATION_CHMOD_PERMS" "$TEMP_FULL_DESTINATION" > /dev/null 2>&1

    return "$?"
}


emp_collect_general_pre_parameters_variables()
{
    EMP_COPY_WITH_PROGRESS_SIZE="10000000"
    EMP_PROGRESS_INTERVAL_SECS="5"
    EMP_PROGRESS_MAX_STEPS="720" # 720 times 5 s step is 1 hour.

    EMP_MOUNT_POINT="$EMP_TOPDIR/work/mount"
    EMP_WIM_DIRS_PARENT="$EMP_TOPDIR/work/wims"
    EMP_WIM_DIR_FIRST="$EMP_WIM_DIRS_PARENT/1"
    EMP_WIM_DIR_SECOND="$EMP_WIM_DIRS_PARENT/2"
}


emp_collect_general_post_parameters_variables()
{
    EMP_BOOT_OS_ISO_FILE="$(basename "$EMP_BOOT_OS_ISO_PATH")"
}


emp_collect_provisioning_variables()
{
    EMP_ASSETS_DIRS_CHMOD_PERMS="u+rwX"
    EMP_BOOT_OS_ISO_NAME="${EMP_BOOT_OS_ISO_FILE%.*}"

    # EMP_BOOT_OS_ASSETS_SUBDIR is like ubuntu/20.04/x64/ubuntu-20.04-mini-amd64
    EMP_BOOT_OS_ASSETS_TYPE="unknown"
    EMP_BOOT_OS_ASSETS_FILES_COPY_ISO_PATHS_LIST=""
    EMP_BOOT_OS_ASSETS_SUBDIR="${EMP_BOOT_OS_ASSETS_PARENT#$EMP_ASSETS_ROOT_DIR/}/$EMP_BOOT_OS_ISO_NAME"
    EMP_BOOT_OS_ASSETS_UNPACKED_ISO_SUBDIR="unpacked"
    EMP_BOOT_OS_ASSETS_HTTP_BASE_PATH="$EMP_WEBSERVER_PROTOCOL://$EMP_WEBSERVER_IP/$EMP_WEBSERVER_PATH_PREFIX/$EMP_BOOT_OS_ASSETS_SUBDIR"
    EMP_BOOT_OS_ASSETS_FS_BASE_PATH="$EMP_ASSETS_ROOT_DIR/$EMP_BOOT_OS_ASSETS_SUBDIR"
    EMP_BOOT_OS_ASSETS_UNPACKED_ISO_SUBDIR="unpacked"
    EMP_BOOT_OS_ASSETS_CIFS_BASE_PATH="$(echo "//$EMP_CIFS_SERVER_IP/$EMP_CIFS_SHARE_NAME/$EMP_BOOT_OS_ASSETS_SUBDIR" | sed 's|\/|\\\\|g')"
    EMP_BOOT_OS_FRAGMENT_PATH_X32_BIOS="$EMP_BOOT_OS_ASSETS_FS_BASE_PATH.x32-bios.ipxe"
    EMP_BOOT_OS_FRAGMENT_PATH_X32_EFI="$EMP_BOOT_OS_ASSETS_FS_BASE_PATH.x32-efi.ipxe"
    EMP_BOOT_OS_FRAGMENT_PATH_X64_BIOS="$EMP_BOOT_OS_ASSETS_FS_BASE_PATH.x64-bios.ipxe"
    EMP_BOOT_OS_FRAGMENT_PATH_X64_EFI="$EMP_BOOT_OS_ASSETS_FS_BASE_PATH.x64-efi.ipxe"

    # Based on actual arch, select first and second proper fragments.
    # All fragments will be initially removed if existing. Basically
    # arch A fragments cannot live in arch B directory, so removing
    # all first is ok. We then recreate the actual fragments, first
    # and second.
    if [ "$EMP_BOOT_OS_MAIN_ARCH" = "x32" ]
    then
        EMP_BOOT_OS_FRAGMENT_PATH_FIRST="$EMP_BOOT_OS_FRAGMENT_PATH_X32_BIOS"
        EMP_BOOT_OS_FRAGMENT_PATH_SECOND="$EMP_BOOT_OS_FRAGMENT_PATH_X32_EFI"
        EMP_NONMATCHING_BOOT_OS_FRAGMENT_PATH_FIRST="$EMP_BOOT_OS_FRAGMENT_PATH_X64_BIOS"
        EMP_NONMATCHING_BOOT_OS_FRAGMENT_PATH_SECOND="$EMP_BOOT_OS_FRAGMENT_PATH_X64_EFI"

    elif [ "$EMP_BOOT_OS_MAIN_ARCH" = "x64" ]
    then
        EMP_BOOT_OS_FRAGMENT_PATH_FIRST="$EMP_BOOT_OS_FRAGMENT_PATH_X64_BIOS"
        EMP_BOOT_OS_FRAGMENT_PATH_SECOND="$EMP_BOOT_OS_FRAGMENT_PATH_X64_EFI"
        EMP_NONMATCHING_BOOT_OS_FRAGMENT_PATH_FIRST="$EMP_BOOT_OS_FRAGMENT_PATH_X32_BIOS"
        EMP_NONMATCHING_BOOT_OS_FRAGMENT_PATH_SECOND="$EMP_BOOT_OS_FRAGMENT_PATH_X32_EFI"
    fi
    
}


emp_collect_windows_template_creation_variables()
{
    EMP_WIN_TEMPLATE_DIRS_CHMOD_PERMS="u+rwX"
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


emp_scan_for_single_parameter()
{
    TEMP_LONG_OPTION="$1"
    TEMP_SHORT_OPTION="$2"

    TEMP_OPEN=0
    TEMP_FOUND_PARAM=""
    
    for TEMP_PARAM in $EMP_ALL_COMMAND_LINE_PARAMS
    do
	if [ "$TEMP_OPEN" -eq 0 ]
	then
	    # Nothing open

	    # Check first if long forms
	    case "$TEMP_PARAM" in
		"$TEMP_LONG_OPTION"=*)
		    TEMP_FOUND_PARAM="${TEMP_PARAM##${TEMP_LONG_OPTION}=}"
		    ;;
		*)
		    # Here short form opening checks
		    if [ "$TEMP_PARAM" = "$TEMP_SHORT_OPTION" ]
		    then
			TEMP_OPEN=1
		    fi
		    ;;
	    esac

	else
	    # What we seek was open
	    TEMP_FOUND_PARAM="$TEMP_PARAM"
	    TEMP_OPEN=0
	fi
    done

    echo "$TEMP_FOUND_PARAM"
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
    # --iso-file=/opt/isos_ro/ubuntu/20.04/ubuntu-20.04-mini-amd64.iso
    # --assets-parent=/opt/easy_multi_pxe/netbootassets/ubuntu/20.04/x64
    # --copy-iso=no
    # --unpack-iso=no

    # Or the same:
    # ./emp_provision_ubuntu_iso_to_assets_dir.sh
    # -i /opt/isos_ro/ubuntu/20.04/ubuntu-20.04-mini-amd64.iso
    # -a /opt/easy_multi_pxe/netbootassets/ubuntu/20.04/x64
    # -c no
    # -u no



    for TEMP_PARAM in "$@"
    do
	if [ -z "$TEMP_OPEN" ]
	then
	    # Nothing open

	    # Check first if long forms
	    case "$TEMP_PARAM" in
		--iso-file=*)
		    TEMP_ISO_PATH="${TEMP_PARAM##--iso-file=}"
		    ;;
		--assets-parent=*)
		    TEMP_ASSETS_PARENT="${TEMP_PARAM##--assets-parent=}"
		    ;;
		--copy-iso=*)
		    TEMP_COPY_ISO="${TEMP_PARAM##--copy-iso=}"
		    ;;
		--unpack-iso=*)
		    TEMP_UNPACK_ISO="${TEMP_PARAM##--unpack-iso=}"
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
	emp_print_provisioning_help
	
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
	"$EMP_ASSETS_ROOT_DIR/$TEMP_SCRIPT_OS_FAMILY/"*)
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
	emp_print_provisioning_help
	
	exit 1
    fi
}




emp_collect_windows_template_creation_parameters()
{
    EMP_WIN_TEMPLATE_ISO_PATH=""
    EMP_WIN_TEMPLATE_DIR_PATH=""
    
    TEMP_OPEN=""
    # Example run (wrapped):
    # ./emp_create_windows_template.sh
    # --iso-file=/opt/isos_ro/win10/Win10_22H2_English_x64-2023-04-08.iso
    # --template-dir=/opt/easy_multi_pxe/netbootassets/windows/template/x64

    # Or the same:
    # ./emp_create_windows_template.sh
    # -i /opt/isos_ro/win10/Win10_22H2_English_x64-2023-04-08.iso
    # -t /opt/easy_multi_pxe/netbootassets/windows/template/x64

    TEMP_WIN_TEMPLATE_ISO_PATH="$(emp_scan_for_single_parameter --iso-file -i)"
    TEMP_WIN_TEMPLATE_DIR_PATH="$(emp_scan_for_single_parameter --template-dir -t)"
    
    # Rudimentary checks for some values here after dereferencing
    # Separate function checks that params are fine in all ways

    EMP_WIN_TEMPLATE_ISO_PATH="$(realpath "${TEMP_WIN_TEMPLATE_ISO_PATH}" 2>/dev/null)"
    # If path is garbage, variable is empty. In this
    # case assign the original, even if it was erroneous.
    if [ -z "$EMP_WIN_TEMPLATE_ISO_PATH" ]
    then
	EMP_WIN_TEMPLATE_ISO_PATH="${TEMP_WIN_TEMPLATE_ISO_PATH}"
    fi

    EMP_WIN_TEMPLATE_DIR_PATH="$(realpath "${TEMP_WIN_TEMPLATE_DIR_PATH}" 2>/dev/null)"
    # Ditto
    if [ -z "$EMP_WIN_TEMPLATE_DIR_PATH" ]
    then
	EMP_WIN_TEMPLATE_DIR_PATH="${TEMP_WIN_TEMPLATE_DIR_PATH}"
    fi
}







emp_assert_windows_template_creation_parameters()
{
    TEMP_RETVAL=0

    if [ -z "$EMP_WIN_TEMPLATE_ISO_PATH" ]
    then
	echo "ERROR: No iso path given at all"
	TEMP_RETVAL=1
    fi

    if [ -z "$EMP_WIN_TEMPLATE_DIR_PATH" ]
    then
	echo "ERROR: No template directory path given at all"
	TEMP_RETVAL=1
    fi

    # Bailing out already on errors because would create too many messages
    if [ "$TEMP_RETVAL" -ne 0 ]
    then
	emp_print_windows_template_creation_help
	
	exit "$TEMP_RETVAL"
    fi

    # Then the actual checks
    if [ ! -f "$EMP_WIN_TEMPLATE_ISO_PATH" ]
    then
	echo "ERROR: Cannot find iso file $EMP_BOOT_OS_ISO_PATH"
	TEMP_RETVAL=1
    fi

    # Can be:
    #
    # $EMP_WIN_TEMPLATE_DIR_PATH=/opt/easy_multi_pxe/netbootassets/windows/template/x64
    # $EMP_ASSETS_ROOT_DIR=/opt/easy_multi_pxe/netbootassets
    #
    # Conclusion:
    # $EMP_ASSETS_ROOT_DIR must be the beginning of $EMP_WIN_TEMPLATE_DIR_PATH

    case "$EMP_WIN_TEMPLATE_DIR_PATH" in
	"$EMP_ASSETS_ROOT_DIR/"*)
	    ;;
	*)
	    echo "ERROR: Given template directory path $EMP_WIN_TEMPLATE_DIR_PATH not under $EMP_ASSETS_ROOT_DIR"
	    TEMP_RETVAL=1
	    ;;
    esac

    # Can be:
    #
    # $EMP_WIN_TEMPLATE_DIR_PATH=/opt/easy_multi_pxe/netbootassets/windows/template/x64
    #
    # Conclusion:
    # Must validate the last fragment to have correct arch.
    
    EMP_WIN_TEMPLATE_MAIN_ARCH="${EMP_WIN_TEMPLATE_DIR_PATH##*/}"

    if [ "$EMP_WIN_TEMPLATE_MAIN_ARCH" != "x32" -a "$EMP_WIN_TEMPLATE_MAIN_ARCH" != "x64" ]
    then
	echo "ERROR: Wrong main architecture given in template directory path $EMP_WIN_TEMPLATE_DIR_PATH , expected x32 or x64"
	TEMP_RETVAL=1
    fi

    # Can be:
    #
    # $EMP_ASSETS_ROOT_DIR=/opt/easy_multi_pxe/netbootassets
    # $EMP_WIN_TEMPLATE_DIR_PATH=/opt/easy_multi_pxe/netbootassets/windows/template/x64
    # $EMP_WIN_TEMPLATE_MAIN_ARCH=x64
    #
    # Conclusion:
    # Must check that only 20.04 remains, so strip from
    # $EMP_WIN_TEMPLATE_DIR_PATH beginning $EMP_ASSETS_ROOT_DIR/
    # and from end /$EMP_WIN_TEMPLATE_MAIN_ARCH
    # Then check that the results is exactly windows/template
    TEMP_WIN_TEMPLATE_IDENTIFIER_REMAINDER="${EMP_WIN_TEMPLATE_DIR_PATH##$EMP_ASSETS_ROOT_DIR/}"
    TEMP_WIN_TEMPLATE_IDENTIFIER_REMAINDER="${TEMP_WIN_TEMPLATE_IDENTIFIER_REMAINDER%%/$EMP_WIN_TEMPLATE_MAIN_ARCH}"

    if [ "$TEMP_WIN_TEMPLATE_IDENTIFIER_REMAINDER" != "windows/template" ]
    then
	echo "ERROR: Unable to fully validate EMP_WIN_TEMPLATE_DIR_PATH as template directory path"
	TEMP_RETVAL=1
    fi

    if [ "$TEMP_RETVAL" -ne 0 ]
    then
	emp_print_windows_template_creation_help
	
	exit 1
    fi
}







emp_assert_general_directories()
{
    TEMP_ERRORS=0
    
    for TEMP_GENERAL_DIRECTORY in "$EMP_MOUNT_POINT" \
				  "$EMP_WIM_DIRS_PARENT" \
				  "$EMP_WIM_DIR_FIRST" \
				  "$EMP_WIM_DIR_SECOND"
    do
	if [ ! -d "$TEMP_GENERAL_DIRECTORY" -o ! -r "$TEMP_GENERAL_DIRECTORY" ]
	then
	    echo "ERROR: General directory $TEMP_GENERAL_DIRECTORY does not exist or is not readable"
	    TEMP_ERRORS=1
	fi
    done

    if [ "$TEMP_ERRORS" -ne 0 ]
    then
	exit 1
    fi
}


emp_ensure_provisioning_directories()
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


emp_ensure_windows_template_creation_directories()
{
    if [ ! -d "$EMP_WIN_TEMPLATE_DIR_PATH" ]
    then
	mkdir -p "$EMP_WIN_TEMPLATE_DIR_PATH"

	if [ "$?" -ne 0 ]
	then
	    echo "ERROR: Unable to create template directory path $EMP_WIN_TEMPLATE_DIR_PATH"

	    exit 1
	fi
	
	chmod "$EMP_WIN_TEMPLATE_DIRS_CHMOD_PERMS" "$EMP_WIN_TEMPLATE_DIR_PATH"

	if [ "$?" -ne 0 ]
	then
	    echo "ERROR: Unable to ensure chmod permissions for template directory path $EMP_WIN_TEMPLATE_DIR_PATH"

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
	echo -n "Unpacking iso..."

	# Need to remove old if existing

	emp_copy_directory "$EMP_MOUNT_POINT" "$EMP_BOOT_OS_ASSETS_FS_BASE_PATH/$EMP_BOOT_OS_ASSETS_UNPACKED_ISO_SUBDIR" "$EMP_ASSETS_DIRS_CHMOD_PERMS" "Unpacking iso..."

	if [ "$?" -ne 0 ]
	then
	    echo "ERROR: Unable to unpack iso mounted at $EMP_MOUNT_POINT to $EMP_BOOT_OS_ASSETS_FS_BASE_PATH/$EMP_BOOT_OS_ASSETS_UNPACKED_ISO_SUBDIR"
	    emp_force_unmount_generic_mountpoint

	    exit 1
	fi
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
