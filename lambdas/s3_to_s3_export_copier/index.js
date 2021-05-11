const AWS = require("aws-sdk");

const AWS_REGION = "eu-west-2";

let iamRoleArn = process.env.IAM_ROLE_ARN
let kmsKeyId = process.env.KMS_KEY_ID
let s3BucketName = process.env.S3_BUCKET_NAME

// Find newest back up

// Start export task to export Snapshot to S3 (using RDS instance?)

exports.handler = async (events) => {
  const rdsClient = new AWS.RDS({region: AWS_REGION});
  const s3Client = new AWS.S3({region: AWS_REGION});
  AWS.S3Control
  const sqsClient = new AWS.SQS({region: AWS_REGION});

  for(const event in events.Records) {
    const message = JSON.parse(event.Message);

    const describeExportTasks = await rdsClient.describeExportTasks({
      ExportTaskIdentifier: message.ExportTaskIdentifier
    }).promise();

    if(!describeExportTasks || !describeExportTasks.ExportTasks || describeExportTasks.ExportTasks.length === 0) {
      throw new Error('describeExportTasks or it\'s child ExportTasks is missing')
    }

    const exportTaskStatus = describeExportTasks.ExportTasks.pop();

    // Check to see if the export has finished
    if(exportTaskStatus.Status !== 'COMPLETE') {
      // If NOT then requeue the event with an extended delay
      sqsClient.sendMessage({
        QueueUrl: event.eventSourceARN,
        MessageBody: event.Message,
        DelaySeconds: 300
      })
      return;
    }

    s3Client.copyObject({
      Bucket: BucketName,
      CopySource: CopySource,
      Key: ObjectKey
    });

    // If it has copy the files from s3 bucket A => s3 bucket B
  }
};