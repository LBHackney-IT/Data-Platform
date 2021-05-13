const AWS = require("aws-sdk");

const AWS_REGION = "eu-west-2";

let iamRoleArn = process.env.IAM_ROLE_ARN;
let kmsKeyId = process.env.KMS_KEY_ID;
let s3BucketName = process.env.S3_BUCKET_NAME;

exports.handler = async (event) => {
  console.log(event);

  const rdsClient = new AWS.RDS({region: AWS_REGION});

  // TODO: check how many snapshots are currently being processed,
  //       if it's more than 5 return message back to queue
  await Promise.all(event.Records.map(async (record) => {
    let sqsMessage;
    try {
      const snsMessage = JSON.parse(record.body);
      sqsMessage = JSON.parse(snsMessage.Message);
      console.log("SQS Message:", sqsMessage);
    } catch (err) {
      console.log("event error:", err);
      console.log("sqs message:", sqsMessage);
      return;
    }
    const dbSnapshotId = sqsMessage["Source ID"].split(':').pop();

    let marker = undefined;
    let dbSnapshots;
    do {
      const describeDBSnapshotsParams = {
        DBInstanceIdentifier: dbSnapshotId,
        Marker: marker,
      };

      dbSnapshots = await rdsClient.describeDBSnapshots(describeDBSnapshotsParams).promise();
      console.log("Describe DB Snapshot (Page):", dbSnapshots);

      marker = dbSnapshots.Marker;
    } while (marker);

      // else order by SnapshotCreateTime: 2021-05-13T10:46:45.176Z, and get latest

    const found = dbSnapshots.DBSnapshots.find( ({ Status }) => Status === 'creating' );

    if (found) {
      // if there's a snapshot to be created, rescedule,
      return ''
    }
    dbSnapshots = dbSnapshots.sort((a, b) => {return a.SnapshotCreateTime - b.SnapshotCreateTime;});
    const latestSnapshot = dbSnapshots.DBSnapshots[0];
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
    let response = await rdsClient.startExportTask(startExportTaskParams).promise();
    console.log(response);
  }));
};
