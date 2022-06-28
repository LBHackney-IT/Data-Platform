#!/bin/bash

environment="${1}"
aws_access_key_id="${2}"
aws_secret_access_key="${3}"
terraform_state_s3_key_prefix="${4}"
aws_deploy_region="${5}"
aws_deploy_account_id="${6}"
aws_api_account_id="${7}"
aws_mosaic_prod_account_id="${8}"
aws_data_platform_account_id="${9}"
aws_hackit_account_id="${10}"
aws_deploy_iam_role_name="${11}"
google_project_id="${12}"
automation_build_url="${13}"
aws_api_vpc_id="${14}"
aws_housing_vpc_id="${15}"
aws_mosaic_vpc_id="${16}"
aws_dp_vpc_id="${17}"
copy_liberator_to_pre_prod_lambda_execution_role="${18}"
sync_production_to_pre_production_task_role="${19}"
pre_production_liberator_data_storage_kms_key_arn="${20}"

aws configure set default.region eu-west-2
aws configure set aws_access_key_id "${aws_access_key_id}"
aws configure set aws_secret_access_key "${aws_secret_access_key}"

echo "Get Core Resources to move to new state"
terraform init -backend-config="region=eu-west-2" -backend-config="dynamodb_table=lbhackney-terraform-state-lock" -backend-config="encrypt=true" -backend-config="workspace_key_prefix=${terraform_state_s3_key_prefix}" -backend-config="bucket=lbhackney-terraform-state" -backend-config="key=${terraform_state_s3_key_prefix}/${environment}-terraform.tfstate"
terraform plan -lock=false -var-file="../config/${environment}.tfvars" -var "aws_deploy_region=${aws_deploy_region}" -var "aws_deploy_account_id=${aws_deploy_account_id}" -var "aws_api_account_id=${aws_api_account_id}" -var "aws_mosaic_prod_account_id=${aws_mosaic_prod_account_id}" -var "aws_data_platform_account_id=${aws_data_platform_account_id}" -var "aws_hackit_account_id=${aws_hackit_account_id}" -var "aws_deploy_iam_role_name=${aws_deploy_iam_role_name}" -var "environment=${environment}" -var "google_project_id=${google_project_id}" -var "automation_build_url=${automation_build_url}" -var "aws_api_vpc_id=${aws_api_vpc_id}" -var "aws_housing_vpc_id=${aws_housing_vpc_id}" -var "aws_mosaic_vpc_id=${aws_mosaic_vpc_id}" -var "aws_dp_vpc_id=${aws_dp_vpc_id}" -var "copy_liberator_to_pre_prod_lambda_execution_role=${copy_liberator_to_pre_prod_lambda_execution_role}" -var "sync_production_to_pre_production_task_role=${sync_production_to_pre_production_task_role}" -var "pre_production_liberator_data_storage_kms_key_arn=${pre_production_liberator_data_storage_kms_key_arn}" -input=false -out=core-plan.out
terraform show -json ./core-plan.out > core-plan.json

echo "Core Plan"
cat ./core-plan.json

terraform state list > orginal-state.txt
echo "Original State"
cat ./orginal-state.txt

while read -r resource_address; do
  if grep -q "$resource_address" ./core-plan.json ; then
    terraform state mv -dry-run -state-out=./"${environment}"-terraform-etl.tfstate "$resource_address" "$resource_address";
  else
    echo "${line} does not need to be moved";
  fi
done < ./orginal-state.txt

#echo "New Core State"
#terraform state list
#
#ls
#cp ./"${environment}"-terraform-etl.tfstate ../etl/"${environment}"-terraform-etl.tfstate
#cd ../etl
#ls
#terraform state push -force ./"${environment}"-terraform-etl.tfstate
