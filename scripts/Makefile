.PHONY: $(MAKECMDGOALS)

test:
	docker run -v ${PWD}:/root/scripts amazon/aws-glue-libs:glue_libs_1.0.0_image_01 /home/aws-glue-libs/bin/gluepytest /root/scripts/
