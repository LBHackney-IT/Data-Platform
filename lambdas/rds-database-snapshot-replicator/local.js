process.on('unhandledRejection', error => {
  // Will print "unhandledRejection err is not defined"
  console.log('[UnhandledRejection]', error.message);
  console.log(error)
});

const AWS = require("aws-sdk");

const credentials = new AWS.SharedIniFileCredentials({
  profile: "madetech-sandbox"
});
AWS.config.credentials = credentials;

const handler = require("./index");

handler.handler({
  Records: [
    {
      EventVersion: "1.0",
      EventSubscriptionArn: "arn:aws:sns:us-east-2:123456789012:rds-lambda:21be56ed-a058-49f5-8c98-aedd2564c486",
      EventSource: "aws:sns",
      Sns: {
        SignatureVersion: "1",
        Timestamp: "2019-01-02T12:45:07.000Z",
        Signature: "tcc6faL2yUC6dgZdmrwh1Y4cGa/ebXEkAi6RibDsvpi+tE/1+82j...65r==",
        SigningCertUrl: "https://sns.us-east-2.amazonaws.com/SimpleNotificationService-ac565b8b1a6c5d002d285f9598aa1d9b.pem",
        MessageId: "95df01b4-ee98-5cb9-9903-4c221d41eb5e",
        Message: "{\"Event Source\":\"task-manager\",\"Event Time\":\"2019-01-02 12:45:06.000\",\"Identifier Link\":\"https://console.aws.amazon.com/rds/home?region=eu-west-2#dbinstance:id=task-manager\",\"Source ID\":\"task-manager\",\"Event ID\":\"http://docs.amazonwebservices.com/AmazonRDS/latest/UserGuide/USER_Events.html#RDS-EVENT-0091\",\"Event Message\":\"An automated DB snapshot is being created.\"}",
        MessageAttributes: {},
        Type: "Notification",
        UnsubscribeUrl: "https://sns.us-east-2.amazonaws.com/?Action=Unsubscribe&amp;SubscriptionArn=arn:aws:sns:us-east-2:123456789012:test-lambda:21be56ed-a058-49f5-8c98-aedd2564c486",
        TopicArn:"arn:aws:sns:us-east-2:123456789012:sns-lambda",
        Subject: "RDS Notification Message"
      }
    }
  ],
});
