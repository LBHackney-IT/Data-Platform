# Data Platform

Hackney Data Platform Infrastructure and Code

![Dataplatform](https://user-images.githubusercontent.com/8051117/118786691-fd9eb880-b889-11eb-97cc-e0b5fbf56d6b.jpg)


## Data Dictionary & Playbook

The Data Dictionary & Playbook can be found on the [Document Site](http://playbook.hackney.gov.uk/Data-Platform-Playbook/) and it's related [GitHub Repository](https://github.com/LBHackney-IT/Data-Platform-Playbook/)

## Architecture Decision Records

We use Architecture Decision Records (ADRs) to document architecture decisions that we make. They can be found in the
[Data Platform - Playbook](http://playbook.hackney.gov.uk/)

## Notebooks

We use [Jupyter Notebooks](https://jupyter.org/) to prototype glue jobs.
These can be hosted either [locally](https://github.com/LBHackney-IT/Data-Platform-Notebooks#running-jupyter-locally-using-docker) or in [AWS sagemaker](https://lbhackney-it.github.io/Data-Platform-Playbook/playbook/transforming-data/using-aws-glue/using-sagemaker).
The notebooks are stored in the [Data Platform Notebooks](https://github.com/LBHackney-IT/Data-Platform-Notebooks) GitHub repository.

## Terraform Deployment

The Terraform will be deployed, using GitHub Actions, on push to main / when a Pull Request is merged into main

#### /terraform/core

The terraform/core directory contains the majority of the infrastructure and at the time of writing has one Github action to deploy to staging and one to deploy to production.

#### /terraform/etl

The terraform/etl directory contains the ETL and Glue related infrastructure and at the time of writing has one Github action to deploy to staging and one to deploy to production.

#### /terraform/networking

The terraform/networking directory contains the networking aspect of the data platform (see [`Networking`](#Networking)) and at the time of writing has one Github action to deploy to staging and one to deploy to production.

#### /terraform/backend-setup

The terraform/backend-setup directory is just for Dev’s bucket deployment, so it does not need a Github action. The terraform state for this area is maintained in the repo and we run it locally.

## Terraform Development

### Local deployment

#### Set up

1. Create a env.tfvars file for local deployment, this can be done by running `cp terraform/config/env.tfvars.example terraform/config/env.tfvars` from the project root directory.
2. Update the following required variables in the newly created file:

- `environment` - Environment you're working in (this is normally `dev`)
- `aws_api_account_id` - API AWS Account number to deploy RDS Export Lambda to, ie. the number after the #, beneath the public account name (for development purposes this is normally the account named DevScratch)
- `aws_deploy_account_id` Primary AWS Account number to deploy to (for development purposes this is normally the account named DataPlatform-Development)
- `aws_deploy_iam_role_name` - This is the role that will be used to deploy the infrastructure (for development purposes this is normally `LBH_Automation_Deployment_Role`)
- `google_project_id` - The Google Project to create service accounts in (for DevScratch `dataplatform-dev0`)

3. For local deployment AWS needs a AWS CLI profile (assumed to be called `hackney-dataplatform-development`) in the profile configuration file (which can be set in `~/.aws/config`). Read [documentation on Named Profiles](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-profiles.html) for more guidance setting up AWS credentials and named profiles.

To set up this profile, you can use the AWS CLI using the following command:

```
$ aws configure sso
```

In the terminal, add the start URL and the region as below

```
SSO start URL [None]: https://hackney.awsapps.com/start
SSO Region [None]: eu-west-1
```

Your terminal should look like this:

```
Attempting to automatically open the SSO authorization page in your default browser.
If the browser does not open or you wish to use a different device to authorize this request, open the following URL:

https://device.sso.eu-west-1.amazonaws.com/

Then enter the code:
LDHD-CKXW

There are {number} AWS accounts available to you.
```

Below the final line there will be a box which can be scrolled through using the arrow keys, select with <kbd>Enter</kbd> the account which corresponds to the `aws_api_account_id` used in step 2 above (normally DevScratch)

```
Using the account ID {number}
```

If you have access to multiple roles within that account, select the appropriate role (this is assumed to be `AWSAdministratorAccess` below), press <kbd>Enter</kbd> to select the default options for `client Region`, `output format` and `profile name`

```
Using the role name "AWSAdministratorAccess"
CLI default client Region [eu-west-2]:
CLI default output format [json]:
CLI profile name [AWSAdministratorAccess-{number}]:
hackney-dataplatform-development
```

Install AWS-Vault

Mac
```
$ brew install --cask aws-vault
```
Windows

- Install chocolatey using the following guide: [Link](https://chocolatey.org/install#individual)
- Install aws-vault using chocolatey: ```choco install aws-vault```

Generate Credentials for Vault

```
$ aws-vault exec hackney-dataplatform-development -- aws sts get-caller-identity
```

Ensure that GNU Make is installed on your computer. The full commands for the below instructions can be found in `/terraform/core/Makefile` & `/terraform/etl/Makefile`

Initialise the Project

- Before you run, ensure:
  - You remove _hackney-dataplatform-development_ aws credentials if they exist in your AWS credentials file
  - You are in the project's `terraform/core` directory 
  - You remove the _.terraform_ directory, and the _.terraform.lock.hcl_ file if they exist in the project's terraform/core & terraform/etl directories
    
- Please complete the below make commands in both the terraform/core & terraform/etl directories

```
$ make init
```

Initialise your Workspace (note capitalisation)

```
$ WORKSPACE={developer} make workspace-new
```

Select your Workspace (note capitalisation)

```
$ WORKSPACE={developer} make workspace-select
```

4. Set up Google credentials

- Run `brew install --cask google-cloud-sdk` to install _Google Cloud SDK_
- Log in into Google Cloud by running `gcloud auth application-default login`
- The full path of where the file is saved will be displayed, for example `/Users/*/.config/gcloud/application_default_credentials.json`
  - Copy this file to the root of the project by running the following command in the root of the project `cp /Users/*/.config/gcloud/application_default_credentials.json ./google_service_account_creds.json`

5. Next run `make init` in the `/terraform/core` directory.
   This will initialize terraform/core using the AWS profile `hackney-dataplatform-development`. Before you run, ensure:
   - You remove _hackney-dataplatform-development_ aws credentials if they exist in your AWS credentials file
   - You remove the _.terraform_ directory, and the _.terraform.lock.hcl_ file if they exist in the project's terraform/core directory

6. Next run `make init` in the `/terraform/etl` directory.
   This will initialize terraform/etl using the AWS profile `hackney-dataplatform-development`. Before you run, ensure:
    - You remove _hackney-dataplatform-development_ aws credentials if they exist in your AWS credentials file
    - You remove the _.terraform_ directory, and the _.terraform.lock.hcl_ file if they exist in the project's terraform/etl directory

#### Building dependencies 

In order to apply Terraform some dependencies must be in place first.

To build all necessary dependencies:

1. Navigate to `external-lib` folder and run `make all`
2. Run `make package-helpers` in the project root directory 

Please note there are other dependencies, such as Python, Maven etc., that must be in place in the development environment before the above commands can be executed successfully, but those can be resolved separately as and when required.

#### Terraform commands

After running, you can run `make plan`, `make apply` and `make destroy` to run the Terraform deploy/destroy commands with the development `env.tfvars` set for you.

## Networking

As part of the Terraform deployment, we deploy out a VPC which connects to Hackney's Hub account. Hackney use a Hub &
Spoke pattern for interconnecting their accounts and to provide internet access to those spoke accounts. External
traffic is routed to the Hub account and scanned before being passed to the Spoke accounts. Outbound traffic follows the
opposite flow.

### Development Networking

Due to the above described setup only a single VPC can be created within the AWS Development account. As a consequence
we have created a separate Terraform module which will deploy the VPC out to each account. The VPC is then referenced
by the main Terraform script by providing the VPC ID as an input variable.

For new developers coming onto project, the VPC should have already been established and associated with the default
workspace state stored in S3. The ID of the VPC has also already been included in the example env.tsvars file. Unless
you intend to modify the network configuration, you should not need to modify or deploy the network to run your own
personal development environment.

#### Destroying development workspaces

All resources in a given workspace can be destroyed with `make destroy` command. However some resources have deletion protection enabled. In order to destroy the resources you cen remove those protections by replacing all `prevent_destroy = true` statements with `prevent_destroy = true`.

Please ensure you are in the correct workspace before deleting resources and also make sure you destroy the workspaces in the correct order since they have dependecies to each other. Destroy ETL first and then Core. Please don't destroy Networking since it's using default/shared workspace and is used by all developers. 

If you receive any timeout errors when destroying resources you can simply run destroy again until it succeeds.