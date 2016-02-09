# Table of Contents

- [Supported tags](#supported-tags)
- [Introduction](#introduction)
    - [Version](#version)
- [Installation](#installation)
- [Quick Start](#quick-start)
- [Configuration](#configuration)

## Supported tags

- `latest`

## Introduction

Dockerfile to build an image which allows to create backup archives on daily
basic. This image is based on [Alpine Linux](http://www.alpinelinux.org) and
[s3cmd](http://s3tools.org/s3cmd) tool. You can use this image to create
backup archives and store them on local folder or upload to S3.

## Installation

Pull the image from the [docker registry](https://registry.hub.docker.com/u/outcoldman/backup/).
This is the recommended method of installation as it is easier to update image.
These builds are performed by the **Docker Trusted Build** service.

```bash
docker pull outcoldman/backup:latest
```

Alternately you can build the image locally.

```bash
git clone https://github.com/outcoldman/docker-backup.git
cd docker-backup
docker build --tag="$USER/backup" .
```

## Quick start

At first if you want to upload backups to AWS S3 you need to create new
bucket on S3 and create an user in IAM with next policy (don't forget to
update bucket locations)

```xml
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "Stmt1412062044000",
            "Effect": "Allow",
            "Action": [
                "s3:PutObject",
                "s3:PutObjectAcl"
            ],
            "Resource": [
                "arn:aws:s3:::your-backup-us-west-2/*"
            ]
        },
        {
            "Sid": "Stmt1412062097000",
            "Effect": "Allow",
            "Action": [
                "s3:GetBucketLocation",
                "s3:ListAllMyBuckets"
            ],
            "Resource": [
                "*"
            ]
        },
        {
            "Sid": "Stmt1412062128000",
            "Effect": "Allow",
            "Action": [
                "s3:ListBucket"
            ],
            "Resource": [
                "arn:aws:s3:::your-backup-us-west-2"
            ]
        }
    ]
}
```

> NOTE: I'm not a AWS expert, so if you think that it is possible to give less
> permissions - please let me know.

```bash
docker run -d \
    -e "BACKUP_FIND_OPTIONS=/etc/" \
    -e "BACKUP_PREFIX=my_etc" \
    -e "BACKUP_AWS_KEY=AWS_KEY" \
    -e "BACKUP_AWS_SECRET=AWS_SECRET" \
    -e "BACKUP_AWS_S3_PATH=s3://your-backup-us-west-2" \
    outcoldman/backup:latest
```

## Configuration

- `BACKUP_PREFIX` - prefix for the backup archives in format
    `${BACKUP_PREFIX}.$(date -Iseconds | sed 's/:/-/g').tar.gz`, for example
    `my_etc.2015-09-04T05-28-55+0000.tar.gz`. Default value is `backup`.
- `BACKUP_DEST_FOLDER` - if you want to keep backups locally you can change
    destination folder which is used to create backup archives. Default
    value is `/var/tmp`
- `BACKUP_DELETE_LOCAL_COPY` - if you want to keep backups in
    `BACKUP_DEST_FOLDER` set it to `true`. Default value is `true`.
- `BACKUP_FIND_OPTIONS` - this image is using `find` to select files you want
    to backup. See [man find](https://www.freebsd.org/cgi/man.cgi?query=find(1)&sektion=).
- `BACKUP_AWS_KEY` - AWS Key.
- `BACKUP_AWS_SECRET` - AWS Secret.
- `BACKUP_AWS_S3_PATH` - path to S3 bucket, like `s3://your-backup-us-west-2`.
    Default value is empty, which means that archives will not be uploaded.
- `BACKUP_TIMEZONE` - change timezone from UTC to
    [tz database](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones),
    for example `America/Los_Angeles`. Defaults to empty.
- `BACKUP_CRON_SCHEDULE` - specify when and how often you want to run backup
    script. Defaults to `0 2 * * *` (every day at 2am).

To enable email notifications, use the following settings:

 - `SMTP_ENABLED` - Enable sending via SMTP. Defaults to `false`
 - `SMTP_SERVER_HOST` - The server to send the mail to. Defaults to `smtp.gmail.com`
 - `SMTP_SERVER_PORT` - The port to use on the `SMTP_SERVER_HOST`. Defaults to `587`
 - `SMTP_REWRITE_DOMAIN` - The domain from which this email seems to come, used for user authentication. Defaults to `gmail.com`
 - `SMTP_HOSTNAME` - The full hostname. If not specified, the host is queried for its hostname
 - `SMTP_TLS` - Specifies whether SSMTP uses TLS to talke to the SMTP server. Defaults to `true`
 - `SMTP_START_TLS` - Specifies wheter SSMTP does a `EHLO/STARTTLS` before stating SSL negotiation. Defaults to `true`
 - `SMTP_USERNAME` - Username to authenticate with. Unset by default.
 - `SMTP_PASSWORD` - Password to authenticate with. Unset by default
 - `MAILTO_ON_SUCCESS` - Email address to mail on backup success. Leave blank (default) to disable emails on success.
 - `MAILTO_ON_FAIL` - Email address to mail on backup failure. Leave blank (default) to disable emails on failure.
 - `MAIL_FROM` - The email address that notifications are send from. Defaults to `docker-backup@example.com`
 - `MAIL_FROM_NAME` - The name of the email address. Defaults to `docker-backup`
 - `MAIL_SUBJECT_HEADER` - The header to prepend to the notification email subject. Defaults to the machine hostname


## Examples

### Backing up Splunk `etc` folder

My `docker-compose.yml` part for backing up `Splunk Light` settings, including
system no default settings and search non default settings

```
vsplunk:
  image: busybox
  volumes:
    - /opt/splunk/etc
    - /opt/splunk/var

splunk:
  image: outcoldman/splunk:latest
  volumes_from:
    - vsplunk
  restart: always

splunkbackup:
  image: outcoldman/backup:latest
  environment:
    - BACKUP_PREFIX=splunk-etc
    - BACKUP_AWS_KEY=AWS_KEY
    - BACKUP_AWS_SECRET=AWS_SECRET
    - BACKUP_AWS_S3_PATH=s3://my-backup-bucket
    - BACKUP_FIND_OPTIONS=/opt/splunk/etc \( -path "/opt/splunk/etc/apps/search/*" -a ! -path "/opt/splunk/etc/apps/search/default*" \) -o \( -path "/opt/splunk/etc/system/*" -a ! -path "/opt/splunk/etc/system/default*" \)
  volumes_from:
    - vsplunk
  restart: always
```

### Backing up Jenkins

```
vdata:
  image: busybox
  volumes:
    - /var/jenkins_home
  command: chown -R 1000:1000 /var/jenkins_home

jenkins:
  build: jenkins:latest
  volumes_from:
    - vdata
  restart: always

backup:
  image: outcoldman/backup:latest
  environment:
    - BACKUP_PREFIX=jenkins
    - BACKUP_AWS_KEY=AWS_KEY
    - BACKUP_AWS_SECRET=AWS_SECRET
    - BACKUP_AWS_S3_PATH=s3://my-backup-bucket
    - BACKUP_FIND_OPTIONS=/var/jenkins_home/ -path "/var/jenkins_home/.ssh/*" -o -path "/var/jenkins_home/plugins/*.jpi" -o -path "/var/jenkins_home/users/*" -o -path "/var/jenkins_home/secrets/*" -o -path "/var/jenkins_home/jobs/*" -o -regex "/var/jenkins_home/[^/]*.xml" -o -regex "/var/jenkins_home/secret.[^/]*"
  volumes_from:
    - vdata
  restart: always
```
