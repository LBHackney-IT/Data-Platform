import sys

from awsglue.context import GlueContext
from awsglue.dynamicframe import DynamicFrame
from awsglue.job import Job
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext

from scripts.helpers.helpers import (
    PARTITION_KEYS,
    add_import_time_columns,
    get_glue_env_var,
)

args = getResolvedOptions(sys.argv, ["JOB_NAME"])

sc = SparkContext()
glue_context = GlueContext(sc)
job = Job(glue_context)
job.init(args["JOB_NAME"], args)
logger = glue_context.get_logger()

s3_target = get_glue_env_var("s3_target")
table_names = get_glue_env_var("table_names").split(",")
role_arn = get_glue_env_var("role_arn")

for table_name in table_names:
    logger.info(f"Starting import for table {table_name}")
    read_dynamo_db_options = {
        "dynamodb.export": "ddb",
        "dynamodb.tableArn": (
            f"arn:aws:dynamodb:eu-west-2:{role_arn.split(':')[4]}:table/{table_name}"
        ),
        "dynamodb.simplifyDDBJson": "true",
        "dynamodb.sts.roleArn": role_arn,
    }

    source_dynamic_frame = glue_context.create_dynamic_frame.from_options(
        connection_type="dynamodb",
        connection_options=read_dynamo_db_options,
        tranformation_ctx=f"{table_name}_source_data",
    )

    data_frame = source_dynamic_frame.toDF()

    # Drop all rows where all values are null NOTE: must be done before
    # add_import_time_columns
    data_frame = data_frame.na.drop("all")
    data_frame_with_import_columns = add_import_time_columns(data_frame)

    dynamic_frame_to_write = DynamicFrame.fromDF(
        data_frame_with_import_columns, glue_context, f"{table_name}_output_data"
    )

    glue_context.write_dynamic_frame.from_options(
        frame=dynamic_frame_to_write,
        connection_type="s3",
        format="parquet",
        connection_options={
            "path": f"{s3_target}/{table_name}",
            "partitionKeys": PARTITION_KEYS,
        },
        transformation_ctx=f"{table_name}_output_data",
    )

job.commit()
