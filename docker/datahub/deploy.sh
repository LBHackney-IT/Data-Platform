#!/bin/bash

set -eu -o pipefail

export AWS_VPC=${1}
export AWS_ECS_CLUSTER=${2}
export AWS_ALB=${3}
AWS_DEPLOY_ACCOUNT_ID=${4}
AWS_DEPLOY_IAM_ROLE_NAME=${5}


echo "[profile deploy_role]" >> ~/.aws/config
echo "role_arn=arn:aws:iam::${AWS_DEPLOY_ACCOUNT_ID}:role/${AWS_DEPLOY_IAM_ROLE_NAME}" >> ~/.aws/config
echo "source_profile=default" >> ~/.aws/config
echo "role_session_name=deploy" >> ~/.aws/config
echo "region=eu-west-2" >> ~/.aws/config

export AWS_PROFILE=deploy_role

docker context create ecs datahub

docker context use datahub

docker compose up

