# AWS Account Bootstrap Terraform

## About
This repository contains the baseline Terraform that is deployed to all new AWS accounts. It should NOT be used directly as a basis for any new projects. See [the Example project](https://github.com/LBHackney-IT/infrastructure/tree/master/projects/example) for that.

The Terraform is formatted to use the [Jinja2 template engine](https://palletsprojects.com/p/jinja/) to customise the Terraform for each new AWS account as part of the automated setup process. An AWS Lambda (`ct-automation-configure-account-terraform`) in the root account is triggered by AWS CloudWatch Events, specifically  AWS Control Tower `CreateManagedAccount` or `UpdateManagedAccount` events, and subsequently triggers a [GitHub Action](https://github.com/LBHackney-IT/infrastructure/actions/workflows/platform_account_bootstrap.yml) with input parameters that are used to customise the Terraform and create a GitHub Action workflow to provision it via a CI/CD process.

## Making Changes

Please make all changes on a branch and raise pull request. Once an account has been bootstrapped, all changes to that account should be made to the account Terraform (i.e. it is not possible to re-bootstrap accounts at this time).
