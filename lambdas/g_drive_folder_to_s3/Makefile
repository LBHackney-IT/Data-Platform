.PHONY: all build run zip stop clean

CONTAINER_NAME := lambda_docker
DOCKER_IMAGE := aws_lambda

# Commands
all: zip clean

build: 
	docker build -t $(DOCKER_IMAGE) .

run: build 
	docker run --name=$(CONTAINER_NAME) -d $(DOCKER_IMAGE) tail -f /dev/null

zip: run 
	docker cp $(CONTAINER_NAME):/app/source/g_drive_folder_to_s3.zip . 

stop: 
	docker stop $(CONTAINER_NAME)

clean: stop
	docker rm $(CONTAINER_NAME)
