#!/bin/sh

if [ "$EMP_OP" != "create_configs" -a "$EMP_OP" != "do_provisioning" ]
then
    echo "Error: Unknown operation: $EMP_OP"

    exit 1
fi

# Common definitions

EMP_TOPDIR="$(realpath "$(dirname ${EMP_INC_COMMON})"/..)"
MAIN_CONFIG="$EMP_TOPDIR/conf/easy_multi_pxe.conf"
EMP_ASSETS_ROOT_DIR="$EMP_TOPDIR/netbootassets"

if [ "$EMP_OP" = "create_configs" ]
then
    WEBSERVER_PREFIX_DEFAULT="netbootassets"
    CIFS_SHARE_NAME_DEFAULT="Netboot"

    CONFIGS_DIR="$EMP_TOPDIR/conf"
    SCRIPTS_DIR="$EMP_TOPDIR/scripts"
    TFTPROOT_DIR="$EMP_TOPDIR/tftproot"

    WEBSERVER_USERNAME="www-data"

    APACHE_EMP_CONF_TEMPLATE="$CONFIGS_DIR/apache2_emp_inc.conf.template"
    APACHE_EMP_CONF_FINAL="$CONFIGS_DIR/apache2_emp_inc.conf"
    DNSMASQ_EMP_CONF_TEMPLATE="$CONFIGS_DIR/dnsmasq_emp_inc.conf.template"
    DNSMASQ_EMP_CONF_FINAL="$CONFIGS_DIR/dnsmasq_emp_inc.conf"
    NGINX_EMP_CONF_TEMPLATE="$CONFIGS_DIR/nginx_emp_inc.conf.template"
    NGINX_EMP_CONF_FINAL="$CONFIGS_DIR/nginx_emp_inc.conf"

elif [ "$EMP_OP" = "do_provisioning" ]
then
    if [ ! -f "$MAIN_CONFIG" ]
    then
	echo "Error: Config file $MAIN_CONFIG does not exist."

	exit 1
    fi
    # Main config is guaranteed to exist now, including it
    . "$MAIN_CONFIG"
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


