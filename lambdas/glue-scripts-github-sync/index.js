const AWS = require("aws-sdk");
const fs = require("fs/promises");
const { execSync } = require("child_process");
const path = require("path");
const tempDirectory = process.env.TEMP_DIR || "/tmp";
const awsSecretClient = new AWS.SecretsManager({region: "eu-west-2"});

async function directoryExists(directoryPath) {
  try {
    await fs.access(directoryPath);
    return true;
  } catch (error) {
    return false;
  }
}

async function cloneRepo(directory){
  const key = await awsSecretClient.getSecretValue({SecretId: "ben_lambda_key"}).promise();
  execSync(`ssh-keyscan github.com >> ${directory}/githubKey`)
  execSync(`ssh-keygen -lf ${directory}/githubKey`)
  // await fs.writeFile(`${directory}/known_hosts`, 'github.com,192.30.252.*,192.30.253.*,192.30.254.*,192.30.255.* ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAq2A7hRGmdnm9tUDbO9IDSwBK6TbQa+PXYPCPy6rbTrTtw7PHkccKrpp0yVhp5HdEIcKr6pLlVDBfOLX9QUsyCOV0wzfjIJNlGEYsdlLJizHhbn2mUjvSAHQqZETYP81eFzLQNnPHt4EVVUh7VfDESU84KezmD5QlWpXLmvU31/yMf+Se8xhHTvKSCZIFImWwoG6mbUoWf9nzpIoaSjB+weqqUUmpaaasXVal72J+UX2B+2RPW3RcT0eOzQgqlJL3RKrTJvdsjE3JEAvGq3lGHSZXy28G3skua2SmVi/w4yCE6gbODqnTWlg7+wC604ydGXA8VJiS5ap43JXiUFFAaQ==')

  await fs.writeFile(`${directory}/id_rsa`, key.SecretString)
  execSync(`chmod 400 ${directory}/id_rsa`, { encoding: 'utf8', stdio: 'inherit' })

  process.env.GIT_SSH_COMMAND = `ssh -o UserKnownHostsFile=${directory}/githubKey -i ${directory}/id_rsa`

  execSync(`git clone --depth 1 git@github.com:LBHackney-IT/data-platform.git -b temp_branch ${directory}/repo`, { encoding: 'utf8', stdio: 'inherit' })

}

exports.handler = async (events) => {
  if (await directoryExists(tempDirectory)) {
    await fs.rmdir(tempDirectory, { recursive: true });
  }

  await fs.mkdir(tempDirectory);

  await cloneRepo(tempDirectory);

  const awsS3Client = new AWS.S3({ region: "eu-west-2" });
  for(const eventRecord of events.Records){
    const bucketName = eventRecord.s3.bucket.name;
    const fileKey = decodeURIComponent(
      eventRecord.s3.object.key.replace(/\+/g, " ")
    );
    const params = {
      Bucket: bucketName,
      Key: fileKey,
    };
    try {
      const s3Object = await awsS3Client.getObject(params).promise();
      if (!s3Object.Body) {
        continue;
      }
      const filePath = `${tempDirectory}/repo/scripts/custom/${fileKey}`;
      const directoryPath = path.dirname(filePath);
      if (!(await directoryExists(directoryPath))) {
        await fs.mkdir(directoryPath, { recursive: true });
      }
      await fs.writeFile(filePath, s3Object.Body);
      console.log(`File ${filePath} downloaded`);
    } catch (err) {
      console.log(err);
      throw err;
    }
  }

  execSync(`git -C ${tempDirectory}/repo add scripts/custom/\*`, { encoding: 'utf8', stdio: 'inherit' });
  execSync(`git -C ${tempDirectory}/repo commit -m "update script"`, { encoding: 'utf8', stdio: 'inherit' });
  execSync(`git -C ${tempDirectory}/repo push`, { encoding: 'utf8', stdio: 'inherit' });
};
