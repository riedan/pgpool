#!/usr/bin/env bash
set -e

export CONFIG_FILE='/etc/pgpool2/pgpool.conf'
export PCP_FILE='/etc/pgpool2/pcp.conf'
export HBA_FILE='/etc/pgpool2/pool_hba.conf'
export POOL_PASSWD_FILE='/etc/pgpool2/pool_passwd'
export PCPPASSFILE='/etc/pgpool2/.pcppass'




echo '>>> TURNING PGPOOL...'
/usr/local/bin/pgpool/pgpool_setup.sh


chown ${SYS_USER}:${SYS_GROUP} -R /etc/pgpool2 /var/run/pgpool /var/log/pgpool /var/run/postgresql /var/log/postgresql /usr/share/pgpool2

echo '>>> STARTING PGPOOL...'
su-exec ${SYS_USER} /usr/local/bin/pgpool/pgpool_start.sh