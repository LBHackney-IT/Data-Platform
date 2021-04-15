#!/bin/bash
set -e

eval "$(jq -r '@sh "aws_deploy_account=\(.aws_deploy_account) aws_deploy_iam_role_name=\(.aws_deploy_iam_role_name) aws_deploy_region=\(.aws_deploy_region)"')"
temp_role=$(aws sts assume-role --role-arn arn:aws:iam::$aws_deploy_account:role/$aws_deploy_iam_role_name --role-session-name primary-vpc-attachment-query)

export AWS_ACCESS_KEY_ID=$(echo $temp_role | jq -r .Credentials.AccessKeyId)
export AWS_SECRET_ACCESS_KEY=$(echo $temp_role | jq -r .Credentials.SecretAccessKey)
export AWS_SESSION_TOKEN=$(echo $temp_role | jq -r .Credentials.SessionToken)

aws configure set aws_access_key_id $AWS_ACCESS_KEY_ID --profile vpc-attachments-query
aws configure set aws_secret_access_key $AWS_SECRET_ACCESS_KEY --profile vpc-attachments-query
aws configure set aws_session_token $AWS_SESSION_TOKEN --profile vpc-attachments-query

query=$(aws ec2 describe-transit-gateway-attachments --region $aws_deploy_region --profile vpc-attachments-query --filter Name=state,Values=available --query {\"as_string\":to_string\([TransitGatewayAttachments[?!not_null\(Tags[?Key==\`Name\`].Value\)]]\)})

echo $query