.PHONY: $(MAKECMDGOALS)

init:
	aws-vault exec hackney-dataplatform-development -- terraform init

plan:
	aws-vault exec hackney-dataplatform-development -- terraform plan -var-file="../config/env.tfvars"

apply: 
	aws-vault exec hackney-dataplatform-development -- terraform apply -var-file="../config/env.tfvars"

validate:
	terraform validate

destroy: 
	aws-vault exec hackney-dataplatform-development -- terraform destroy -var-file="../config/env.tfvars"

lint-init:
	tflint --init --config="../config/.tflint.hcl"

lint:
	aws-vault exec hackney-dataplatform-development -- tflint --var-file='../config/env.tfvars' --module --config="../config/.tflint.hcl" --loglevel=warn .