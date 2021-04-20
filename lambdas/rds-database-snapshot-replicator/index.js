const AWS = require("aws-sdk");

const AWS_REGION = 'eu-west-2';
// Find newest back up

// Start export task to export Snapshot to S3 (using RDS instance?)

exports.handler = async (events) => {
  for (const eventRecord of events.Records) {
    const snsMessage = JSON.parse(eventRecord.Sns.Message);
    const dbInstanceId = snsMessage["Source ID"];

    const rds = new AWS.RDS({ region: AWS_REGION });

    var params = {
      DBInstanceIdentifier: dbInstanceId,
    };

    const dbSnapshots = await rds.describeDBSnapshots(params).promise();

    console.log(dbSnapshots);
  }
};
