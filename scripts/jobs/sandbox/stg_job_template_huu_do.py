 # This is a template for prototyping jobs. It loads the latest data from S3 using the Glue catalogue, performs an empty transformation, and writes the result to a target location in S3.
 # Before running your job, go to the Job Details tab and customise:
    # - the role Glue should use to run the job (it should match the department where the data is stored - if not, you will get permissions errors)
    # - the temporary storage path (same as above)
    # - the job parameters (replace the template values coming from the Terraform with real values)

import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
from pyspark.sql.functions import col, max, lit
from awsglue.dynamicframe import DynamicFrame
from scripts.helpers.helpers import get_glue_env_var, get_latest_partitions, create_pushdown_predicate, add_import_time_columns, PARTITION_KEYS
from pyspark.sql.functions import to_date

# Define the functions that will be used in your job (optional). For Production jobs, these functions should be tested via unit testing.
def rename_location_to_country(df):
    # do something
    df = df.withColumnRenamed('location','country')
    # df.printSchema()
    return df
    
def cast_string_to_date(df):
    # do something
    df = df.withColumn("date",to_date(df.date,'yyyy-MM-dd'))
    # df.printSchema()
    return df
    
def rename_imports(df,prefix):
    df = df.withColumnRenamed('import_datetime',f'{prefix}_import_datetime')
    df = df.withColumnRenamed('import_timestamp',f'{prefix}_import_timestamp')
    df = df.withColumnRenamed('import_year',f'{prefix}_import_year')
    df = df.withColumnRenamed('import_month',f'{prefix}_import_month')
    df = df.withColumnRenamed('import_day',f'{prefix}_import_day')
    df = df.withColumnRenamed('import_date',f'{prefix}_import_date')
    return df
    
    

# The block below is the actual job. It is ignored when running tests locally.
if __name__ == "__main__":
    
    # read job parameters
    args = getResolvedOptions(sys.argv, ['JOB_NAME'])
    
    #get aws env variables
    source_catalog_table = get_glue_env_var('source_catalog_table','')
    source_catalog_database = get_glue_env_var('source_catalog_database', '')
    target_bucket = get_glue_env_var('s3_bucket_target', '')
    
    source_catalog_table2 = get_glue_env_var('source_catalog_table2', '')
    source_catalog_database2 = get_glue_env_var('source_catalog_database2', '')
    target_bucket2 = get_glue_env_var('s3_bucket_target2', '')
 
    # start the Spark session and the logger
    glueContext = GlueContext(SparkContext.getOrCreate()) 
    logger = glueContext.get_logger()
    job = Job(glueContext)
    job.init(args['JOB_NAME'], args)

    # Log something. This will be ouput in the logs of this Glue job [search in the Runs tab: all logs>xxxx_driver]
    logger.info(f'The job is starting. The source table is {source_catalog_database}.{source_catalog_table}')


    # Load data from glue catalog
    data_source = glueContext.create_dynamic_frame.from_catalog(
        name_space = source_catalog_database,
        table_name = source_catalog_table
        # if the source data IS partitionned by import_date, you can use a pushdown predicate to only load a few days worth of data and speed up the job   
        # pushdown_predicate = create_pushdown_predicate('import_date', 2)
    )
    
    data_source2 = glueContext.create_dynamic_frame.from_catalog(
        name_space=source_catalog_database2,
        table_name=source_catalog_table2
        # pushdown_predicate = create_pushdown_predicate('import_date', 2)
    )

    # convert dynamic frame to data frame
    df = data_source.toDF()
    vaccinations_df = data_source2.toDF()

    # only keep the latest imported data
    df = get_latest_partitions(df)
    vaccinations_df = get_latest_partitions(vaccinations_df)

    # Transform data using the fuctions defined outside the main block
    df = rename_location_to_country(df)
    df = rename_imports(df,'left')
    
    vaccinations_df = rename_location_to_country(vaccinations_df)
    vaccinations_df = cast_string_to_date(vaccinations_df)
    vaccinations_df = rename_imports(vaccinations_df,'right')
    
    joined_dataframe = df.join(vaccinations_df,on=['country'],how='left')
    
    # If the source data was NOT partitioned by import_date, you can add create time columns now (you'll never use statements line 46 and 59 in the same job)
    joined_dataframe = add_import_time_columns(joined_dataframe)
    
    # Convert data frame to dynamic frame 
    dyanmic_frame = DynamicFrame.fromDF(joined_dataframe, glueContext, "target_data_to_write")

    # Write the data to S3
    parquet_data = glueContext.write_dynamic_frame.from_options(
        frame=dyanmic_frame,
        connection_type="s3",
        format="parquet",
        connection_options={"path": target_bucket, "partitionKeys": PARTITION_KEYS},
        transformation_ctx="target_data_to_write")

    job.commit()

   
