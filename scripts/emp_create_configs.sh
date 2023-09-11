#!/bin/sh

EMP_OP="create_configs"
EMP_INC_COMMON="$(dirname "$(realpath "${0}")")/emp_inc_common.sh"
if [ ! -f "$EMP_INC_COMMON" ]; then echo "Error: No common include file $EMP_INC_COMMON"; exit 1; fi
. "$EMP_INC_COMMON"


# Take old config as base if existing
echo "INCLUDING main config $MAIN_CONFIG"

if [ -f "$MAIN_CONFIG" ]
then
    . "$MAIN_CONFIG"
fi

echo ""
echo "Creating Easy Multi Pxe configs"
echo ""



# Webserver-related stuff.

# Webserver IP.
# Mandatory.
echo -n "Give webserver IP [$WEBSERVER_IP]: "
read INPUT

if [ -z "$INPUT" ]
then
    if [ -z "$WEBSERVER_IP" ]
    then
	echo "Error: No webserver IP given, exiting."
	exit 1
    fi
else
    WEBSERVER_IP="$INPUT"
fi



# Webserver prefix.
# Mandatory.
# Take prefix from default as base.
if [ -z "$WEBSERVER_PREFIX" ]
then
    WEBSERVER_PREFIX="$WEBSERVER_PREFIX_DEFAULT"
fi

echo -n "Give webserver prefix [$WEBSERVER_PREFIX]: "
read INPUT

if [ -z "$INPUT" ]
then
    if [ -z "$WEBSERVER_PREFIX" ]
    then
	echo "Error: No webserver prefix given, exiting."
	exit 1
    fi
else
    WEBSERVER_PREFIX="$INPUT"
fi



# Drivers base dir.
# Not always needed, so ask user.
# By default do not use:
USE="N"

# But if we have it from old config, assume it is used:
if [ -n "$DRIVERS_BASE_DIR" ]
then
    USE="Y"
fi

# But let user decide in the end:
echo -n "Use drivers directory Y/N? [$USE]: "
read INPUT

if [ -n "$INPUT" ]
then
    if [ "$INPUT" = "Y" ]
    then
	USE="Y"
    else
	USE="N"
    fi
fi


if [ "$USE" = "Y" ]
then
    echo -n "Give drivers directory [$DRIVERS_BASE_DIR]: "
    read INPUT

    if [ -z "$INPUT" ]
    then
	if [ -z "$DRIVERS_BASE_DIR" ]
	then
	    echo "Error: No drivers directory given, exiting."
	    exit 1
	fi
    else
	DRIVERS_BASE_DIR="$INPUT"
    fi
else
    DRIVERS_BASE_DIR=""
fi



# CIFS related stuff.

# CIFS/SMB Server IP.
# Mandatory.
echo -n "Give CIFS/SMB server IP [$CIFS_SERVER_IP]: "
read INPUT

if [ -z "$INPUT" ]
then
    if [ -z "$CIFS_SERVER_IP" ]
    then
	echo "Error: No CIFS/SMB server IP given, exiting."
	exit 1
    fi
else
    CIFS_SERVER_IP="$INPUT"
fi



# CIFS/SMB share name.
# Take share name from default as base
if [ -z "$CIFS_SHARE_NAME" ]
then
    CIFS_SHARE_NAME="$CIFS_SHARE_NAME_DEFAULT"
fi

echo -n "Give CIFS/SMB share name [$CIFS_SHARE_NAME]: "
read INPUT

if [ -z "$INPUT" ]
then
    if [ -z "$CIFS_SHARE_NAME" ]
    then
	echo "Error: No CIFS/SMB share name given, exiting."
	exit 1
    fi
else
    CIFS_SHARE_NAME="$INPUT"
fi



# CIFS/SMB user name.
# Not always needed, so ask user.
# By default do not use:
USE="N"

# But if we have it from old config, assume it is used:
if [ -n "$CIFS_USER" ]
then
    USE="Y"
fi

# But let user decide in the end:
echo -n "Use username for CIFS/SMB Y/N? [$USE]: "
read INPUT

if [ -n "$INPUT" ]
then
    if [ "$INPUT" = "Y" ]
    then
	USE="Y"
    else
	USE="N"
    fi
fi

if [ "$USE" = "Y" ]
then
    echo -n "Give username for CIFS/SMB [$CIFS_USER]: "
    read INPUT

    if [ -z "$INPUT" ]
    then
	if [ -z "$CIFS_USER" ]
	then
	    echo "Error: No username for CIFS/SMB given, exiting."
	    exit 1
	fi
    else
	CIFS_USER="$INPUT"
    fi
else
    CIFS_USER=""
fi



# CIFS/SMB password.
# Not always needed, so ask user.
# By default do not use:
USE="N"

# But if we have it from old config, assume it is used:
if [ -n "$CIFS_PASSWD" ]
then
    USE="Y"
fi

