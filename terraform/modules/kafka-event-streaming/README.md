## Local Development & Testing

Kafka takes a long time to create in AWS, specifically the MSK connectors. Due to this kafka is not deployed to dev environments by default. 
If you wish to test kafka changes in a dev environment then please follow these steps:

1. In ```32-kafka-event-streaming.tf``` modify the count on line 2 so that it reads ```kafka_event_streaming_count = local.is_live_environment ? 1 : 1```. Do not commit this change
2. Deploy terraform/core to your dev environment, this will deploy kafka and the lambda for testing kafka
3. In the AWS console search for a lambda with the following name: ```{your-terraform-workspace-name}-kafka-test```
6. In the /lambdas/kafka-test/lambda-events folder you will find json files containing the correct lambda test event message structure to trigger operations against the kafka cluster
7. Take the contents of one of the files and paste it into the Event JSON window on the test tab of the lambda and then click test to run it
    1. list-all-topics:
        1. This is fairly straight forward, it will print out a list of topics currently in the cluster
    2. send-message-to-topic:
        1. This will fire a preconfigured message stored in /lambdas/kafka-test/topics-messages to the topic of your choice
        2. Once the lambda has completed successfully you should see the event has been processed by Kafka and that the data has appeared in the event-streaming folder in the raw zone

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