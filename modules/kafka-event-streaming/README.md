# Help File
## Cli Help

### Installing the Kafka CLI tools
```shell
sudo yum install java
wget https://dlcdn.apache.org/kafka/3.1.0/kafka_2.13-3.1.0.tgz
tar -xzf kafka_2.13-3.1.0.tgz
cd kafka_2.13-3.1.0
```

### Setting up the properties
When using the CLI tools, you need to configure them to use SSL based connections. To do this we create a properties
file that we reference when ever we make a call. Create the following file:

_server.properties_
```
security.protocol=SSL
```

### CLI Examples

#### AVRO Producer
This only works if you have specifically installed the AVRO package. It is NOT included in the package listed above.
```shell
./bin/kafka-avro-console-producer --broker-list localhost:9092 --topic s3_topic --property value.schema='{"type":"record","name":"myrecord","fields":[{"name":"f1","type":"string"}]}'
```

#### Consume a Topic
```shell
bin/kafka-console-consumer.sh --topic {topic} --consumer.config server.properties --from-beginning --bootstrap-server {bootstap-server-list}
```

#### List Topics
```shell
bin/kafka-topics.sh --command-config server.properties --list --bootstrap-server {bootstap-server-list}
```

#### Create Topic
```shell
bin/kafka-topics.sh --command-config server.properties --create --topic {topic} --replication-factor 2 --partitions 1 --bootstrap-server {bootstap-server-list}
```

## Schema Registry UI
We haven't had chance to setup an UI for the schema registry in the environment yet, so I have instead been using the
docker image and port forwarding to it via the bastian. It's a little convoluted, but it just works once setup.

### Docker

```shell
docker pull landoop/schema-registry-ui
```

### Bastian Tunnel

#### Setup
If your bastian has been re-deployed or is new, you will need to setup a few bits to allow the SSH tunneling to work.
The guide presume you are using `aws ssm start-session --target i-*` to connect to the bastion
```shell
sudo su ec2-user
cd ~
ssh-keygen
```

`Enter file in which to save the key (/home/ec2-user/.ssh/id_rsa):` Just press enter

`Enter passphrase (empty for no passphrase):` Just press enter

`Enter same passphrase again:` You've guessed it, just press enter

```shell
cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
```

#### Start the Tunnel

```shell
ssh -i .ssh/id_rsa -L 8081:{schema_repository_server_ip}:8081 ec2-user@localhost -v
```

### Local Tunnel

```shell
aws-vault exec hackney-dataplatform-{environment} -- aws ssm start-session --target {bastion_id} --document-name AWS-StartPortForwardingSession --parameters '{"portNumber":["8081"],"localPortNumber":["8081"]}'
```


## MSK Connect

```
connector.class=io.confluent.connect.s3.S3SinkConnector
flush.size=1
format.class=io.confluent.connect.s3.format.parquet.ParquetFormat
partitioner.class=io.confluent.connect.storage.partitioner.DefaultPartitioner
s3.bucket.name=dataplatform-joates-raw-zone
s3.region=eu-west-2
s3.sse.kms.key.id=8c5aa61d-8dab-4127-9190-5dfabc20d84c
schema.compatibility=BACKWARD
storage.class=io.confluent.connect.s3.storage.S3Storage
tasks.max=2
topics=testing
key.converter=org.apache.kafka.connect.storage.StringConverter
value.converter=io.confluent.connect.avro.AvroConverter
value.converter.schema.registry.url=http://10.120.30.15:8081
```





Current Settings
```
connector.class=io.confluent.connect.s3.S3SinkConnector
s3.region=eu-west-2
flush.size=1
schema.compatibility=NONE
tasks.max=2
topics=mtfh-reporting-data-listener
s3.part.size=5242880
s3.sse.kms.key.id=8c5aa61d-8dab-4127-9190-5dfabc20d84c
s3.compression.type=gzip
partitioner.class=io.confluent.connect.storage.partitioner.DefaultPartitioner
storage.class=io.confluent.connect.s3.storage.S3Storage
errors.log.enable=true
s3.bucket.name=dataplatform-joates-raw-zone
```

AWS Example:
```
connector.class=io.confluent.connect.s3.S3SinkConnector,
s3.region=us-east-1
format.class=io.confluent.connect.s3.format.json.JsonFormat
flush.size=1
schema.compatibility=NONE
topics=my-test-topic
tasks.max=2
partitioner.class=io.confluent.connect.storage.partitioner.DefaultPartitioner
storage.class=io.confluent.connect.s3.storage.S3Storage
s3.bucket.name=my-test-bucket
```

This works! With strings
```
connector.class=io.confluent.connect.s3.S3SinkConnector
s3.region=eu-west-2
flush.size=1
schema.compatibility=NONE
topics=tenure_api_test
tasks.max=2
s3.sse.kms.key.id=8c5aa61d-8dab-4127-9190-5dfabc20d84c
format.class=io.confluent.connect.s3.format.bytearray.ByteArrayFormat
partitioner.class=io.confluent.connect.storage.partitioner.DefaultPartitioner
value.converter=org.apache.kafka.connect.converters.ByteArrayConverter
storage.class=io.confluent.connect.s3.storage.S3Storage
errors.log.enable=true
key.converter=org.apache.kafka.connect.converters.ByteArrayConverter
s3.bucket.name=dataplatform-joates-raw-zone
```

