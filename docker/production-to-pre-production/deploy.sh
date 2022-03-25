#!/bin/bash
set -eu -o pipefail

if [[ $ENVIRONMENT != "prod" ]]
then
    echo "Exiting as not in production environment"
    exit 0;
fi

script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

terraform_dir="${script_dir}/../../terraform"
ecr_url=$(AWS_PROFILE="" terraform -chdir=${terraform_dir} output -raw raw_zone_prod_to_pre_prod_ecr_repository_endpoint -raw landing_zone_prod_to_pre_prod_ecr_repository_endpoint -raw refined_zone_prod_to_pre_prod_ecr_repository_endpoint)

docker build -f ${script_dir}/Dockerfile -t ${ecr_url} ${script_dir}

aws ecr get-login-password --region eu-west-2 | docker login --username AWS --password-stdin $ecr_url

docker push $ecr_url
