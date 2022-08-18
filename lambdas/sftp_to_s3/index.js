const AWS = require("aws-sdk");
const sftpClient = require('ssh2-sftp-client');
const { PassThrough } = require("stream");

const AWS_REGION = "eu-west-2";

let s3Bucket = process.env.S3_BUCKET;
let objectKeyPrefix = process.env.OBJECT_KEY_PREFIX;
let filePathOnServer = process.env.TARGET_FILEPATH;
let sourceFilePrefix = process.env.SOURCE_FILE_PREFIX;
let targetFilePrefix = process.env.TARGET_FILE_PREFIX;
let config = {
  host: process.env.SFTP_HOST,
  username: process.env.SFTP_USERNAME,
  password: process.env.SFTP_PASSWORD,
  port: 22,
};

const getCurrentDate = () => {
  const today = new Date();
  const year = today.getFullYear().toString();
  const month = (today.getMonth() + 1).toString().padStart(2, '0');
  const day = today.getDate().toString().padStart(2, '0');
  return `${year}-${month}-${day}`;
}

const fileNamePattern = `${sourceFilePrefix}${getCurrentDate()}*`;

async function findFiles(sftpConn) {
  const validPath = await sftpConn.exists(filePathOnServer);
  if (!validPath) {
    return {
      success: false,
      message: `Path ${filePathOnServer} doesn't exist on SFTP server`,
      fileNames: []
    };
  }

  console.log(`Looking for pattern ${fileNamePattern} in path ${filePathOnServer}`);
  const fileList = await sftpConn.list(filePathOnServer, fileNamePattern);

  if (fileList.length === 0) {
    return {
      success: false,
      message: `no files were found matching the pattern ${fileNamePattern} in path ${filePathOnServer}`,
      fileNames: [],
    };
  }

  const fileNames = fileList.map(file => file.name);
  console.log("Found files: ", fileNames);
  return {
    success: true,
    fileNames,
    message: ""
  };
}

async function checkS3ForFile() {
  const s3Client = new AWS.S3({ region: AWS_REGION });
  const params = {
    Bucket: s3Bucket,
    Key: `${objectKeyPrefix}${targetFilePrefix}_dump_${getCurrentDate()}.zip`,
  };

  try {
    await s3Client.headObject(params).promise();
    return true;
  } catch (error) {
    console.log(`Today's ${targetFilePrefix} file not yet present in S3 bucket, retrieving file from SFTP`)
    return false;
  }
}

function putFile() {
  const s3Client = new AWS.S3({ region: AWS_REGION });
  const stream = new PassThrough();

  const params = {
    Bucket: s3Bucket,
    Key: `${objectKeyPrefix}${targetFilePrefix}_dump_${getCurrentDate()}.zip`,
    Body: stream
  };

  const upload = s3Client.upload(params);
  return { stream, upload };
}

function getFile(sftpConn, fileName, filePath, stream) {
  return sftpConn.get(`${filePath}/${fileName}`, stream);
}

async function streamFileFromSftpToS3(sftp, fileName) {
  const { stream, upload } = putFile();
  getFile(sftp, fileName, filePathOnServer, stream);

  const response = await upload.promise();
  console.log("Successfully upload to S3 with response:", response);
}

exports.handler = async () => {
  const sftp = new sftpClient();

  if (await checkS3ForFile()) {
    console.log(`Today's ${targetFilePrefix} file is already present in S3 bucket!`);
    return { success: true, message: `File already found in s3, no further action taken` };
}

  await sftp.connect(config);

  try {
    console.log("Connected to server...Looking for todays file");
    const findFilesResponse = await findFiles(sftp);

    if (!findFilesResponse.success) {
      console.log(findFilesResponse);
      return {
        success: findFilesResponse.success,
        message: findFilesResponse.message
      };
    }

    await Promise.all(findFilesResponse.fileNames.map(file => streamFileFromSftpToS3(sftp, file)));

    console.log("Success!");
    return { success: true, message: `Successfully uploaded ${findFilesResponse.fileNames.length} file(s) to s3` };
  } catch (error) {
    console.error(error.message, error.stack);
  } finally {
    await sftp.end();
  }
};
