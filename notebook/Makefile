run-notebook:
	-(aws-vault exec hackney-dataplatform-development -- env | grep  ^AWS_)  > ./.env
	docker compose up -d notebook

script_name = "manually_uploaded_parking_data_to_raw.py"
s3_bucket_target = "dataplatform-emmacorbett-raw-zone"
s3_bucket_source = "dataplatform-emmacorbett-landing-zone"

run-script:
	(aws-vault exec hackney-dataplatform-development -- env | grep  ^AWS_)  > ./.env
	docker compose run cli /home/spark-2.4.3-bin-spark-2.4.3-bin-hadoop2.8/bin/spark-submit /home/jupyter/jupyter_default_dir/$(script_name) \
	--JOB_NAME local_test \
	--s3_bucket_target $(s3_bucket_target) \
	--s3_bucket_source $(s3_bucket_source)

remove-images:
	-docker kill glue_jupyter
	docker rm glue_jupyter

.PHONY: run-notebook