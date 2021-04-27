.PHONY: init

init:
	terraform init -backend-config="profile=hackney-dev-scratch"
	aws ssm get-parameter --name "/data_platform/dev/google_service_account_creds" --output text --query Parameter.Value > ../google_service_account_creds.json --profile=hackney-dev-scratch

plan:
	AWS_PROFILE=hackney-dev-scratch terraform plan -var-file="../config/terraform/dev.tfvars"
