FROM alpine

RUN apk add --update --no-cache \
                bash \
                mariadb-connector-c-dev \
                mysql mysql-client

COPY ./entrypoint.sh .

RUN chmod +x entrypoint.sh

CMD ./entrypoint.sh
