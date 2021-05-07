const AWS = require("aws-sdk");

const AWS_REGION = "eu-west-2";

let iamRoleArn = process.env.IAM_ROLE_ARN
let kmsKeyId = process.env.KMS_KEY_ID
let s3BucketName = process.env.S3_BUCKET_NAME

// Find newest back up

// Start export task to export Snapshot to S3 (using RDS instance?)

exports.handler = async (events) => {
  let snsMessage;
  for (const eventRecord of events.Records) {
    try {
      snsMessage = JSON.parse(eventRecord.Sns.Message);
      console.log("event record:", eventRecord);
    } catch (err) {
      console.log("event error:", err);
      console.log("event record:", eventRecord);
      return;
    }
    const dbSnapshotId = snsMessage["Source ID"];

    const rds = new AWS.RDS({ region: AWS_REGION });
    let marker;
    let dbSnapshots;
    do {
      var params = {
        DBSnapshotIdentifier: dbSnapshotId,
        Marker: marker,
      };

      dbSnapshots = await rds.describeDBSnapshots(params).promise();
      console.log("All Snapshot:", dbSnapshots);

      marker = dbSnapshots.Marker;
    } while (marker);
    const latestSnapshot = dbSnapshots.DBSnapshots.pop();
    console.log("Latest Snapshot:", latestSnapshot);

    var params = {
      ExportTaskIdentifier: `${latestSnapshot.DBInstanceIdentifier}-${latestSnapshot.DBSnapshotIdentifier}-export`,
      IamRoleArn: iamRoleArn,
      KmsKeyId: kmsKeyId,
      S3BucketName: s3BucketName,
      SourceArn: latestSnapshot.DBSnapshotArn,
      S3Prefix: `exports/${latestSnapshot.DBInstanceIdentifier}`,
    };
    let response = await rds.startExportTask(params).promise();
    console.log(response);
  }
};
