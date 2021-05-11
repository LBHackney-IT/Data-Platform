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
  Type: "Notification",
  MessageId: "14ea38d1-e74e-5b95-a8e3-61c0cd4df432",
  TopicArn: "arn:aws:sns:eu-west-2:715003523189:dataengineers-dataplatform-stg-rds-snapshot-to-s3",
  Subject: "RDS Notification Message",
  Message: JSON.stringify({
    "Event Source": "db-snapshot",
    "Event Time": "2021-05-09 00:07:30.285",
    "Identifier Link": "https://console.aws.amazon.com/rds/home?region=eu-west-2#snapshot:id=rds:fss-public-staging-db-staging-2021-05-09-00-05",
    "Source ID": "rds:fss-public-staging-db-staging-2021-05-09-00-05",
    "Source ARN": "arn:aws:rds:eu-west-2:715003523189:snapshot:rds:fss-public-staging-db-staging-2021-05-09-00-05",
    "Event ID": "http://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_Events.html#RDS-EVENT-0091",
    "Event Message": "Automated snapshot created"
  }),
  Timestamp: "2021-05-09T00:07:31.373Z",
  SignatureVersion: "1",
  Signature: "Mjmqy7Ok5EUlTw9Z4xMKx3YTKaqldrsTJ0bICg4uht5NQUIcuF56ibURLur6sA9NGOgsLIVbUGGWv44Bcc12WatAwd/7hfk12NKftCnjqzVA+PY8aDoShTij9yUc6/8h0SZK9M+hJlgoTIw1Z4MYQ0pm/zcA3zpUbqlPYr2ZvTvCGHjF10JiSQjVRgdx8nHzRFHpg0ax/I21VrtlGo1eoYF4nb2nSzI7iK+0UgT+4NcuK5BD6sjl9e01rtrTihFB2P5bGd2wj21WLvHH+89x4Elut/L/MiSMN9AeAMFVbruZ451wj+Y6r0HZ/Li7zgFhVHJcf6/m5mr9COyDBSoweQ==",
  SigningCertURL: "https://sns.eu-west-2.amazonaws.com/SimpleNotificationService-010a507c1833636cd94bdb98bd93083a.pem",
  UnsubscribeURL: "https://sns.eu-west-2.amazonaws.com/?Action=Unsubscribe&SubscriptionArn=arn:aws:sns:eu-west-2:715003523189:dataengineers-dataplatform-stg-rds-snapshot-to-s3:bf5efe21-79fc-4a4f-99ee-2be58a103eb4"
});
