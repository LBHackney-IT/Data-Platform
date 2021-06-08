.PHONY: push-ecr format

push-ecr:
	aws-vault exec hackney-dataplatform-development -- ./docker/sql-to-parquet/deploy.sh

format:
	terraform fmt ./terraform
	terraform fmt ./terraform-backend-setup
	terraform fmt ./terraform-networking
	terraform fmt -recursive ./modules
