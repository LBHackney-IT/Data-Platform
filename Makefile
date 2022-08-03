.PHONY: $(MAKECMDGOALS)

push-ecr:
	aws-vault exec hackney-dataplatform-development -- ./docker/sql-to-parquet/deploy.sh

format:
	terraform fmt -recursive

lint:
	$(MAKE) -C terraform/core lint-init lint
	$(MAKE) -C terraform/etl lint-init lint
	$(MAKE) -C terraform/networking lint-init lint
	$(MAKE) -C terraform/backend-setup lint-init lint

init:
	cd external-lib && make all
	cd scripts && make all
	cd terraform/core && make init
	cd terraform/etl && make init
	cd terraform/networking && make init
	cd terraform/backend-setup && make init
	git config core.hooksPath .github/hooks

apply:
	cd scripts && make all
	cd external-lib && make all
	cd terraform/core && make apply

plan:
	cd scripts && make all
	cd external-lib && make all
	cd terraform/core && make plan

validate:
	cd scripts && make all
	cd external-lib && make all
	$(MAKE) -C terraform/core validate
	$(MAKE) -C terraform/etl validate
	$(MAKE) -C terraform/networking validate
	$(MAKE) -C terraform/backend-setup validate

start-qlik-ssm-session:
	@echo "Environment (development,staging,production): "; read ENVIRONMENT; \
	echo "Qlik instance id: "; read QLIK_INSTANCE_ID; \
	aws-vault exec hackney-dataplatform-$$ENVIRONMENT -- aws ssm start-session --target $$QLIK_INSTANCE_ID --document-name AWS-StartPortForwardingSession --parameters '{"portNumber":["3389"],"localPortNumber":["3389"]}'

package-helpers: lib/data_platform_glue_job_helpers-1.0-py3-none-any.whl lib/convertbng-0.6.36-cp310-cp310-manylinux_2_17_x86_64.manylinux2014_x86_64.whl

.venv/bin/python:
	python3 -m venv .venv

.venv/.install.stamp: .venv/bin/python scripts/requirements.build.txt
	.venv/bin/python -m pip install -r scripts/requirements.build.txt
	touch .venv/.install.stamp

lib/data_platform_glue_job_helpers-1.0-py3-none-any.whl: .venv/.install.stamp ./scripts/*
	./scripts/package-helpers.sh
	mv dist/data_platform_glue_job_helpers-1.0-py3-none-any.whl scripts/lib/data_platform_glue_job_helpers-1.0-py3-none-any.whl

lib/convertbng-0.6.36-cp310-cp310-manylinux_2_17_x86_64.manylinux2014_x86_64.whl:
	wget https://files.pythonhosted.org/packages/73/08/d75ba0299d1ac2db7c1143214d4e9f26f1f04e25941cb19d0e28555955a9/convertbng-0.6.36-cp310-cp310-manylinux_2_17_x86_64.manylinux2014_x86_64.whl -O ./scripts/lib/convertbng-0.6.36-cp310-cp310-manylinux_2_17_x86_64.manylinux2014_x86_64.whl
