const AWS = require("aws-sdk");

const AWS_REGION = "eu-west-2";

let bucketDestination = process.env.BUCKET_DESTINATION;

async function s3CopyFolder(bucket, source, destination) {
  console.log("bucket", bucket);
  console.log("source", source);
  console.log("destination", destination);
  // sanity check: source and destination must end with '/'
  if (!source.endsWith('/') || !destination.endsWith('/')) {
    return Promise.reject(new Error('source or destination must ends with fwd slash'));
  }
  const s3 = new AWS.S3( { region: AWS_REGION });

  // plan, list through the source, if got continuation token, recursive
  var params = {
    Bucket: bucket,
    Prefix: source,
    Delimiter: '/',
  };

  const listResponse = await s3.listObjectsV2(params, function(err, data) {
    if (err) console.log("error occurred", err);
    else console.log(data);
  }).promise();

  console.log("list response", listResponse);
  console.log("list response contents", listResponse.Contents);

  // copy objects
  await Promise.all(
    listResponse.Contents.map(async (file) => {
      console.log("bucket", bucket);
      console.log("copy source", file.Key);
      console.log("key", `${destination}${file.Key.replace(listResponse.Prefix, '')}`);
      await s3.copyObject({
        Bucket: bucket,
        CopySource: `${file.Key}`,
        Key: `${destination}${file.Key.replace(listResponse.Prefix, '')}`,
      }).promise();
    }),
  );
  return Promise.resolve('ok');
}

exports.handler = async (events) => {
  const rdsClient = new AWS.RDS({region: AWS_REGION});
  const s3Client = new AWS.S3({region: AWS_REGION});
  const sqsClient = new AWS.SQS({region: AWS_REGION});

  for(const event of events.Records) {
    const message = JSON.parse(event.body);
    console.log("message.ExportTaskIdentifier", message.ExportTaskIdentifier);
    const describeExportTasks = await rdsClient.describeExportTasks({
      ExportTaskIdentifier: message.ExportTaskIdentifier
    }).promise();

    console.log("describeExportTasks", describeExportTasks);

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

    const bucketSource = `s3://dataplatform-stg-rds-export-storage/${message.ExportTaskIdentifier}/`;
    const fullBucketDestination = `${bucketDestination}/`;
    // const exportBucket = "arn:aws:s3:eu-west-2:715003523189:dataplatform-stg-rds-export-storage";
    // created access point on rds-export-storage bucket
    const exportBucketAccessPoint = "arn:aws:s3:eu-west-2:715003523189:accesspoint/rds-snapshot-export-point";

    // If it has copy the files from s3 bucket A => s3 bucket B
    await s3CopyFolder(exportBucketAccessPoint, bucketSource, fullBucketDestination);

  }
  console.log("Copy complete");
  return 0;
};