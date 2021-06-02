#!/bin/bash

ecr_url=$(terraform output -raw ecr_repository_worker_endpoint)

docker build -f ../docker/Dockerfile -t $ecr_url ../docker
echo $ROLE_ARN
TEMP_ROLE=`aws sts assume-role --role-arn $ROLE_ARN --role-session-name deploy-image-to-ecr`

access_key=$(echo "${TEMP_ROLE}" | jq -r '.Credentials.AccessKeyId')
echo $access_key
secret_access_key=$(echo "${TEMP_ROLE}" | jq -r '.Credentials.SecretAccessKey')
session_token=$(echo "${TEMP_ROLE}" | jq -r '.Credentials.SessionToken')

AWS_ACCESS_KEY_ID=$access_key AWS_SECRET_ACCESS_KEY=$secret_access_key AWS_SESSION_TOKEN=$session_token aws ecr get-login-password --region eu-west-2 | docker login --username AWS --password-stdin $ecr_url

docker push $ecr_url
