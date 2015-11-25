FROM mhart/alpine-node:latest

# Could remove bash to trim .5 MB
RUN apk add --update bash && rm -rf /var/cache/apk/*

# Approx 2MB
RUN npm install -g s3-cli

COPY backup /usr/local/bin/
RUN chmod +x /usr/local/bin/backup

COPY s3cfg /root/.s3cfg
COPY entrypoint.sh /sbin/entrypoint.sh
RUN chmod +x /sbin/entrypoint.sh

CMD /sbin/entrypoint.sh 
