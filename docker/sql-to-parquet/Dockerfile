FROM alpine

RUN apk add --update --no-cache \
                bash \
                unzip \
                mariadb-connector-c-dev \
                mariadb-client

# Install AWS CLI
RUN apk add --no-cache \
        python3 \
        py3-pip
        
RUN python3 -m venv /venv
ENV PATH="/venv/bin:$PATH"

RUN pip3 install --upgrade pip \
    && pip3 install awscli boto3 \
    && rm -rf /var/cache/apk/*

COPY ./entrypoint.sh .
COPY ./delete_db_snapshots_in_db.py .

RUN chmod +x entrypoint.sh

CMD ./entrypoint.sh
