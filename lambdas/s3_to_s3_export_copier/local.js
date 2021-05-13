process.on('unhandledRejection', error => {
  // Will print "unhandledRejection err is not defined"
  console.log('[UnhandledRejection]', error.message);
  console.log(error)
});

const AWS = require("aws-sdk");

const credentials = new AWS.SharedIniFileCredentials({
  profile: "hackney-api-staging"
});
AWS.config.credentials = credentials;

process.env.BUCKET_DESTINATION = "dataplatform-stg-landing-zone";
const handler = require("./index");

handler.handler({
  "Records": [
    {
      "messageId": "2e1424d4-f796-459a-8184-9c92662be6da",
      "receiptHandle": "AQEBzWwaftRI0KuVm4tP+/7q1rGgNqicHq...",
      "body": JSON.stringify({
        ExportTaskIdentifier: "dataplatform-el-tests-fss-again",
        ExportBucket: "dataplatform-stg-rds-export-storage"
      }),
      "attributes": {
        "ApproximateReceiveCount": "1",
        "SentTimestamp": "1545082650636",
        "SenderId": "AIDAIENQZJOLO23YVJ4VO",
        "ApproximateFirstReceiveTimestamp": "1545082650649"
      },
      "messageAttributes": {},
      "md5OfBody": "e4e68fb7bd0e697a0ae8f1bb342846b3",
      "eventSource": "aws:sqs",
      "eventSourceARN": "arn:aws:sqs:us-east-2:123456789012:my-queue",
      "awsRegion": "us-east-2"
    }
  ]
});
