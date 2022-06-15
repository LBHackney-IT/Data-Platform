#!/bin/bash

set -ex

lambda_name=$1

cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd && cd "../../lambdas/api_ingestion_lambdas/${lambda_name}/" && make -f Makefile
