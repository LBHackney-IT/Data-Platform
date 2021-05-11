const AWS = require("aws-sdk");

const AWS_REGION = "eu-west-2";

let iamRoleArn = process.env.IAM_ROLE_ARN
let kmsKeyId = process.env.KMS_KEY_ID
let s3BucketName = process.env.S3_BUCKET_NAME

// Find newest back up

// Start export task to export Snapshot to S3 (using RDS instance?)

exports.handler = async (event) => {
  console.log(event);
  // TODO: check how many snapshots are currentlt being processed,
  //       if it's more than 5 return message back to queue
  event.Records.forEach( async (record) => {
    let sqsMessage;
      try {
        sqsMessage = JSON.parse(record.body.Message);
        console.log("sqs message:", sqsMessage);
      } catch (err) {
        console.log("event error:", err);
        console.log("sqs message:", sqsMessage);
        return;
      }
      const dbSnapshotId = sqsMessage["Source ID"];

      const rds = new AWS.RDS({ region: AWS_REGION });
      let marker = undefined;
      let dbSnapshots;

      do {
        const describeDBSnapshotsParams = {
          DBSnapshotIdentifier: dbSnapshotId,
          Marker: marker,
        };

        dbSnapshots = await rds.describeDBSnapshots(describeDBSnapshotsParams).promise();
        console.log("All Snapshot:", dbSnapshots);

        marker = dbSnapshots.Marker;
      } while (marker);

      const latestSnapshot = dbSnapshots.DBSnapshots.pop();
      console.log("Latest Snapshot:", latestSnapshot);

      const snapshotIdentifier = latestSnapshot.DBSnapshotIdentifier.replace(':', '-');
      console.log("new snapshotIdentifier:", snapshotIdentifier);

      const databaseName = latestSnapshot.DBInstanceIdentifier;
      console.log("databaseName:", databaseName);

      const startExportTaskParams = {
        ExportTaskIdentifier: snapshotIdentifier.substr(0, 60),
        IamRoleArn: iamRoleArn,
        KmsKeyId: kmsKeyId,
        S3BucketName: s3BucketName,
        SourceArn: latestSnapshot.DBSnapshotArn,
        S3Prefix: `${databaseName}/${snapshotIdentifier}`,
      };
      let response = await rds.startExportTask(startExportTaskParams).promise();
      console.log(response);
  });
};
