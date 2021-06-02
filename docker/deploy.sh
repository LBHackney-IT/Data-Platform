#!/bin/bash

ecr_url=$(terraform output -raw ecr_repository_worker_endpoint)

docker build -f ../docker/Dockerfile -t $ecr_url ../docker

aws ecr get-login-password --region eu-west-2 | docker login --username AWS --password-stdin $ecr_url

docker push $ecr_url
