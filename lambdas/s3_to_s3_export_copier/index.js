const AWS = require("aws-sdk");

const AWS_REGION = "eu-west-2";

const bucketDestination = process.env.BUCKET_DESTINATION;
const targetServiceArea = process.env.SERVICE_AREA;
const workflowName = process.env.WORKFLOW_NAME

async function s3CopyFolder(s3Client, sourceBucketName, sourcePath, targetBucketName, targetPath, snapshotTime) {
  console.log("sourceBucketName", sourceBucketName);
  console.log("targetBucketName", targetBucketName);
  console.log("sourcePath", sourcePath);
  console.log("targetPath", targetPath);
  console.log();

  // plan, list through the source, if got continuation token, recursive

  let listResponse;
  do {
    const listObjectsParams = {
      Bucket: sourceBucketName,
      Prefix: sourcePath,
      ContinuationToken: listResponse?.NextContinuationToken
    };
    console.log("continuation token", listResponse?.NextContinuationToken);

    listResponse = await s3Client.listObjectsV2(listObjectsParams).promise();

    const day = (snapshotTime.getDate() < 10 ? '0' : '') + snapshotTime.getDate();
    const month = ((snapshotTime.getMonth() + 1) < 10 ? '0' : '') + (snapshotTime.getMonth() + 1);
    const year = snapshotTime.getFullYear();

    console.log("list response contents", listResponse.Contents);

    await Promise.all(
      listResponse.Contents.map(async (file) => {
        if (!file.Key.endsWith("parquet")) {
          return;
        }
        const [snapShotName, databaseName, tableName] = file.Key.split("/", 3);

        const fileName = file.Key.substr(`${snapShotName}/${databaseName}/${tableName}`.length + 1);
        console.log("fileName====", fileName);
        const copyObjectParams = {
          Bucket: targetBucketName,
          CopySource: `${sourceBucketName}/${file.Key}`,
          Key: `${targetPath}/${databaseName}/${tableName}/import_year=${year}/import_month=${month}/import_day=${day}/${fileName}`,
          ACL: "bucket-owner-full-control",
        };
        console.log("copyObjectParams", copyObjectParams)

        await s3Client.copyObject(copyObjectParams).promise().catch(console.log);
      })
    );
  } while (listResponse.IsTruncated && listResponse.NextContinuationToken)
}

async function startWorkflowRun(workflowName) {
  const glue = new AWS.Glue({apiVersion: '2017-03-31'});
  const params = {
    Name: workflowName
  };
  console.log("starting workflow run with params", params)

  await glue.startWorkflowRun(params).promise();
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

      // Don't re-queue if status is cancelled
      if (exportTaskStatus.Status === 'CANCELED') {
        return;
      }

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
      const snapshotTime = exportTaskStatus.SnapshotTime;

      // If it has copy the files from s3 bucket A => s3 bucket B
      await s3CopyFolder(s3Client, sourceBucketName, pathPrefix, targetBucketName, targetServiceArea, snapshotTime);
    })
    )

    if (workflowName) {
      return await startWorkflowRun(workflowName);
    }
};
