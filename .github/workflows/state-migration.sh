#!/bin/bash

environment="${1}"
aws_access_key_id="${2}"
aws_secret_access_key="${3}"
terraform_state_s3_key_prefix="${4}"

cd ./terraform/core

aws configure set default.region eu-west-2
aws configure set aws_access_key_id "${aws_access_key_id}"
aws configure set aws_secret_access_key "${aws_secret_access_key}"
terraform init -backend-config="region=eu-west-2" -backend-config="dynamodb_table=lbhackney-terraform-state-lock" -backend-config="encrypt=true" -backend-config="workspace_key_prefix=${terraform_state_s3_key_prefix}" -backend-config="bucket=lbhackney-terraform-state" -backend-config="key=${terraform_state_s3_key_prefix}/${environment}-terraform.tfstate"

echo "Current State"
terraform state list

FILES="../etl/*.tf"
for f in $FILES
do
    grep -Eo -e '^module \".*\"' -e '^data \".*\"' "$f" | tr -s " \"" "." | sed 's/\.$//' | \
    while read -r resource_address; do terraform state mv -dry-run -state-out=./"${environment}"-terraform-etl.tfstate "$resource_address" "$resource_address"; done

    grep -Eo '^resource \".*\"' "$f" | tr -s " \"" "." | sed 's/\.$//' | sed 's/^resource\.//' | \
    while read -r resource_address; do terraform state mv -dry-run -state-out=./"${environment}"-terraform-etl.tfstate "$resource_address" "$resource_address"; done;
done

echo "New State"
terraform state list

ls
cp ./"${environment}"-terraform-etl.tfstate ../etl/"${environment}"-terraform-etl.tfstate
cd ../etl
ls
#terraform state push -force ./"${environment}"-terraform-etl.tfstate
