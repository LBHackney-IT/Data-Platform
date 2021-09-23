// const { SNSClient } = require('aws-sdk/client-sns')
const { Glue, SNS } = require("aws-sdk");

// const AWS_REGION = "eu-west-2";
const client = new SNS({});
const glue = new Glue({});

let snsTopicARN = process.env.SNS_TOPIC_ARN;

exports.handler = async (event) => {
  try {
    console.log(`Event: ${JSON.stringify(event)}`);
    console.log(`JSON Stringify Event: ${JSON.stringify(event)}`);

    let {jobName, jobRunId, message } = event.detail;

    // use Glue SDK to get glue job run details: start & end time and url? or construct url
    let glueJobParams = {
      JobName: jobName
    }

    let glueJob = await glue.getJob(glueJobParams);
    console.log("glue job:", glueJob);

    let glueJobRunParams = {
      JobName: jobName,
      RunId: jobRunId
    }

    let glueJobRun = await glue.getJobRun(glueJobRunParams);
    console.log("glue job run:", glueJobRun);

    let glueJobUrl = "https://eu-west-2.console.aws.amazon.com/gluestudio/home?region=eu-west-2#/job/${url_encode(jobName)}/run/${jobRunId}";

    let snsMessage = {
      time: event.time,
      jobName: jobName,
      jobRunID: jobRunId,
      glueJobError: message,
      glueJobLink: `${glueJobUrl}/${jobRunId}`
    };
    console.log(`message: ${JSON.stringify(snsMessage)}`);

    let publishParams = {
      Message: JSON.stringify(snsMessage),
      TopicArn: snsTopicARN
    };

    await client.publish(publishParams);

    return {
      success: true,
      message: `Event ${JSON.stringify(event)}, sns topic arn: ${snsTopicARN}`
    };

  }

  catch (error) {
    console.log(`Error: ${error}`)
  }

}

// construct message:
  // Job start time, job end time, error message, job name, job run id, link to cloudwatch

// glue job details from api?