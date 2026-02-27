#! /bin/bash

set -ex

topic_name=$1
instance_id=$2
schema_registry_url=$3
private_key_ssm_parameter=$4
path_to_schema_file=$5
is_live_environment=$6

if $is_live_environment; then
  export AWS_PROFILE=deploy_role
fi

key_file=$(mktemp)

aws ssm get-parameter --name $private_key_ssm_parameter --with-decryption --output text --query Parameter.Value > $key_file
chmod 400 $key_file
schema_string=$(jq -c . $path_to_schema_file | jq -R) 


ssh -4 -i $key_file -f -M \
    -L 8081:${schema_registry_url//\"}:8081 \
    -o "UserKnownHostsFile=/dev/null" \
    -o "StrictHostKeyChecking=no" \
    -o ProxyCommand="aws ssm start-session --target %h --document AWS-StartSSHSession --parameters portNumber=%p --region=eu-west-2" \
    -o ExitOnForwardFailure=yes \
    ec2-user@${instance_id//\"} \
    sleep 10

curl -X POST -H "Content-Type: application/vnd.schemaregistry.v1+json" --data "{ \"schema\": ${schema_string} }" "http://localhost:8081/subjects/$topic_name-value/versions"

rm -f $key_file
