process.on('unhandledRejection', error => {
  // Will print "unhandledRejection err is not defined"
  console.log('[UnhandledRejection]', error.message);
  console.log(error)
});

process.env.BUCKET_DESTINATION = "dataplatform-ryanbratten-landing-zone";
const handler = require("./index");

handler.handler({
  "Records": [
    {
      "messageId": "2e1424d4-f796-459a-8184-9c92662be6da",
      "receiptHandle": "AQEBzWwaftRI0KuVm4tP+/7q1rGgNqicHq...",
      "body": '{"ExportTaskIdentifier":"sql-to-parquet-22-06-01-backdated","ExportBucket":"dataplatform-ryanbratten-dp-rds-export-storage"}',
      "attributes": {
        "ApproximateReceiveCount": "1",
        "SentTimestamp": "1545082650636",
        "SenderId": "AIDAIENQZJOLO23YVJ4VO",
        "ApproximateFirstReceiveTimestamp": "1545082650649"
      },
      "messageAttributes": {},
      "md5OfBody": "e4e68fb7bd0e697a0ae8f1bb342846b3",
      "eventSource": "aws:sqs",
      "eventSourceARN": "arn:aws:sqs:eu-west-2:937934410339:dataplatform-ryanbratten-s3-to-s3-copier",
      "awsRegion": "us-east-2"
    }
  ]
});


// /housing/databases   / name of the database / name of the table /
// import_year{snapshot year} / import_month={snapshot month} / import_day={snapshot day} / parquet filename