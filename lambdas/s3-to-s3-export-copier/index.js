const AWS = require("aws-sdk");

const AWS_REGION = "eu-west-2";

const bucketDestination = process.env.BUCKET_DESTINATION;
const targetServiceArea = process.env.SERVICE_AREA;
const workflowName = process.env.WORKFLOW_NAME
const backdatedWorkflowName = process.env.BACKDATED_WORKFLOW_NAME

async function s3CopyFolder(s3Client, sourceBucketName, sourcePath, targetBucketName, targetPath, snapshotTime, exportTaskIdentifier, is_backdated) {
    console.log("sourceBucketName", sourceBucketName);
    console.log("targetBucketName", targetBucketName);
    console.log("sourcePath", sourcePath);
    console.log("targetPath", targetPath);
    console.log("snapshotTime", snapshotTime);
    console.log("exportTaskIdentifier", exportTaskIdentifier);
    console.log("is_backdated", is_backdated);
    console.log();

    // plan, list through the source, if got continuation token, recursive

    let listResponse;

    do {
        const listObjectsParams = {
            Bucket: sourceBucketName,
            Prefix: sourcePath,
            ContinuationToken: listResponse?.NextContinuationToken
        };
        console.log("continuation token", listResponse?.NextContinuationToken);

        listResponse = await s3Client.listObjectsV2(listObjectsParams).promise();
        let {day, month, year, date} = getDateTime(snapshotTime, exportTaskIdentifier, is_backdated);

        console.log("list response contents", listResponse.Contents);

        await Promise.all(
            listResponse.Contents.map(async (file) => {
                if (!file.Key.endsWith("parquet")) {
                    return;
                }
                const [snapShotName, databaseName, tableName] = file.Key.split("/", 3);

                const fileName = file.Key.substr(`${snapShotName}/${databaseName}/${tableName}`.length + 1);
                // remove extra partitions if necessary and get name of parquet files
                const parquetFileName = getParquetFileName(fileName);

                console.log("fileName:", fileName);
                console.log("parquetFileName:", parquetFileName);
                const copyObjectParams = {
                    Bucket: targetBucketName,
                    CopySource: `${sourceBucketName}/${file.Key}`,
                    Key: `${targetPath}/${databaseName}/${tableName}/import_year=${year}/import_month=${month}/import_day=${day}/import_date=${date}/${parquetFileName}`,
                    ACL: "bucket-owner-full-control",
                };
                console.log("copyObjectParams", copyObjectParams)

                await s3Client.copyObject(copyObjectParams).promise().catch(console.log);
            })
        );
    } while (listResponse.IsTruncated && listResponse.NextContinuationToken)
}

function getDateTime(snapshotTime, exportTaskIdentifier, is_backdated) {
    let day = (snapshotTime.getDate() < 10 ? '0' : '') + snapshotTime.getDate();
    let month = ((snapshotTime.getMonth() + 1) < 10 ? '0' : '') + (snapshotTime.getMonth() + 1);
    let year = snapshotTime.getFullYear();
    let date = year + month + day;

    if (is_backdated) {
        let split = exportTaskIdentifier.split("-");
        day = split[5]
        month = split[4]
        year = split[3]
        date = year + month + day;
    }
    return {day, month, year, date};
}

function getParquetFileName(fileName) {
    if (!fileName.startsWith('p')) {
        const index = fileName.lastIndexOf('/');
        return fileName.substr(index + 1);
    }
    return fileName;
}

async function startWorkflowRun(workflowName) {
    const glue = new AWS.Glue({apiVersion: '2017-03-31'});
    const params = {
        Name: workflowName
    };
    console.log("starting workflow run with params", params)

    await glue.startWorkflowRun(params).promise();
}

async function startBackdatedWorkflowRun(workflowName,import_date) {
    const glue = new AWS.Glue({apiVersion: '2017-03-31'});
    const run_params = {
        Name: workflowName
    };
    const update_params = {
        Name: workflowName,
        DefaultRunProperties: {
            "import_date" : import_date
        }
    };
    console.log("updating workflow run with params", update_params)
    await glue.updateWorkflow(update_params).promise();
    console.log("starting workflow run with params", run_params)
    await glue.startWorkflowRun(run_params).promise();
}

exports.handler = async (events) => {
    const rdsClient = new AWS.RDS({region: AWS_REGION});
    const s3Client = new AWS.S3({region: AWS_REGION});
    const sqsClient = new AWS.SQS({region: AWS_REGION});

    await Promise.all(
        events.Records.map(async (event) => {
            const message = JSON.parse(event.body);
            console.log("event", event);
            console.log("message.ExportTaskIdentifier", message.ExportTaskIdentifier);
            const describeExportTasks = await rdsClient.describeExportTasks({
                ExportTaskIdentifier: message.ExportTaskIdentifier
            }).promise();

            console.log("describeExportTasks", describeExportTasks);

            if (!describeExportTasks || !describeExportTasks.ExportTasks || describeExportTasks.ExportTasks.length === 0) {
                throw new Error('describeExportTasks or it\'s child ExportTasks is missing')
            }

            const exportTaskStatus = describeExportTasks.ExportTasks.pop();

            // Don't re-queue if status is cancelled
            if (exportTaskStatus.Status === 'CANCELED') {
                return;
            }

            // Check to see if the export has finished
            if (exportTaskStatus.Status !== 'COMPLETE') {
                // If NOT then requeue the event with an extended delay
                console.log(event.eventSourceARN);

                const queueName = event.eventSourceARN.split(':').pop();

                const getQueueUrlResponse = await sqsClient.getQueueUrl({
                    QueueName: queueName
                }).promise();

                console.log(getQueueUrlResponse);
                await sqsClient.sendMessage({
                    QueueUrl: getQueueUrlResponse.QueueUrl,
                    MessageBody: event.body,
                    DelaySeconds: 300
                }).promise();
                return;
            }

            const sourceBucketName = message.ExportBucket
            const targetBucketName = bucketDestination;
            const pathPrefix = `${message.ExportTaskIdentifier}`;
            const snapshotTime = exportTaskStatus.SnapshotTime;
            let is_backdated = false;

            //Example: sql-to-parquet-21-07-01-override - back dated ingestion so use time from snapshot instead of today
            let pattern = /^sql-to-parquet-\d\d-\d\d-\d\d-backdated$/;
            if (pattern.test(pathPrefix)) {
                is_backdated = true;
            }

            // If it has copy the files from s3 bucket A => s3 bucket B
            await s3CopyFolder(s3Client, sourceBucketName, pathPrefix, targetBucketName, targetServiceArea, snapshotTime, pathPrefix, is_backdated);

            if (workflowName && !is_backdated) {
                await startWorkflowRun(workflowName);
            }

            if (backdatedWorkflowName && is_backdated) {
                let {day, month, year, date} = getDateTime(snapshotTime, pathPrefix, is_backdated);
                await startBackdatedWorkflowRun(backdatedWorkflowName, date);
            }
        })
    )
};
