#!/bin/bash
set -eu -o pipefail

script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

terraform_dir="${script_dir}/../../terraform"
ecr_url=$(AWS_PROFILE="" terraform -chdir=${terraform_dir} output -raw ecr_repository_worker_endpoint)

docker build -f ${script_dir}/Dockerfile -t ${ecr_url} ${script_dir}

aws ecr get-login-password --region eu-west-2 | docker login --username AWS --password-stdin $ecr_url

docker push $ecr_url
