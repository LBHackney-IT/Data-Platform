# Jupyter Notebook

## Prerequisites
- [Docker Desktop](https://docs.docker.com/desktop/#download-and-install)

## Run the Container

If you have make and aws-vault installed and setup with credentials for `hackney-dataplatform-development` already you can follow option 1, otherwise use the second option. The first option has the advantage that you don't have to change your credentials each day as they get rotated.

To install and setup aws-vault follow the instructions in step 3 of the [setup section in the project README](https://github.com/LBHackney-IT/Data-Platform/blob/main/README.md#set-up).

### Option 1. Using make and aws-vault (Preferred)
  - make `run-notebook`

### Option 2. Using access keys and docker
1. Navigate to [the hackney SSO](https://hackney.awsapps.com/start#/), click on the account you want to use then click "Command line or programmatic access".
2. Copy the aws access key, aws secret access key and aws session token into the file `/aws-config/credentials`.
3. Run 
```sh
docker-compose up notebook
```

## Open Jupyter Notebook
- Navigate to [http://localhost:8888](http://localhost:8888)

## Test connection to AWS

1. Within the notebook open `scripts/test-s3-connection`.
1. Change the `s3_url` variable to be an s3 bucket that exists in the AWS account you are using.
1. Click "Run"
1. You should get some data back from the s3 bucket and no errors.
