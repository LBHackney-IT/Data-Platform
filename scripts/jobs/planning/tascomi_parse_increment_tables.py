import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from awsglue.context import GlueContext
from awsglue.job import Job
from pyspark.context import SparkContext
from pyspark.sql import SparkSession

from helpers.helpers import get_glue_env_var, PARTITION_KEYS, parse_json_into_dataframe, table_exists_in_catalog, \
    check_if_dataframe_empty

# TODO this needs to go in helpers and behaviour needs to change
def check_if_dataframe_empty(df):
    if df.rdd.isEmpty():
        raise Exception('Dataframe is empty')


if __name__ == "__main__":

    args = getResolvedOptions(sys.argv, ['JOB_NAME'])

    table_list_string = get_glue_env_var('table_list', '')
    source_catalog_database = get_glue_env_var('source_catalog_database', '')
    s3_bucket_target = get_glue_env_var('s3_bucket_target', '')

    sc = SparkContext.getOrCreate()
    spark = SparkSession.builder.getOrCreate()
    glueContext = GlueContext(sc)
    logger = glueContext.get_logger()
    job = Job(glueContext)
    job.init(args['JOB_NAME'], args)

    # create table list
    table_list = table_list_string.split(',')

    # loop through each table
    for table in table_list:

        # Add prefix to table name to retrieve API data
        source_table_name = f'api_response_{table}'

        if not table_exists_in_catalog(glueContext, source_table_name, source_catalog_database):
            logger.info(f"Couldn't find table {source_table_name} in database {source_catalog_database}, moving onto next table.")
            continue

        source_data = glueContext.create_dynamic_frame.from_catalog(
            name_space=source_catalog_database,
            table_name=source_table_name,
            transformation_ctx = "data_source" + source_table_name,
            push_down_predicate = "import_date>=date_format(date_sub(current_date, 5), 'yyyyMMdd')"
        )

        df = source_data.toDF()

        check_if_dataframe_empty(df=df)

        # keep only rows where api_response_code == 200
        df = df.where(df.import_api_status_code == '200')

        # parse data
        df = parse_json_into_dataframe(spark=spark, column=table, dataframe=df)

        # WRITE TO S3
        target_destination = s3_bucket_target + table

        parsed_df = DynamicFrame.fromDF(df, glueContext, "cleanedDataframe")

        parquetData = glueContext.write_dynamic_frame.from_options(
            frame=parsed_df,
            connection_type="s3",
            format="parquet",
            connection_options={"path": target_destination, "partitionKeys": PARTITION_KEYS},
            transformation_ctx="parquetData")

    job.commit()