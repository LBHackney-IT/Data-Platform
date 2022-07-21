import sys

from awsglue import DynamicFrame
from awsglue.context import GlueContext
from awsglue.job import Job
from awsglue.utils import getResolvedOptions
from pyspark import SparkContext
from pyspark.sql.functions import to_date, col

from scripts.helpers.helpers import get_glue_env_var, get_latest_partitions, PARTITION_KEYS

# Define the functions that will be used in your job (optional). For Production jobs, these functions should be tested via unit testing.

# The block below is the actual job. It is ignored when running tests locally.
if __name__ == "__main__":
    
    # read job parameters
    args = getResolvedOptions(sys.argv, ['JOB_NAME'])
    source_catalog_table = get_glue_env_var('source_catalog_table','')
    source_catalog_table2 = get_glue_env_var('source_catalog_table2','')
    source_catalog_database = get_glue_env_var('source_catalog_database', '')
    target_bucket = get_glue_env_var('s3_bucket_target', '')
 
    # start the Spark session and the logger
    glueContext = GlueContext(SparkContext.getOrCreate()) 
    logger = glueContext.get_logger()
    job = Job(glueContext)
    job.init(args['JOB_NAME'], args)

    # Log something. This will be ouput in the logs of this Glue job [search in the Runs tab: all logs>xxxx_driver]
    logger.info(f'The job is starting. The source table is {source_catalog_database}.{source_catalog_table}')


    # Load data from glue catalog

    data_source = glueContext.create_dynamic_frame.from_catalog(
    name_space=source_catalog_database,
    table_name=source_catalog_table
    #pushdown_predicate = create_pushdown_predicate('import_date', 2)
    )

    data_source2 = glueContext.create_dynamic_frame.from_catalog(
    name_space=source_catalog_database,
    table_name=source_catalog_table2
    #pushdown_predicate = create_pushdown_predicate('import_date', 2)
    )
        
    # if the source data IS partitionned by import_date, you can use a pushdown predicate to only load a few days worth of data and speed up the job   


    # convert dynamic frame to data frame
    df = data_source.toDF()
    df2 = data_source2.toDF()

    # only keep the latest imported data
    df = get_latest_partitions(df)
    df2 = get_latest_partitions(df2)

    # Transform data using the fuctions defined outside the main block
    df = df.withColumnRenamed('location', 'country')
    df2 = df2.withColumnRenamed('location', 'country')
    df2 = df2.withColumnRenamed('import_date', 'import_date2')
    df2 = df2.withColumnRenamed('import_year', 'import_year2')
    df2 = df2.withColumnRenamed('import_month', 'import_month2')
    df2 = df2.withColumnRenamed('import_day', 'import_day2')
    df2 = df2.withColumnRenamed('import_timestamp', 'import_timestamp2')
    df2 = df2.withColumnRenamed('import_datetime', 'import_datetime2')
    
    df = df.withColumn('last_observation_date', to_date(col("last_observation_date"),"yyyy-mm-dd"))
    
    df3 = df.join(df2, df2.country == df.country, how='left')
    
    logger.info(f'Row count {df3.count()}')
    
    # If the source data was NOT partitioned by import_date, you can add create time columns now (you'll never use statements line 46 and 59 in the same job)
    #df = add_import_time_columns(df)
    
    # Convert data frame to dynamic frame 
    dynamic_frame = DynamicFrame.fromDF(df3, glueContext, "target_data_to_write")

    # Write the data to S3
    parquet_data = glueContext.write_dynamic_frame.from_options(
        frame=dynamic_frame,
        connection_type="s3",
        format="parquet",
        connection_options={"path": target_bucket, "partitionKeys": PARTITION_KEYS},
        transformation_ctx="target_data_to_write")

    job.commit()
