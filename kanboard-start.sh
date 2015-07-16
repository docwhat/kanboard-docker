#!/bin/bash

set -euo pipefail

trap _exit_trap EXIT
trap _err_trap ERR
_showed_traceback=f

function _exit_trap
{
  local _ec="$?"
  if [[ $_ec != 0 && "${_showed_traceback}" != t ]]; then
    traceback 1
  fi
}

function _err_trap
{
  local _ec="$?"
  local _cmd="${BASH_COMMAND:-unknown}"
  traceback 1
  _showed_traceback=t
  echo "ERROR: The command ${_cmd} exited with exit code ${_ec}." 1>&2
}

function traceback
{
  # Hide the traceback() call.
  local -i start=$(( ${1:-0} + 1 ))
  local -i end=${#BASH_SOURCE[@]}
  local -i i=0
  local -i j=0

  echo "Traceback (last called is first):" 1>&2
  for ((i=${start}; i < ${end}; i++)); do
    j=$(( $i - 1 ))
    local function="${FUNCNAME[$i]}"
    local file="${BASH_SOURCE[$i]}"
    local line="${BASH_LINENO[$j]}"
    echo "     ${function}() in ${file}:${line}" 1>&2
  done
}

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

export APACHE_HOSTNAME=${APACHE_HOSTNAME:-$HOSTNAME}

info "Configure Apache"
perl \
  -pi \
  -e 's/^\s*(ErrorLog|ServerName)/#-> $1/g' \
  /etc/apache2/apache2.conf
cat <<APACHE_EXTRA >> /etc/apache2/apache2.conf
ServerName \${APACHE_HOSTNAME}
LogLevel debug
ErrorLog "|/bin/cat"
APACHE_EXTRA

info "Configure PHP"
if [[ "${KANBOARD_DEBUG:-false}" = true ]]; then
  display=On
  error_reporting='E_ALL'
else
  display=Off
  error_reporting='E_ALL & ~E_DEPRECATED & ~E_STRICT'
fi

cat <<PHP_EXTRA > /etc/php5/apache2/conf.d/99-kanboard.ini
error_reporting = ${error_reporting}
error_log = stderr

html_errors = ${display}
display_errors = ${display}
display_startup_errors = ${display}
PHP_EXTRA


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
source "${APACHE_CONFDIR}/envvars"

info "Starting Kanboard"
exec /usr/sbin/apache2 -DFOREGROUND

# EOF
