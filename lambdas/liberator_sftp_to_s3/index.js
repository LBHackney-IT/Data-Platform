const AWS = require("aws-sdk");
const sftpClient = require('ssh2-sftp-client');
const { PassThrough } = require("stream");

const AWS_REGION = "eu-west-2";

let s3Bucket = process.env.S3_BUCKET;
let objectKeyPrefix = process.env.OBJECT_KEY_PREFIX;
let config = {
  host: process.env.SFTP_HOST,
  username: process.env.SFTP_USERNAME,
  password: process.env.SFTP_PASSWORD,
  port: 22
};

const filePathOnServer = 'LogiXML'

const YYMMDD = () => {
  const today = new Date();
  const year = today.getFullYear().toString().substring(2, 4);
  const month = (today.getMonth() + 1).toString().padStart(2, '0')
  const day = today.getDate().toString().padStart(2, '0');
  return `${year}${month}${day}`;
}

const fileNamePattern = `data_warehouse${YYMMDD()}*`;

async function findFiles(sftpConn) {
  return sftpConn.exists(filePathOnServer)
    .then(() => {
      console.log(`Looking for pattern ${fileNamePattern} in path ${filePathOnServer}`)

      return sftpConn.list(filePathOnServer, fileNamePattern);
    })
    .then((fileList) => {
      if(fileList.length === 0){
        console.log("couldn't find any files")
        throw Error("no files were found matching the given pattern")
      }
      const fileNames = fileList.map(file => file.name);
      console.log("Found files: ", fileNames)
      return { files: fileNames };
    })
    .catch(err => {
      console.log(`Error: ${err.message}`);
    });
}

function putFile(fileName) {
  const s3Client = new AWS.S3({region: AWS_REGION});
  const stream = new PassThrough();

  const params = {
    Bucket: s3Bucket,
    Key: `${objectKeyPrefix}${fileName}`,
    Body: stream
  };
  const upload = s3Client.upload(params, (err, data) => (err ? reject(err) : resolve(data)));

  return { stream, upload }
}

function getFile(sftpConn, fileName, filePath, stream) {
  return sftpConn.get(`${filePath}/${fileName}`, stream)
}

async function streamFileFromSftpToS3(sftp, fileName) {
  const {stream, upload} = putFile(fileName);
  getFile(sftp, fileName, filePathOnServer, stream);

  return upload.promise()
    .then(response => {
      console.log("Successfully upload to S3 with response:", response)
    })
    .catch(err => {
      console.log("Error", err.message);
    });
}

exports.handler = async () => {
  const sftp = new sftpClient();

  return await sftp.connect(config)
  .then(() => {
    console.log("Connected to server...Looking for todays file")
    return findFiles(sftp);
  })
  .then(({ files }) => {
    return Promise.all(files.map(file => streamFileFromSftpToS3(sftp, file)));
  })
  .then(() => sftp.end())
  .catch(err => {
    console.log("Error", err.message);
  });
};


