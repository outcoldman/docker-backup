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

##
## Setup email
##
#setting default vals
SMTP_ENABLED=${SMTP_ENABLED:-false}
#the server to send the mail to
SMTP_SERVER_HOST=${SMTP_SERVER_HOST:-"smtp.gmail.com"}
#the port to use on the SMTP_HOST
SMTP_SERVER_PORT=${SMTP_SERVER_PORT:-587}
#The domain from which mail seems to come. for user authentication.
SMTP_REWRITE_DOMAIN=${SMTP_REWRITE_DOMAIN:-"gmail.com"}
#Specifies whether the From header of an email, if any, may override the default domain. Defaults to true
SMTP_FROM_LINE_OVERRIDE=${SMTP_FROM_LINE_OVERRIDE:-true}
#Specifies whether ssmtp uses TLS to talk to the SMTP server. Defaults to true
SMTP_TLS=${SMTP_TLS:-true}
#Specifies whether ssmtp does a EHLO/STARTTLS before starting SSL negotiation. See RFC 2487. Defaults to true
SMTP_START_TLS=${SMTP_START_TLS:-true}

#no defaults set for:
# The person who gets all mail for userids < 1000.Set as empty to disable rewriting.
# SMTP_ADMIN_EMAIL
# SMTP_USERNAME
# SMTP_PASSWORD
#The full hostname. If not specified, the host is queried for its hostname
# SMTP_HOSTNAME


boolToYesNo() {
  [ -z "${1}" ] && echo "NO" && return;
  #do string comparison for boolean. Regular boolean check executes the var,
  #making it susceptible for injection
  [ "${1}" == "true" ] && echo "YES" && return;
  echo "NO" && return
}

if ${SMTP_ENABLED}; then
  echo "Configuring SMTP"

  # The mail server (where the mail is sent to), both port 465 or 587 should be acceptable
  # See also http://mail.google.com/support/bin/answer.py?answer=78799
  echo "mailhub=${SMTP_SERVER_HOST}:${SMTP_SERVER_PORT}" > /etc/ssmtp/ssmtp.conf
  echo "rewriteDomain=${SMTP_REWRITE_DOMAIN}" >> /etc/ssmtp/ssmtp.conf
  echo "hostname=${SMTP_HOSTNAME}" >> /etc/ssmtp/ssmtp.conf
  echo "root=${SMTP_ADMIN_EMAIL}" >> /etc/ssmtp/ssmtp.conf
  echo "UseTLS=$(boolToYesNo ${SMTP_TLS})" >> /etc/ssmtp/ssmtp.conf
  echo "UseSTARTTLS=$(boolToYesNo ${SMTP_START_TLS})" >> /etc/ssmtp/ssmtp.conf
  echo "FromLineOverride=$(boolToYesNo ${SMTP_FROM_LINE_OVERRIDE})" >> /etc/ssmtp/ssmtp.conf
  if [ -n "${SMTP_USERNAME}" ]; then
    echo "AuthUser=${SMTP_USERNAME}" >>  /etc/ssmtp/ssmtp.conf
    echo "AuthPass=${SMTP_PASSWORD}" >> /etc/ssmtp/ssmtp.conf
  fi
fi



# Every day at 2am
BACKUP_CRON_SCHEDULE=${BACKUP_CRON_SCHEDULE:-"0 2 * * *"}
if [ -n "${MAILTO_ON_SUCCESS}" ] || [ -n ${MAILTO_ON_FAIL} ]; then
  echo "${BACKUP_CRON_SCHEDULE} /usr/local/bin/backupAndEmail" > /etc/crontabs/root
else
  echo "${BACKUP_CRON_SCHEDULE} /usr/local/bin/backup" > /etc/crontabs/root
fi


# Starting cron
crond -f -d 0
