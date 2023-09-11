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
    if [ ! -f "$EMP_MAIN_CONFIG" ]
    then
	echo "Error: Config file $EMP_MAIN_CONFIG does not exist."

	exit 1
    fi
    # Main config is guaranteed to exist now, including it
    . "$EMP_MAIN_CONFIG"
    # Already include the provisioning functions file,
    # we might need it in figuring out variables.
    . "$EMP_TOPDIR/emp_functions.sh"

    # Prereq for prechecks
    COPY_ISO="yes"
    # Need to do a couple of prechecks
    check_iso_file "$1"
    check_assets_prefix_dir "$2"
    check_copy_iso "$3"

    # Can continue with parameters and stuff
    
fi


