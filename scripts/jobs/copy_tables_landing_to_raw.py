import re
import sys
from datetime import datetime

import boto3
from awsglue.context import GlueContext
from awsglue.dynamicframe import DynamicFrame
from awsglue.job import Job
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext

from scripts.helpers.helpers import (
    PARTITION_KEYS,
    add_timestamp_column,
    get_glue_env_var,
    initialise_job,
)


def purge_today_partition(
    glue_context: GlueContext,
    target_destination: str,
    table_name: str,
    retentionPeriod: int = 0,
) -> None:
    """
    Purges (delete) only today's partition under the given target destination.
    Parameters:
      glue_context: GlueContext instance.
      target_destination: Base S3 path (e.g., "s3://your-bucket/path").
      table_name: Name of the table being purged for logging purposes.
      retentionPeriod: Retention period in hours (default 0, meaning delete all files immediately).
    Returns:
      partition_path: The S3 partition path that was purged.
    """
    now = datetime.now()
    import_year = str(now.year)
    import_month = str(now.month).zfill(2)
    import_day = str(now.day).zfill(2)
    import_date = import_year + import_month + import_day

    partition_path = f"{target_destination}/import_year={import_year}/import_month={import_month}/import_day={import_day}/import_date={import_date}"

    logger.info(
        f"Purging today's partition for table {table_name} at path: {partition_path}"
    )
    glue_context.purge_s3_path(partition_path, {"retentionPeriod": retentionPeriod})
    logger.info(f"Successfully purged partition for table {table_name}")


## @params: [JOB_NAME]
args = getResolvedOptions(sys.argv, ["JOB_NAME"])

sc = SparkContext()
glue_context = GlueContext(sc)
spark = glue_context.spark_session
job = Job(glue_context)

# Global logger
logger = glue_context.get_logger()

initialise_job(args, job, logger)

glue_client = boto3.client("glue")
database_name_source = get_glue_env_var("glue_database_name_source")
database_name_target = get_glue_env_var("glue_database_name_target")
bucket_target = get_glue_env_var("s3_bucket_target")
prefix = get_glue_env_var("s3_prefix")
table_filter_expression = get_glue_env_var("table_filter_expression")


filtering_pattern = re.compile(table_filter_expression)
tables_to_copy = [
    table
    for table in glue_context.tableNames(dbName=database_name_source)
    if filtering_pattern.match(table)
]
logger.info(f"Tables to copy: {tables_to_copy}")
logger.info(f"Number of tables to copy: {len(tables_to_copy)}")

for table_name in tables_to_copy:
    logger.info(f"Starting to copy table {database_name_source}.{table_name}")
    table_data_frame = glue_context.create_dynamic_frame.from_catalog(
        name_space=database_name_source,
        table_name=table_name,
        transformation_ctx="data_source" + table_name,
        push_down_predicate="import_date>=date_format(date_sub(current_date, 5), 'yyyyMMdd')",
    ).toDF()

    if len(table_data_frame.columns) == 0:
        logger.info(
            f"Aborting copy of data for table {database_name_source}.{table_name}, as it has empty columns."
        )
        continue

    table_with_timestamp = add_timestamp_column(table_data_frame)

    target_destination = f"s3://{bucket_target}/{prefix}{table_name}"

    # Clean up today's partition before writing
    purge_today_partition(glue_context, target_destination, table_name)

    data_sink = glue_context.getSink(
        path=target_destination + "/",
        connection_type="s3",
        updateBehavior="UPDATE_IN_DATABASE",
        partitionKeys=PARTITION_KEYS,
        enableUpdateCatalog=True,
        transformation_ctx="data_sink" + table_name,
    )
    data_sink.setCatalogInfo(
        catalogDatabase=database_name_target, catalogTableName=table_name
    )
    data_sink.setFormat("glueparquet")
    data_sink.writeFrame(
        DynamicFrame.fromDF(table_with_timestamp, glue_context, "result_dataframe")
    )
    logger.info(f"Finished copying table {database_name_source}.{table_name}")

job.commit()
