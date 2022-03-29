#! /bin/bash

sudo yum update -y

# Install Docker
sudo amazon-linux-extras install docker
sudo service docker start
sudo usermod -a -G docker ec2-user

# Install JQ
sudo apt-get install jq.

# Install Docker Compose
# TODO Surface hardcoded version higher up the chain
sudo curl -L "https://github.com/docker/compose/releases/download/${docker_compose_version}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose

# Install Python
# TODO Surface hardcoded version higher up the chain
sudo apt-get update
sudo apt-get install python"${python_version}"

# Install DataHub python CLI
python3 -m pip install --upgrade pip wheel setuptools
python3 -m pip install --upgrade acryl-datahub
datahub version

# Deploy DataHub
datahub docker quickstart