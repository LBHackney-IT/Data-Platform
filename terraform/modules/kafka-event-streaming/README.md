## Local Development & Testing

Kafka takes a long time to create in AWS, specifically the MSK connectors. Due to this kafka is not deployed to dev environments by default. 
If you wish to test our kafka changes in a dev environment then please follow these steps:

1. In ```32-kafka-event-streaming.tf``` modify the count on line two so that it reads ```count       = local.is_live_environment ? 1 : 1```. Do not commit this change
2. Deploy terraform/core to your dev environment, this will deploy kafka but it will also deploy a test lambda for each kafka topic
3. Navigate in AWS to the Lambdas are
4. Search for ```{your-username}-kafka-test```
5. This lambda can be used to run a variety of operations against the Kafka cluster.

## Schema Registry UI
We haven't had chance to setup an UI for the schema registry in the environment yet, so I have instead been using the
docker image and port forwarding to it via the bastion. It's a little convoluted, but it just works once setup.

### Docker

```shell
docker pull landoop/schema-registry-ui
docker run --rm -p 8000:8000 \
           -e "SCHEMAREGISTRY_URL=http://localhost:8081" \
           landoop/schema-registry-ui
```

## Schema Registry
Schema name should be: `{topic}-value` for example `tenure_api-value`


## MSK Connect
Working Settings
```
connector.class=io.confluent.connect.s3.S3SinkConnector
s3.region=eu-west-2
flush.size=1
schema.compatibility=NONE
tasks.max=2
topics=tenure_api
s3.sse.kms.key.id=8c5aa61d-8dab-4127-9190-5dfabc20d84c
key.converter.schemas.enable=false
value.converter.schema.registry.url=http://10.120.30.78:8081
format.class=io.confluent.connect.s3.format.parquet.ParquetFormat
partitioner.class=io.confluent.connect.storage.partitioner.DefaultPartitioner
value.converter.schemas.enable=true
value.converter=io.confluent.connect.avro.AvroConverter
storage.class=io.confluent.connect.s3.storage.S3Storage
errors.log.enable=true
s3.bucket.name=dataplatform-joates-raw-zone
key.converter=org.apache.kafka.connect.storage.StringConverter
```