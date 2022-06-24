import AWS, {AWSError} from 'aws-sdk'
import {ListObjectsV2Output} from 'aws-sdk/clients/s3'

const AWS_REGION = 'eu-west-2'

const originBucketId = process.env.ORIGIN_BUCKET_ID || ''
const originPath = process.env.ORIGIN_PATH || ''
const targetBucketId = process.env.TARGET_BUCKET_ID || ''
const targetPath = process.env.TARGET_PATH || ''

function listObjects(s3Client: AWS.S3, bucket: string, prefix: string, cb: any) {
    const params = {
        Bucket: bucket,
        Prefix: prefix,
    }
    var res = {}
    var more = true
    var count = 1

    function getBatch(cb: any) {
        s3Client.listObjectsV2(params, function (err: AWSError, data: ListObjectsV2Output) {

        })
    }
}

async function touchObject(s3Client: AWS.S3, origin: string, destinationBucket: string, key: string) {
    console.log(JSON.stringify({
        from: origin,
        target: origin
    }))
    let params: any = {}//_.clone(commonParams);
    params.CopySource = origin //encodeURIComponent(target);
    params.Bucket = destinationBucket;
    params.Key = key;
    params.MetadataDirective = "REPLACE";
    return s3Client.copyObject(params).promise();
}

exports.handler = async () => {
    const s3Client = new AWS.S3({region: AWS_REGION})
    console.log(JSON.stringify({message: 'Hello'}))
    const origin = [originBucketId, 'test.txt'].join('/')
    await touchObject(s3Client, origin, targetBucketId, 'a/fileB.txt')
    console.log(JSON.stringify({message: 'Hello2'}))
}
