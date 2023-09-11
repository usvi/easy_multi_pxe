#!/bin/sh

if [ "$EMP_OP" != "create_configs" -a "$EMP_OP" != "do_provisioning" ]
then
    echo "Error: Unknown operation: $EMP_OP"

    exit 1
fi

# Common definitions

EMP_TOPDIR="$(realpath "$(dirname ${EMP_INC_COMMON})"/..)"

echo "Created topdir $EMP_TOPDIR"

if [ "$EMP_OP" = "create_configs" ]
then
    WEBSERVER_PREFIX_DEFAULT="netbootassets"
    CIFS_SHARE_NAME_DEFAULT="Netboot"

    CONFIGS_DIR="$EMP_TOPDIR/conf"
    SCRIPTS_DIR="$EMP_TOPDIR/scripts"
    ASSETS_DIR="$EMP_TOPDIR/netbootassets"
    TFTPROOT_DIR="$EMP_TOPDIR/tftproot"
    MAIN_CONFIG="$EMP_TOPDIR/conf/easy_multi_pxe.conf"

    WEBSERVER_USERNAME="www-data"

    APACHE_EMP_CONF_TEMPLATE="$CONFIGS_DIR/apache2_emp_inc.conf.template"
    APACHE_EMP_CONF_FINAL="$CONFIGS_DIR/apache2_emp_inc.conf"
    DNSMASQ_EMP_CONF_TEMPLATE="$CONFIGS_DIR/dnsmasq_emp_inc.conf.template"
    DNSMASQ_EMP_CONF_FINAL="$CONFIGS_DIR/dnsmasq_emp_inc.conf"
    NGINX_EMP_CONF_TEMPLATE="$CONFIGS_DIR/nginx_emp_inc.conf.template"
    NGINX_EMP_CONF_FINAL="$CONFIGS_DIR/nginx_emp_inc.conf"

elif [ "$EMP_OP" = "do_provisioning" ]
then
    echo "BAR"

    # Finally include the provisioning functions file
    
fi


