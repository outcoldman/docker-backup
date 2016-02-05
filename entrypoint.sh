#!/bin/sh

set +e
echoerr() { echo "$@" 1>&2; }

#validate config first
[ -z ${BACKUP_FIND_OPTIONS} ] && echoerr "BACKUP_FIND_OPTIONS are required" && exit 1;
[ -z ${BACKUP_AWS_KEY} ] && echoerr "BACKUP_AWS_KEY is required" && exit 1;
[ -z ${BACKUP_AWS_SECRET} ] && echoerr "BACKUP_AWS_SECRET is required" && exit 1;
[ -z ${BACKUP_AWS_S3_PATH} ] && echoerr "BACKUP_AWS_S3_PATH is required" && exit 1;

if [[ ${BACKUP_TIMEZONE} ]]; then
  # See http://wiki.alpinelinux.org/wiki/Setting_the_timezone
  cp /usr/share/zoneinfo/${BACKUP_TIMEZONE} /etc/localtime
  echo "${BACKUP_TIMEZONE}" >  /etc/timezone
fi

# Every day at 2am
BACKUP_CRON_SCHEDULE=${BACKUP_CRON_SCHEDULE:-"0 2 * * *"}

echo "${BACKUP_CRON_SCHEDULE} /usr/local/bin/backup" > /etc/crontabs/root

# Starting cron
crond -f -d 0
