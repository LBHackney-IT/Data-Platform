const {Glue, SNS} = require("aws-sdk");
const sns = new SNS({});
const glue = new Glue({});

async function getSnsTopicForDepartment(departmentName) {
  let topics = await sns.listTopics({}).promise();
  console.log("topics list", topics)

  let departmentTopicArnPromises = topics.Topics.map(async (topic) => {
    let topicArn = topic["TopicArn"];
    console.log("topic arn", topicArn);

    let tags = await sns.listTagsForResource({ResourceArn: topicArn}).promise()
    console.log(`tags for topic arn ${topicArn}`, tags)

    let departmentTag = tags.Tags.find(tag => tag.Key === "PlatformDepartment")

    return {
      departmentName: departmentTag ? departmentTag.Value : "",
      topicArn
    }
  });

  let departmentTopicArn = await Promise.all(departmentTopicArnPromises);
  return departmentTopicArn.find(topic => topic["departmentName"] === departmentName).topicArn
}

async function getGlueJob(jobName) {
  let glueJobParams = {
    JobName: jobName
  }

  let glueJob = await glue.getJob(glueJobParams).promise();

  return glueJob.Job;
}

async function getGlueJobRun(jobName, jobRunId) {
  let glueJobRunParams = {
    JobName: jobName,
    RunId: jobRunId
  }

  let glueJobRun = await glue.getJobRun(glueJobRunParams).promise();

  return glueJobRun.JobRun;
}

async function getTags(account, jobName) {
  let glueJobResourceArn = {
    ResourceArn: `arn:aws:glue:eu-west-2:${account}:job/${jobName}`
  }

  let glueJobTags = await glue.getTags(glueJobResourceArn).promise();

  return glueJobTags.Tags;
}

async function sendEmail(snsTopicArn, emailBody) {
  let emailMessage = `The Glue job, ${emailBody.glueJobName}, failed with error:` + "\n" +
    " \n" +
    `${emailBody.glueErrorMessage}` + "\n\n" +
    `Job Run ID: ${emailBody.glueJobRunId}` + "\n" +
    `Time of failure: ${new Date(emailBody.jobErrorTime).toString()}` + "\n" +
    `Job start time: ${emailBody.jobStartTime.toString()}` + "\n" +
    `Job end time: ${emailBody.jobEndTime.toString()}` + "\n" +
    `Glue job last modified on: ${emailBody.lastModifiedOn}` + "\n" +
    "\n" +
    `To investigate this error:` + "\n" +
    `1. log into the AWS ${emailBody.awsEnvironment ?? ""} environment via the Hackney SSO https://hackney.awsapps.com/start#/` + "\n" +
    `2. view the Glue job run details here ${emailBody.glueJobUrl}`

  let publishParams = {
    Message: emailMessage,
    TopicArn: snsTopicArn
  };

  return await sns.publish(publishParams).promise();
}

exports.handler = async (event) => {
  try {
    console.log(`JSON Stringify Event: ${JSON.stringify(event)}`);

    let {jobName, jobRunId, message} = event.detail;
    let {account, time} = event;

    let {LastModifiedOn} = await getGlueJob(jobName);
    let {StartedOn, CompletedOn} = await getGlueJobRun(jobName, jobRunId);
    let glueJobUrl = `https://eu-west-2.console.aws.amazon.com/gluestudio/home?region=eu-west-2#/job/${encodeURI(jobName)}/run/${encodeURI(jobRunId)}`;

    let tags = await getTags(account, jobName);
    let environment = tags["Environment"];
    let department = tags["PlatformDepartment"] ?? "admin";
    console.log("department", department);

    let emailBody = {
      glueJobName: jobName,
      glueErrorMessage: message,
      glueJobRunId: jobRunId,
      jobErrorTime: time,
      jobStartTime: StartedOn,
      jobEndTime: CompletedOn,
      lastModifiedOn: LastModifiedOn,
      awsEnvironment: environment,
      glueJobUrl: glueJobUrl,
    }

    let snsTopicArn = await getSnsTopicForDepartment(department);
    console.log("sns topic arn:", snsTopicArn);

    await sendEmail(snsTopicArn, emailBody);

    return {
      success: true,
    };
  } catch (error) {
    console.log(`Error: ${error}`)
    throw error;
  }
}
