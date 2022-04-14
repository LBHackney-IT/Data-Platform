.PHONY: $(MAKECMDGOALS)

push-ecr:
	aws-vault exec hackney-dataplatform-development -- ./docker/sql-to-parquet/deploy.sh

format:
	terraform fmt -recursive

lint:
	$(MAKE) -C terraform lint-init lint
	$(MAKE) -C terraform-networking lint-init lint
	$(MAKE) -C terraform-backend-setup lint-init lint

init:
	cd external-lib && make all
	cd scripts && make all
	cd terraform && make init
	cd terraform-networking && make init
	cd terraform-backend-setup && make init
	git config core.hooksPath .github/hooks

apply:
	cd scripts && make all
	cd external-lib && make all
	cd terraform && make apply

plan:
	cd scripts && make all
	cd external-lib && make all
	cd terraform && make plan

validate:
	cd scripts && make all
	cd external-lib && make all
	$(MAKE) -C terraform validate
	$(MAKE) -C terraform-networking validatenasd
	$(MAKE) -C terraform-backend-setup validate

start-qlik-ssm-session:
	@echo "Environment (development,staging,production): "; read ENVIRONMENT; \
	echo "Qlik instance id: "; read QLIK_INSTANCE_ID; \
	aws-vault exec hackney-dataplatform-$$ENVIRONMENT -- aws ssm start-session --target $$QLIK_INSTANCE_ID --document-name AWS-StartPortForwardingSession --parameters '{"portNumber":["3389"],"localPortNumber":["3389"]}'
