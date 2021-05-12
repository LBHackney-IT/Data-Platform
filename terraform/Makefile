.PHONY: init plan apply destroy

init:
	aws-vault exec hackney-dataplatform-development -- terraform init

plan:
	aws-vault exec hackney-dataplatform-development -- terraform plan -var-file="../config/terraform/env.tfvars"

apply: 
	aws-vault exec hackney-dataplatform-development -- terraform apply -var-file="../config/terraform/env.tfvars"

destroy: 
	aws-vault exec hackney-dataplatform-development -- terraform destroy -var-file="../config/terraform/env.tfvars"