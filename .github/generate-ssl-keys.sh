#!/bin/bash
set -eu -o pipefail

## Connecting to RedShift from Google Data Studio requires the user to provide an SSL client certificate.
## This script creates and uploads a certificate, and private key which fulfill these requirements.
## Thereby allowing us to point analysts at these instead of asking them to run `openssl` commands locally.
## More details on connecting to Google Data Studio with SSL enabled: https://stackoverflow.com/a/48994943

## Certificates are not currently being generated in the pipeline, but this script is here for reference should it be needed later on
## --acl parameter value changed to reflect bucket permissions update

script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

terraform_dir="${script_dir}/../terraform/core"

ssl_connection_resources_bucket_id=$(AWS_PROFILE="" terraform -chdir=${terraform_dir} output -raw ssl_connection_resources_bucket_id)

openssl req -newkey rsa:2048 -nodes -keyout client_private_key.key -x509 -days 365 -out client_certificate.crt \
  -subj "/CN=www.example.com"

aws s3 cp client_private_key.key s3://${ssl_connection_resources_bucket_id}/ --acl private
aws s3 cp client_certificate.crt s3://${ssl_connection_resources_bucket_id}/ --acl private
