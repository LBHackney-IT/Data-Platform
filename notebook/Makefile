save-credentials:
	-(aws-vault exec hackney-dataplatform-staging -- env | grep  ^AWS_)  > ./.env

run-notebook: save-credentials
	docker compose up notebook

run-notebook-v2: save-credentials
	docker compose up notebook-v2

run-notebook-v3: save-credentials
	docker compose run --service-ports notebook-v3 

remove-images:
	-docker kill glue_jupyter
	docker rm glue_jupyter

thrift-server:
	docker compose exec notebook bash -c "/home/spark-2.4.3-bin-spark-2.4.3-bin-hadoop2.8/sbin/start-thriftserver.sh --hiveconf hive.metastore.client.factory.class=com.amazonaws.glue.catalog.metastore.AWSGlueDataCatalogHiveClientFactory --hiveconf hive.metastore.schema.verification=false --hiveconf aws.region=eu-west-2"

spark-sql:
	docker compose exec notebook /home/spark-2.4.3-bin-spark-2.4.3-bin-hadoop2.8/bin/beeline -u jdbc:hive2://localhost:10000/default -n root -p ""

.PHONY: run-notebook run-notebook-v3 run-notebook-v2
