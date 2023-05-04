#!/bin/bash
set -eu -o pipefail

if [[ $ENVIRONMENT != "stg" ]]
then
    echo "Exiting as not in pre-production environment"
    exit 0;
fi

script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

terraform_dir="${script_dir}/../../terraform/core"
ecr_url=$(AWS_PROFILE="" terraform -chdir=${terraform_dir} output -raw pre_prod_data_cleanup_ecr_repository_endpoint)

docker build -f ${script_dir}/Dockerfile -t ${ecr_url} ${script_dir}

aws ecr get-login-password --region eu-west-2 | docker login --username AWS --password-stdin $ecr_url

docker push $ecr_url
