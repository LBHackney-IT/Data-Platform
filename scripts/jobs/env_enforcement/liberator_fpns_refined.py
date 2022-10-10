 # This is a template for prototyping jobs. It loads the latest data from S3 using the Glue catalogue, performs an empty transformation, and writes the result to a target location in S3.
 # Before running your job, go to the Job Details tab and customise:
    # - the role Glue should use to run the job (it should match the department where the data is stored - if not, you will get permissions errors)
    # - the temporary storage path (same as above)
    # - the job parameters (replace the template values coming from the Terraform with real values)

import sys
import boto3
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
from awsglue.dynamicframe import DynamicFrame
from pyspark.sql.functions import *
import pyspark.sql.functions as F
from scripts.helpers.helpers import get_glue_env_var, get_latest_partitions, create_pushdown_predicate, add_import_time_columns, PARTITION_KEYS

# Define the functions that will be used in your job (optional). For Production jobs, these functions should be tested via unit testing.
def drop_null_columns(df):
  
    _df_length = df.count()
    null_counts = df.select([F.count(F.when(F.col(c).isNull(), c)).alias(c) for c in df.columns]).collect()[0].asDict()
    to_drop = [k for k, v in null_counts.items() if v >= _df_length]
    df = df.drop(*to_drop)
    return df
    
# Creates a function that returns only the latest snapshot, not needed if pushdown_predicate is used but it 
def get_latest_snapshot(df):

   df = df.where(col('import_date') == df.select(max('import_date')).first()[0])
   return df  

# Creates a function that clears the target folder in S3
def clear_target_folder(s3_bucket_target):
    s3 = boto3.resource('s3')
    folderString = s3_bucket_target.replace('s3://', '')
    bucketName = folderString.split('/')[0]
    prefix = folderString.replace(bucketName+'/', '')+'/'
    bucket = s3.Bucket(bucketName)
    bucket.objects.filter(Prefix=prefix).delete()
    return

# The block below is the actual job. It is ignored when running tests locally.
if __name__ == "__main__":
    
    # read job parameters
    args = getResolvedOptions(sys.argv, ['JOB_NAME'])
    source_catalog_table = get_glue_env_var('source_catalog_table','')
    source_catalog_table2 = get_glue_env_var('source_catalog_table2','')
    source_catalog_database = get_glue_env_var('source_catalog_database', '')
    s3_bucket_target = get_glue_env_var('s3_bucket_target', '')
    s3_bucket_target2 = get_glue_env_var('s3_bucket_target2', '')
 
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
        table_name = source_catalog_table,
    # if the source data IS partitionned by import_date and there is a lot of historic data there that you don't need, consider using a pushdown predicate to only load a few days worth of data and speed up the job   
        push_down_predicate = "import_date=date_format(current_date, 'yyyyMMdd')"
    )
    data_source2 = glueContext.create_dynamic_frame.from_catalog(
        name_space=source_catalog_database,
        table_name=source_catalog_table2,
        push_down_predicate = "import_date=date_format(current_date, 'yyyyMMdd')"
    )


    # convert dynamic frame to data frame
    df = data_source.toDF()
    df2 = data_source2.toDF()
    
    #filter out the blanks
    df=df.filter(df.TICKET_REF != "")
    df2=df2.filter(df2.TICKET_REF != "")
    
    #reduce the columns and rename the join field
    df2 = df2.select("ticket_ref","amount")
    df2 = df2.withColumnRenamed("ticket_ref","ticket_ref_payment")
    
    # total payments per ticket
    df2 = df2.groupby(['ticket_ref_payment']).sum()
    df2= df2.distinct()
    
    # join the tables
    output = df.join(df2,df.TICKET_REF ==  df2.ticket_ref_payment,"left")
    
    #lower case the column names
    for col in output.columns:
        output = output.withColumnRenamed(col, col.lower())
        
    #cols to drop
    output = output.drop("ticket_ref_payment" )
    
    # create output to gecode
    
    geo = output.select("ticket_ref","latitude","longitude","import_year", "import_month", "import_day", "import_date") 
    geo = geo.filter(geo.latitude.isNotNull())
    geo = geo.withColumnRenamed("ticket_ref","id")
    geo = geo.withColumn("Source", lit('Liberator'))
 
    # If the source data is NOT partitioned by import_date, create the necessary import_ columns now and populate them with today's date so the result data gets partitioned as per the DP standards. 
    # Clarification: You normally won't use this if you have used pushdown_predicate and/or get_latest_partition earlier (unless you have dropped or renamed the import_ columns of the source data and want fresh dates to partition the result by processing date)
    # df = add_import_time_columns(df)
    
    # Convert data frame to dynamic frame 
   # dynamic_frame = DynamicFrame.fromDF(output, glueContext, "target_data_to_write")
    dynamic_frame = DynamicFrame.fromDF(output.repartition(1), glueContext, "target_data_to_write")
    
    clear_target_folder(s3_bucket_target)

    # Write the data to S3
    parquet_data = glueContext.write_dynamic_frame.from_options(
        frame=dynamic_frame,
        connection_type="s3",
        format="parquet",
        connection_options={"path": s3_bucket_target, "partitionKeys": ['import_year', 'import_month', 'import_day', 'import_date']},
        transformation_ctx="target_data_to_write")
    
        #dataframe for geo output
    dynamic_frame = DynamicFrame.fromDF(geo.repartition(1), glueContext, "target_data_to_write")
    
    clear_target_folder(s3_bucket_target2)

    # Write the data to S3 for geocode

    parquet_data = glueContext.write_dynamic_frame.from_options(
        frame=dynamic_frame,
        connection_type="s3",
        format="parquet",
        connection_options={"path": s3_bucket_target2, "partitionKeys": ['import_year', 'import_month', 'import_day', 'import_date']},
        transformation_ctx="target_data_to_write")

job.commit()

   
