CONTAINER_NAME := lambda_$(LAYER_FILE)_docker
DOCKER_IMAGE := aws_lambda_$(LAYER_FILE)
LAYER_NUMBER := $(patsubst layer%.zip,%,$(LAYER_FILE))
.PHONY: build run copy

all: copy clean

build: 
	docker build --build-arg L_N=$(LAYER_NUMBER) -t $(DOCKER_IMAGE) .

run: build
	docker run --name $(CONTAINER_NAME) -d $(DOCKER_IMAGE) env

copy: run
	docker cp $(CONTAINER_NAME):/app/$(LAYER_FILE) ./$(LAYER_FILE)

stop: 
	docker stop $(CONTAINER_NAME)

clean: stop
	docker rm $(CONTAINER_NAME)