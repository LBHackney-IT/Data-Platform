CONTAINER_NAME := lambda_layer_docker$(shell cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 5 | head -n 1)
DOCKER_IMAGE := aws_lambda_layer

.PHONY: build run copy

all: copy clean

build: 
	docker build -t $(DOCKER_IMAGE) .

run: build
	docker run --name $(CONTAINER_NAME) -d $(DOCKER_IMAGE)

copy: run
	docker cp $(CONTAINER_NAME):/app/layer1.zip ./layer1.zip
	docker cp $(CONTAINER_NAME):/app/layer2.zip ./layer2.zip
	docker cp $(CONTAINER_NAME):/app/layer3.zip ./layer3.zip
	docker cp $(CONTAINER_NAME):/app/layer4.zip ./layer4.zip
	docker cp $(CONTAINER_NAME):/app/layer5.zip ./layer5.zip
	docker cp $(CONTAINER_NAME):/app/layer6.zip ./layer6.zip
stop: 
	docker stop $(CONTAINER_NAME)

clean: stop
	docker rm $(CONTAINER_NAME)
