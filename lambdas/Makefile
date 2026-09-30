.PHONY: test runtime-deps

# Runtime dependencies are installed inside the Lambda base image, so pip only
# picks wheels the runtime can load. The image has no compiler, so a version
# needing a native build fails here rather than on import in AWS.
PYTHON_VERSION := $(shell cut -d. -f1,2 .python-version)
LAMBDA_IMAGE := public.ecr.aws/lambda/python:$(PYTHON_VERSION)
DOCKER_RUN ?= docker run
RUNTIME_REQUIREMENTS := $(wildcard */requirements.runtime.txt)

.venv/bin/python:
	python3 -m venv .venv

.venv/.install.stamp: .venv/bin/python requirements.test.txt
	.venv/bin/python -m pip install -r requirements.test.txt
	touch .venv/.install.stamp

test: .venv/.install.stamp
	.venv/bin/python -m unittest */test.py

runtime-deps: $(RUNTIME_REQUIREMENTS:requirements.runtime.txt=lib)

%/lib: %/requirements.runtime.txt
	rm -rf $@
	$(DOCKER_RUN) --rm --user "$$(id -u):$$(id -g)" -e HOME=/tmp --entrypoint pip \
		-v "$(CURDIR)/$*:/var/task:z" -w /var/task $(LAMBDA_IMAGE) \
		install --no-cache-dir --no-compile --prefer-binary \
		--target lib -r requirements.runtime.txt
