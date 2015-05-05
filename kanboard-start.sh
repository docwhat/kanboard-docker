#!/bin/bash

set -eu

# Force the files to be in /data
export KANBOARD_FILES_DIR=/data/files/

function info
{
  echo "INFO: $@" 1>&2
}

# Sets up links for databases.
if [ "${KANBOARD_DB_DRIVER}" = 'mysql' ]; then
  if [ -n "${DB_PORT_3306_TCP_ADDR}" ]; then
    KANBOARD_DB_HOSTNAME=${DB_PORT_3306_TCP_ADDR}
    KANBOARD_DB_PORT=${DB_PORT_3306_TCP_PORT}
  fi
elif [ "${KANBOARD_DB_DRIVER}" = 'postgres' ]; then
  if [ -n "${DB_PORT_5432_TCP_ADDR}" ]; then
    KANBOARD_DB_HOSTNAME=${DB_PORT_5432_TCP_ADDR}
    KANBOARD_DB_PORT=${DB_PORT_5432_TCP_PORT}
  fi
elif [ "${KANBOARD_DB_DRIVER}" = 'sqlite' ]; then
  export KANBOARD_DB_FILENAME=/data/db.sqlite
  touch "${KANBOARD_DB_FILENAME}"
fi

info "Setup data directory"
mkdir -p /data/files/
chown www-data:www-data -Rc /data /var/www/html/data
chmod u=rwX,g=rwX,o= -Rc /data /var/www/html/data

info "Configure Kanboard"
echo '*********************************'
/kanboard-configure.py | tee /var/www/html/config.php
echo '*********************************'
chown www-data:www-data -c /var/www/html/config.php
chmod 644 -c /var/www/html/config.php

info "Prepare apache for running"
export APACHE_CONFDIR=/etc/apache2
export APACHE_HOSTNAME=$HOSTNAME
source "${APACHE_CONFDIR}/envvars"

info "Starting Kanboard"
exec /usr/sbin/apache2 -DFOREGROUND

# EOF
