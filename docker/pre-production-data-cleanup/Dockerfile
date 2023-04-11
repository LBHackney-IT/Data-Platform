FROM alpine

RUN apk add --update --no-cache \
    bash \
    aws-cli \
    coreutils \
    && rm -rf /var/cache/apk/*

COPY ./clean-up-past-x-days.sh .

RUN addgroup -S docker_users \
    && adduser -S docker_user -G docker_users

USER docker_user

CMD ./clean-up-past-x-days.sh
