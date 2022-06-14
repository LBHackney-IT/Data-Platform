#!/bin/bash

set -ex

lambda_name=$1

(cd ~/lambdas/"$lambda_name"/ && make -f Makefile)