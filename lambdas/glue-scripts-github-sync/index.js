const AWS = require("aws-sdk");
const fs = require('fs');
const { execSync } = require('child_process');

const tempDirectory = process.env.TEMP_DIR || "/tmp";
console.log(tempDirectory);
exports.handler = async (event) => {
    const awsSecretClient = new AWS.SecretsManager({region: "eu-west-2"});
    const key = await awsSecretClient.getSecretValue({SecretId: "ben_lambda_key"}).promise();
    execSync(`rm -rf ${tempDirectory}/*`, { encoding: 'utf8', stdio: 'inherit' })

    if (!fs.existsSync(tempDirectory)){
        fs.mkdirSync(tempDirectory);
    }
    fs.writeFileSync(`${tempDirectory}/known_hosts`, 'github.com,192.30.252.*,192.30.253.*,192.30.254.*,192.30.255.* ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAq2A7hRGmdnm9tUDbO9IDSwBK6TbQa+PXYPCPy6rbTrTtw7PHkccKrpp0yVhp5HdEIcKr6pLlVDBfOLX9QUsyCOV0wzfjIJNlGEYsdlLJizHhbn2mUjvSAHQqZETYP81eFzLQNnPHt4EVVUh7VfDESU84KezmD5QlWpXLmvU31/yMf+Se8xhHTvKSCZIFImWwoG6mbUoWf9nzpIoaSjB+weqqUUmpaaasXVal72J+UX2B+2RPW3RcT0eOzQgqlJL3RKrTJvdsjE3JEAvGq3lGHSZXy28G3skua2SmVi/w4yCE6gbODqnTWlg7+wC604ydGXA8VJiS5ap43JXiUFFAaQ==')

    fs.writeFileSync(`${tempDirectory}/id_rsa`, key.SecretString)
    execSync(`chmod 400 ${tempDirectory}/id_rsa`, { encoding: 'utf8', stdio: 'inherit' })

    
    process.env.GIT_SSH_COMMAND = `ssh -o UserKnownHostsFile=${tempDirectory}/known_hosts -i ${tempDirectory}/id_rsa`

    execSync(`git clone --depth 1 git@github.com:LBHackney-IT/data-platform.git -b terraform-setup ${tempDirectory}/glue-script`, { encoding: 'utf8', stdio: 'inherit' })

    const awsS3Client = new AWS.S3({region: "eu-west-2"});


    // awsS3Client.getBuck
    return execSync(`ls ${tempDirectory}/glue-script`, { encoding: 'utf8' }).split('\n')
};


