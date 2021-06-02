.PHONY: init plan apply destroy new push-ecr

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

new:
	aws-vault exec hackney-dataplatform-development -- terraform workspace new ${WORKSPACE}

push-ecr:
	aws-vault exec hackney-dataplatform-development -- ../docker/deploy.sh
