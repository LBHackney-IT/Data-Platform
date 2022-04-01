#!/bin/bash

set -ex

image_name=$1
image_tag=$2
ecr_url=$3

docker pull "$image_name":"$image_tag"

aws ecr get-login-password --region eu-west-2 | docker login --username AWS --password-stdin "$ecr_url"

docker tag "$image_name" "$ecr_url"/"$image_name":"$image_tag"
docker push "$ecr_url"/"$image_name":"$image_tag"