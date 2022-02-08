#!/bin/bash
set -ex
[ -e /home/ec2-user/glue_ready ] && exit 0

mkdir -p /home/ec2-user/glue
cd /home/ec2-user/glue

# Write dev endpoint in a file which will be used by daemon scripts
glue_endpoint_file="/home/ec2-user/glue/glue_endpoint.txt"

if [ -f $glue_endpoint_file ] ; then
    rm $glue_endpoint_file
fi
echo "https://glue.eu-west-2.amazonaws.com" >> $glue_endpoint_file

ASSETS=s3://aws-glue-jes-prod-eu-west-2-assets/sagemaker/assets/

aws s3 cp $ASSETS . --recursive

bash "/home/ec2-user/glue/Miniconda2-4.5.12-Linux-x86_64.sh" -b -u -p "/home/ec2-user/glue/miniconda"

source "/home/ec2-user/glue/miniconda/bin/activate"

tar -xf autossh-1.4e.tgz
cd autossh-1.4e
./configure
make
sudo make install
sudo cp /home/ec2-user/glue/autossh.conf /etc/init/

mkdir -p /home/ec2-user/.sparkmagic
cp /home/ec2-user/glue/config.json /home/ec2-user/.sparkmagic/config.json

mkdir -p /home/ec2-user/SageMaker/Glue\ Examples
mv /home/ec2-user/glue/notebook-samples/* /home/ec2-user/SageMaker/Glue\ Examples/

# ensure SageMaker notebook has permission for the dev endpoint
aws glue get-dev-endpoint --endpoint-name ${glueendpoint} --endpoint https://glue.eu-west-2.amazonaws.com

# Run daemons as cron jobs and use flock make sure that daemons are started only iff stopped
(crontab -l; echo "* * * * * /usr/bin/flock -n /tmp/lifecycle-config-v2-dev-endpoint-daemon.lock /usr/bin/sudo /bin/sh /home/ec2-user/glue/lifecycle-config-v2-dev-endpoint-daemon.sh 2>&1 | tee -a /var/log/sagemaker-lifecycle-config-v2-dev-endpoint-daemon.log") | crontab -

(crontab -l; echo "* * * * * /usr/bin/flock -n /tmp/lifecycle-config-reconnect-dev-endpoint-daemon.lock /usr/bin/sudo /bin/sh /home/ec2-user/glue/lifecycle-config-reconnect-dev-endpoint-daemon.sh 2>&1 | tee -a /var/log/sagemaker-lifecycle-config-reconnect-dev-endpoint-daemon.log") | crontab -

CONNECTION_CHECKER_FILE=/home/ec2-user/glue/dev_endpoint_connection_checker.py
if [ -f "$CONNECTION_CHECKER_FILE" ]; then
    # wait for async dev endpoint connection to come up
    echo "Checking DevEndpoint connection."
    python3 $CONNECTION_CHECKER_FILE
fi

source "/home/ec2-user/glue/miniconda/bin/deactivate"

rm -rf "/home/ec2-user/glue/Miniconda2-4.5.12-Linux-x86_64.sh"

sudo touch /home/ec2-user/glue_ready