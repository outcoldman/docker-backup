FROM alpine:latest

RUN apk add --update-cache python py-pip ca-certificates \
    && pip install s3cmd \
    && rm -rf /var/cache/apk/*

ENV BACKUP_NAME backup
ENV BACKUP_FIND_OPTIONS /root

COPY backup /etc/periodic/daily/

RUN chmod +x /etc/periodic/daily/backup

COPY s3cfg /root/.s3cfg

CMD crond -f -d 0
