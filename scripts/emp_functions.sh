#!/bin/sh


emp_print_help()
{
    echo ""
    echo "Example run:"
    echo "$0"
    
    case "$0" in
	*emp_make_windows_template.sh)
	    echo "--iso-file=/opt/isos_ro/win10/Win10_22H2_English_x64-2023-04-08.iso "
	    echo "--template-dir=/opt/easy_multi_pxe/netbootassets/windows/template/x64 "
	    echo ""
	    echo "Or with short forms:"
	    echo "$0"
	    echo "-i /opt/isos_ro/win10/Win10_22H2_English_x64-2023-04-08.iso "
	    echo "-t /opt/easy_multi_pxe/netbootassets/windows/template/x64 "
	    ;;
	*emp_provision_windows_iso_to_assets_dir.sh)
	    echo "--iso-file=/opt/isos_ro/windows/10/Win10_22H2_English_x64-2023-04-08.iso "
	    echo "--assets-parent=/opt/easy_multi_pxe/netbootassets/windows/10/x64 "
	    echo "--template-file=/opt/easy_multi_pxe/netbootassets/windows/template/x64/boot-gen2.wim "
	    echo "[--unpack-iso=no] "
	    echo ""
	    echo "Or with short forms:"
	    echo "$0"
	    echo "-i /opt/isos_ro/windows/10/Win10_22H2_English_x64-2023-04-08.iso "
	    echo "-a /opt/easy_multi_pxe/netbootassets/windows/10/x64 "
	    echo "-t /opt/easy_multi_pxe/netbootassets/windows/template/x64/boot-gen2.wim "
	    echo "[-u no] "
	    ;;
	*emp_provision_ubuntu_iso_to_assets_dir.sh)
	    echo "--iso-file=/opt/isos_ro/ubuntu/20.04/ubuntu-20.04-mini-amd64.iso "
	    echo "--assets-parent=/opt/easy_multi_pxe/netbootassets/ubuntu/20.04/x64 "
	    echo "[--copy-iso=no] "
	    echo ""
	    echo "Or with short forms:"
	    echo "$0"
	    echo "-i /opt/isos_ro/ubuntu/20.04/ubuntu-20.04-mini-amd64.iso "
	    echo "-a /opt/easy_multi_pxe/netbootassets/ubuntu/20.04/x64 "
	    echo "[-c no] "
	    ;;
	*emp_provision_debian_iso_to_assets_dir.sh)
	    echo "--iso-file=/opt/isos_ro/debian/debian-12.5.0-amd64-netinst.iso "
	    echo "--assets-parent=/opt/easy_multi_pxe/netbootassets/debian/12/x64 "
	    echo "[--unpack-iso=no] "
	    echo ""
	    echo "Or with short forms:"
	    echo "$0"
	    echo "-i /opt/isos_ro/debian/debian-12.5.0-amd64-netinst.iso "
	    echo "-a /opt/easy_multi_pxe/netbootassets/debian/12/x64 "
	    echo "[-u no] "
	    ;;
	*emp_provision_systemrescuecd_iso_to_assets_dir.sh)
	    echo "--iso-file=/opt/isos_ro/systemrescuecd/systemrescue-8.05-amd64.iso "
	    echo "--assets-parent=/opt/easy_multi_pxe/netbootassets/systemrescuecd/8/x64 "
	    echo "[--unpack-iso=no] "
	    echo ""
	    echo "Or with short forms:"
	    echo "$0"
	    echo "-i /opt/isos_ro/systemrescuecd/systemrescue-8.05-amd64.iso "
	    echo "-a /opt/easy_multi_pxe/netbootassets/systemrescuecd/8/x64 "
	    echo "[-u no] "
	    ;;
	*emp_download_debian_support_files.sh)
	    echo "--debian-name=bookworm "
	    echo "--support-dir=/opt/easy_multi_pxe/netbootassets/debian/12/x64/support "
	    echo ""
	    echo "Or with short forms:"
	    echo "$0"
	    echo "-d bookworm"
	    echo "-s /opt/easy_multi_pxe/netbootassets/debian/12/x64/support "
	    ;;
	*)
	    echo "ERROR: Unknown script called, unable to print help"
	    ;;
    esac
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


emp_count_path_data_size()
{
    TEMP_DU_DIR="$1"

    TEMP_DU_OUT="$(du --apparent-size -b -s "${TEMP_DU_DIR}" 2>/dev/null)"
    TEMP_SIZE="${TEMP_DU_OUT%%	*}" # Literal tab!!
    echo "$TEMP_SIZE"
}


emp_calculate_progress_interval_time()
{
    TEMP_BYTES="$1"
    TEMP_CALCULATED_INTERVAL_TIME_SECS="$((TEMP_BYTES / EMP_PROGRESS_UNIT_BYTES))"

    if [ "$TEMP_CALCULATED_INTERVAL_TIME_SECS" -gt "$EMP_PROGRESS_MAX_SECS" ]
    then
	TEMP_CALCULATED_INTERVAL_TIME_SECS="$EMP_PROGRESS_MAX_SECS"
    fi

    echo "$TEMP_CALCULATED_INTERVAL_TIME_SECS"
}


emp_copy_file_list_to_dir()
{
    TEMP_PARAMS_TAIL="$@"

    TEMP_SOURCE_DIR="$1"
    TEMP_DESTINATION_DIR="$2"
    TEMP_DESTINATION_CHMOD_PERMS="$3"
    TEMP_PRINT_PREFIX="$4"
    TEMP_SOURCE_REL_FILE_PATH_LIST="${TEMP_PARAMS_TAIL#*$TEMP_PRINT_PREFIX* }"

    TEMP_SOURCE_FILES_SIZE_TOTAL=0
    TEMP_DESTINATION_FILES_SIZE_TOTAL=0
    
    # First need to calculate size
    # Also while at it, remove olds
    for TEMP_SOURCE_REL_FILE_PATH in $TEMP_SOURCE_REL_FILE_PATH_LIST
    do
	TEMP_FULL_SOURCE_PATH="$TEMP_SOURCE_DIR/$TEMP_SOURCE_REL_FILE_PATH"
	TEMP_DESTINATION_FILE="$(basename "$TEMP_FULL_SOURCE_PATH")"
	TEMP_FULL_DESTINATION_PATH="$TEMP_DESTINATION_DIR/$TEMP_DESTINATION_FILE"
	TEMP_SOURCE_PATH_SIZE="$(emp_count_path_data_size "$TEMP_FULL_SOURCE_PATH")"
	TEMP_SOURCE_FILES_SIZE_TOTAL="$((TEMP_SOURCE_FILES_SIZE_TOTAL + TEMP_SOURCE_PATH_SIZE))"

	if [ -f "$TEMP_FULL_DESTINATION_PATH" ]
	then
	    rm "$TEMP_FULL_DESTINATION_PATH" > /dev/null 2>&1
	    TEMP_RM_RETVAL="$?"
	    
	    if [ "$TEMP_RM_RETVAL" -ne 0 ]
	    then
		echo ""
		echo "ERROR: Unable to remove old file $TEMP_FULL_DESTINATION_PATH"

		return "$TEMP_RM_RETVAL"

	    fi
	fi
    done

    # Actual copy loop
    # Steps is shared
    TEMP_STEP=0
    
    for TEMP_SOURCE_REL_FILE_PATH in $TEMP_SOURCE_REL_FILE_PATH_LIST
    do
	TEMP_FULL_SOURCE_PATH="$TEMP_SOURCE_DIR/$TEMP_SOURCE_REL_FILE_PATH"
	TEMP_DESTINATION_FILE="$(basename "$TEMP_FULL_SOURCE_PATH")"
	TEMP_FULL_DESTINATION_PATH="$TEMP_DESTINATION_DIR/$TEMP_DESTINATION_FILE"

	TEMP_SOURCE_PATH_SIZE="$(emp_count_path_data_size "$TEMP_FULL_SOURCE_PATH")"
	TEMP_PROGRESS_INTERVAL_TIME="$(emp_calculate_progress_interval_time "$TEMP_SOURCE_PATH_SIZE")"

	TEMP_RUN_STATUS="ongoing"
	cp "$TEMP_FULL_SOURCE_PATH" "$TEMP_FULL_DESTINATION_PATH" > /dev/null 2>&1 &
	TEMP_CP_PID="$!"

	while [ "$TEMP_RUN_STATUS" = "ongoing" -a "$TEMP_STEP" -lt "$EMP_PROGRESS_MAX_STEPS" ]
	do
	    sleep "$TEMP_PROGRESS_INTERVAL_TIME" > /dev/null 2>&1
	    ps -p "$TEMP_CP_PID" > /dev/null 2>&1

	    if [ "$?" -eq 0 ]
	    then
		TEMP_PATH_SIZE_DESTINATION="$(emp_count_path_data_size "$TEMP_FULL_DESTINATION_PATH")"
		TEMP_TOTAL_PRINT_COPIED_SIZE="$((TEMP_DESTINATION_FILES_SIZE_TOTAL + TEMP_PATH_SIZE_DESTINATION))"
		TEMP_TOTAL_PERCENTAGE="$((100 * TEMP_TOTAL_PRINT_COPIED_SIZE / TEMP_SOURCE_FILES_SIZE_TOTAL))"
		
		if [ "$TEMP_TOTAL_PERCENTAGE" -gt 100 ]
		then
		    TEMP_TOTAL_PERCENTAGE=100
		fi
		
		echo -n "\r${TEMP_PRINT_PREFIX}${TEMP_TOTAL_PERCENTAGE}%"
	    else
		wait "$TEMP_CP_PID"
		TEMP_CP_RETVAL="$?"

		if [ "$TEMP_CP_RETVAL" -ne 0 ]
		then
		    # Fail case.
		    echo ""
		    echo "ERROR: Failed copying $TEMP_FULL_SOURCE_PATH to $TEMP_FULL_DESTINATION_PATH"

		    return "$TEMP_CP_RETVAL"
		fi

		if [ "$TEMP_DESTINATION_CHMOD_PERMS" != "" ]
		then
		    chmod "$TEMP_DESTINATION_CHMOD_PERMS" "$TEMP_FULL_DESTINATION_PATH" > /dev/null 2>&1
		    TEMP_CHMOD_RETVAL="$?"
		    
		    if [ "$TEMP_CHMOD_RETVAL" -ne 0 ]
		    then
			echo ""
			echo "ERROR: Unable to set permissons for file TEMP_FULL_DESTINATION_PATH"

			return "$TEMP_CHMOD_RETVAL"
		    fi
		fi
		
		# This copy was fine
		TEMP_RUN_STATUS="file_finished"
		TEMP_PATH_SIZE_DESTINATION="$(emp_count_path_data_size "$TEMP_FULL_DESTINATION_PATH")"
		TEMP_DESTINATION_FILES_SIZE_TOTAL="$((TEMP_DESTINATION_FILES_SIZE_TOTAL + TEMP_PATH_SIZE_DESTINATION))"
		TEMP_TOTAL_PERCENTAGE="$((100 * TEMP_DESTINATION_FILES_SIZE_TOTAL / TEMP_SOURCE_FILES_SIZE_TOTAL))"

		if [ "$TEMP_TOTAL_PERCENTAGE" -gt 100 ]
		then
		    TEMP_TOTAL_PERCENTAGE=100
		fi
		
		echo -n "\r${TEMP_PRINT_PREFIX}${TEMP_TOTAL_PERCENTAGE}%"
	    fi

	    TEMP_STEP="$((TEMP_STEP + 1))"
	done
    done

    echo "\r${TEMP_PRINT_PREFIX}done"

    return 0
}


