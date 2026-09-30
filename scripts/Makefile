.PHONY: test test-watch history-server shell

filename ?= ""
# The Glue image runs as glue_user, which needs to write Spark event logs here
test:
	chmod a+w spark_events
	filename=${filename} docker compose run unit_tests

test-watch:
	chmod a+w spark_events
	docker compose run --entrypoint "bash -c 'python3 -m pip install -r requirements.test.txt && python3 -m pytest_watch ./${filename}'" unit_tests

history-server:
	docker run --rm -p "18080:18080" -v ${PWD}/spark_events:/tmp/spark-events --entrypoint bash amazon/aws-glue-libs:glue_libs_4.0.0_image_01 -c '$${SPARK_HOME}/bin/spark-class org.apache.spark.deploy.history.HistoryServer'

shell:
	docker run --rm -it -w /home/glue_user/workspace/scripts -v ${PWD}:/home/glue_user/workspace/scripts amazon/aws-glue-libs:glue_libs_4.0.0_image_01