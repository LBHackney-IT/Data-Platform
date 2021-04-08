const handler = require("./index");
const AWS = require("aws-sdk");

var credentials = new AWS.SharedIniFileCredentials({ profile: "madetech" });
AWS.config.credentials = credentials;

handler.handler({
  Records: [
    {
      eventVersion: "2.1",
      eventSource: "aws:s3",
      awsRegion: "eu-west-2",
      eventTime: "2021-04-08T11:02:13.265Z",
      eventName: "ObjectCreated:Put",
      userIdentity: {
        principalId: "AWS:AROATZUPEIUG2OBTIH63L:ben.dalton",
      },
      requestParameters: {
        sourceIPAddress: "172.18.42.31",
      },
      responseElements: {
        "x-amz-request-id": "RJ2X1172EKBEKVEJ",
        "x-amz-id-2":
          "28tSGE9IApAOCzhJzzplMFf99WJLtfeakHc5BCp3V1rieSWshyuUnVjO9PwvyatPk2RB2fTvQbDxWHZW3nZ8SMWrHHLOdVRs",
      },
      s3: {
        s3SchemaVersion: "1.0",
        configurationId: "2640dba5-38d4-4de8-8b1c-d163f4867997",
        bucket: {
          name: "hackney-jamesoates-glue-script-storage",
          ownerIdentity: {
            principalId: "AJP1GHRAJJ92J",
          },
          arn: "arn:aws:s3:::hackney-jamesoates-glue-script-storage",
        },
        object: {
          key: "Scripts/GoogleSheets+Test.py",
          size: 0,
          eTag: "d41d8cd98f00b204e9800998ecf8427e",
          sequencer: "00606EE2B763237ABE",
        },
      },
    },
  ],
});
