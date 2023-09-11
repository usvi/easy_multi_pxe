#!/bin/sh

EMP_OP="create_configs"
EMP_INC_COMMON="$(dirname "$(realpath "${0}")")/emp_inc_common.sh"
if [ ! -f "$EMP_INC_COMMON" ]; then echo "ERROR: No common include file $EMP_INC_COMMON"; exit 1; fi
. "$EMP_INC_COMMON"



echo ""
echo "Creating Easy Multi Pxe configs"
echo ""



# Webserver-related stuff.

# Webserver IP.
# Mandatory.
echo -n "Give webserver IP [$EMP_WEBSERVER_IP]: "
read TEMP_INPUT

if [ -z "$TEMP_INPUT" ]
then
    if [ -z "$EMP_WEBSERVER_IP" ]
    then
	echo "ERROR: No webserver IP given, exiting."
	exit 1
    fi
else
    EMP_WEBSERVER_IP="$TEMP_INPUT"
fi



# Webserver prefix.
# Mandatory.
# Take prefix from default as base.
if [ -z "$EMP_WEBSERVER_PREFIX" ]
then
    EMP_WEBSERVER_PREFIX="$EMP_WEBSERVER_PREFIX_DEFAULT"
fi

echo -n "Give webserver prefix [$EMP_WEBSERVER_PREFIX]: "
read TEMP_INPUT

if [ -z "$TEMP_INPUT" ]
then
    if [ -z "$EMP_WEBSERVER_PREFIX" ]
    then
	echo "ERROR: No webserver prefix given, exiting."

	exit 1
    fi
else
    EMP_WEBSERVER_PREFIX="$TEMP_INPUT"
fi



# Drivers base dir.
# Not always needed, so ask user.
# By default do not use:
TEMP_USE="N"

# But if we have it from old config, assume it is used:
if [ -n "$EMP_DRIVERS_BASE_DIR" ]
then
    TEMP_USE="Y"
fi

# But let user decide in the end:
echo -n "Use drivers directory Y/N? [$TEMP_USE]: "
read TEMP_INPUT

if [ -n "$TEMP_INPUT" ]
then
    if [ "$TEMP_INPUT" = "Y" -o "$TEMP_INPUT" = "y" ]
    then
	TEMP_USE="Y"
    else
	TEMP_USE="N"
    fi
fi

if [ "$TEMP_USE" = "Y" ]
then
    echo -n "Give drivers directory [$EMP_DRIVERS_BASE_DIR]: "
    read TEMP_INPUT

    if [ -z "$TEMP_INPUT" ]
    then
	if [ -z "$EMP_DRIVERS_BASE_DIR" ]
	then
	    echo "ERROR: No drivers directory given, exiting."

	    exit 1
	fi
    else
	EMP_DRIVERS_BASE_DIR="$TEMP_INPUT"
    fi
else
    EMP_DRIVERS_BASE_DIR=""
fi



# CIFS related stuff.

# CIFS/SMB Server IP.
# Mandatory.
echo -n "Give CIFS/SMB server IP [$EMP_CIFS_SERVER_IP]: "
read TEMP_INPUT

if [ -z "$TEMP_INPUT" ]
then
    if [ -z "$EMP_CIFS_SERVER_IP" ]
    then
	echo "ERROR: No CIFS/SMB server IP given, exiting."

	exit 1
    fi
else
    EMP_CIFS_SERVER_IP="$TEMP_INPUT"
fi



# CIFS/SMB share name.
# Take share name from default as base
if [ -z "$EMP_CIFS_SHARE_NAME" ]
then
    EMP_CIFS_SHARE_NAME="$EMP_CIFS_SHARE_NAME_DEFAULT"
fi

echo -n "Give CIFS/SMB share name [$EMP_CIFS_SHARE_NAME]: "
read TEMP_INPUT

if [ -z "$TEMP_INPUT" ]
then
    if [ -z "$EMP_CIFS_SHARE_NAME" ]
    then
	echo "ERROR: No CIFS/SMB share name given, exiting."

	exit 1
    fi
else
    EMP_CIFS_SHARE_NAME="$TEMP_INPUT"
fi



# CIFS/SMB user name.
# Not always needed, so ask user.
# By default do not use:
TEMP_USE="N"

# But if we have it from old config, assume it is used:
if [ -n "$EMP_CIFS_USER" ]
then
    TEMP_USE="Y"
fi

# But let user decide in the end:
echo -n "Use username for CIFS/SMB Y/N? [$TEMP_USE]: "
read TEMP_INPUT

if [ -n "$TEMP_INPUT" ]
then
    if [ "$TEMP_INPUT" = "Y" -o "$TEMP_INPUT" = "y" ]
    then
	TEMP_USE="Y"
    else
	TEMP_USE="N"
    fi
fi

if [ "$TEMP_USE" = "Y" ]
then
    echo -n "Give username for CIFS/SMB [$EMP_CIFS_USER]: "
    read TEMP_INPUT

    if [ -z "$TEMP_INPUT" ]
    then
	if [ -z "$EMP_CIFS_USER" ]
	then
	    echo "ERROR: No username for CIFS/SMB given, exiting."

	    exit 1
	fi
    else
	EMP_CIFS_USER="$TEMP_INPUT"
    fi
else
    EMP_CIFS_USER=""
fi



# CIFS/SMB password.
# Not always needed, so ask user.
# By default do not use:
TEMP_USE="N"

# But if we have it from old config, assume it is used:
if [ -n "$EMP_CIFS_PASSWD" ]
then
    TEMP_USE="Y"
fi

