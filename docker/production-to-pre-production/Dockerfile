FROM alpine

RUN apk add --update --no-cache \
    bash \
    aws-cli \
    coreutils \
    && rm -rf /var/cache/apk/*

COPY ./sync-last-x-days.sh .

CMD ./sync-last-x-days.sh
