const AWS = require("aws-sdk");

const AWS_REGION = "eu-west-2";

const iamRoleArn = process.env.IAM_ROLE_ARN;
const kmsKeyId = process.env.KMS_KEY_ID;
const s3BucketName = process.env.S3_BUCKET_NAME;
const copierQueueName = process.env.COPIER_QUEUE_ARN.split(':').pop();

async function queueMessage(queueName, messageBody, reason, delay = 60) {
  const sqsClient = new AWS.SQS({region: AWS_REGION});

  const getQueueUrlResponse = await sqsClient.getQueueUrl({
    QueueName: queueName
  }).promise();

  const newMsg = {
    QueueUrl: getQueueUrlResponse.QueueUrl,
    MessageBody: messageBody,
    DelaySeconds: delay
  }

  await sqsClient.sendMessage(newMsg).promise();
  console.log(reason + ', message queued:', newMsg);
}

exports.handler = async (event) => {
  console.log(event);

  const rdsClient = new AWS.RDS({region: AWS_REGION});

  await Promise.all(event.Records.map(async (record) => {

    const queueName = record.eventSourceARN.split(':').pop();

    let taskMarker = undefined;
    let exportTasks = [];
    do {
      const params = {
        Marker: taskMarker,
      };

      const response = await rdsClient.describeExportTasks(params).promise();

      exportTasks = exportTasks.concat(response.ExportTasks)

      taskMarker = response.Marker;
    } while (taskMarker);

    const runningTaskCount = exportTasks.filter(task => task.Status === 'STARTING').length

    if (runningTaskCount >= 5) {
      await queueMessage(
        queueName,
        record.body,
        'Too many export tasks still processing',
        300
      );
      return null;
    }

    let sqsMessage;
    try {
      const snsMessage = JSON.parse(record.body);
      sqsMessage = JSON.parse(snsMessage.Message);
      console.log("SQS Message:", sqsMessage);
    } catch (err) {
      console.log("event error:", err);
      console.log("sqs message:", sqsMessage);
      return null;
    }

    const dbSnapshotId = sqsMessage["Source ID"].split(':').pop();

    let snapshotMarker = undefined;
    let dbSnapshots = [];
    do {
      const describeDBSnapshotsParams = {
        DBInstanceIdentifier: dbSnapshotId,
        Marker: snapshotMarker,
      };

      const response = await rdsClient.describeDBSnapshots(describeDBSnapshotsParams).promise();
      console.log("Describe DB Snapshot (Page):", response);

      dbSnapshots = dbSnapshots.concat(response.DBSnapshots)

      snapshotMarker = response.Marker;
    } while (snapshotMarker);

    const found = dbSnapshots.find( ({ Status }) => Status === 'creating' );

    if (found) {
      await queueMessage(
        queueName,
        record.body,
        'Snapshot not ready'
      );
      return null;
    }

    const sortedDbSnapshots = dbSnapshots.sort((a, b) => {return a.SnapshotCreateTime - b.SnapshotCreateTime;});
    console.log('Sorted DB snapshots:', dbSnapshots);

    const latestSnapshot = sortedDbSnapshots.pop();
    console.log("Latest Snapshot:", latestSnapshot);

    const snapshotIdentifier = latestSnapshot.DBSnapshotIdentifier.replace(':', '-');
    console.log("New SnapshotIdentifier:", snapshotIdentifier);

    const databaseName = latestSnapshot.DBInstanceIdentifier;
    console.log("databaseName:", databaseName);

    const exportTaskIdentifier = snapshotIdentifier.substr(0, 60);

    const startExportTaskParams = {
      ExportTaskIdentifier: exportTaskIdentifier,
      IamRoleArn: iamRoleArn,
      KmsKeyId: kmsKeyId,
      S3BucketName: s3BucketName,
      SourceArn: latestSnapshot.DBSnapshotArn
    };

    let response;
    try {
      response = await rdsClient.startExportTask(startExportTaskParams).promise();
      console.log(response);
      await queueMessage(
        copierQueueName,
        JSON.stringify({
            ExportTaskIdentifier: exportTaskIdentifier,
            ExportBucket: s3BucketName
        }),
        'Export started',
        900
      );
    } catch (err) {
      console.log("startExportTask error:", err);
      return null;
    }
  }));
};
