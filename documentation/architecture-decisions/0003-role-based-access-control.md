# 3. Role-Based Access Control

Date: 2021-03-23

## Status

Accepted

## Context

We will be storing sensitive council data within S3 and therefore need to restrict access to this data based on the
department the user belongs to.

## Decision

In order to limit access, we propose to store all S3 buckets in a single AWS account. Users accessing this account
directly will have little or no access to the owned S3 buckets, instead through the infrastructure deployment process
(terraform) we will share a partition of the S3 buckets to relevant department accounts.

E.g. s3://s3-bucket/social-care/* -> Social Care Account

## Consequences

This will allow us to securely segregate department data while relying on existing access control permission sets that
already restrict access to departmental accounts.

We will need to mechanism to share ETL processes between departments, since each department will be operating it's own
ETL processes independently.

Due to the data being stored in a central bucket we can opt to extend a departments read-only scope to other department
partitions to allow wider data analysis.

With the data stored in a single AWS account, if a malicious user were to gain access to the account with a users that
did have access to the entire bucket (such as the AWS Account Root) they would have access to all Hackney data

## Considerations

- Security around AWS terraform deployments
- Review process for Infrastructure as Code deployments
- 