# But let user decide in the end:
echo -n "Use password for CIFS/SMB Y/N? [$TEMP_USE]: "
read TEMP_INPUT

if [ -n "$TEMP_INPUT" ]
then
    if [ "$TEMP_INPUT" = "Y" -o "$TEMP_INPUT" = "y" ]
    then
	TEMP_USE="Y"
    else
	TEMP_USE="N"
    fi
fi

if [ "$TEMP_USE" = "Y" ]
then
    # Special check that username given
    if [ -z "$EMP_CIFS_USER" ]
    then
	echo "ERROR: CIFS/SMB password requested but username not given."

	exit 1
    fi

    echo -n "Give password for CIFS/SMB [$EMP_CIFS_PASSWD]: "
    read TEMP_INPUT

    if [ -z "$TEMP_INPUT" ]
    then
	if [ -z "$EMP_CIFS_PASSWD" ]
	then
	    echo "ERROR: No password for CIFS/SMB given, exiting."

	    exit 1
	fi
    else
	EMP_CIFS_PASSWD="$TEMP_INPUT"
    fi
else
    EMP_CIFS_PASSWD=""
fi



# Finally write everything out

echo "# $EMP_MAIN_CONFIG" > "$EMP_MAIN_CONFIG"
chmod "$EMP_CONFIG_CHMOD_PERMS" "$EMP_MAIN_CONFIG"
chown ":$EMP_WEBSERVER_USERNAME" "$EMP_MAIN_CONFIG"
echo "# Easy Multi Pxe config file" >> "$EMP_MAIN_CONFIG"
echo "" >> "$EMP_MAIN_CONFIG"
echo "WEBSERVER_IP=$EMP_WEBSERVER_IP" >> "$EMP_MAIN_CONFIG"
echo "WEBSERVER_PREFIX=$EMP_WEBSERVER_PREFIX" >> "$EMP_MAIN_CONFIG"

if [ -n "$EMP_DRIVERS_BASE_DIR" ]
then
    echo "DRIVERS_BASE_DIR=$EMP_DRIVERS_BASE_DIR" >> "$EMP_MAIN_CONFIG"
fi

echo "CIFS_SERVER_IP=$EMP_CIFS_SERVER_IP" >> "$EMP_MAIN_CONFIG"
echo "CIFS_SHARE_NAME=$EMP_CIFS_SHARE_NAME" >> "$EMP_MAIN_CONFIG"

if [ -n "$EMP_CIFS_USER" ]
then
    echo "CIFS_USER=$EMP_CIFS_USER" >> "$EMP_MAIN_CONFIG"
fi

if [ -n "$EMP_CIFS_PASSWD" ]
then
    echo "CIFS_PASSWD=$EMP_CIFS_PASSWD" >> "$EMP_MAIN_CONFIG"
fi



echo ""
echo "Preparing to write config files."


# Try to figure out php fpm socket location
EMP_PHP_FPM_RUN_SOCK="/dev/null"
ls -1 /run/php/*.sock &> /dev/null
echo "starting"

if [ "$?" -eq 0 ]
then
    # Just pick the first one for now
    echo -n "Locating php-fpm ... "
    EMP_PHP_FPM_RUN_SOCK="`ls -1 /run/php/*.sock | head -n 1`"
fi
echo "ready"
exit 1

# Read the new config file again, just in case
emp_read_config "$EMP_MAIN_CONFIG"

echo -n "Writing $EMP_APACHE_CONF_FINAL ... " 
sed "s|{EMP_CONFIG_DIR}|$EMP_CONFIG_DIR|g;s|{EMP_WEBSERVER_PREFIX}|$EMP_WEBSERVER_PREFIX|g;s|{EMP_SCRIPTS_DIR}|$EMP_SCRIPTS_DIR|g;s|{EMP_ASSETS_ROOT_DIR}|$EMP_ASSETS_ROOT_DIR|g;s|{EMP_TFTPROOT_DIR}|$EMP_TFTPROOT_DIR|g;" "$EMP_APACHE_CONF_TEMPLATE" > "$EMP_APACHE_CONF_FINAL"
echo "done."


echo -n "Writing $EMP_DNSMASQ_CONF_FINAL ... " 
sed "s|{EMP_DNSMASQ_CONF_FILE}|$EMP_DNSMASQ_CONF_FINAL|g;s|{EMP_TFTPROOT_DIR}|$EMP_TFTPROOT_DIR|g;s|{EMP_WEBSERVER_IP}|$EMP_WEBSERVER_IP|g;s|{EMP_WEBSERVER_PREFIX}|$EMP_WEBSERVER_PREFIX|g;" "$EMP_DNSMASQ_CONF_TEMPLATE" > "$EMP_DNSMASQ_CONF_FINAL"
echo "done."


echo -n "Writing $EMP_NGINX_CONF_FINAL ... " 
sed "s|{EMP_CONFIG_DIR}|$EMP_CONFIG_DIR|g;s|{EMP_WEBSERVER_PREFIX}|$EMP_WEBSERVER_PREFIX|g;s|{EMP_SCRIPTS_DIR}|$EMP_SCRIPTS_DIR|g;s|{EMP_ASSETS_ROOT_DIR}|$EMP_ASSETS_ROOT_DIR|g;s|{EMP_TFTPROOT_DIR}|$EMP_TFTPROOT_DIR|g;s|{EMP_PHP_FPM_RUN_SOCK}|$EMP_PHP_FPM_RUN_SOCK|g;" "$EMP_NGINX_CONF_TEMPLATE" > "$EMP_NGINX_CONF_FINAL"
echo "done."
