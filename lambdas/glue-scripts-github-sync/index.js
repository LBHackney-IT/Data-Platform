const AWS = require("aws-sdk");
const fs = require("fs/promises");
const { execSync } = require("child_process");
const path = require("path");

const AWS_REGION = 'eu-west-2';
const tempDirectory = process.env.TEMP_DIR || "/tmp/lambda";

const directoryExists = async (directoryPath) => {
  try {
    await fs.access(directoryPath);
    return true;
  } catch (error) {
    return false;
  }
};

const cloneRepo = async (directory) => {
  const awsSecretClient = new AWS.SecretsManager({ region: AWS_REGION });
  const key = await awsSecretClient
    .getSecretValue({ SecretId: "ben_lambda_key" })
    .promise();
  await fs.writeFile(`${directory}/id_rsa`, key.SecretString + '\n');

  execSync(`ssh-keyscan github.com >> ${directory}/githubKey`);
  execSync(`ssh-keygen -lf ${directory}/githubKey`);
  execSync(`chmod 600 ${directory}/id_rsa`, {
    encoding: "utf8",
    stdio: "inherit",
  });

  process.env.HOME = directory;
  process.env.GIT_SSH_COMMAND = `ssh -o UserKnownHostsFile=${directory}/githubKey -i ${directory}/id_rsa -v`;

  execSync(
    `git clone --depth 1 git@github.com:LBHackney-IT/data-platform.git -b temp_branch ${directory}/repo`,
    { encoding: "utf8", stdio: "inherit" }
  );
};

const commitCustomScripts = (directory) => {
  try {
    execSync(`git -C ${directory}/repo add scripts/custom/\*`, {
      encoding: "utf8",
      stdio: "inherit",
    });
    execSync(`git -C ${directory}/repo commit -m "update script"`, {
      encoding: "utf8",
      stdio: "inherit",
    });
    execSync(`git -C ${directory}/repo push`, {
      encoding: "utf8",
      stdio: "inherit",
    });
  } catch (error) {
    console.log(`Error committing custom scripts ${error}`);
    throw error;
  }
};

exports.handler = async (events) => {
  if (await directoryExists(tempDirectory)) {
    await fs.rmdir(tempDirectory, { recursive: true });
  }

  await fs.mkdir(tempDirectory);

  await cloneRepo(tempDirectory);

  const awsS3Client = new AWS.S3({ region: AWS_REGION });
  for (const eventRecord of events.Records) {
    const bucketName = eventRecord.s3.bucket.name;
    const fileKey = decodeURIComponent(
      eventRecord.s3.object.key.replace(/\+/g, " ")
    );
    const params = {
      Bucket: bucketName,
      Key: fileKey,
    };
    if (
      fileKey.toLowerCase().substr(0, 7) == "scripts/" ||
      fileKey.toLowerCase().endsWith(".temp")
    ) {
      continue;
    }
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
  commitCustomScripts(tempDirectory);
};
