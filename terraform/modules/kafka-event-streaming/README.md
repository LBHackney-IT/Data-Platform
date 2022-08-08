# Help File

## Local Developement

Kafka takes a long time to create in AWS, specifically the MSK connectors. Due to this kafka is not deployed to dev environments by default. 
If you wish to test our kafka changes in a dev environment then please follow these steps:

1. In ```32-kafka-event-streaming.tf``` modify the count on line two so that it reads ```count       = local.is_live_environment ? 1 : 1```. Do not commit this change
2. Deploy terraform/core to your dev environment
3. 

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
docker image and port forwarding to it via the bastion. It's a little convoluted, but it just works once setup.

### Docker

```shell
docker pull landoop/schema-registry-ui
docker run --rm -p 8000:8000 \
           -e "SCHEMAREGISTRY_URL=http://localhost:8081" \
           landoop/schema-registry-ui
```

### Bastion Tunnel

#### Setup
If your bastion has been re-deployed or is new, you will need to setup a few bits to allow the SSH tunneling to work.
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

Broken Settings
```
connector.class=io.confluent.connect.s3.S3SinkConnector
value.converter.schemaAutoRegistrationEnabled=true
s3.region=eu-west-2
flush.size=1
schema.compatibility=NONE
tasks.max=2
topics=tenure_api
value.converter.registry.name=joates-schema-registry
value.converter.avroRecordType=GENERIC_RECORD
value.converter.region=eu-west-2
s3.sse.kms.key.id=8c5aa61d-8dab-4127-9190-5dfabc20d84c
key.converter.schemas.enable=false
format.class=io.confluent.connect.s3.format.parquet.ParquetFormat
value.converter.schemaName=joates-tenure-api
partitioner.class=io.confluent.connect.storage.partitioner.DefaultPartitioner
value.converter.schemas.enable=true
value.converter=com.amazonaws.services.schemaregistry.kafkaconnect.AWSKafkaAvroConverter
storage.class=io.confluent.connect.s3.storage.S3Storage
errors.log.enable=true
key.converter=org.apache.kafka.connect.storage.StringConverter
s3.bucket.name=dataplatform-joates-raw-zone
```
Plugin: confluentinc-kafka-connect-s3-10-0-5-v3
Name: tenure-api-with-s3-sink-and-aws-schema-registry-using-old-plugin