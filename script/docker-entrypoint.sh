#!/bin/bash

set -e

export PCP_PASSWORD_MD5=`pg_md5 ${PCP_PASSWORD}`

gucci /usr/share/pgpool2/pcp.conf.template > /etc/pcp.conf
gucci /usr/share/pgpool2/pgpool.conf.template > /etc/pgpool.conf
gucci /usr/share/pgpool2/pool_hba.conf.template > /etc/pool_hba.conf

/usr/bin/pg_md5 -m -f /etc/pgpool.conf -u ${PG_USERNAME} ${PG_PASSWORD}
# if [ "$1" = 'pgpool-server' ]; then
# 	exec pgpool "$@"
# fi

pgpool -f /etc/pgpool.conf -F /etc/pcp.conf -a /etc/pool_hba.conf
exec "$@"