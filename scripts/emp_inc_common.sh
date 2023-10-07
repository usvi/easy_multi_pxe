#!/bin/sh

if [ "$EMP_OP" != "create_configs" -a "$EMP_OP" != "do_provisioning" -a "$EMP_OP" != "create_windows_template" ]
then
    echo "Error: Unknown operation: $EMP_OP"

    exit 1
fi

# Common core definitions
EMP_TOPDIR="$(realpath "$(dirname ${EMP_INC_COMMON})"/..)"
EMP_MAIN_CONFIG="$EMP_TOPDIR/conf/easy_multi_pxe.conf"
EMP_ALL_COMMAND_LINE_PARAMS="$@"

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
    emp_collect_general_pre_parameters_variables
    emp_assert_general_directories
    
    emp_collect_provisioning_parameters "$@"
    emp_assert_provisioning_parameters
    
    emp_collect_general_post_parameters_variables
    emp_collect_provisioning_variables

    emp_ensure_provisioning_directories
    
    echo "Starting provisioning for $EMP_BOOT_OS_MAIN_ARCH $EMP_BOOT_OS_FAMILY $EMP_BOOT_OS_MAIN_VERSION"
    echo "Using iso $EMP_BOOT_OS_ISO_PATH"
    echo "Target dir $EMP_BOOT_OS_ASSETS_FS_BASE_PATH"

elif [ "$EMP_OP" = "create_windows_template" ]
then
    emp_collect_general_pre_parameters_variables
    emp_assert_general_directories

    emp_collect_windows_template_creation_parameters "$@"
    emp_assert_windows_template_creation_parameters

    emp_collect_general_post_parameters_variables
    emp_collect_windows_template_creation_variables
    
    emp_ensure_windows_template_creation_directories

    echo "Starting creating windows template for $EMP_WIN_TEMPLATE_MAIN_ARCH"
    echo "Using iso $EMP_WIN_TEMPLATE_ISO_PATH"
    echo "Target dir $EMP_WIN_TEMPLATE_DIR_PATH"
fi

