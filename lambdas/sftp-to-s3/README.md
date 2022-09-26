# Liberator SFTP server to S3

This lambda function streams a daily upload of liberator data from an SFTP server into the landing zone S3 bucket.

See the corresponding [architecture decision record](http://playbook.hackney.gov.uk/Data-Platform-Playbook/architecture-decisions/0007-sftp-to-s3-lambda).


## Development
### Deploy the lambda function in you development workspace

1. Install dependencies by running the following from this directory.
```sh
npm install
```

2. Move to the terraform folder and apply to deploy the lambda.
```sh
cd ../../terraform/core
make init
make apply
```

You can make changes to the lambda code then re apply the terraform to update the lambda function.

## Invoke the lambda function in your development workspace

1. Replace `<your-workspace-name>` with the name of your terraform workspace and run.
```sh
aws-vault exec hackney-dataplatform-development -- aws lambda invoke --function-name dataplatform-<your-workspace-name>-sftp-to-s3 out
```
(You can view the logs for the invocation in the cloudwatch log group `/aws/lambda/dataplatform-<your-workspace-name>-sftp-to-s3`.)