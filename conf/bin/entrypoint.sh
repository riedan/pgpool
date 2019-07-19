#!/usr/bin/env bash
set -e

export CONFIG_FILE='/etc/pgpoo2/pgpool.conf'
export PCP_FILE='/etc/pgpoo2/pcp.conf'
export HBA_FILE='/etc/pgpoo2/pool_hba.conf'
export POOL_PASSWD_FILE='/etc/pgpoo2/pool_passwd'
export PCPPASSFILE='/etc/pgpoo2/.pcppass'



echo '>>> TURNING PGPOOL...'
/usr/local/bin/pgpool/pgpool_setup.sh

echo '>>> STARTING PGPOOL...'
su-exec ${SYS_USER} /usr/local/bin/pgpool/pgpool_start.sh