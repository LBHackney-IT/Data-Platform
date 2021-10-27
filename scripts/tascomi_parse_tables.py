import sys
from awsglue.dynamicframe import DynamicFrame
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from awsglue.context import GlueContext
from awsglue.job import Job
from pyspark.context import SparkContext
from pyspark.sql.window import Window
from pyspark.sql.functions import col, max, from_json
from pyspark.sql import SparkSession

from helpers import get_glue_env_var, PARTITION_KEYS, parse_json_into_dataframe, remove_prefix


def get_max_import_date(dataframe, column, date):
    # create window on selected column (to group)
    w = Window.partitionBy(column)
    dataframe = dataframe.withColumn('max_date', max(date).over(w)).where(col(date) == col('max_date')).drop('max_date')
    return dataframe


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

        # get table name without prefix for use in parse_json_into_dataframe function
        result_table_name = remove_prefix(table, 'api_response_')

        source_data = glueContext.create_dynamic_frame.from_catalog(
            name_space=source_catalog_database,
            table_name=table,
        )

        df = source_data.toDF()

        # check if api response code for table == 200
        if df['import_api_status_code'] == '200':

            # parse data
            df = parse_json_into_dataframe(spark=spark, column=result_table_name, dataframe=df)

            # keep most recently updated records only
            df = get_max_import_date(df=df, column='id', date='import_date')

            # WRITE TO S3
            result_df = DynamicFrame.fromDF(df, glueContext, "result_df")
            target_destination = s3_bucket_target + result_table_name

            df.toDF().write.mode("overwrite").format("parquet").partitionBy(PARTITION_KEYS).save(target_destination)
        else:
            pass

    job.commit()
