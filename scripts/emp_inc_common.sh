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
    EMP_WEBSERVER_PREFIX_DEFAULT="netbootassets"
    EMP_CIFS_SHARE_NAME_DEFAULT="Netboot"

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
    # Main config and functions have been already included in the common section
    emp_collect_provisioning_parameters "$@"
    emp_verify_provisioning_parameters

    if [ "$?" -ne 0 ]
    then
	echo "ERROR: Provisioning parameters failed, exiting."
	emp_print_call_help
	exit 1
    fi

    echo "provisioning debug exit"
    exit 1
    
fi


