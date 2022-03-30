#!/bin/bash

set -e

source_path="$1" # 1st argument from command line
repository_url="$2" # 2nd argument from command line
image_name=$(cd "$source_path" && basename "$(pwd)")

# splits string using '.' and picks 4th item
region="$(echo "$repository_url" | cut -d. -f4)"

# builds docker image
(cd "$source_path" && docker build -t "$image_name" .)

# login to ecr
aws ecr get-login-password --region "$region" | docker login --username AWS --password-stdin "$repository_url"

# tag image
docker tag "$image_name" "$repository_url":latest

# push image
docker push "$repository_url":latest