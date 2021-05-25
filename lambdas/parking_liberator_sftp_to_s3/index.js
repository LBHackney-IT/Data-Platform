const AWS = require("aws-sdk");
const sftpClient = require('ssh2-sftp-client');

const AWS_REGION = "eu-west-2";

let s3Bucket = process.env.S3_BUCKET;
let config = {
  host: process.env.SFTP_HOST,
  username: process.env.SFTP_USERNAME,
  password: process.env.SFTP_PASSWORD,
  port: 22
};

async function findFile(conn, filePath) {
  const today = new Date();
  const year = today.getFullYear().toString().substring(2, 4);
  const month = (today.getMonth() + 1).toString().padStart(2, '0')
  const day = today.getDate().toString().padStart(2, '0');

  return conn.exists(filePath)
    .then(() => {
      const patternToLookFor = `data_warehouse${year}${month}${day}*`;
      console.log(`Looking for pattern ${patternToLookFor}`)

      return conn.list(filePath, patternToLookFor);
    })
    .then((fileList) => {
      if(fileList.length === 0){
        console.log("couldn't find any files")
        throw Error("no file exists today")
      }
      if (fileList.length > 1){
        // warn more than one file has been uploaded
        console.log("found more than one file")
        fileList.forEach((file, index) => {
          console.log(`File ${index + 1}: ${file.name}`);
        });
      }
      const fileName = fileList[0].name;
      console.log(`Found file: ${fileName}`)
      return {fileName: fileName};
    })
    .catch(err => {
      console.log(`Error: ${err.message}`);
    });;
}

async function putFile(fileName, fileStream) {
  const s3Client = new AWS.S3({region: AWS_REGION});
  console.log(`Putting file in ${s3Bucket} at key parking/${fileName}`)
  console.log("stream object", fileStream)

  const params = {
    Bucket: s3Bucket,
    Key: `parking/${fileName}`,
    Body: fileStream
  };

  return s3Client.putObject(params).promise()
}

exports.handler = async () => {
  const filePath = 'LogiXML'
  const sftp = new sftpClient();

  await sftp.connect(config)
    .then(() => {
      console.log("Connected...Finding file")
      return findFile(sftp, filePath);
    })
    .then(({ fileName }) => {
      console.log("getting file")
      return {
        fileStream: sftp.get(`${filePath}/${fileName}`),
        fileName: fileName
      }
    })
    .then(({ fileStream, fileName }) => {
      return putFile(fileName, fileStream)
    })
    .then((s3response) => {
      console.log("upload completed")
      console.log(`uploaded file ${fileName} into s3 bucket ${BUCKET_DESTINATION}`)
    })
    .then(() => {
      sftp.end();
    })
    .catch(err => {
      console.log(`Error: ${err.message}`);
    });
};
