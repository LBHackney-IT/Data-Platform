const AWS = require("aws-sdk");

const AWS_REGION = "eu-west-2";

let iamRoleArn = process.env.IAM_ROLE_ARN
let kmsKeyId = process.env.KMS_KEY_ID
let s3BucketName = process.env.S3_BUCKET_NAME

// Find newest back up

// Start export task to export Snapshot to S3 (using RDS instance?)

exports.handler = async (event) => {
  let sqsMessage;
    try {
      sqsMessage = JSON.parse(event.Message);
      console.log("sqs message:", sqsMessage);
    } catch (err) {
      console.log("event error:", err);
      console.log("sqs message:", sqsMessage);
      return;
    }
    const dbSnapshotId = sqsMessage["Source ID"];

    const rds = new AWS.RDS({ region: AWS_REGION });
    let marker;
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

    const identifier = latestSnapshot.DBSnapshotIdentifier.replace(':', '-');
    console.log("new identifier:", identifier);

    const startExportTaskParams = {
      ExportTaskIdentifier: `${identifier}-export`,
      IamRoleArn: iamRoleArn,
      KmsKeyId: kmsKeyId.toString(),
      S3BucketName: s3BucketName,
      SourceArn: latestSnapshot.DBSnapshotArn,
      S3Prefix: `uprn/${latestSnapshot.DBInstanceIdentifier}`,
    };
    let response = await rds.startExportTask(startExportTaskParams).promise();
    console.log(response);
};
