run-notebook:
	-(aws-vault exec hackney-dataplatform-staging -- env | grep  ^AWS_)  > ./.env
	docker compose up notebook

run-notebook-v3:
	-(aws-vault exec hackney-dataplatform-staging -- env | grep  ^AWS_)  > ./.env
	docker run -it -p 8888:8888 -p 4040:4040 -e DISABLE_SSL="true" \
	--env-file ./.env \
	--name glue_jupyter_v4 -v $$PWD/scripts:/home/glue_user/workspace/jupyter_workspace \
	amazon/aws-glue-libs:glue_libs_3.0.0_image_01
# /home/glue_user/jupyter/jupyter_start.sh

remove-images:
	-docker kill glue_jupyter
	docker rm glue_jupyter

thrift-server:
	docker compose exec notebook bash -c "/home/spark-2.4.3-bin-spark-2.4.3-bin-hadoop2.8/sbin/start-thriftserver.sh --hiveconf hive.metastore.client.factory.class=com.amazonaws.glue.catalog.metastore.AWSGlueDataCatalogHiveClientFactory --hiveconf hive.metastore.schema.verification=false --hiveconf aws.region=eu-west-2"

spark-sql:
	docker compose exec notebook /home/spark-2.4.3-bin-spark-2.4.3-bin-hadoop2.8/bin/beeline -u jdbc:hive2://localhost:10000/default -n root -p ""

.PHONY: run-notebook run-notebook-v3
