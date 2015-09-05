FROM alpine:latest

RUN apk add --update-cache python py-pip ca-certificates tzdata \
    && pip install s3cmd \
    && rm -fR /etc/periodic \
    && rm -rf /var/cache/apk/*

COPY backup /usr/local/bin/
RUN chmod +x /usr/local/bin/backup

COPY s3cfg /root/.s3cfg
COPY entrypoint.sh /sbin/entrypoint.sh
RUN chmod +x /sbin/entrypoint.sh

CMD /sbin/entrypoint.sh
