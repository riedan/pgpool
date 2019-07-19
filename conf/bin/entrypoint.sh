#!/usr/bin/env bash
set -e

export CONFIG_FILE='/etc/pgpoo2/pgpool.conf'
export PCP_FILE='/etc/pgpoo2/pcp.conf'
export HBA_FILE='/etc/pgpoo2/pool_hba.conf'
export POOL_PASSWD_FILE='/etc/pgpoo2/pool_passwd'
export PCPPASSFILE='/etc/pgpoo2/.pcppass'




echo '>>> TURNING PGPOOL...'
/usr/local/bin/pgpool/pgpool_setup.sh


chown ${SYS_USER}:${SYS_GROUP} -R /etc/pgpoo2 /var/run/pgpool /var/log/pgpool /var/run/postgresql /var/log/postgresql /usr/share/pgpoo2

echo '>>> STARTING PGPOOL...'
su-exec ${SYS_USER} /usr/local/bin/pgpool/pgpool_start.sh