emp_copy_directory()
{
    TEMP_SOURCE="$1"
    TEMP_FULL_DESTINATION="$2"
    TEMP_DESTINATION_CHMOD_PERMS="$3"
    TEMP_PRINT_PREFIX="$4"

    TEMP_SOURCE_PATH_SIZE="$(emp_count_path_data_size "$TEMP_SOURCE")"
    TEMP_PROGRESS_INTERVAL_TIME="$(emp_calculate_progress_interval_time "$TEMP_SOURCE_PATH_SIZE")"
    TEMP_RUN_STATUS="ongoing"
    TEMP_STEP=0

    if [ -d "$TEMP_FULL_DESTINATION" ]
    then
	rm -r "$TEMP_FULL_DESTINATION"
	TEMP_RM_RETVAL="$?"

	if [ "$TEMP_RM_RETVAL" -ne 0 ]
	then
	    echo ""
	    echo "ERROR: Unable to remove old directory $TEMP_FULL_DESTINATION_PATH"

	    return "$TEMP_RM_RETVAL"
	fi
    fi

    # Changed the copy engine to rsync. Needs regression testing.
    #cp -r "$TEMP_SOURCE" "$TEMP_FULL_DESTINATION" > /dev/null 2>&1 &
    rsync -r "$TEMP_SOURCE"/* "$TEMP_FULL_DESTINATION" > /dev/null 2>&1 &
    
    TEMP_CP_PID="$!"

    while [ "$TEMP_RUN_STATUS" = "ongoing" -a "$TEMP_STEP" -lt "$EMP_PROGRESS_MAX_STEPS" ]
    do
	sleep "$TEMP_PROGRESS_INTERVAL_TIME" > /dev/null 2>&1
	ps -p "$TEMP_CP_PID" > /dev/null 2>&1

	if [ "$?" -eq 0 ]
	then
	    TEMP_PATH_SIZE_DESTINATION="$(emp_count_path_data_size "$TEMP_FULL_DESTINATION")"
	    TEMP_TOTAL_PERCENTAGE="$(( 100 * TEMP_PATH_SIZE_DESTINATION / TEMP_SOURCE_PATH_SIZE))"

	    if [ "$TEMP_TOTAL_PERCENTAGE" -gt 100 ]
	    then
		TEMP_TOTAL_PERCENTAGE=100
	    fi
	    
	    echo -n "\r${TEMP_PRINT_PREFIX}${TEMP_TOTAL_PERCENTAGE}%"
	else
	    wait "$TEMP_CP_PID"
	    TEMP_CP_RETVAL="$?"

	    if [ "$TEMP_CP_RETVAL" -ne 0 ]
	    then
		# Fail case
		echo ""
		echo "ERROR: Failed copying $TEMP_SOURCE to $TEMP_FULL_DESTINATION"

		return "$TEMP_CP_RETVAL"
	    fi
	    # Copying was fine
	    TEMP_RUN_STATUS="file_finished"
	    echo -n "\r${TEMP_PRINT_PREFIX}done\n"
	fi

	TEMP_STEP="$((TEMP_STEP + 1))"
    done

    if [ "$TEMP_DESTINATION_CHMOD_PERMS" != "" ]
    then
	chmod -R "$TEMP_DESTINATION_CHMOD_PERMS" "$TEMP_FULL_DESTINATION" > /dev/null 2>&1
	TEMP_CHMOD_RETVAL="$?"
	
	if [ "$TEMP_CHMOD_RETVAL" -ne 0 ]
	then
	    echo ""
	    echo "ERROR: Unable to set permissons for directory $TEMP_FULL_DESTINATION_PATH"

	    return "$TEMP_CHMOD_RETVAL"
	fi
    fi

    return 0
}


emp_collect_general_pre_parameters_variables()
{
    EMP_PROGRESS_MAX_STEPS=720 # 720 times 5 s step is 1 hour.
    EMP_PROGRESS_MAX_SECS=5
    EMP_PROGRESS_UNIT_BYTES=10485760
    EMP_WIM_COMPRESSION_PERCENTAGE=41

    EMP_WORK_DIR_PATH="$EMP_TOPDIR/work"
    EMP_MOUNT_POINT="$EMP_WORK_DIR_PATH/mount"
    EMP_WIM_DIRS_PARENT="$EMP_WORK_DIR_PATH/wims"
    EMP_WIM_DIR_FIRST="$EMP_WIM_DIRS_PARENT/1"
    EMP_WIM_DIR_SECOND="$EMP_WIM_DIRS_PARENT/2"
    EMP_WIM_BOOT_FILE_NAME="boot.wim"
    EMP_WIM_INSTALL_FILE_NAME="install.wim"
    EMP_WIM_FILE_ISO_SUBDIR="sources"

    EMP_INITRD_GZIPPED_FILE_NAME="initrd.gz"
    EMP_PRESEED_FILE_NAME="preseed.cfg"
    #EMP_INITRD_DIR_PATH="$EMP_WORK_DIR_PATH/initrd"
    EMP_INITRD_DIR_PARENT_PATH="$EMP_WORK_DIR_PATH/initrd"
    EMP_INITRD_DIR_TREE_PATH="$EMP_INITRD_DIR_PARENT_PATH/tree"
    EMP_KERNEL_MODULES_SUBDIR="/lib/modules"
    EMP_INITRD_COMPRESSION_PERCENTAGE=29
}


emp_collect_general_post_parameters_variables()
{
    EMP_BOOT_OS_ISO_FILE="$(basename "$EMP_BOOT_OS_ISO_PATH")"
    EMP_BOOT_OS_ISO_SOURCE_PARENT="$(dirname "$EMP_BOOT_OS_ISO_PATH")"
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
    EMP_WIN_TEMPLATE_SOURCE_BOOT_WIM_PATH="$EMP_MOUNT_POINT/$EMP_WIM_FILE_ISO_SUBDIR/$EMP_WIM_BOOT_FILE_NAME"
    EMP_WIN_TEMPLATE_WORK_BOOT_WIM_PATH="$EMP_WIM_DIRS_PARENT/$EMP_WIM_BOOT_FILE_NAME"
    EMP_WIN_TEMPLATE_FINAL_BOOT_WIM_PATH="$EMP_WIN_TEMPLATE_DIR_PATH/$EMP_WIM_BOOT_FILE_NAME"
    # Note: EMP_WIN_TEMPLATE_FINAL_BOOT_WIM_PATH needs to be manipulated in custom
    # script when creating templates.
}


emp_collect_download_debian_support_files_variables()
{
    EMP_DEBIAN_SUPPORT_FILES_DIRS_CHMOD_PERMS="u+rwX"
    EMP_DEBIAN_DOWNLOAD_INSTALLER_PAGE_URL="https://packages.debian.org/${EMP_DEBIAN_VERSION_NAME}/all/download-installer/download"
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

    TEMP_ISO_PATH="$(emp_scan_for_single_parameter --iso-file -i)"
    TEMP_ASSETS_PARENT="$(emp_scan_for_single_parameter --assets-parent -a)"
    TEMP_TEMPLATE_PATH="$(emp_scan_for_single_parameter --template-file -t)"
    TEMP_COPY_ISO="$(emp_scan_for_single_parameter --copy-iso -c)"
    TEMP_UNPACK_ISO="$(emp_scan_for_single_parameter --unpack-iso -u)"

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

    EMP_TEMPLATE_PATH="$(realpath "${TEMP_TEMPLATE_PATH}" 2>/dev/null)"

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
	emp_print_help
	
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


    case "$0" in
	*emp_provision_windows_iso_to_assets_dir.sh)

	    if [ -z "$EMP_TEMPLATE_PATH" ]
	    then
		echo "ERROR: No template file path given"
		TEMP_RETVAL="1"

	    elif [ ! -f "$EMP_TEMPLATE_PATH" ]
	    then
		echo "ERROR: Bad template file path given $EMP_TEMPLATE_PATH"
		TEMP_RETVAL="1"
	    fi

	    ;;
	*)
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
	emp_print_help
	
	exit 1
    fi
}




emp_collect_windows_template_creation_parameters()
{
    EMP_WIN_TEMPLATE_ISO_PATH=""
    EMP_WIN_TEMPLATE_DIR_PATH=""
    
    # Example run (wrapped):
    # ./emp_make_windows_template.sh
    # --iso-file=/opt/isos_ro/win10/Win10_22H2_English_x64-2023-04-08.iso
    # --template-dir=/opt/easy_multi_pxe/netbootassets/windows/template/x64

    # Or the same:
    # ./emp_make_windows_template.sh
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
	emp_print_help
	
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
	emp_print_help
	
	exit 1
    fi
}



emp_debian_version_name_to_number()
{
    TEMP_NAME="$1"
    TEMP_NUMBER=""

    case "$TEMP_NAME" in
	"wheezy")
	    TEMP_NUMBER="7"
	    ;;
	"jessie")
	    TEMP_NUMBER="8"
	    ;;
	"stretch")
	    TEMP_NUMBER="9"
	    ;;
	"buster")
	    TEMP_NUMBER="10"
	    ;;
	"bullseye")
	    TEMP_NUMBER="11"
	    ;;
	"bookworm")
	    TEMP_NUMBER="12"
	    ;;
	"trixie")
	    TEMP_NUMBER="13"
	    ;;
	"forky")
	    TEMP_NUMBER="14"
	    ;;
    esac

    echo "$TEMP_NUMBER"
}



emp_collect_download_debian_support_files_parameters()
{

    EMP_DEBIAN_VERSION_NAME=""
    EMP_DEBIAN_VERSION_NUMBER=""
    EMP_DEBIAN_SUPPORT_DIR_PATH=""

    # Example run (wrapped):
    # ./emp_download_debian_support_files.sh
    # --debian-name=bookworm
    # --support-dir=/opt/easy_multi_pxe/netbootassets/debian/10/x64/support

    # Or the same:
    # ./emp_download_debian_support_files.sh
    # -d bookworm
    # -s /opt/easy_multi_pxe/netbootassets/debian/10/x64/support

    EMP_DEBIAN_VERSION_NAME="$(emp_scan_for_single_parameter --debian-name -d)"
    EMP_DEBIAN_VERSION_NUMBER="$(emp_debian_version_name_to_number "$EMP_DEBIAN_VERSION_NAME")"
    EMP_DEBIAN_SUPPORT_DIR_PATH="$(emp_scan_for_single_parameter --support-dir -s)"
}




emp_assert_download_debian_support_files_parameters()
{
    TEMP_RETVAL=0
    
    if [ "$TEMP_RETVAL" -eq 0 -a -z "$EMP_DEBIAN_VERSION_NUMBER" ]
    then
	echo "ERROR: Unable to convert Debian name $EMP_DEBIAN_VERSION_NAME to version number"
	TEMP_RETVAL=1
    fi

    # Can be:
    #
    # $EMP_DEBIAN_SUPPORT_DIR_PATH=/opt/easy_multi_pxe/netbootassets/debian/10/x64/support
    # $EMP_ASSETS_ROOT_DIR=/opt/easy_multi_pxe/netbootassets
    #
    # => $EMP_DEBIAN_SUPPORT_DIR_PATH must contain $EMP_ASSETS_ROOT_DIR in the beginning
    TEMP_REMAINDER_DIR_PATH=""

    if [ "$TEMP_RETVAL" -eq 0 ]
    then
	case "$EMP_DEBIAN_SUPPORT_DIR_PATH" in
	    "$EMP_ASSETS_ROOT_DIR/"*)
		# Strip away beginning already
		TEMP_REMAINDER_DIR_PATH="${EMP_DEBIAN_SUPPORT_DIR_PATH#${EMP_ASSETS_ROOT_DIR}/}"
		;;
	    *)
		echo "ERROR: Given template directory path $EMP_WIN_TEMPLATE_DIR_PATH not under $EMP_ASSETS_ROOT_DIR"
		TEMP_RETVAL=1
		;;
	esac
    fi
    
    # Have something like debian/10/x64/support
    # Basically the beginning needs to be debian, next a valid version number,
    # next a valid arch, then support

    if [ "$TEMP_RETVAL" -eq 0 ]
    then
	TEMP_SUPPORT="$(basename "$TEMP_REMAINDER_DIR_PATH")"

	if [ "$TEMP_SUPPORT" = "support" ]
	then
	    TEMP_REMAINDER_DIR_PATH="$(dirname "$TEMP_REMAINDER_DIR_PATH")"
	fi
    fi

    # Have something like debian/10/x64

    if [ "$TEMP_RETVAL" -eq 0 ]
    then
	TEMP_BOOT_OS_MAIN_ARCH="$(basename "$TEMP_REMAINDER_DIR_PATH")"

	if [ "$TEMP_BOOT_OS_MAIN_ARCH" = "x32" -o "$TEMP_BOOT_OS_MAIN_ARCH" = "x64" ]
	then
	    TEMP_REMAINDER_DIR_PATH="$(dirname "$TEMP_REMAINDER_DIR_PATH")"
	    EMP_BOOT_OS_MAIN_ARCH="$TEMP_BOOT_OS_MAIN_ARCH"
	else
	    echo "ERROR: Implied architecture $TEMP_BOOT_OS_MAIN_ARCH not valid"
	    TEMP_RETVAL=1
	fi
    fi

    # Have something like debian/10
    if [ "$TEMP_RETVAL" -eq 0 ]
    then
	TEMP_BOOT_OS_MAIN_VERSION="$(basename "$TEMP_REMAINDER_DIR_PATH")"
	
	if [ "$TEMP_BOOT_OS_MAIN_VERSION" = "$EMP_DEBIAN_VERSION_NUMBER" ]
	then
	    TEMP_REMAINDER_DIR_PATH="$(dirname "$TEMP_REMAINDER_DIR_PATH")"
	    EMP_BOOT_OS_MAIN_VERSION="$TEMP_BOOT_OS_MAIN_VERSION"
	else
	    echo "ERROR: Implied version $TEMP_BOOT_OS_MAIN_VERSION does not correspond to version name number $EMP_DEBIAN_VERSION_NUMBER"
	    TEMP_RETVAL=1
	fi
    fi
    
    if [ "$TEMP_RETVAL" -eq 0 ]
    then
	if [ "$TEMP_REMAINDER_DIR_PATH" != "debian" ]
	then
	    echo "ERROR: Wrong base directory, expected \"debian\", given \"$TEMP_REMAINDER_DIR_PATH\""
	    TEMP_RETVAL=1
	fi
    fi
    
    if [ "$TEMP_RETVAL" -ne 0 ]
    then
	emp_print_help
	
	exit 1
    fi
}


emp_ensure_download_debian_support_files_directories()
{
    if [ ! -d "$EMP_DEBIAN_SUPPORT_DIR_PATH" ]
    then
	mkdir -p "$EMP_DEBIAN_SUPPORT_DIR_PATH"

	if [ "$?" -ne 0 ]
	then
	    echo "ERROR: Unable to create support files directory path $EMP_DEBIAN_SUPPORT_DIR_PATH"

	    exit 1
	fi
	
	chmod "$EMP_DEBIAN_SUPPORT_FILES_DIRS_CHMOD_PERMS" "$EMP_DEBIAN_SUPPORT_DIR_PATH"

	if [ "$?" -ne 0 ]
	then
	    echo "ERROR: Unable to ensure chmod permissions for support files directory path $EMP_DEBIAN_SUPPORT_DIR_PATH"

	    exit 1
	fi
    fi
}



emp_assert_general_directories()
{
    TEMP_ERRORS=0
    
    for TEMP_GENERAL_DIRECTORY in "$EMP_MOUNT_POINT" \
				  "$EMP_WIM_DIRS_PARENT" \
				  "$EMP_WIM_DIR_FIRST" \
				  "$EMP_WIM_DIR_SECOND" \
				  "$EMP_INITRD_DIR_PARENT_PATH" \
				  "$EMP_INITRD_DIR_TREE_PATH"
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


emp_force_unmount_generic_mountpoint()
{
    sync
    umount -f "$EMP_MOUNT_POINT" > /dev/null 2>&1
    sleep 5
}


emp_mount_iso()
{
    echo -n "Mounting iso via loop device..."
    TEMP_MOUNT_ISO_PATH=""

    if [ "$EMP_OP" = "do_provisioning" ]
    then
	TEMP_MOUNT_ISO_PATH="$EMP_BOOT_OS_ISO_PATH"
	
    elif [ "$EMP_OP" = "make_windows_template" ]
    then
	TEMP_MOUNT_ISO_PATH="$EMP_WIN_TEMPLATE_ISO_PATH"
    else
	echo ""
	echo "ERROR: Unknown operation, not known what iso to mount"
	emp_force_unmount_generic_mountpoint

	exit 1
    fi
    
    mount -t auto -o loop "$TEMP_MOUNT_ISO_PATH" "$EMP_MOUNT_POINT" > /dev/null 2>&1
    
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
    emp_copy_file_list_to_dir "$EMP_MOUNT_POINT" "$EMP_BOOT_OS_ASSETS_FS_BASE_PATH" "" "Copying asset files..." "$EMP_BOOT_OS_ASSETS_FILES_COPY_ISO_PATHS_LIST"

    if [ "$?" -ne 0 ]
    then
	echo ""
	echo "ERROR: Unable to copy asset files $EMP_BOOT_OS_ASSETS_FILES_COPY_ISO_PATHS_LIST from $EMP_MOUNT_POINT" 
	emp_force_unmount_generic_mountpoint

	exit 1
    fi
}


emp_copy_iso_if_needed()
{
    if [ "$EMP_COPY_ISO" = "Y" ]
    then
	#pv -w 80 -N "Copying iso" "$EMP_BOOT_OS_ISO_PATH" > "$EMP_BOOT_OS_ASSETS_FS_BASE_PATH/$EMP_BOOT_OS_ISO_FILE"
	emp_copy_file_list_to_dir "$EMP_BOOT_OS_ISO_SOURCE_PARENT" "$EMP_BOOT_OS_ASSETS_FS_BASE_PATH" "" "Copying iso..." "$EMP_BOOT_OS_ISO_FILE"

	if [ "$?" -ne 0 ]
	then
	    emp_force_unmount_generic_mountpoint

	    exit 1
	fi
    fi
}


emp_unpack_iso_if_needed()
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


emp_remove_old_wim_remnants()
{
    touch "$EMP_WIM_DIR_FIRST/foobar" > /dev/null 2>&1
    touch "$EMP_WIM_DIR_SECOND/foobar" > /dev/null 2>&1

    rm -r "$EMP_WIM_DIR_FIRST/"* > /dev/null 2>&1

    if [ "$?" -ne 0 ]
    then
	echo "ERROR: Unable to remove old wim remnants from $EMP_WIM_DIR_FIRST"

	exit 1
    fi
    
    rm -r "$EMP_WIM_DIR_SECOND/"* > /dev/null 2>&1

    if [ "$?" -ne 0 ]
    then
	echo "ERROR: Unable to remove old wim remnants from $EMP_WIM_DIR_SECOND"

	exit 1
    fi
}


emp_remove_old_template_wim()
{
    echo -n "Removing old template file..."
    
    if [ -f "$EMP_WIN_TEMPLATE_FINAL_BOOT_WIM_PATH" ]
    then
	rm "$EMP_WIN_TEMPLATE_FINAL_BOOT_WIM_PATH" > /dev/null 2>&1

	if [ "$?" -ne 0 ]
	then
	    echo ""
	    echo "ERROR: Unable to remove old template wim $EMP_WIN_TEMPLATE_FINAL_BOOT_WIM_PATH"
	    emp_force_unmount_generic_mountpoint

	    exit 1
	fi
	    
    fi

    echo "done"

    return 0
}


emp_count_wim_index_bytes_size()
{
    TEMP_WIM_FILE="$1"
    TEMP_WIM_INDEX="$2"
    TEMP_TOTAL_BYTES="$(wiminfo "$TEMP_WIM_FILE" "$TEMP_WIM_INDEX" | grep "Total Bytes" | sed 's/[[:alnum:] ]*:\s*//')"
    TEMP_HARD_LINK_BYTES="$(wiminfo "$TEMP_WIM_FILE" "$TEMP_WIM_INDEX" | grep "Hard Link Bytes" | sed 's/[[:alnum:] ]*:\s\
*//')"
    TEMP_WIM_FINAL_SIZE="$((TEMP_TOTAL_BYTES - TEMP_HARD_LINK_BYTES))"

    echo "$TEMP_WIM_FINAL_SIZE"

    return 0
}


