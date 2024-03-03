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
	make package-helpers
	cd terraform/core && make init
	cd terraform/etl && make init
	cd terraform/networking && make init
	cd terraform/backend-setup && make init
	git config core.hooksPath .github/hooks

apply:
	make package-helpers
	cd external-lib && make all
	cd terraform/core && make apply
	cd terraform/etl && make apply

destroy:
	cd terraform/core && make destroy
	cd terraform/etl && make destroy

plan:

	cd external-lib && make all
	cd terraform/core && make plan

validate:
	make package-helpers
	cd external-lib && make all
	$(MAKE) -C terraform/core validate
	$(MAKE) -C terraform/etl validate
	$(MAKE) -C terraform/networking validate
	$(MAKE) -C terraform/backend-setup validate

start-qlik-ssm-session:
	@echo "Environment (development,staging,production): "; read ENVIRONMENT; \
	echo "Qlik instance id: "; read QLIK_INSTANCE_ID; \
	aws-vault exec hackney-dataplatform-$$ENVIRONMENT -- aws ssm start-session --target $$QLIK_INSTANCE_ID --document-name AWS-StartPortForwardingSession --parameters '{"portNumber":["3389"],"localPortNumber":["3389"]}'

package-helpers: scripts\lib\data_platform_glue_job_helpers-1.0-py3-none-any.whl scripts\lib\convertbng-0.6.36-cp310-cp310-manylinux_2_17_x86_64.manylinux2014_x86_64.whl

.venv\Scripts\python:
	python -m venv .venv

.venv\.install.stamp: .venv\Scripts\python scripts\requirements.build.txt
	.venv\Scripts\python -m pip install -r scripts\requirements.build.txt
	echo > .venv\.install.stamp

scripts\lib\data_platform_glue_job_helpers-1.0-py3-none-any.whl: .venv\.install.stamp
	.\scripts\package-helpers.bat
	move dist\data_platform_glue_job_helpers-1.0-py3-none-any.whl scripts\lib\data_platform_glue_job_helpers-1.0-py3-none-any.whl

scripts\lib\convertbng-0.6.36-cp310-cp310-manylinux_2_17_x86_64.manylinux2014_x86_64.whl:
	Invoke-WebRequest -Uri "https://files.pythonhosted.org/packages/73/08/d75ba0299d1ac2db7c1143214d4e9f26f1f04e25941cb19d0e28555955a9/convertbng-0.6.36-cp310-cp310-manylinux_2_17_x86_64.manylinux2014_x86_64.whl" -OutFile "./scripts/lib/convertbng-0.6.36-cp310-cp310-manylinux_2_17_x86_64.manylinux2014_x86_64.whl"