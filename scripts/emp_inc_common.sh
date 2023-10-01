#!/bin/sh

if [ "$EMP_OP" != "create_configs" -a "$EMP_OP" != "do_provisioning" ]
then
    echo "Error: Unknown operation: $EMP_OP"

    exit 1
fi

# Common core definitions
EMP_TOPDIR="$(realpath "$(dirname ${EMP_INC_COMMON})"/..)"
EMP_MAIN_CONFIG="$EMP_TOPDIR/conf/easy_multi_pxe.conf"

# Functions are always needed to be available, even if some
# dependant variables dont exist. We just dont run the scripts
# prematurely.
. "$EMP_TOPDIR/scripts/emp_functions.sh"

# Read config so we can access more variables
emp_read_config "$EMP_MAIN_CONFIG"

# Rest of common definitions
EMP_ASSETS_ROOT_DIR="$EMP_TOPDIR/netbootassets"

if [ "$EMP_OP" = "create_configs" ]
then
    EMP_CONFIG_DIR="$EMP_TOPDIR/conf"
    EMP_SCRIPTS_DIR="$EMP_TOPDIR/scripts"
    EMP_TFTPROOT_DIR="$EMP_TOPDIR/tftproot"

    EMP_CONFIG_CHMOD_PERMS="ug=r"
    EMP_WEBSERVER_USERNAME="www-data"

    EMP_APACHE_CONF_TEMPLATE="$EMP_CONFIG_DIR/apache2_emp_inc.conf.template"
    EMP_APACHE_CONF_FINAL="$EMP_CONFIG_DIR/apache2_emp_inc.conf"
    EMP_DNSMASQ_CONF_TEMPLATE="$EMP_CONFIG_DIR/dnsmasq_emp_inc.conf.template"
    EMP_DNSMASQ_CONF_FINAL="$EMP_CONFIG_DIR/dnsmasq_emp_inc.conf"
    EMP_NGINX_CONF_TEMPLATE="$EMP_CONFIG_DIR/nginx_emp_inc.conf.template"
    EMP_NGINX_CONF_FINAL="$EMP_CONFIG_DIR/nginx_emp_inc.conf"

elif [ "$EMP_OP" = "do_provisioning" ]
then
    # Static provision-specific variables not affected
    # by parameters or configurations
    EMP_MOUNT_POINT="$EMP_TOP_DIR/work/mount"
    
    # Collect and verify provision-specific variables
    emp_collect_provisioning_parameters "$@"
    emp_assert_provisioning_parameters
    # emp_assert_provisioning_parameters provides:
    # EMP_BOOT_OS_FAMILY
    # EMP_BOOT_OS_MAIN_ARCH
    # EMP_BOOT_OS_MAIN_VERSION

    EMP_ASSETS_DIR_CHMOD_PERMS="u+rwX"
    
    # Now we can create all the rest of the variables
    EMP_BOOT_OS_ISO_FILE="$(basename "$EMP_BOOT_OS_ISO_PATH")"
    EMP_BOOT_OS_ISO_NAME="${EMP_BOOT_OS_ISO_FILE%.*}"
    # EMP_BOOT_OS_ASSETS_SUBDIR is like ubuntu/20.04/x64/ubuntu-20.04-mini-amd64
    EMP_BOOT_OS_ASSETS_TYPE="unknown"
    EMP_BOOT_OS_ASSETS_SUBDIR="${EMP_BOOT_OS_ASSETS_PARENT#$EMP_ASSETS_ROOT_DIR/}/$EMP_BOOT_OS_ISO_NAME"
    EMP_BOOT_OS_ASSETS_HTTP_BASE_PATH="$EMP_WEBSERVER_PROTOCOL://$EMP_WEBSERVER_IP/$EMP_WEBSERVER_PATH_PREFIX/$EMP_BOOT_OS_ASSETS_SUBDIR"
    EMP_BOOT_OS_ASSETS_FS_BASE_PATH="$EMP_ASSETS_ROOT_DIR/$EMP_BOOT_OS_ASSETS_SUBDIR"
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
fi


