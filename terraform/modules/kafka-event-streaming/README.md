## Local Development & Testing

Kafka takes a long time to create in AWS, specifically the MSK connectors. Due to this kafka is not deployed to dev environments by default. 
If you wish to test our kafka changes in a dev environment then please follow these steps:

1. In ```32-kafka-event-streaming.tf``` modify the count on line two so that it reads ```count       = local.is_live_environment ? 1 : 1```. Do not commit this change
2. Deploy terraform/core to your dev environment
3. Configure bastion tunnel to your kafka instance
    1. ```aws-vault exec hackney-dataplatform-development -- aws ssm start-session --target {personal_dev_bastion_instance_id}```
    2. ```shell
        sudo su ec2-user
        cd ~
        ssh-keygen
        ```
    3. `Enter file in which to save the key (/home/ec2-user/.ssh/id_rsa):` Just press enter
    4. `Enter passphrase (empty for no passphrase):` Just press enter
    5. `Enter same passphrase again:` You've guessed it, just press enter
    6. ```shell
        cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
        ```
    7. Start the tunnel: ```ssh -i .ssh/id_rsa -L 9094:{kafka_cluster_bootstrap_server}:9094 ec2-user@localhost -v```
4. In a seperate terminal run the command to connect your local machine to the bastion tunnel 
    1. ```aws-vault exec hackney-dataplatform-development -- aws ssm start-session --target {personal_dev_bastion_instance_id} --document-name AWS-StartPortForwardingSession --parameters '{"portNumber":["9094"],"localPortNumber":["9094"]}'```
5. Install the kafka tools on your local machine
    1. ```brew cask install java``` or manually install if on Windows
    2. ```brew install kafka``` or manually install if on Windows
6. Set up properties
    1. ```cd cd /usr/local/opt/kafka/bin/``` or find your kafka install location
    1. ```echo "security.protocol=SSL" > server.properties```
7. You are now ready to run any of the following commands to test your deployed kafka instance:
   
   #### Write an event into a topic
   This only works if you have specifically installed the AVRO package. It is NOT included in the package listed above.
   ```shell
   ./kafka-avro-console-producer --broker-list 127.0.0.1:9094 --topic s3_topic --property value.schema='{"type":"record","name":"myrecord","fields":[{"name":"f1","type":"string"}]}'
   ```
   
   #### Consume a Topic
   ```shell
   ./kafka-console-consumer --topic {topic} --consumer.config server.properties --from-beginning --bootstrap-server {kafka_cluster_bootstrap_server}
   ```
   
   #### List Topics
   ```shell
   ./kafka-topics --command-config server.properties --list --bootstrap-server {kafka_cluster_bootstrap_server}
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