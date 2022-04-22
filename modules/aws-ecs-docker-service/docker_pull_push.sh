#!/bin/bash

set -ex

image_name=$1
image_tag=$2
ecr_url=$3

#Pull image from docker hub
docker pull "$image_name":"$image_tag"

#Login to ECR
# shellcheck disable=SC2091
# shellcheck disable=SC2216
$(aws ecr get-login-password --region eu-west-2 | docker login --username AWS --password-stdin "$ecr_url") | true

#Tag image pulled from docker hub
docker tag "$image_name":"$image_tag" "$ecr_url":"$image_tag"

#Push tagged image to ECR
docker push "$ecr_url":"$image_tag"