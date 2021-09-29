#!/bin/bash


modules=$(ls ./modules)


for module in $(ls ./modules) do echo $module done
    # ../tflint --var-file='../config/terraform/stg.tfvars'  --var 'aws_deploy_region=${{ env.aws_deploy_region }}' --var 'aws_deploy_account=${{ env.aws_deploy_account }}' --var 'aws_api_account=${{ env.aws_api_account }}' --var 'aws_hackit_account_id=${{ env.aws_hackit_account_id }}' --var 'aws_deploy_iam_role_name=${{ env.aws_deploy_iam_role_name }}' --var 'environment=${{ env.environment }}' --var 'google_project_id=${{ env.google_project_id }}' --var 'automation_build_url=${{ env.automation_build_url }}' --var 'aws_api_vpc_id=${{ env.aws_api_vpc_id }}' --module --config="../.tflint.hcl" --loglevel=warn .

