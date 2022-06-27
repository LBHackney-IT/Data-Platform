import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
from awsglue.dynamicframe import DynamicFrame

from scripts.helpers.helpers import get_glue_env_var, add_import_time_columns, PARTITION_KEYS

args = getResolvedOptions(sys.argv, ['JOB_NAME'])

sc = SparkContext()
glue_context = GlueContext(sc)
job = Job(glue_context)
job.init(args['JOB_NAME'], args)
logger = glue_context.get_logger()

s3_target = get_glue_env_var("s3_target")
table_names = get_glue_env_var("table_names").split(",")
role_arn = get_glue_env_var("role_arn")
number_of_workers = int(get_glue_env_var("number_of_workers"))

# this is the number of partitions to use whilst reading, default 1, max 1000000
# Recommened calculation for splits, if using standard workers is: splits =  (8 * numWorkers - 12)
# Recommened calculation for splits, if using standard G.1X is: splits =  8 * (numWorkers - 1)
number_of_splits = 8 * number_of_workers - 12


for table_name in table_names:
    logger.info(f"Starting import for table {table_name}")
    read_dynamo_db_options = {
        "dynamodb.input.tableName": table_name,
        "dynamodb.splits": f"{number_of_splits}" , 
        "dynamodb.sts.roleArn": role_arn,
    }

    source_dynamic_frame = glue_context.create_dynamic_frame.from_options(
        connection_type="dynamodb",
        connection_options=read_dynamo_db_options,
        tranformation_ctx=f"{table_name}_source_data"
    )

    data_frame = source_dynamic_frame.toDF()
    data_frame = data_frame.na.drop('all') # Drop all rows where all values are null NOTE: must be done before add_import_time_columns
    data_frame_with_import_columns = add_import_time_columns(data_frame)

    dynamic_frame_to_write = DynamicFrame.fromDF(data_frame_with_import_columns, glue_context, f"{table_name}_output_data")

    glue_context.write_dynamic_frame.from_options(
        frame=dynamic_frame_to_write,
        connection_type="s3",
        format="parquet",
        connection_options={ "path": f"{s3_target}/{table_name}", "partitionKeys": PARTITION_KEYS },
        transformation_ctx=f"{table_name}_output_data"
    )

job.commit()

