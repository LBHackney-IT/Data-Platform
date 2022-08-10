#!/bin/bash

if [ -z "$WORKSPACE" ] || [ -z "$KAFKA_SERVERS" ] || [ -z "$KAFKA_TOPIC" ]; then
  echo "Please set the workspace env variable using: export WORKSPACE=<your_terrform_workspace_name>"
  echo "Please set the kafka servers env variable using: export KAFKA_SERVERS=<your_kafka_bootstrap_servers>"
  echo "Please set the kafka topic you wish to send an event to, this information can be found by running list-topics.sh and then running export KAFKA_TOPIC=<your_kafka_topic_from_list_topic.sh>"
  exit 1
fi

search_dir="../../kafka-schema-registry/schemas/"
for entry in $(ls $search_dir | xargs -n 1 basename)
do
  options+=$(echo "$entry" | cut -f1 -d ".")
  options+=","
done
echo "Which api message do you wish to use."
echo "Options=$options"
read -r topic_name_to_use

bastion_instance_id=$(aws-vault exec hackney-dataplatform-development --  aws ec2 describe-instances  --filters "Name=tag:Name,Values=dataplatform-${WORKSPACE}-bastion" | jq -r '.Reservations[].Instances[].InstanceId')

topic_schema=$(tr -d '\n' < ../../kafka-schema-registry/schemas/"$topic_name_to_use".json | jq -Rsa .)
topic_schema="${topic_schema#?}"
topic_schema="${topic_schema%?}"

topic_message=$(tr -d '\n' < ./test-events/"$topic_name_to_use".json | jq -Rsa .)
topic_message="${topic_message#?}"
topic_message="${topic_message%?}"

cat <<EOF > send-message-to-topic.json
{
    "Parameters": {
        "commands": [
          "#!/bin/bash",
          "sudo su -",
          "if [ ! -d 'confluent-2.0.0' ]; then",
            "sudo yum install java",
            "wget http://packages.confluent.io/archive/2.0/confluent-2.0.0-2.11.7.zip",
            "sleep 30",
            "unzip confluent-2.0.0-2.11.7.zip",
            "cd confluent-2.0.0",
            "killall -9 java",
          "else",
            "killall -9 java",
            "echo 'Kafka already installed'",
            "cd confluent-2.0.0",
          "fi",
          "echo 'security.protocol=SSL' > server.properties",
          "echo 'Sending Message to kafka:'",
          "echo $topic_message | bin/kafka-avro-console-producer --broker-list $KAFKA_SERVERS --topic $KAFKA_TOPIC --property value.schema=$topic_schema"
        ]
    }
}
EOF

AWS_SSM_RUN_COMMAND_ID=$(aws-vault exec hackney-dataplatform-development --  aws ssm send-command \
--target "Key=instanceids,Values=$bastion_instance_id" \
--document-name "AWS-RunShellScript" \
--cli-input-json file://send-message-to-topic.json \
--query 'Command.{CommandId:CommandId}' \
--output text)

echo "Command Id=$AWS_SSM_RUN_COMMAND_ID"

sleep 10

COMMAND_RESULT=$(aws-vault exec hackney-dataplatform-development -- aws ssm get-command-invocation --command-id "$AWS_SSM_RUN_COMMAND_ID" --instance-id "$bastion_instance_id" | jq ".StandardOutputContent, .StandardErrorContent")
echo "$COMMAND_RESULT"

echo "Message has been sent to kafka, please check S3 output location"