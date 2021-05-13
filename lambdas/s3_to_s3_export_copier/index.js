const AWS = require("aws-sdk");

const AWS_REGION = "eu-west-2";

let bucketDestination = process.env.BUCKET_DESTINATION;

async function s3CopyFolder(s3Client, sourceBucketName, sourcePath, targetBucketName, targetPath) {
  console.log("sourceBucketName", sourceBucketName);
  console.log("targetBucketName", targetBucketName);
  console.log("sourcePath", sourcePath);
  console.log("targetPath", targetPath);
  console.log();

  // plan, list through the source, if got continuation token, recursive
  const listObjectsParams = {
    Bucket: sourceBucketName,
    Prefix: sourcePath
  };
  const listResponse = await s3Client.listObjectsV2(listObjectsParams).promise();

  //console.log("list response", listResponse);
  console.log("list response contents", listResponse.Contents);

  await Promise.all(
    listResponse.Contents.map(async (file) => {
      const copyObjectParams = {
        Bucket: targetBucketName,
        CopySource: `${sourceBucketName}/${file.Key}`,
        Key: `${targetPath}/${file.Key}`,
      };
      console.log(copyObjectParams)
      await s3Client.copyObject(copyObjectParams).promise().catch(console.log);
    })
  );
}

exports.handler = async (events) => {
  const rdsClient = new AWS.RDS({region: AWS_REGION});
  const s3Client = new AWS.S3({region: AWS_REGION});
  const sqsClient = new AWS.SQS({region: AWS_REGION});

  await Promise.all(
    events.Records.map(async (event) => {
      const message = JSON.parse(event.body);
      console.log("message.ExportTaskIdentifier", message.ExportTaskIdentifier);
      const describeExportTasks = await rdsClient.describeExportTasks({
        ExportTaskIdentifier: message.ExportTaskIdentifier
      }).promise();

      console.log("describeExportTasks", describeExportTasks);

      if (!describeExportTasks || !describeExportTasks.ExportTasks || describeExportTasks.ExportTasks.length === 0) {
        throw new Error('describeExportTasks or it\'s child ExportTasks is missing')
      }

      const exportTaskStatus = describeExportTasks.ExportTasks.pop();

      // Check to see if the export has finished
      if (exportTaskStatus.Status !== 'COMPLETE') {
        // If NOT then requeue the event with an extended delay
        console.log(event.eventSourceARN);

        const queueName = event.eventSourceARN.split(':').pop();

        const getQueueUrlResponse = await sqsClient.getQueueUrl({
          QueueName: queueName
        }).promise();

        console.log(getQueueUrlResponse);
        await sqsClient.sendMessage({
          QueueUrl: getQueueUrlResponse.QueueUrl,
          MessageBody: event.body,
          DelaySeconds: 300
        }).promise();
        return;
      }

      const sourceBucketName = message.ExportBucket
      const targetBucketName = bucketDestination;
      const pathPrefix = `${message.ExportTaskIdentifier}`;

      // If it has copy the files from s3 bucket A => s3 bucket B
      await s3CopyFolder(s3Client, sourceBucketName, pathPrefix, targetBucketName, 'joates-test-copy');
    })
  );
};