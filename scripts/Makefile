.PHONY: $(MAKECMDGOALS)

filename ?= ""
test:
	docker run --rm -p "4040:4040" -w /root/scripts -v ${PWD}:/root/scripts amazon/aws-glue-libs:glue_libs_1.0.0_image_01 /home/aws-glue-libs/bin/gluepytest ./${filename} --durations=0

test-watch:
	docker run --rm -p "4040:4040" -w /root/scripts -v ${PWD}:/root/scripts amazon/aws-glue-libs:glue_libs_1.0.0_image_01 bash -c 'pip install pytest-watch && pytest-watch ./${filename}'

history-server:
	docker run --rm -p "18080:18080" -v ${PWD}/spark_events:/tmp/spark-events amazon/aws-glue-libs:glue_libs_1.0.0_image_01 bash -c '$${SPARK_HOME}/bin/spark-class org.apache.spark.deploy.history.HistoryServer'

shell:
	docker run --rm -it -w /root/scripts -v ${PWD}:/root/scripts amazon/aws-glue-libs:glue_libs_1.0.0_image_01 bash