emp_get_wim_file_generation_signature()
{
    TEMP_WIM_PATH="$1"
    TEMP_WIM_INDEX="$2"
    TEMP_WIM_VERSION_MAJOR="$(wiminfo "$TEMP_WIM_PATH" "$TEMP_WIM_INDEX" | grep "Major Version" | sed 's/Major Version:\s*//')"
    TEMP_WIM_VERSION_MINOR="$(wiminfo "$TEMP_WIM_PATH" "$TEMP_WIM_INDEX" | grep "Minor Version" | sed 's/Minor Version:\s*//')"
    TEMP_WIM_GENERATION_SIGNATURE="error"

    if [ "$TEMP_WIM_VERSION_MAJOR" -eq 10 ]
    then
	TEMP_WIM_GENERATION_SIGNATURE="gen2"

    elif  [ "$TEMP_WIM_VERSION_MAJOR" -eq 6 ]
    then
	TEMP_WIM_GENERATION_SIGNATURE="gen1"
    fi

    echo "$TEMP_WIM_GENERATION_SIGNATURE"
    
    if [ "$TEMP_WIM_GENERATION_SIGNATURE" != "error" ]
    then
	return 0
    fi
    
    return 1
}


emp_extract_wim_list()
{
    TEMP_PARAMS_TAIL="$@"

    TEMP_WIM_FILE="$1"
    TEMP_DESTINATION_CHMOD_PERMS="$2"
    TEMP_PRINT_PREFIX="$3"
    TEMP_WIM_INDEX_LIST="${TEMP_PARAMS_TAIL#*$TEMP_PRINT_PREFIX* }"
    
    TEMP_SOURCE_FILES_SIZE_TOTAL=0
    TEMP_DESTINATION_FILES_SIZE_TOTAL=0
    
    echo -n "${TEMP_PRINT_PREFIX}"
    
    # First need to calculate size
    # Also while at it, remove old destinations
    for TEMP_WIM_INDEX in $TEMP_WIM_INDEX_LIST
    do
	# TEMP_WIM_FILE already given as parameter
	TEMP_FULL_DESTINATION_PATH="$EMP_WIM_DIRS_PARENT/$TEMP_WIM_INDEX"
	TEMP_SOURCE_WIM_SIZE="$(emp_count_wim_index_bytes_size "$TEMP_WIM_FILE" "$TEMP_WIM_INDEX")"
	TEMP_SOURCE_FILES_SIZE_TOTAL="$((TEMP_SOURCE_FILES_SIZE_TOTAL + TEMP_SOURCE_WIM_SIZE))"

	if [ ! -d "$TEMP_FULL_DESTINATION_PATH" ]
	then
	    echo ""
	    echo "ERROR: Needed wim file path $TEMP_FULL_DESTINATION_PATH does not exist."

	    return 1
	else
	    # Need to remove everything in it
	    touch "$TEMP_FULL_DESTINATION_PATH/foobar" > /dev/null 2>&1

	    rm -r "$TEMP_FULL_DESTINATION_PATH"/* > /dev/null 2>&1

	    if [ "$?" -ne 0 ]
	    then
		echo ""
		echo "ERROR: Unable to remove old files from wim path $TEMP_FULL_DESTINATION_PATH"

		return 1
	    fi
	fi
    done

    # Actual copy loop
    # Steps is shared
    TEMP_STEP=0
    
    for TEMP_WIM_INDEX in $TEMP_WIM_INDEX_LIST
    do
	# TEMP_WIM_FILE already given as parameter
	TEMP_FULL_DESTINATION_PATH="$EMP_WIM_DIRS_PARENT/$TEMP_WIM_INDEX"
	TEMP_SOURCE_WIM_SIZE="$(emp_count_wim_index_bytes_size "$TEMP_WIM_FILE" "$TEMP_WIM_INDEX")"
	#TEMP_SOURCE_FILES_SIZE_TOTAL="$((TEMP_SOURCE_FILES_SIZE_TOTAL + TEMP_SOURCE_WIM_SIZE))"
	TEMP_PROGRESS_INTERVAL_TIME="$(emp_calculate_progress_interval_time "$TEMP_SOURCE_WIM_SIZE")"

	TEMP_RUN_STATUS="ongoing"
	wimapply "$TEMP_WIM_FILE" "$TEMP_WIM_INDEX" "$TEMP_FULL_DESTINATION_PATH" > /dev/null 2>&1 &
	TEMP_CP_PID="$!"

	while [ "$TEMP_RUN_STATUS" = "ongoing" -a "$TEMP_STEP" -lt "$EMP_PROGRESS_MAX_STEPS" ]
	do
	    sleep "$TEMP_PROGRESS_INTERVAL_TIME" > /dev/null 2>&1
	    ps -p "$TEMP_CP_PID" > /dev/null 2>&1

	    if [ "$?" -eq 0 ]
	    then
		TEMP_PATH_SIZE_DESTINATION="$(emp_count_path_data_size "$TEMP_FULL_DESTINATION_PATH")"
		TEMP_TOTAL_PRINT_COPIED_SIZE="$((TEMP_DESTINATION_FILES_SIZE_TOTAL + TEMP_PATH_SIZE_DESTINATION))"
		TEMP_TOTAL_PERCENTAGE="$((100 * TEMP_TOTAL_PRINT_COPIED_SIZE / TEMP_SOURCE_FILES_SIZE_TOTAL))"

		if [ "$TEMP_TOTAL_PERCENTAGE" -gt 100 ]
		then
		    TEMP_TOTAL_PERCENTAGE=100
		fi

		echo -n "\r${TEMP_PRINT_PREFIX}${TEMP_TOTAL_PERCENTAGE}%"
		
	    else
		wait "$TEMP_CP_PID"
		TEMP_CP_RETVAL="$?"

		if [ "$TEMP_CP_RETVAL" -ne 0 ]
		then
		    # Fail case.
		    echo ""
		    echo "ERROR: Failed extracting $TEMP_WIM_FILE index $TEMP_WIM_INDEX to $TEMP_FULL_DESTINATION_PATH"

		    return "$TEMP_CP_RETVAL"
		fi

		if [ "$TEMP_DESTINATION_CHMOD_PERMS" != "" ]
		then
		    chmod -R "$TEMP_DESTINATION_CHMOD_PERMS" "$TEMP_FULL_DESTINATION_PATH" > /dev/null 2>&1
		    TEMP_CHMOD_RETVAL="$?"
		    
		    if [ "$TEMP_CHMOD_RETVAL" -ne 0 ]
		    then
			echo ""
			echo "ERROR: Unable to set permissions for directory $TEMP_FULL_DESTINATION_PATH"

			return "$TEMP_CHMOD_RETVAL"
		    fi
		fi

		# This copy was fine
		TEMP_RUN_STATUS="file_finished"
		TEMP_PATH_SIZE_DESTINATION="$(emp_count_path_data_size "$TEMP_FULL_DESTINATION_PATH")"
		TEMP_DESTINATION_FILES_SIZE_TOTAL="$((TEMP_DESTINATION_FILES_SIZE_TOTAL + TEMP_PATH_SIZE_DESTINATION))"
		TEMP_TOTAL_PERCENTAGE="$((100 * TEMP_DESTINATION_FILES_SIZE_TOTAL / TEMP_SOURCE_FILES_SIZE_TOTAL))"

		if [ "$TEMP_TOTAL_PERCENTAGE" -gt 100 ]
		then
		    TEMP_TOTAL_PERCENTAGE=100
		fi
		
		echo -n "\r${TEMP_PRINT_PREFIX}${TEMP_TOTAL_PERCENTAGE}%"
	    fi

	    TEMP_STEP="$((TEMP_STEP + 1))"
	done
    done

    echo "\r${TEMP_PRINT_PREFIX}done"

    return 0
}




emp_copy_work_wim()
{
    emp_copy_file_list_to_dir "$EMP_MOUNT_POINT/$EMP_WIM_FILE_ISO_SUBDIR" "$EMP_WIM_DIRS_PARENT" "$EMP_WIN_TEMPLATE_DIRS_CHMOD_PERMS" "Copying wim as work item..." "$EMP_WIM_BOOT_FILE_NAME"

    if [ "$?" -ne 0 ]
    then
	emp_force_unmount_generic_mountpoint

	exit 1
    fi
}


emp_remove_setup_from_wim()
{
    echo -n "Removing setup files from wim..."
    wimupdate "$EMP_WIN_TEMPLATE_WORK_BOOT_WIM_PATH" 2 > /dev/null 2>&1 <<EOF
delete --force /setup.exe
delete --force --recursive /Sources
delete --force --recursive /sources 
delete --force /Windows/System32/startnet.cmd
EOF

    if [ "$?" -ne 0 ]
    then
	echo "ERROR: Unable to remove setup files from $EMP_WIN_TEMPLATE_WORK_BOOT_WIM_PATH image 2"
	emp_force_unmount_generic_mountpoint

	exit 1
    fi
    echo "done"
}


emp_extract_base_wims()
{
    emp_extract_wim_list "$EMP_WIN_TEMPLATE_WORK_BOOT_WIM_PATH" "$EMP_WIN_TEMPLATE_DIRS_CHMOD_PERMS" "Extracting base wims..." 1 2
    
    if [ "$?" -ne 0 ]
    then
	emp_force_unmount_generic_mountpoint

	exit 1
    fi
}


emp_collect_trim_list_of_base_wim_files()
{
    echo -n "Collecting trim list of base wim files..."
    
    TEMP_CMD_ARCH=""
    
    if [ "$EMP_WIN_TEMPLATE_MAIN_ARCH" = "x64" ]
    then
	TEMP_CMD_ARCH="amd64"

    elif [ "$EMP_WIN_TEMPLATE_MAIN_ARCH" = "x32" ]
    then
	TEMP_CMD_ARCH="x86"

    else
	echo ""
	echo "ERROR: Collecting trim list failed due to unknown template main arch $EMP_WIN_TEMPLATE_MAIN_ARCH"
	emp_force_unmount_generic_mountpoint

	exit 1
    fi

    EMP_WIN_TEMPLATE_WIM_TRIM_LIST="$(diff -u -r "$EMP_WIM_DIR_FIRST" "$EMP_WIM_DIR_SECOND" | grep "SxS:" | sed "s,SxS: $TEMP_CMD_ARCH,SxS/$TEMP_CMD_ARCH,g" | sed "s,^Only in $EMP_WIM_DIR_SECOND,,g")"

    if [ "$?" -ne 0 ]
    then
	echo ""
	echo "ERROR: Unable to collect trim list"
	emp_force_unmount_generic_mountpoint

	exit 1
    fi

    echo "done"
}


emp_trim_base_wim()
{
    echo -n "Trimming base wim..."
    TEMP_CMD_ARCH=""
    
    if [ "$EMP_WIN_TEMPLATE_MAIN_ARCH" = "x64" ]
    then
	TEMP_CMD_ARCH="amd64"

    elif [ "$EMP_WIN_TEMPLATE_MAIN_ARCH" = "x32" ]
    then
	TEMP_CMD_ARCH="x86"

    else
	exit 1
    fi
    
    OIFS=$IFS
    # Easiest way to get posix IFS
    IFS="
"
    TEMP_LINES_TOTAL="$(echo "$EMP_WIN_TEMPLATE_WIM_TRIM_LIST" | wc -l)"
    TEMP_LINES_PROCESSED=0
    
    for TEMP_LINE in $EMP_WIN_TEMPLATE_WIM_TRIM_LIST
    do
	echo "delete --force --recursive $TEMP_LINE" | wimupdate "$EMP_WIN_TEMPLATE_WORK_BOOT_WIM_PATH" 2 > /dev/null 2>&1
	# Check error here
	TEMP_LINES_PROCESSED="$((TEMP_LINES_PROCESSED+1))"
	TEMP_TOTAL_PERCENTAGE="$(((100 * TEMP_LINES_PROCESSED) / TEMP_LINES_TOTAL))"
	echo -n "\rTrimming base wim...$TEMP_TOTAL_PERCENTAGE%"
    done
    IFS=$OIFS
    
    echo "\rTrimming base wim...done"
}


emp_re_export_wim_as_bootable()
{
    TEMP_SOURCE_WIM_FILE="$1"
    TEMP_SOURCE_WIM_INDEX="$2"
    TEMP_DESTINATION_WIM_FILE="$3"
    TEMP_DESTINATION_CHMOD_PERMS="$4"
    TEMP_PRINT_PREFIX="$5"

    TEMP_SOURCE_WIM_FILES_SIZE="$(emp_count_wim_index_bytes_size "$EMP_WIN_TEMPLATE_WORK_BOOT_WIM_PATH" 2)"
    TEMP_EXPECTED_EXPORTED_WIM_SIZE="$(((EMP_WIM_COMPRESSION_PERCENTAGE * TEMP_SOURCE_WIM_FILES_SIZE) / 100))"

    echo -n "${TEMP_PRINT_PREFIX}"

    if [ -f "$TEMP_DESTINATION_WIM_FILE" ]
    then
	rm "$TEMP_DESTINATION_WIM_FILE" > /dev/null 2>&1

	if [ "$?" -ne 0 ]
	then
	    echo "ERROR: Unable to remove destination wim file $TEMP_DESTINATION_WIM_FILE"
	    emp_force_unmount_generic_mountpoint

	    exit 1
	fi
    fi
    
    TEMP_RUN_STATUS="ongoing"
    wimexport "$TEMP_SOURCE_WIM_FILE" "$TEMP_SOURCE_WIM_INDEX" "$TEMP_DESTINATION_WIM_FILE" --boot --rebuild  > /dev/null 2>&1 &

    TEMP_WIM_EXPORT_PID="$!"

    while [ "$TEMP_RUN_STATUS" = "ongoing" -a "$TEMP_STEP" -lt "$EMP_PROGRESS_MAX_STEPS" ]
    do
	sleep "$TEMP_PROGRESS_INTERVAL_TIME" > /dev/null 2>&1
	ps -p "$TEMP_WIM_EXPORT_PID" > /dev/null 2>&1

	if [ "$?" -eq 0 ]
	then
	    TEMP_TOTAL_PRINT_COPIED_SIZE="$(emp_count_path_data_size "$TEMP_DESTINATION_WIM_FILE")"
	    TEMP_TOTAL_PERCENTAGE="$((100 * TEMP_TOTAL_PRINT_COPIED_SIZE / TEMP_EXPECTED_EXPORTED_WIM_SIZE))"

	    if [ "$TEMP_TOTAL_PERCENTAGE" -gt 100 ]
	    then
		TEMP_TOTAL_PERCENTAGE=100
	    fi

	    echo -n "\r${TEMP_PRINT_PREFIX}${TEMP_TOTAL_PERCENTAGE}%"
	    
	else
	    wait "$TEMP_WIM_EXPORT_PID"
	    TEMP_WIM_EXPORT_RETVAL="$?"

	    if [ "$TEMP_WIM_EXPORT_RETVAL" -ne 0 ]
	    then
		# Fail case.
		echo ""
		echo "ERROR: Failed exporting final wim to $TEMP_DESTINATION_WIM_FILE"
		emp_force_unmount_generic_mountpoint

		exit "$TEMP_WIM_EXPORT_RETVAL"
	    fi

	    if [ "$TEMP_DESTINATION_CHMOD_PERMS" != "" ]
	    then
		chmod -R "$TEMP_DESTINATION_CHMOD_PERMS" "$TEMP_DESTINATION_WIM_FILE" > /dev/null 2>&1
		TEMP_CHMOD_RETVAL="$?"
		
		if [ "$TEMP_CHMOD_RETVAL" -ne 0 ]
		then
		    echo ""
		    echo "ERROR: Unable to set permissions for final wim $TEMP_DESTINATION_WIM_FILE"
		    emp_force_unmount_generic_mountpoint

		    return "$TEMP_CHMOD_RETVAL"
		fi
	    fi

	    # Copying of the only wim was fine
	    TEMP_RUN_STATUS="file_finished"
	    TEMP_TOTAL_PERCENTAGE=100
	    
	    echo -n "\r${TEMP_PRINT_PREFIX}${TEMP_TOTAL_PERCENTAGE}%"
	fi

	TEMP_STEP="$((TEMP_STEP + 1))"
    done
    
    echo "\r${TEMP_PRINT_PREFIX}done"

    return 0
}


emp_export_final_wim()
{
    emp_re_export_wim_as_bootable "$EMP_WIN_TEMPLATE_WORK_BOOT_WIM_PATH" 2 "$EMP_WIN_TEMPLATE_FINAL_BOOT_WIM_PATH" "$EMP_WIN_TEMPLATE_DIRS_CHMOD_PERMS" "Exporting final template wim..."

    if [ "$?" -ne 0 ]
    then
	exit 1
    fi

    echo "Exported to $EMP_WIN_TEMPLATE_FINAL_BOOT_WIM_PATH"
}


debian_mirror_selection()
{
    echo -n ""
    # This function does nothing
}



debian_download_support_files()
{
    echo -n "Downloading index file..."
    TEMP_URL="`wget -O - https://packages.debian.org/bookworm/all/download-installer/download 2> /dev/null | grep href | grep download-installer_ | head -n 1 | grep -o -E 'https?://[^"]+'`"

    if [ "$?" != 0 -o -z "$TEMP_URL" ]
    then
	echo ""
	echo "ERROR: Unable to download index from $EMP_DEBIAN_DOWNLOAD_INSTALLER_PAGE_URL"
	exit 1
    fi
    
    echo "done"
    TEMP_FILE_NAME="$(basename "$TEMP_URL")"
    TEMP_FILE_PATH="$EMP_DEBIAN_SUPPORT_DIR_PATH/$TEMP_FILE_NAME"
    TEMP_TEMP_FILE_PATH="$EMP_DEBIAN_SUPPORT_DIR_PATH/$TEMP_FILE_NAME.tmp"

    if [ -f "$TEMP_TEMP_FILE_PATH" ]
    then
	rm "$TEMP_TEMP_FILE_PATH"

	if [ "$?" -ne 0 ]
	then
	    echo "ERROR: Unable to remove old temporary file $TEMP_TEMP_FILE_PATH"
	    exit 1
	fi
    fi
    echo -n "Downloading support files..."
    wget -O "$TEMP_TEMP_FILE_PATH" "$TEMP_URL" > /dev/null 2>&1

    if [ "$?" -ne 0 ]
    then
	echo ""
	echo "ERROR: Unable to download $TEMP_URL as $TEMP_TEMP_FILE_PATH"
	exit 1
    fi
    echo "done"

    # Move temporary file as official
    mv "$TEMP_TEMP_FILE_PATH" "$TEMP_FILE_PATH" > /dev/null 2>&1

    if [ "$?" -ne 0 ]
    then
	echo "ERROR: Unable to move temporary file $TEMP_TEMP_FILE_PATH as final"
	exit 1
    fi
    echo "Downloaded files:"
    echo "$TEMP_FILE_PATH"
}




emp_unpack_initrd()
{
    echo -n "Unpacking initrd.gz..."
    # Remove old EMP_INITRD_DIR_PATH
    touch "$EMP_INITRD_DIR_TREE_PATH/foobar" > /dev/null 2>&1

    rm -r "$EMP_INITRD_DIR_TREE_PATH/"* > /dev/null 2>&1

    if [ "$?" -ne 0 ]
    then
	echo ""
	echo "ERROR: Unable to remove old initrd remnants in $EMP_INITRD_DIR_TREE_PATH"
	emp_force_unmount_generic_mountpoint

	exit 1
    fi

    for TEMP_FILE_PATH in "$EMP_INITRD_DIR_TREE_PATH"/.*
    do
	TEMP_FILE="$(basename "$TEMP_FILE_PATH")"

	if [ "$TEMP_FILE" != "." -a "$TEMP_FILE" != ".." -a "$TEMP_FILE" != ".gitignore" ]
	then
	    rm "$TEMP_FILE_PATH" > /dev/null 2>&1

	    if [ "$?" -ne 0 ]
	    then
		echo ""
		echo "ERROR: Unable to remove old initrd remnant $TEMP_FILE_PATH"
		emp_force_unmount_generic_mountpoint
		
		exit 1
	    fi
	fi
    done
    
    TEMP_INITRD_SOURCE_PATH="$EMP_MOUNT_POINT/$EMP_BOOT_OS_INITRD_PATH"
    zcat "$TEMP_INITRD_SOURCE_PATH" | cpio -i -d -D "$EMP_INITRD_DIR_TREE_PATH" > /dev/null 2>&1

    if [ "$?" -ne 0 ]
    then
	echo ""
	echo "ERROR: Unable to unpack $TEMP_INITRD_SOURCE_PATH to $EMP_INITRD_DIR_TREE_PATH"
	emp_force_unmount_generic_mountpoint
	
	exit 1
    fi	

    echo "done"
}



dpkg_remove_initrd_packages()
{
    echo -n "Removing conflicting packages from initrd.gz..."
    
    dpkg --root="$EMP_INITRD_DIR_TREE_PATH" --force-architecture -P ${EMP_INITRD_REMOVE_PACKAGES_LIST} > /dev/null 2>&1

    if [ "$?" -ne 0 ]
    then
	echo ""
	echo "ERROR: Unable to remove packages from $EMP_INITRD_DIR_TREE_PATH"
	emp_force_unmount_generic_mountpoint
	
	exit 1
    fi
    
    echo "done"
}


dpkg_install_udeb_packages_from_tree()
{
    TEMP_PARAMS_TAIL="$@"

    TEMP_PACKAGES_SOURCE_TREE="$1"
    TEMP_PACKAGE_NAME_SUFFIX="$2"
    TEMP_INITRD_ROOT="$3"
    TEMP_PRINT_PREFIX="$4"
    TEMP_SOURCE_REL_FILE_LIST="${TEMP_PARAMS_TAIL#*$TEMP_PRINT_PREFIX* }"

    echo -n "$TEMP_PRINT_PREFIX"
    
    # First make full list of packages
    TEMP_SOURCE_REL_FILE_PATH_LIST=""
    
    for TEMP_PACKAGE in $TEMP_SOURCE_REL_FILE_LIST
    do

	TEMP_SEARCH_PACKAGE="/$TEMP_PACKAGE$TEMP_PACKAGE_NAME_SUFFIX"
	TEMP_PACKAGE_PATH="$(find "$TEMP_PACKAGES_SOURCE_TREE" | grep "$TEMP_SEARCH_PACKAGE" | grep "\\.udeb$" | head -n 1)"

	if [ -z "TEMP_PACKAGE_PATH" ]
	then
	    echo ""
	    echo "ERROR: Unable to find find package $TEMP_PACKAGE from $TEMP_PACKAGES_SOURCE_TREE"
	    
	    return 1
	fi
	TEMP_SOURCE_REL_FILE_PATH_LIST="$TEMP_SOURCE_REL_FILE_PATH_LIST $TEMP_PACKAGE_PATH"
    done

    # Calculate sizes
    TEMP_SOURCE_FILES_SIZE_TOTAL=0
    TEMP_DESTINATION_FILES_SIZE_TOTAL=0

    for TEMP_SOURCE_REL_FILE_PATH in $TEMP_SOURCE_REL_FILE_PATH_LIST
    do
	TEMP_SOURCE_PATH_SIZE="$(emp_count_path_data_size "$TEMP_SOURCE_REL_FILE_PATH")"
	TEMP_SOURCE_FILES_SIZE_TOTAL="$((TEMP_SOURCE_FILES_SIZE_TOTAL + TEMP_SOURCE_PATH_SIZE))"
    done

    # Actual installation
    # Just a simple loop, no background things because we don't know what would happen there
    TEMP_TOTAL_PERCENTAGE=0

    for TEMP_SOURCE_REL_FILE_PATH in $TEMP_SOURCE_REL_FILE_PATH_LIST
    do
	TEMP_SOURCE_PATH_SIZE="$(emp_count_path_data_size "$TEMP_SOURCE_REL_FILE_PATH")"
	dpkg --root="$TEMP_INITRD_ROOT" --force-architecture --unpack "$TEMP_SOURCE_REL_FILE_PATH" > /dev/null 2>&1

	if [ "$?" -ne 0 ]
	then
	    echo ""
	    echo "ERROR: Error installing $TEMP_SOURCE_REL_FILE_PATH to initrd $TEMP_INITRD_ROOT"
	    
	    return 1
	fi
	# It was ok. Make percentage
	TEMP_DESTINATION_FILES_SIZE_TOTAL="$((TEMP_DESTINATION_FILES_SIZE_TOTAL + TEMP_SOURCE_PATH_SIZE))"
	TEMP_TOTAL_PERCENTAGE="$((100 * TEMP_DESTINATION_FILES_SIZE_TOTAL / TEMP_SOURCE_FILES_SIZE_TOTAL))"
	# Print it
	echo -n "\r${TEMP_PRINT_PREFIX}${TEMP_TOTAL_PERCENTAGE}%"
    done

    echo "\r${TEMP_PRINT_PREFIX}done"
}


dpkg_install_support_packages()
{
    dpkg_install_udeb_packages_from_tree "$EMP_BOOT_OS_ASSETS_PARENT/support" "_" "$EMP_INITRD_DIR_TREE_PATH" "Installing support packages to initrd.gz..." "$EMP_INITRD_ADD_SUPPORT_PACKAGES_LIST"

    if [ "$?" -ne 0 ]
    then
	echo "ERROR: Error installing support packages"
	emp_force_unmount_generic_mountpoint
	
	return 1
    fi
}


dpkg_install_extra_packages()
{
    dpkg_install_udeb_packages_from_tree "$EMP_MOUNT_POINT" "_" "$EMP_INITRD_DIR_TREE_PATH" "Installing extra packages to initrd.gz..." "$EMP_INITRD_ADD_EXTRA_PACKAGES_LIST"

    if [ "$?" -ne 0 ]
    then
	echo "ERROR: Error installing extra packages"
	emp_force_unmount_generic_mountpoint
	
	return 1
    fi
}


dpkg_install_module_packages()
{
    dpkg_install_udeb_packages_from_tree "$EMP_MOUNT_POINT" "-" "$EMP_INITRD_DIR_TREE_PATH" "Installing module packages to initrd.gz..." "$EMP_INITRD_ADD_MODULE_PACKAGES_LIST"

    if [ "$?" -ne 0 ]
    then
	echo "ERROR: Error installing extra packages"
	emp_force_unmount_generic_mountpoint
	
	exit 1
    fi

    # Need to depmod
    TEMP_KERNEL_ID="`ls -1 $EMP_INITRD_DIR_TREE_PATH$EMP_KERNEL_MODULES_SUBDIR | head -n 1`"
    TEMP_KERNEL_MODULES_DIR_PATH="$EMP_INITRD_DIR_TREE_PATH$EMP_KERNEL_MODULES_SUBDIR/$TEMP_KERNEL_ID"
    
    if [ ! -d "$TEMP_KERNEL_MODULES_DIR_PATH" ]
    then
	echo "ERROR: Unable to determine kernel modules path in $EMP_INITRD_DIR_PATH"
	emp_force_unmount_generic_mountpoint
	
	exit 1
    fi
	
    depmod -b "$EMP_INITRD_DIR_TREE_PATH" "$TEMP_KERNEL_ID" > /dev/null 2>&1

    if [ "$?" -ne 0 ]
    then
	echo "ERROR: Unable to depmod new modules in $EMP_INITRD_DIR_TREE_PATH"
	emp_force_unmount_generic_mountpoint
	
	exit 1
    fi
}


emp_create_initrd_preseed()
{
    echo -n "Creating initrd preseed file..."

    if [ -f "$EMP_INITRD_DIR_TREE_PATH/$EMP_PRESEED_FILE_NAME" ]
    then
	rm "$EMP_INITRD_DIR_TREE_PATH/$EMP_PRESEED_FILE_NAME" > /dev/null 2>&1

	if [ "$?" -ne 0 ]
	then
	    echo ""
	    echo "ERROR: Unable to remove old preseed file $EMP_INITRD_DIR_TREE_PATH/$EMP_PRESEED_FILE_NAME"
	    emp_force_unmount_generic_mountpoint
	    
	    exit 1

	fi
	   
    fi
    
    cat <<EOF > "$EMP_INITRD_DIR_TREE_PATH/$EMP_PRESEED_FILE_NAME"
#_preseed_V1
d-i mirror/country string manual
d-i mirror/http/hostname string $EMP_WEBSERVER_IP
d-i mirror/http/directory string /$EMP_WEBSERVER_PATH_PREFIX/$EMP_BOOT_OS_ASSETS_SUBDIR/$EMP_BOOT_OS_ASSETS_UNPACKED_ISO_SUBDIR
d-i debian-installer/allow_unauthenticated boolean true
EOF

    if [ "$?" -ne 0 ]
    then
	echo "ERROR: Unable to create initrd preseed file $EMP_INITRD_DIR_TREE_PATH/$EMP_PRESEED_FILE_NAME"
	emp_force_unmount_generic_mountpoint
	
	exit 1
    fi

    echo "done"
}



emp_repack_initrd()
{
    TEMP_PWD="`pwd`"
    #EMP_INITRD_COMPRESSION_PERCENTAGE=29
    #cd "$EMP_INITRD_DIR_PATH" && find . | grep -v gitignore | cpio -o -H newc > "../$EMP_INITRD_FILE_NAME"

    TEMP_SOURCE_INITRD_DIR_PATH="$EMP_INITRD_DIR_TREE_PATH"
    TEMP_DESTINATION_INITRD_FILE_PATH="$EMP_INITRD_DIR_PARENT_PATH/$EMP_INITRD_GZIPPED_FILE_NAME"
    TEMP_DESTINATION_CHMOD_PERMS="$EMP_ASSETS_DIRS_CHMOD_PERMS"
    TEMP_PRINT_PREFIX="Repacking initrd..."
    TEMP_SOURCE_INITRD_FILES_SIZE="$(emp_count_path_data_size "$TEMP_SOURCE_INITRD_DIR_PATH")"
    TEMP_EXPECTED_REPACKED_INITRD_SIZE="$(((EMP_INITRD_COMPRESSION_PERCENTAGE * TEMP_SOURCE_INITRD_FILES_SIZE) / 100))"
    TEMP_PROGRESS_INTERVAL_TIME="$(emp_calculate_progress_interval_time "$TEMP_EXPECTED_REPACKED_INITRD_SIZE")"
    TEMP_STEP=0

    echo -n "${TEMP_PRINT_PREFIX}"

    if [ -f "$TEMP_DESTINATION_INITRD_FILE_PATH" ]
    then
	rm "$TEMP_DESTINATION_INITRD_FILE_PATH" > /dev/null 2>&1

	if [ "$?" -ne 0 ]
	then
	    echo "ERROR: Unable to remove destination wim file $TEMP_DESTINATION_INITRD_FILE_PATH"
	    emp_force_unmount_generic_mountpoint

	    exit 1
	fi
    fi
    
    TEMP_RUN_STATUS="ongoing"

    cd "$EMP_INITRD_DIR_TREE_PATH" &&
	find . |
	grep -v gitignore |
	cpio -o -H newc --quiet |
	gzip -9 > "$TEMP_DESTINATION_INITRD_FILE_PATH" &
    TEMP_INITRD_REPACK_PID="$!"

    while [ "$TEMP_RUN_STATUS" = "ongoing" -a "$TEMP_STEP" -lt "$EMP_PROGRESS_MAX_STEPS" ]
    do
	sleep "$TEMP_PROGRESS_INTERVAL_TIME" > /dev/null 2>&1
	ps -p "$TEMP_INITRD_REPACK_PID" > /dev/null 2>&1

	if [ "$?" -eq 0 ]
	then
	    TEMP_TOTAL_PRINT_COPIED_SIZE="$(emp_count_path_data_size "$TEMP_DESTINATION_INITRD_FILE_PATH")"
	    TEMP_TOTAL_PERCENTAGE="$((100 * TEMP_TOTAL_PRINT_COPIED_SIZE / TEMP_EXPECTED_REPACKED_INITRD_SIZE))"

	    if [ "$TEMP_TOTAL_PERCENTAGE" -gt 100 ]
	    then
		TEMP_TOTAL_PERCENTAGE=100
	    fi

	    echo -n "\r${TEMP_PRINT_PREFIX}${TEMP_TOTAL_PERCENTAGE}%"
	    
	else
	    wait "$TEMP_INITRD_REPACK_PID"
	    TEMP_INITRD_REPACK_RETVAL="$?"

	    if [ "$TEMP_INITRD_REPACK_RETVAL" -ne 0 ]
	    then
		# Fail case.
		echo ""
		echo "ERROR: Failed repacking initrd file to $TEMP_DESTINATION_INITRD_FILE_PATH"
		emp_force_unmount_generic_mountpoint

		exit "$TEMP_INITRD_REPACK_RETVAL"
	    fi

	    if [ "$TEMP_DESTINATION_CHMOD_PERMS" != "" ]
	    then
		chmod -R "$TEMP_DESTINATION_CHMOD_PERMS" "$TEMP_DESTINATION_INITRD_FILE_PATH" > /dev/null 2>&1
		TEMP_CHMOD_RETVAL="$?"
		
		if [ "$TEMP_CHMOD_RETVAL" -ne 0 ]
		then
		    echo ""
		    echo "ERROR: Unable to set permissions for initrd file $TEMP_DESTINATION_INITRD_FILE_PATH"
		    emp_force_unmount_generic_mountpoint

		    return "$TEMP_CHMOD_RETVAL"
		fi
	    fi

	    # Processing the only initrd was fine
	    TEMP_RUN_STATUS="file_finished"
	    TEMP_TOTAL_PERCENTAGE=100
	    
	    echo -n "\r${TEMP_PRINT_PREFIX}${TEMP_TOTAL_PERCENTAGE}%"
	fi

	TEMP_STEP="$((TEMP_STEP + 1))"
    done

    echo "\r${TEMP_PRINT_PREFIX}done"
    
    return 0
}


emp_copy_simple_initrd_file()
{
    emp_copy_file_list_to_dir "$EMP_INITRD_DIR_PARENT_PATH" "$EMP_BOOT_OS_ASSETS_FS_BASE_PATH" "" "Copying initrd file..." "$EMP_INITRD_GZIPPED_FILE_NAME"

    if [ "$?" -ne 0 ]
    then
	echo ""
	echo "ERROR: Unable to copy initrd file $EMP_INITRD_GZIPPED_FILE_NAME from $EMP_INITRD_DIR_PARENT_PATH"
	emp_force_unmount_generic_mountpoint

	exit 1
    fi
}
