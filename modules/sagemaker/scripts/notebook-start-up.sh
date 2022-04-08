#!/bin/bash
set -ex

mkdir -p /home/ec2-user/glue
cd /home/ec2-user/glue

# Write dev endpoint in a file which will be used by daemon scripts
glue_endpoint_file="/home/ec2-user/glue/glue_endpoint.txt"

if [ -f $glue_endpoint_file ] ; then
    rm $glue_endpoint_file
fi
echo "https://glue.eu-west-2.amazonaws.com" >> $glue_endpoint_file

ASSETS=s3://aws-glue-jes-prod-eu-west-2-assets/sagemaker/assets/

aws s3 cp $ASSETS . --recursive \
    --include "*autossh-1.4e.tgz" \
    --include "*lifecycle-config-v2-dev-endpoint-daemon.sh" \
    --include "*lifecycle-config-reconnect-dev-endpoint-daemon.sh" \
    --include "*dev_endpoint_connection_checker.py"

wget "https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh" -O /home/ec2-user/glue/Miniconda3-latest-Linux-x86_64.sh
bash "/home/ec2-user/glue/Miniconda3-latest-Linux-x86_64.sh" -b -u -p "/home/ec2-user/glue/miniconda"

source "/home/ec2-user/glue/miniconda/bin/activate"

tar -xf autossh-1.4e.tgz
cd autossh-1.4e
./configure
make
sudo make install
sudo cp -u /home/ec2-user/glue/autossh.conf /etc/init/

# Saving sparkmagic config file to server
mkdir -p /home/ec2-user/.sparkmagic

cat > /home/ec2-user/.sparkmagic/config.json << 'EOF'
${sparkmagicconfig}
EOF


# Preparing glue development endpoint configuration
cat > /home/ec2-user/endpoint_config.json << 'EOF'
${glueendpointconfig}
EOF

endpoint_config=/home/ec2-user/endpoint_config.json

endpoint_name=$(jq -r .endpoint_name $endpoint_config)
extra_python_libs_s3_path=$(jq -r .extra_python_libs_s3_path $endpoint_config)
extra_jars_s3_path=$(jq -r .extra_jars_s3_path $endpoint_config)
worker_type=$(jq -r .worker_type $endpoint_config)
number_of_workers=$(jq -r .number_of_workers $endpoint_config)
role_arn=$(jq -r .role_arn $endpoint_config)
public_keys=$(jq -r .public_key $endpoint_config)

# check if Sagemaker can find the development endpoint, create the dev endpoint if not
{
    aws glue get-dev-endpoint --endpoint-name $endpoint_name --endpoint https://glue.eu-west-2.amazonaws.com 
} || {
    aws glue create-dev-endpoint --endpoint-name $endpoint_name \
    --role-arn $role_arn \
    --public-keys $public_key \
    --number-of-workers $number_of_workers \
    --extra-python-libs-s3-path $extra_python_libs_s3_path \
    --extra-jars-s3-path $extra_jars_s3_path \
    --worker-type $worker_type \
    --glue-version "1.0" \
    --arguments '{"--enable-glue-datacatalog": "true","GLUE_PYTHON_VERSION": "3"}'
}

# Run daemons as cron jobs and use flock make sure that daemons are started only iff stopped
(crontab -l; echo "* * * * * /usr/bin/flock -n /tmp/lifecycle-config-v2-dev-endpoint-daemon.lock /usr/bin/sudo /bin/sh /home/ec2-user/glue/lifecycle-config-v2-dev-endpoint-daemon.sh 2>&1 | tee -a /var/log/sagemaker-lifecycle-config-v2-dev-endpoint-daemon.log") | crontab -

(crontab -l; echo "* * * * * /usr/bin/flock -n /tmp/lifecycle-config-reconnect-dev-endpoint-daemon.lock /usr/bin/sudo /bin/sh /home/ec2-user/glue/lifecycle-config-reconnect-dev-endpoint-daemon.sh 2>&1 | tee -a /var/log/sagemaker-lifecycle-config-reconnect-dev-endpoint-daemon.log") | crontab -


CONNECTION_CHECKER_FILE=/home/ec2-user/glue/dev_endpoint_connection_checker.py
if [ -f "$CONNECTION_CHECKER_FILE" ]; then
    # wait for async dev endpoint connection to come up
    echo "Checking DevEndpoint connection."
    python3 $CONNECTION_CHECKER_FILE
fi

rm -rf "/home/ec2-user/glue/Miniconda3-latest-Linux-x86_64.sh"