```
connector.class=io.confluent.connect.s3.S3SinkConnector
s3.region=eu-west-2
flush.size=1
schema.compatibility=NONE
topics=tenure_api_test
tasks.max=2
s3.sse.kms.key.id=8c5aa61d-8dab-4127-9190-5dfabc20d84c
format.class=io.confluent.connect.s3.format.bytearray.ByteArrayFormat
partitioner.class=io.confluent.connect.storage.partitioner.DefaultPartitioner
storage.class=io.confluent.connect.s3.storage.S3Storage
errors.log.enable=true
s3.bucket.name=dataplatform-joates-raw-zone
key.converter=org.apache.kafka.connect.storage.StringConverter
key.converter.schemas.enable=false
value.converter=io.confluent.connect.avro.AvroConverter
value.converter.schemas.enable=true
value.converter.schema.registry.url=http://10.120.30.15:8081
value.converter.enhanced.avro.schema.support=true
```

Test15
```
connector.class=io.confluent.connect.s3.S3SinkConnector
tasks.max=2
topics=tenure_api_test
s3.region=eu-west-2
s3.bucket.name=dataplatform-joates-raw-zone
s3.sse.kms.key.id=8c5aa61d-8dab-4127-9190-5dfabc20d84c
flush.size=1
storage.class=io.confluent.connect.s3.storage.S3Storage
format.class=io.confluent.connect.s3.format.json.JsonFormat
schema.generator.class=io.confluent.connect.storage.hive.schema.DefaultSchemaGenerator
partitioner.class=io.confluent.connect.storage.partitioner.DefaultPartitioner
schema.compatibility=NONE
key.converter=org.apache.kafka.connect.storage.StringConverter
key.converter.schemas.enable=false
value.converter=io.confluent.connect.avro.AvroConverter
value.converter.schema.registry.url=http://10.120.30.15:8081
value.converter.schemas.enable=true
errors.log.enable=true
```

```
connector.class=io.confluent.connect.s3.S3SinkConnector
s3.bucket.name=chris-test-data
s3.region=us-west-2
topics-dir=parquet-demo
flush.size=3
rotate.schedule.interval.ms=20000
auto.register.schemas=false
timezone=UTC
parquet.codec=snappy
storage.class=io.confluent.connect.s3.storage.S3Storage
format.class=io.confluent.connect.s3.format.parquet.ParquetFormat
schema.generator.class=io.confluent.connect.storage.hive.schema.DefaultSchemaGenerator
partitioner.class=io.confluent.connect.storage.partitioner.DailyPartitioner
locale=en-US
key.converter.schemas.enable=false
key.converter=org.apache.kafka.connect.storage.StringConverter
value.converter.schemas.enable=true
value.converter.schema.registry.url=http://localhost:8081
value.converter=io.confluent.connect.avro.AvroConverter
tasks.max=1
name=test-s3-ngap-sink
topics=CDS_NGAP_SENDS
```

```
connector.class=io.confluent.connect.s3.S3SinkConnector
flush.size=1
schema.compatibility=FULL
tasks.max=2
topics=testing
format.class=io.confluent.connect.s3.format.parquet.ParquetFormat
partitioner.class=io.confluent.connect.storage.partitioner.DefaultPartitioner
storage.class=io.confluent.connect.s3.storage.S3Storage
s3.bucket.name=dataplatform-joates-landing-zone
s3.region=eu-west-2
s3.sse.kms.key.id=8c5aa61d-8dab-4127-9190-5dfabc20d84c
topics.dir=testing
key.converter=com.amazonaws.services.schemaregistry.kafkaconnect.AWSKafkaAvroConverter
value.converter=com.amazonaws.services.schemaregistry.kafkaconnect.AWSKafkaAvroConverter
key.converter.region=eu-west-2
value.converter.region=eu-west-2
key.converter.schemaAutoRegistrationEnabled=true
value.converter.schemaAutoRegistrationEnabled=true
key.converter.avroRecordType=GENERIC_RECORD
value.converter.avroRecordType=GENERIC_RECORD
key.converter.schemaName=testing-key
value.converter.schemaName=testing-value
key.converter.registry.name=joates-schema-registry
value.converter.registry.name=joates-schema-registry
```

Test 31
```
connector.class=io.confluent.connect.s3.S3SinkConnector
tasks.max=2
topics=tenure_api_test
s3.region=eu-west-2
s3.bucket.name=dataplatform-joates-raw-zone
s3.sse.kms.key.id=8c5aa61d-8dab-4127-9190-5dfabc20d84c
flush.size=1
storage.class=io.confluent.connect.s3.storage.S3Storage
format.class=io.confluent.connect.s3.format.parquet.ParquetFormat
partitioner.class=io.confluent.connect.storage.partitioner.DefaultPartitioner
schema.compatibility=NONE
key.converter=org.apache.kafka.connect.storage.StringConverter
key.converter.schemas.enable=false
value.converter=io.confluent.connect.avro.AvroConverter
value.converter.schema.registry.url=http://10.120.30.15:8081
value.converter.schemas.enable=true
errors.log.enable=true
```