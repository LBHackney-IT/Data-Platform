#!/bin/bash

if [ -z "$WORKSPACE" ] || [ -z "$KAFKA_SERVERS" ]; then
  echo "Please set the workspace env variable using: export WORKSPACE=<your_terrform_workspace_name>"
  echo "Please set the kafka servers env variable using: export KAFKA_SERVERS=<your_kafka_bootstrap_servers>"
  exit 1
fi

bastion_instance_id=$(aws-vault exec hackney-dataplatform-development --  aws ec2 describe-instances  --filters "Name=tag:Name,Values=dataplatform-${WORKSPACE}-bastion" | jq -r '.Reservations[].Instances[].InstanceId')

cat <<EOF > list-topics.json
{
    "Parameters": {
        "commands": [
          "#!/bin/bash",
          "sudo su -",
          "if [ ! -d 'kafka_2.13-3.1.0' ]; then",
            "sudo yum install java",
            "wget https://dlcdn.apache.org/kafka/3.1.0/kafka_2.13-3.1.0.tgz",
            "tar -xzf kafka_2.13-3.1.0.tgz",
            "cd kafka_2.13-3.1.0",
            "killall -9 java",
          "else",
            "echo 'Kafka already installed'",
            "cd kafka_2.13-3.1.0",
          "fi",
          "echo 'security.protocol=SSL' > server.properties",
          "echo 'Kafka Topic List:'",
          "bin/kafka-topics.sh --command-config server.properties --list --bootstrap-server $KAFKA_SERVERS"
        ]
    }
}
EOF

AWS_SSM_RUN_COMMAND_ID=$(aws-vault exec hackney-dataplatform-development --  aws ssm send-command \
--target "Key=instanceids,Values=$bastion_instance_id" \
--document-name "AWS-RunShellScript" \
--cli-input-json file://list-topics.json \
--query 'Command.{CommandId:CommandId}' \
--output text)

echo "Command Id=$AWS_SSM_RUN_COMMAND_ID"

sleep 10

COMMAND_RESULT=$(aws-vault exec hackney-dataplatform-development -- aws ssm get-command-invocation --command-id "$AWS_SSM_RUN_COMMAND_ID" --instance-id "$bastion_instance_id" | jq '.StandardOutputContent')
printf "$COMMAND_RESULT"