FROM alpine

RUN apk add --update --no-cache \
    bash \
    aws-cli \
    coreutils \
    && rm -rf /var/cache/apk/*

COPY ./cleanup-past-x-days.sh .

CMD ./cleanup-past-x-days.sh
