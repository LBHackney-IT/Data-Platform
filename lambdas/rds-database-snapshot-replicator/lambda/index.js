const AWS = require("aws-sdk");

const AWS_REGION = "eu-west-2";
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
      IamRoleArn: "arn:aws:iam::261219435789:role/rds-s3-export-role",
      KmsKeyId:
        "arn:aws:kms:eu-west-2:261219435789:key/60e9157b-458d-4ed7-9f5d-751769995d39",
      S3BucketName: "hackney-jamesoates-landing-zone",
      SourceArn: latestSnapshot.DBSnapshotArn,
      S3Prefix: `exports/${latestSnapshot.DBInstanceIdentifier}`,
    };
    let response = await rds.startExportTask(params).promise();
    console.log(response);
  }
};
