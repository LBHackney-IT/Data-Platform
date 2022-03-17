FROM alpine

RUN apk add --update --no-cache \
                bash 
                # unzip \
                # mariadb-connector-c-dev \
                # mysql mysql-client

# Install AWS CLI
RUN apk add --no-cache \
        python3 \
        py3-pip \
    && rm -rf /var/cache/apk/*

COPY ./requirements.txt .
COPY ./backfilling.py .

RUN pip3 install --upgrade pip \
    && pip3 install -r requirements.txt

CMD ./sync-last-x-days.sh
