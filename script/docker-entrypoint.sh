#!/bin/sh

set -e

if [ "$1" = 'pgpool' ]; then

  configure-pgpool2

  sed -i "s:socket_dir = '.*':socket_dir = '/var/run/pgpool':g" /etc/pgpool2/pgpool.conf
  sed -i "s:pcp_socket_dir = '.*':pcp_socket_dir = '/var/run/pgpool':g" /etc/pgpool2/pgpool.conf

  su-exec ${SYS_USER} "$@"

fi

exec "$@"