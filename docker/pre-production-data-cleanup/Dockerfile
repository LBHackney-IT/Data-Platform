FROM alpine:3.19

RUN apk add --update --no-cache \
    bash \
    aws-cli \
    coreutils \
    && rm -rf /var/cache/apk/*

COPY ./cleanup-past-x-days.sh .

RUN addgroup -S docker_users \
    && adduser -S docker_user -G docker_users

USER docker_user

CMD ./cleanup-past-x-days.sh
