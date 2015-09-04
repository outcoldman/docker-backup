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
backet on S3 and create an user in IAM with next policy (don't forget to
update backet locations)

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
    `${BACKUP_PREFIX}.$(date -uIseconds | sed 's/:/-/g').tar.gz`, for example
    `my_etc.2015-09-04T05-28-55UTC.tar.gz`. Default value is `backup`.
- `BACKUP_DEST_FOLDER` - if you want to keep backups locally you can change
    destination folder which is used to create backup archives. Default
    value is `/var/tmp`
- `BACKUP_DELETE_LOCAL_COPY` - if you want to keep backups in
    `BACKUP_DEST_FOLDER` set it to `true`. Default value is `true`.
- `BACKUP_FIND_OPTIONS` - this image is using `find` to select files you want
    to backup. See [man find](https://www.freebsd.org/cgi/man.cgi?query=find(1)&sektion=).
- `BACKUP_AWS_KEY` - AWS Key.
- `BACKUP_AWS_SECRET` - AWS Secret.
- `BACKUP_AWS_S3_PATH` - path to S3 backet, like `s3://your-backup-us-west-2`.
    Default value is empty, which means that archives will not be uploaded.

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
  ports:
    - '8000:8000'
  restart: always

splunkbackup:
  image: outcoldman/backup:latest
  environment:
    - BACKUP_PREFIX=splunk-etc
    - BACKUP_AWS_KEY=AWS_KEY
    - BACKUP_AWS_SECRET=AWS_SECRET
    - BACKUP_AWS_S3_PATH=s3://my-backup-backet
    - BACKUP_FIND_OPTIONS=/opt/splunk/etc \( -path "/opt/splunk/etc/apps/search/*" -a ! -path "/opt/splunk/etc/apps/search/default*" \) -o \( -path "/opt/splunk/etc/system/*" -a ! -path "/opt/splunk/etc/system/default*" \)
  volumes_from:
    - vsplunk
  restart: always
```
