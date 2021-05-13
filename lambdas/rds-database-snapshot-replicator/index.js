const AWS = require("aws-sdk");

const AWS_REGION = "eu-west-2";

let iamRoleArn = process.env.IAM_ROLE_ARN;
let kmsKeyId = process.env.KMS_KEY_ID;
let s3BucketName = process.env.S3_BUCKET_NAME;

async function returnMessageToQueue(eventSourceARN, messageBody, reason, sqsClient, delay = 60) {
  const queueName = eventSourceARN.split(':').pop();

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
  const sqsClient = new AWS.SQS({region: AWS_REGION});

  await Promise.all(event.Records.map(async (record) => {
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
      await returnMessageToQueue(
        record.eventSourceARN,
        record.body,
        'Too many export tasks still processing',
        sqsClient,
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
      await returnMessageToQueue(
        record.eventSourceARN,
        record.body,
        'Snapshot not ready',
        sqsClient
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

    const startExportTaskParams = {
      ExportTaskIdentifier: snapshotIdentifier.substr(0, 60),
      IamRoleArn: iamRoleArn,
      KmsKeyId: kmsKeyId,
      S3BucketName: s3BucketName,
      SourceArn: latestSnapshot.DBSnapshotArn
    };

    let response;
    try {
      response = await rdsClient.startExportTask(startExportTaskParams).promise();
      console.log(response);
    } catch (err) {
      console.log("startExportTask error:", err);
      return null;
    }
  }));
};
