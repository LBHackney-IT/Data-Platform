.PHONY: $(MAKECMDGOALS)

init:
	aws-vault exec hackney-dataplatform-development -- terraform init

plan:
	aws-vault exec hackney-dataplatform-development -- terraform plan -var-file="../config/terraform/env.tfvars"

apply:
	aws-vault exec hackney-dataplatform-development -- terraform apply -var-file="../config/terraform/env.tfvars" --auto-approve

validate:
	terraform validate

destroy:
	aws-vault exec hackney-dataplatform-development -- terraform destroy -var-file="../config/terraform/env.tfvars"

workspace-new:
	aws-vault exec hackney-dataplatform-development -- terraform workspace new ${WORKSPACE}

workspace-list:
	aws-vault exec hackney-dataplatform-development -- terraform workspace list

workspace-select:
	aws-vault exec hackney-dataplatform-development -- terraform workspace select ${WORKSPACE}

format:
	terraform fmt .

lint-init:
	tflint --init --config="../.tflint.hcl"

lint:
	aws-vault exec hackney-dataplatform-development -- tflint --var-file='../config/terraform/env.tfvars' --module --config="../.tflint.hcl" --loglevel=warn .
