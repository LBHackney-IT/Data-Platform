run-notebook:
	-(aws-vault exec hackney-dataplatform-development -- env | grep  ^AWS_)  > ./.env
	docker compose up -d notebook

remove-images:
	-docker kill glue_jupyter
	docker rm glue_jupyter

.PHONY: run-notebook