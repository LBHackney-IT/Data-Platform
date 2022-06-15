.PHONY: $(MAKECMDGOALS)

init:
	aws-vault exec hackney-dataplatform-development -- terraform init

plan:
	aws-vault exec hackney-dataplatform-development -- terraform plan -var-file="../config/terraform/env.tfvars"

apply: 
	aws-vault exec hackney-dataplatform-development -- terraform apply -var-file="../config/terraform/env.tfvars"

validate:
	terraform validate

destroy: 
	aws-vault exec hackney-dataplatform-development -- terraform destroy -var-file="../config/terraform/env.tfvars"

lint-init:
	tflint --init --config="../terraform/config/.tflint.hcl"

lint:
	aws-vault exec hackney-dataplatform-development -- tflint --var-file='../config/terraform/env.tfvars' --module --config="../terraform/config/.tflint.hcl" --loglevel=warn .