# But let user decide in the end:
echo -n "Use password for CIFS/SMB Y/N? [$USE]: "
read INPUT

if [ -n "$INPUT" ]
then
    if [ "$INPUT" = "Y" ]
    then
	USE="Y"
    else
	USE="N"
    fi
fi


if [ "$USE" = "Y" ]
then
    # Special check that username given
    if [ -z "$CIFS_USER" ]
    then
	echo "Error: CIFS/SMB password requested but username not given."
	exit 1
    fi

    echo -n "Give password for CIFS/SMB [$CIFS_PASSWD]: "
    read INPUT

    if [ -z "$INPUT" ]
    then
	if [ -z "$CIFS_PASSWD" ]
	then
	    echo "Error: No password for CIFS/SMB given, exiting."
	    exit 1
	fi
    else
	CIFS_PASSWD="$INPUT"
    fi
else
    CIFS_PASSWD=""
fi



# And write everything out

echo "# $MAIN_CONFIG" > "$MAIN_CONFIG"
chmod ug=r "$MAIN_CONFIG"
chown ":$WEBSERVER_USERNAME" "$MAIN_CONFIG"
echo "# Easy Multi Pxe config file" >> "$MAIN_CONFIG"
echo "" >> "$MAIN_CONFIG"
echo "WEBSERVER_IP=\"$WEBSERVER_IP\"" >> "$MAIN_CONFIG"
echo "WEBSERVER_PREFIX=\"$WEBSERVER_PREFIX\"" >> "$MAIN_CONFIG"

if [ -n "$DRIVERS_BASE_DIR" ]
then
    echo "DRIVERS_BASE_DIR=\"$DRIVERS_BASE_DIR\"" >> "$MAIN_CONFIG"
fi

echo "CIFS_SERVER_IP=\"$CIFS_SERVER_IP\"" >> "$MAIN_CONFIG"
echo "CIFS_SHARE_NAME=\"$CIFS_SHARE_NAME\"" >> "$MAIN_CONFIG"

if [ -n "$CIFS_USER" ]
then
    echo "CIFS_USER=\"$CIFS_USER\"" >> "$MAIN_CONFIG"
fi

if [ -n "$CIFS_PASSWD" ]
then
    echo "CIFS_PASSWD=\"$CIFS_PASSWD\"" >> "$MAIN_CONFIG"
fi



echo ""
echo "Preparing to Write config files."


# Try to figure out php fpm socket location
PHP_FPM_RUN_SOCK="/dev/null"
ls -1 /run/php/*.sock &> /dev/null

if [ "$?" -eq 0 ]
then
    # Just pick the first one for now
    echo -n "Locating php-fpm ... "
    PHP_FPM_RUN_SOCK="`ls -1 /run/php/*.sock | head -n 1`"
fi



# Include the new config file, just in case
. "$MAIN_CONFIG"

echo -n "Writing $APACHE_EMP_CONF_FINAL ... " 
sed "s|{EMP_CONFIG_DIR}|$CONFIGS_DIR|g;s|{EMP_WEBSERVER_PREFIX}|$WEBSERVER_PREFIX|g;s|{EMP_SCRIPTS_DIR}|$SCRIPTS_DIR|g;s|{EMP_ASSETS_DIR}|$EMP_ASSETS_ROOT_DIR|g;s|{EMP_TFTPROOT_DIR}|$TFTPROOT_DIR|g;" "$APACHE_EMP_CONF_TEMPLATE" > "$APACHE_EMP_CONF_FINAL"
echo "done."


echo -n "Writing $DNSMASQ_EMP_CONF_FINAL ... " 
sed "s|{EMP_DNSMASQ_CONF_FILE}|$DNSMASQ_EMP_CONF_FINAL|g;s|{EMP_TFTPROOT_DIR}|$TFTPROOT_DIR|g;s|{EMP_WEBSERVER_IP}|$WEBSERVER_IP|g;s|{EMP_WEBSERVER_PREFIX}|$WEBSERVER_PREFIX|g;" "$DNSMASQ_EMP_CONF_TEMPLATE" > "$DNSMASQ_EMP_CONF_FINAL"
echo "done."


echo -n "Writing $NGINX_EMP_CONF_FINAL ... " 
sed "s|{EMP_CONFIG_DIR}|$CONFIGS_DIR|g;s|{EMP_WEBSERVER_PREFIX}|$WEBSERVER_PREFIX|g;s|{EMP_SCRIPTS_DIR}|$SCRIPTS_DIR|g;s|{EMP_ASSETS_DIR}|$EMP_ASSETS_ROOT_DIR|g;s|{EMP_TFTPROOT_DIR}|$TFTPROOT_DIR|g;s|{EMP_PHP_FPM_RUN_SOCK}|$PHP_FPM_RUN_SOCK|g;" "$NGINX_EMP_CONF_TEMPLATE" > "$NGINX_EMP_CONF_FINAL"
echo "done."
