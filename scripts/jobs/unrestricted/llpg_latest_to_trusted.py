 # Before running your job, go to the Job Details tab and customise:
    # - the temporary storage path (same as above)

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

def clear_target_folder(s3_bucket_target):
    s3 = boto3.resource('s3')
    folderString = s3_bucket_target.replace('s3://', '')
    bucketName = folderString.split('/')[0]
    prefix = folderString.replace(bucketName+'/', '')+'/'
    bucket = s3.Bucket(bucketName)
    bucket.objects.filter(Prefix=prefix).delete()
    return

if __name__ == "__main__":
    
    # read job parameters
    args = getResolvedOptions(sys.argv, ['JOB_NAME'])
    source_catalog_table = get_glue_env_var('source_catalog_table','')
    source_catalog_database = get_glue_env_var('source_catalog_database', '')
    s3_bucket_target = get_glue_env_var('s3_bucket_target', '')
 
    # start the Spark session and the logger
    glueContext = GlueContext(SparkContext.getOrCreate()) 
    logger = glueContext.get_logger()
    job = Job(glueContext)
    job.init(args['JOB_NAME'], args)

    logger.info(f'The job is starting. The source table is {source_catalog_database}.{source_catalog_table}')

    data_source = glueContext.create_dynamic_frame.from_catalog(
        name_space=source_catalog_database,
        table_name=source_catalog_table,
        push_down_predicate = create_pushdown_predicate('import_date', 10)
    )
    
    map_ward = {
                "Hoxton East and Shoreditch": "Hoxton East & Shoreditch"
                }
                
    df2 = data_source.toDF()
    df2 = get_latest_partitions(df2)
    # Duplicate ward column to apply mapping
    df2 = df2.withColumn('llpg_ward_map', col('ward').cast('string')) 

    # Apply Mapping
    df2 = df2.replace(to_replace=map_ward, subset=['llpg_ward_map'])
    
    # Create a single line address
    df2 = df2.withColumn('address_full',concat(trim(col('line1')),
                                                 lit(", "),
                                                 trim(col('line2')),
                                                 lit(", "),
                                                 trim(col('line3')),
                                                 lit(", "),
                                                 trim(col('line4')),
                                                 lit(", "),
                                                 trim(col('postcode')),
                                                ))

    # Filter the ones with an approved preferred status
    app = df2.filter(df2.lpi_logical_status == "Approved Preferred") 

#create historic set of data not in the approved
    hist = df2.filter(df2.lpi_logical_status =="Historic") 

    delta = hist.join(app,hist.uprn == app.uprn,'leftanti') #remove the uprns in the other dataset

    delta = delta.withColumnRenamed("uprn","uprn_hist") 

    # seperate the lpi key as int
    delta = delta.withColumn("lpi_key2", delta.lpi_key.substr(-9,9))

    # cast the value as an int
    delta = delta.withColumn("key_int", delta.lpi_key2.cast('int')) 


    #create the composite key
    delta = delta.withColumn('comp_id', concat(delta.uprn_hist,delta.key_int))

    #get the latest address for historic cases, create the base df with comp_id to join
    hist = delta.select("uprn_hist","lpi_key")
    hist = hist.withColumn("lpi_key2", hist.lpi_key.substr(-9,9))
    # cast the value as an int
    hist = hist.withColumn("key_int", hist.lpi_key2.cast('int')) 

    # get the max lpi with comp_id to join
    hist_max = hist.groupBy("uprn_hist").max("key_int")
    hist_max = hist_max.withColumnRenamed("max(key_int)","key_link")
    hist_max = hist_max.withColumn('comp_id', concat(hist_max.uprn_hist,hist_max.key_link))
    hist_max = hist_max.drop('uprn_hist')

    # join the comp ids to get the latest, drop fields and rename
    hist_final = hist_max.join(delta,hist_max.comp_id ==  delta.comp_id,"left")
    hist_final = hist_final.drop('key_link','comp_id','max_id','lpi_key2','key_int')
    hist_final = hist_final.withColumnRenamed("uprn_hist","uprn") 

    #union the approved and the historic data
    unionDF2 = app.union(hist_final)
    
#add the provisional ones
    prov = df2.filter(df2.lpi_logical_status =="Provisional") 
    #remove the uprns in the other dataset
    delta = prov.join(unionDF2,prov.uprn == unionDF2.uprn,'leftanti') 
    delta = delta.withColumnRenamed("uprn","uprn_prov") 

    # seperate the lpi key as int
    delta = delta.withColumn("lpi_key2", delta.lpi_key.substr(-9,9))
    delta = delta.withColumn("key_int", delta.lpi_key2.cast('int')) # cast the value as an int

    #create the composite key
    delta = delta.withColumn('comp_id', concat(delta.uprn_prov,delta.key_int))

    #get the latest address
    prov1 = delta.select("uprn_prov","lpi_key")
    prov1 = prov1.withColumn("lpi_key2", prov1.lpi_key.substr(-9,9))
    prov1 = prov1.withColumn("key_int", prov1.lpi_key2.cast('int')) # cast the value as an int

    prov_max = prov1.groupBy("uprn_prov").max("key_int")
    prov_max = prov_max.withColumnRenamed("max(key_int)","key_link")

    prov_latest = prov_max.withColumn('comp_id', concat(prov_max.uprn_prov,prov_max.key_link))
    prov_latest = prov_latest.drop('uprn_prov')

    # join the comp ids to get the latest
    joinh2 =  prov_latest.join(delta,prov_latest.comp_id ==  delta.comp_id,"left")
    joinh2 = joinh2.drop('key_link','comp_id','max_id','lpi_key2','key_int')
    joinh2 = joinh2.withColumnRenamed("uprn_prov","uprn") 

    #Union with the previous dataset
    unionDF3 = unionDF2.union(joinh2)

#create the output
    output = unionDF3.drop('ward')
    output = unionDF3.withColumnRenamed("llpg_ward_map","ward")
    
    # Convert data frame to dynamic frame 
    dynamic_frame = DynamicFrame.fromDF(output, glueContext, "target_data_to_write")


# delete the target folder in the trusted zone
    clear_target_folder(s3_bucket_target)

# Write the data to S3
    parquet_data = glueContext.write_dynamic_frame.from_options(
        frame=dynamic_frame,
        connection_type="s3",
        format="parquet",
        connection_options={"path": s3_bucket_target, "partitionKeys": ['import_year', 'import_month', 'import_day', 'import_date']},
        transformation_ctx="target_data_to_write")

    job.commit()

   
