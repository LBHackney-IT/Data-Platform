import datetime
import sys

from awsglue.context import GlueContext
from awsglue.dynamicframe import DynamicFrame
from awsglue.job import Job
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext

from scripts.helpers.helpers import add_import_time_columns

args = getResolvedOptions(
    sys.argv,
    [
        "JOB_NAME",
        "ARG_TABLE_NAME",
        "ARG_INPUT_BUCKET",
        "ARG_INPUT_PREFIX",
        "ARG_OUTPUT_BUCKET",
        "ARG_OUTPUT_PREFIX",
        "ARG_OUTPUT_CATALOG_DATABASE",
        "ARG_FORMAT",
    ],
)


table_name = args["ARG_TABLE_NAME"]
input_bucket = args["ARG_INPUT_BUCKET"]
input_prefix = args["ARG_INPUT_PREFIX"]
output_bucket = args["ARG_OUTPUT_BUCKET"]
output_prefix = args["ARG_OUTPUT_PREFIX"]
output_catalog_database = args["ARG_OUTPUT_CATALOG_DATABASE"]
fmt = args["ARG_FORMAT"]

sc = SparkContext()
glueContext = GlueContext(sc)
logger = glueContext.get_logger()

job = Job(glueContext)
job.init(args["JOB_NAME"], args)

logger.info(f"Reading table {table_name} from {input_bucket}/{input_prefix}")

table = glueContext.create_dynamic_frame.from_options(
    "s3",
    connection_options={
        "paths": [f"s3://{input_bucket}/{input_prefix}"],
        "recurse": "True",
    },
    format="json",
    transformation_ctx="datasource_0",
)


table = table.toDF()
table = add_import_time_columns(table)

transfomed_table0 = DynamicFrame.fromDF(table, glueContext, "transfomed_table0")

logger.info(f"Writing table {table_name} to {output_bucket}/{output_prefix}")

sink = glueContext.getSink(
    connection_type="s3",
    path=f"s3://{output_bucket}/{output_prefix}{table_name}",
    enableUpdateCatalog=True,
    updateBehavior="UPDATE_IN_DATABASE",
    partitionKeys=["import_year", "import_month", "import_day", "import_date"],
)

sink.setFormat(fmt)

sink.setCatalogInfo(
    catalogDatabase=output_catalog_database, catalogTableName=table_name
)

sink.writeFrame(transfomed_table0)

job.commit()
