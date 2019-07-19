#!/usr/bin/env bash
set -e

export CONFIG_FILE='/usr/local/etc/pgpool.conf'
export PCP_FILE='/usr/local/etc/pcp.conf'
export HBA_FILE='/usr/local/etc/pool_hba.conf'
export POOL_PASSWD_FILE='/usr/local/etc/pool_passwd'
export PCPPASSFILE='/usr/local/etc/.pcppass'



echo '>>> TURNING PGPOOL...'
/usr/local/bin/pgpool/pgpool_setup.sh

echo '>>> STARTING PGPOOL...'
su-exec ${SYS_USER} /usr/local/bin/pgpool/pgpool_start.sh