const AWS = require("aws-sdk");
const sftpClient = require("ssh2-sftp-client");
const { PassThrough } = require("stream");
const { DateTime, Settings } = require("luxon");

const AWS_REGION = "eu-west-2";

const s3Bucket = process.env.S3_BUCKET;
const s3TargetFolder = process.env.S3_TARGET_FOLDER;
let sftpFilePath = process.env.SFTP_TARGET_FILE_PATH; 
let sftpSourceFilePrefix = process.env.SFTP_SOURCE_FILE_PREFIX;
const sftpSourceFileExtension = process.env.SFTP_SOURCE_FILE_EXTENSION;

const config = {
  host: process.env.SFTP_HOST,
  username: process.env.SFTP_USERNAME,
  password: process.env.SFTP_PASSWORD,
  port: 22
};

let fileNamePattern = "";
let year;
let month;
let day;
let date;

async function getImportDate(manualOverrideDateString)
{
  let dateToImport = new Date();

  if(manualOverrideDateString)
  {
    //throw exception if invalid date or date format is detected
    Settings.throwOnInvalid = true;
    DateTime.fromISO(manualOverrideDateString);

    let parts = manualOverrideDateString.split('-');
    dateToImport = new Date(parts[0], parts[1] - 1, parts[2]); 
  }

  year = dateToImport.getFullYear().toString();
  month = (dateToImport.getMonth() + 1).toString().padStart(2, '0');
  day = dateToImport.getDate().toString().padStart(2, '0');
  date = `${year}-${month}-${day}`

  fileNamePattern = `${sftpSourceFilePrefix}${date}`;
}

async function findFiles(sftpConn) {
  console.log(`filepath on server: ${sftpFilePath}`)
  
  const validPath = await sftpConn.exists(sftpFilePath);
  
  if (!validPath) {
    return {
      success: false,
      message: `Path ${sftpFilePath} doesn't exist on SFTP server`,
      fileNames: []
    };
  }

  console.log("filename pattern" + fileNamePattern);

  const fileList = await sftpConn.list(
    //set path
    sftpFilePath,
    //filter files by given pattern
    function filterByFileNamePattern(file) 
    {
      let name = file.name.toLowerCase();
      return name.includes(fileNamePattern.toLowerCase());
    }
  );

  if (fileList.length === 0) {
    return {
      success: false,
      message: `no files were found matching the pattern ${fileNamePattern} in path ${sftpFilePath}`,
      fileNames: [],
    };
  }
  
  const fileNames = fileList.filter(file => file.type != 'd').map(file => file.name);
  console.log(fileNames);
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
    Key: `${s3TargetFolder}/import_year=${year}/import_month=${month}/import_day=${day}/import_date=${date}/${sftpSourceFilePrefix}${date}.${sftpSourceFileExtension}`
  };
  try {
    await s3Client.headObject(params).promise();
    return true;
  } catch (error) {
    console.log(`Today's ${s3TargetFolder} file not yet present in S3 bucket, retrieving file from SFTP`)
    return false;
  }
}

function putFile() {
  const s3Client = new AWS.S3({ region: AWS_REGION });
  const stream = new PassThrough();
  const params = {
    Bucket: s3Bucket,
    Key: `${s3TargetFolder}/import_year=${year}/import_month=${month}/import_day=${day}/import_date=${date}/${sftpSourceFilePrefix}${date}.${sftpSourceFileExtension}`,
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
  getFile(sftp, fileName, sftpFilePath, stream);

  const response = await upload.promise();
  console.log("Successfully upload to S3 with response:", response);
}

exports.handler = async (event) => {
  
  let manualOverrideDateString = event['DateToImport'];
 
  console.log(`Manual override date: ${manualOverrideDateString}`);
 
  getImportDate(manualOverrideDateString);
 
  const sftp = new sftpClient();

  if (await checkS3ForFile()) {
    console.log(`Today's ${s3TargetFolder} file is already present in S3 bucket!`);
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
    console.error(error.message);
  } finally {
    await sftp.end();
  }
}
