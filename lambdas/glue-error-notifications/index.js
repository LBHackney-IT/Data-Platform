const {SNSClient} = require("@aws-sdk/client-sns")
const AWS_REGION = "eu-west-2";

let snsTopicARN = process.env.SNS_TOPIC_ARN;

exports.handler = async (event) => {
  // log event
  let snsClient = new SNSClient({region: AWS_REGION})


  try {
    let responseMessage = 'Testing';
    console.log(`response message: ${responseMessage}`)

    return {
      success: true,
      message: `Event ${event}, sns topic arn: ${snsTopicARN}`
    }

  }

  catch (error) {
    console.log(`Error: ${error}`)
  }

}


// get glue job name
// get glue job run id

// check for ERROR pattern and send sns notification

// construct message
// glue job details from api?
// Job start time, job end time, error message, job name, link to cloudwatch