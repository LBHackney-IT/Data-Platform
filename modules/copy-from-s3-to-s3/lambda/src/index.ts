import AWS, {AWSError} from 'aws-sdk'
import {ListObjectsV2Output} from 'aws-sdk/clients/s3'

const AWS_REGION = "eu-west-2";

const originbucketid = process.env.ORIGIN_BUCKET_ID;
const originpath = process.env.ORIGIN_PATH;
const targetbucketid = process.env.TARGET_BUCKET_ID
const targetpath = process.env.TARGET_PATH

function listObjects(s3Client: AWS.S3, bucket: string, prefix: string, cb: any) {
  const params = {
    Bucket: bucket,
    Prefix: prefix
  };
  var res = {};
  var more = true;
  var count = 1;
  function getBatch(cb: any) {
    s3Client.listObjectsV2(params, function(err: AWSError, data: ListObjectsV2Output) {

    });
  }
}

exports.handler = async () => {
  const s3Client = new AWS.S3({region: AWS_REGION});

};
