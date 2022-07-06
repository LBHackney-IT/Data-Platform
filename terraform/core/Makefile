.PHONY: $(MAKECMDGOALS)

init:
	aws-vault exec hackney-dataplatform-development -- terraform init

upgrade:
	aws-vault exec hackney-dataplatform-development -- terraform init -upgrade

plan:
	aws-vault exec hackney-dataplatform-development -- terraform plan -var-file="../config/env.tfvars"

apply:
	aws-vault exec hackney-dataplatform-development -- terraform apply -var-file="../config/env.tfvars" --auto-approve

validate:
	terraform validate

destroy:
	aws-vault exec hackney-dataplatform-development -- terraform destroy -var-file="../config/env.tfvars"

workspace-new:
	aws-vault exec hackney-dataplatform-development -- terraform workspace new ${WORKSPACE}

workspace-select:
	aws-vault exec hackney-dataplatform-development -- terraform workspace select ${WORKSPACE}

workspace-list:
	aws-vault exec hackney-dataplatform-development -- terraform workspace list

format:
	terraform fmt .

lint-init:
	tflint --init --config="../terraform/config/.tflint.hcl"

lint:
	aws-vault exec hackney-dataplatform-development -- tflint --var-file='../config/env.tfvars' --module --config="../terraform/config/.tflint.hcl" --loglevel=warn .
