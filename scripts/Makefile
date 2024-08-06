.PHONY: test test-watch history-server shell

filename ?= ""
test:
	filename=${filename} docker compose run unit_tests

test-watch:
	docker compose run --entrypoint "bash -c 'pip install -r requirements.test.txt && pytest-watch ./${filename}'" unit_tests

history-server:
	docker run --rm -p "18080:18080" -v ${PWD}/spark_events:/tmp/spark-events amazon/aws-glue-libs:glue_libs_1.0.0_image_01 bash -c 'rm $${SPARK_HOME}/jars/jersey-*-1.9.jar; $${SPARK_HOME}/bin/spark-class org.apache.spark.deploy.history.HistoryServer'

shell:
	docker run --rm -it -w /root/scripts -v ${PWD}:/root/scripts amazon/aws-glue-libs:glue_libs_1.0.0_image_01 bash