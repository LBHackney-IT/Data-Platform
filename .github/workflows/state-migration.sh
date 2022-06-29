#!/bin/bash

environment="${1}"
aws_access_key_id="${2}"
aws_secret_access_key="${3}"
terraform_state_s3_key_prefix="${4}"

aws configure set default.region eu-west-2
aws configure set aws_access_key_id "${aws_access_key_id}"
aws configure set aws_secret_access_key "${aws_secret_access_key}"

#cd ../etl
#terraform init -backend-config="region=eu-west-2" -backend-config="dynamodb_table=lbhackney-terraform-state-lock" -backend-config="encrypt=true" -backend-config="workspace_key_prefix=${terraform_state_s3_key_prefix}" -backend-config="bucket=lbhackney-terraform-state" -backend-config="key=${terraform_state_s3_key_prefix}/${environment}-terraform-etl.tfstate"
#while read -r resource; do
#    terraform import -lock=false "$resource";
#done < ../../.github/workflows/resources-to-import.txt
#cd ../core



#
#terraform init -backend-config="region=eu-west-2" -backend-config="dynamodb_table=lbhackney-terraform-state-lock" -backend-config="encrypt=true" -backend-config="workspace_key_prefix=${terraform_state_s3_key_prefix}" -backend-config="bucket=lbhackney-terraform-state" -backend-config="key=${terraform_state_s3_key_prefix}/${environment}-terraform.tfstate"
#while read -r resource_address; do
#    terraform state mv -lock=false -state-out=../etl/"${environment}"-terraform-etl.tfstate "$resource_address" "$resource_address";
#done < ../../.github/workflows/resources-to-move.txt
#
#echo "New Core State"
#terraform state list
#
#cd ../etl
#ls
#terraform init -backend-config="region=eu-west-2" -backend-config="dynamodb_table=lbhackney-terraform-state-lock" -backend-config="encrypt=true" -backend-config="workspace_key_prefix=${terraform_state_s3_key_prefix}" -backend-config="bucket=lbhackney-terraform-state" -backend-config="key=${terraform_state_s3_key_prefix}/${environment}-terraform-etl.tfstate"
#terraform state push -force ./"${environment}"-terraform-etl.tfstate

terraform init -backend-config="region=eu-west-2" -backend-config="dynamodb_table=lbhackney-terraform-state-lock" -backend-config="encrypt=true" -backend-config="workspace_key_prefix=${terraform_state_s3_key_prefix}" -backend-config="bucket=lbhackney-terraform-state" -backend-config="key=${terraform_state_s3_key_prefix}/${environment}-terraform.tfstate"
terraform force-unlock 5949bfd0-76d0-ae70-82bf-d2fe9df6d797