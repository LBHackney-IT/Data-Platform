# DataHub Glue Metadata Ingestion Analysis

## Overview
This document analyzes how the DataHub module in `./terraform/modules/datahub` is configured to fetch metadata from AWS Glue Catalog and where the actual ingestion process runs.

## Key Finding: Missing Ingestion Process

The DataHub module sets up the **infrastructure** for Glue ingestion but **doesn't actually run any automated ingestion process**.

## What's Deployed

### DataHub Infrastructure
- DataHub services (frontend, backend, actions) running on ECS
- IAM permissions for Glue access  
- A sample ingestion recipe template (`datasource-ingestion-recipes/glue-example.yml`)

### IAM Permissions (`12-iam.tf:41-50`)
The module creates specific IAM permissions for Glue access:
- `glue:GetDatabases` - to list databases in Glue Catalog
- `glue:GetTables` - to retrieve table metadata
- Resources set to `"*"` for broad access

### Environment Variables (`03-locals.tf:157-160`)
Datahub services are configured with these environment variables:
- `AWS_DEFAULT_REGION` - current AWS region
- `AWS_ROLE` - ARN of the datahub IAM role for assume role access
- `GLUE_EXTRACT_TRANSFORMS` - set to `"false"` (excludes Glue job/transform metadata)
- `GMS_URL` - DataHub's metadata service endpoint

### Authentication
- IAM user with programmatic access keys stored in SSM parameters
- IAM role that can be assumed by both the datahub user and Glue service
- AWS credentials passed as secrets to ECS containers

### Ingestion Recipe Template (`datasource-ingestion-recipes/glue-example.yml`)
```yaml
source:
  type: glue
  config:
    aws_region: '${AWS_DEFAULT_REGION}'
    aws_role: '${AWS_ROLE}'
    extract_transforms: '${GLUE_EXTRACT_TRANSFORMS}'
sink:
  type: datahub-rest
  config:
    server: '${GMS_URL}'
```

## What's Missing: Automated Ingestion Process

The comprehensive search revealed **no active DataHub ingestion processes** running automated Glue metadata sync:

- **No scheduled ingestion jobs** - No CloudWatch Events, cron jobs, or scheduled tasks
- **No ingestion scripts** - No Python/shell scripts executing DataHub CLI commands
- **No ECS tasks** - No standalone ECS tasks or services running ingestion workers
- **No Lambda functions** - No Lambda functions triggering ingestion processes  
- **No Airflow DAGs** - No DAGs running DataHub ingestion
- **No Step Functions** - No state machines orchestrating metadata sync

## DataHub Actions: Not for Ingestion

### What DataHub Actions Actually Does
DataHub Actions is a **reactive** framework that:

1. **Listens to events** from sources (primarily Kafka topics containing DataHub metadata events)
2. **Processes events** through transformers and filters
3. **Executes actions** in response to these events

### What DataHub Actions is Designed For
- **Notifications** (send Slack when tags are added)
- **Workflow integration** (create Jira tickets)  
- **Synchronization** (sync DataHub changes to other systems)
- **Auditing** (track who made changes)

### What DataHub Actions is NOT
The Actions framework is **not** designed to be a metadata ingestion system. It doesn't:
- Poll external systems for metadata
- Run scheduled ingestion jobs
- Execute `datahub ingest` commands

## Where Your Glue Ingestion is Actually Running

If you're seeing Glue metadata in DataHub, it's most likely happening through:

1. **Manual ingestion via DataHub UI** - Someone is running ingestion jobs through the web interface
2. **External scheduled process** - A cron job, Airflow DAG, or other scheduler running `datahub ingest` commands with your Glue recipe
3. **Different system entirely** - Another part of your infrastructure that's not visible in this codebase

## Next Steps to Find the Ingestion Process

To find where the actual ingestion is running:

1. **Check DataHub UI ingestion history** - Look for scheduled or manual ingestion runs
2. **Review DataHub Actions container logs** - Check what the Actions container is actually processing
3. **Look for external schedulers** - Search for Airflow DAGs, cron jobs, or other scheduling systems
4. **Check other repositories** - The ingestion process might be in a different codebase
5. **Review CloudWatch logs** - Look for evidence of `datahub ingest` commands being executed

## Conclusion

The DataHub module provides the *capability* for Glue ingestion through proper infrastructure, IAM permissions, and configuration templates, but it doesn't *execute* the ingestion automatically. The actual metadata synchronization you're observing is likely happening through manual processes or external systems not visible in this Terraform configuration.