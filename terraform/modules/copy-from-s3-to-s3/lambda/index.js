"use strict";
let __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : {"default": mod};
};
Object.defineProperty(exports, "__esModule", {value: true});
const aws_sdk_1 = __importDefault(require("aws-sdk"));
const AWS_REGION = 'eu-west-1';
const originBucketId = process.env.ORIGIN_BUCKET_ID || '';
const originPath = process.env.ORIGIN_PATH || '';
const targetBucketId = process.env.TARGET_BUCKET_ID || '';
const targetPath = process.env.TARGET_PATH || '';

async function listObjects(s3Client, bucket, prefix) {
    const params = {
        Bucket: bucket,
        Prefix: prefix,
    };
    let objectList = {};
    let more = true;
    while (more) {
        //console.log(params)
        const results = await s3Client.listObjectsV2(params).promise();
        more = results.IsTruncated || false;
        //console.log(results)
        if (!results.Contents) {
            break;
        }
        for (let item of results.Contents) {
            if (!item.Key)
                continue;
            // If it ends with a / it's a folder, so we can ignore it.
            if (item.Key.endsWith('/'))
                continue;
            objectList[item.Key] = {
                Key: item.Key,
                LastModified: item.LastModified,
                Etag: item.ETag,
                Size: item.Size,
            };
            params.ContinuationToken = results.NextContinuationToken;
        }
    }
    return objectList;
}

function mapKeys(objectList, originPath, targetPath) {
    let keyMap = {};
    for (const [, v] of Object.entries(objectList)) {
        //console.log(v)
        keyMap[v.Key] = v.Key.replace(originPath, targetPath);
    }
    return keyMap;
}

async function copyObjects(s3Client, originBucket, objectList, targetBucket, keyMap) {
    for (const [, v] of Object.entries(objectList)) {
        let targetKey = keyMap[v.Key];
        await copyObject(s3Client, originBucket, v.Key, targetBucket, targetKey);
    }
}

async function copyObject(s3Client, originBucket, originKey, targetBucket, targetKey) {
    let params = {
        ServerSideEncryption: 'AES256',
        StorageClass: 'STANDARD',
        CopySource: encodeURIComponent([originBucket, originKey].join('/')),
        Bucket: targetBucket,
        Key: targetKey,
        MetadataDirective: 'COPY',
    };
    console.log(JSON.stringify({
        fromBucket: originBucket,
        fromKey: originKey,
        toBucket: targetBucket,
        toKey: targetKey,
    }));
    return s3Client.copyObject(params).promise();
}

exports.handler = async () => {
    let s3Client = new aws_sdk_1.default.S3({region: AWS_REGION});
    if (process.env.ASSUME_ROLE_ARN && process.env.ASSUME_ROLE_ARN.includes('role')) {
        console.log(`Assuming Role: ${process.env.ASSUME_ROLE_ARN}`);
        let stsClient = new aws_sdk_1.default.STS({region: AWS_REGION});
        const assumeRoleRequest = {
            RoleArn: process.env.ASSUME_ROLE_ARN,
            RoleSessionName: 'FileCopier',
            DurationSeconds: 900,
        };
        const result = await stsClient.assumeRole(assumeRoleRequest).promise();
        if (!result.Credentials)
            throw new Error(`Unable to assume role: ${process.env.ASSUME_ROLE_ARN}`);
        const credentials = {
            accessKeyId: result.Credentials.AccessKeyId,
            secretAccessKey: result.Credentials.SecretAccessKey,
            sessionToken: result.Credentials.SessionToken
        };
        s3Client = new aws_sdk_1.default.S3({region: AWS_REGION, credentials: credentials});
        stsClient = new aws_sdk_1.default.STS({region: AWS_REGION, credentials: credentials});
        const getCallerIdentityResponse = await stsClient.getCallerIdentity().promise();
        console.log(JSON.stringify(getCallerIdentityResponse));
        console.log('Assume Role Complete');
    }
    console.log('Running S3 to S3 Copier');
    console.log(`Evaluating Origin: ${originBucketId}`);
    console.log(`Path: ${originPath}`);
    const objectList = await listObjects(s3Client, originBucketId, originPath);
    console.log('Mapping to new Location');
    const keyMap = mapKeys(objectList, originPath, targetPath);
    console.log('Copying Objects');
    return copyObjects(s3Client, originBucketId, objectList, targetBucketId, keyMap);
};
