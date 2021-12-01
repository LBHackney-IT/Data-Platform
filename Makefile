.PHONY: $(MAKECMDGOALS)

push-ecr:
	aws-vault exec hackney-dataplatform-development -- ./docker/sql-to-parquet/deploy.sh

format:
	terraform fmt ./terraform
	terraform fmt ./terraform-backend-setup
	terraform fmt ./terraform-networking
	terraform fmt -recursive ./modules

lint:
	$(MAKE) -C terraform lint-init lint
	$(MAKE) -C terraform-networking lint-init lint
	$(MAKE) -C terraform-backend-setup lint-init lint

init:
	cd external-lib && make all
	cd scripts && make dist/data_platform_glue_job_helpers-1.0-py3-none-any.whl
	cd terraform && make init

apply:
	cd scripts && make dist/data_platform_glue_job_helpers-1.0-py3-none-any.whl
	cd external-lib && make all
	cd terraform && make apply

plan:
	cd scripts && make dist/data_platform_glue_job_helpers-1.0-py3-none-any.whl
	cd external-lib && make all
	cd terraform && make plan

validate:
	cd scripts && make dist/data_platform_glue_job_helpers-1.0-py3-none-any.whl
	cd external-lib && make all
	$(MAKE) -C terraform validate
	$(MAKE) -C terraform-networking validate
	$(MAKE) -C terraform-backend-setup validate
