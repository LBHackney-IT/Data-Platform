.PHONY: $(MAKECMDGOALS)

init:
	aws-vault exec hackney-dataplatform-development -- terraform init

plan:
	aws-vault exec hackney-dataplatform-development -- terraform plan ./terraform -var-file="../config/terraform/env.tfvars"

apply:
	aws-vault exec hackney-dataplatform-development -- terraform apply -var-file="../config/terraform/env.tfvars" --auto-approve

validate:
	terraform validate ./terraform

destroy:
	aws-vault exec hackney-dataplatform-development -- terraform destroy -var-file="../config/terraform/Dev.tfvars"

new:
	aws-vault exec hackney-dataplatform-development -- terraform workspace new ${WORKSPACE}

format:
	terraform fmt .

lint-init:
	tflint --init --config="../../../.tflint.hcl"

lint:
	aws-vault exec hackney-dataplatform-development -- tflint --var-file='../config/terraform/Dev.tfvars' --module --config="../.tflint.hcl" --loglevel=warn .
