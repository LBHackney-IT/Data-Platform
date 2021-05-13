process.on('unhandledRejection', error => {
  // Will print "unhandledRejection err is not defined"
  console.log('[UnhandledRejection]', error.message);
  console.log(error)
});

process.env.IAM_ROLE_ARN = 'arn:aws:iam::715003523189:role/dataplatform-stg-rds-snapshot-export-service';
process.env.KMS_KEY_ID = '7ca452a6-e414-4556-8f29-cb46c35c18e8';
process.env.S3_BUCKET_NAME = 'dataplatform-stg-rds-export-storage';

const handler = require("./index");

// handler.handler({
//   Type: "Notification",
//   MessageId: "14ea38d1-e74e-5b95-a8e3-61c0cd4df432",
//   TopicArn: "arn:aws:sns:eu-west-2:715003523189:dataengineers-dataplatform-stg-rds-snapshot-to-s3",
//   Subject: "RDS Notification Message",
//   Message: JSON.stringify({
//     "Event Source": "db-snapshot",
//     "Event Time": "2021-05-09 00:07:30.285",
//     "Identifier Link": "https://console.aws.amazon.com/rds/home?region=eu-west-2#snapshot:id=rds:fss-public-staging-db-staging-2021-05-09-00-05",
//     "Source ID": "rds:fss-public-staging-db-staging-2021-05-09-00-05",
//     "Source ARN": "arn:aws:rds:eu-west-2:715003523189:snapshot:rds:fss-public-staging-db-staging-2021-05-09-00-05",
//     "Event ID": "http://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_Events.html#RDS-EVENT-0091",
//     "Event Message": "Automated snapshot created"
//   }),
//   Timestamp: "2021-05-09T00:07:31.373Z",
//   SignatureVersion: "1",
//   Signature: "Mjmqy7Ok5EUlTw9Z4xMKx3YTKaqldrsTJ0bICg4uht5NQUIcuF56ibURLur6sA9NGOgsLIVbUGGWv44Bcc12WatAwd/7hfk12NKftCnjqzVA+PY8aDoShTij9yUc6/8h0SZK9M+hJlgoTIw1Z4MYQ0pm/zcA3zpUbqlPYr2ZvTvCGHjF10JiSQjVRgdx8nHzRFHpg0ax/I21VrtlGo1eoYF4nb2nSzI7iK+0UgT+4NcuK5BD6sjl9e01rtrTihFB2P5bGd2wj21WLvHH+89x4Elut/L/MiSMN9AeAMFVbruZ451wj+Y6r0HZ/Li7zgFhVHJcf6/m5mr9COyDBSoweQ==",
//   SigningCertURL: "https://sns.eu-west-2.amazonaws.com/SimpleNotificationService-010a507c1833636cd94bdb98bd93083a.pem",
//   UnsubscribeURL: "https://sns.eu-west-2.amazonaws.com/?Action=Unsubscribe&SubscriptionArn=arn:aws:sns:eu-west-2:715003523189:dataengineers-dataplatform-stg-rds-snapshot-to-s3:bf5efe21-79fc-4a4f-99ee-2be58a103eb4"
// });

handler.handler({
  Records: [
    {
      messageId: '72b0e35c-6a7e-464d-b1c3-ea4526ae3e7f',
      receiptHandle: 'AQEBDK93ENCV5XzdV9q26B9GBcL4bqWpCtTH9e/sXKIWT3Fe9abjKECnrMoaeLfac8ltA/DBi2wPHCL3VFITfKMQyqRwFMOR4vpPrCtb3E32y1j5pBgC49Id22/n2V/98fHD3/Eg4sjBxncnKOiC0OXDah77fK9Rj7PVXyPUX7PXx0LIRXnKjWr4iNSnKgGmfnhTZQhl6CKprpry/tfYkvamTxiJ8y8d7yxl00eCt5RVcbF3sl568JZ8hmjt0UY2Bexd8yYWQZqogEIcEGtNrbopw8FseiUr26ko/Brl0Mf+axwduY2UhyZBGUj90J9/H7SWFmBUFSqiI3RiZcnnD3Lnre8EedeiqNIwiO+AiZDNvE/bnklftVMYjE//wGQLivwxQWvmxjfwq4DKc6uw2hnB5nTmIGF26dCgQCYzHfdNRi9pQbkHTBitSx1XFscFi980',
      body: JSON.stringify({
        "Type": "Notification",
        "MessageId": "0c5cb152-fe54-5f2b-8c5e-e8465b4f13ce",
        "TopicArn": "arn:aws:sns:eu-west-2:715003523189:dataengineers-dataplatform-stg-rds-snapshot-to-s3",
        "Subject": "RDS Notification Message",
        "Message": JSON.stringify({
          "Event Source": "db-snapshot",
          "Event Time": "2021-05-11 15:29:31.058",
          "Identifier Link": "https://console.aws.amazon.com/rds/home?region=eu-west-2#snapshot:id=dataplatform-el-tests-fss",
          "Source ID": "dataplatform-el-tests-fss",
          "Source ARN": "arn:aws:rds:eu-west-2:715003523189:dataplatform-el-tests-fss",
          "Event ID": "http://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_Events.html#RDS-EVENT-0040",
          "Event Message": "Creating manual snapshot"
        }),
        "Timestamp": "2021-05-11T15:29:31.684Z",
        "SignatureVersion": "1",
        "Signature": "W03TMyMkS4DO/yuzBdmVZ8HXOfcrDby8ZCahPHAy808uSEvTm1dRWVCT4fztM5EmZAyoHJOLspMn+rJvBQKOLyYE5gqhznAXsQS7+HmY4abG8dgowL/mYnXZjvFM8zzdABRRll7cVTf9aAh2nQXNmx+d91HB3WS9KNRgmjU58gvKFFBTE/h7pejZxCLl/CJnCwJXSc7BS2GGi08L3JyVQETNqFTrs14tWB3oMys/9K7+oNhKqDjncExZJ0YqPvuUeigyRvkzW7jJD6rVkx9+wCs+tWtp/ti23YkO0A4lAtxS4CqKyUKQrfdSzaAufZK9ut94lE8S9ph0CTtWX89OKw==",
        "SigningCertURL": "https://sns.eu-west-2.amazonaws.com/SimpleNotificationService-010a507c1833636cd94bdb98bd93083a.pem",
        "UnsubscribeURL": "https://sns.eu-west-2.amazonaws.com/?Action=Unsubscribe&SubscriptionArn=arn:aws:sns:eu-west-2:715003523189:dataengineers-dataplatform-stg-rds-snapshot-to-s3:bf5efe21-79fc-4a4f-99ee-2be58a103eb4"
      }),
      attributes: [Object],
      messageAttributes: {},
      md5OfBody: '2d4e73e4928077a7995a1af4146ba944',
      eventSource: 'aws:sqs',
      eventSourceARN: 'arn:aws:sqs:eu-west-2:715003523189:dataengineers-dataplatform-stg-rds-snapshot-to-s3',
      awsRegion: 'eu-west-2'
    }
  ]
})
