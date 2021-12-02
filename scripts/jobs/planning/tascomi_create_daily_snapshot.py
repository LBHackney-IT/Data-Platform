import sys
from awsglue.utils import getResolvedOptions
from pyspark import SparkContext, SparkConf
from pyspark.sql import SparkSession
from awsglue.context import GlueContext
from awsglue.dynamicframe import DynamicFrame
from awsglue.job import Job
import pyspark.sql.functions as F
from pyspark.sql.functions import col, max, date_format, date_sub, current_date
from pyspark.sql import Window
from datetime import datetime
from helpers.helpers import get_glue_env_var, table_exists_in_catalog, create_pushdown_predicate




def get_latest_snapshot(dfa):
   dfa = dfa.where(col('snapshot_date') == dfa.select(max('snapshot_date')).first()[0])
   return dfa
   
def now_as_string():
    now = datetime.now()
    snapshotYear = str(now.year)
    snapshotMonth = str(now.month).zfill(2)
    snapshotDay = str(now.day).zfill(2)
    snapshotDate = snapshotYear + snapshotMonth + snapshotDay
    return snapshotDate

def add_snapshot_date_columns(data_frame):
    now = datetime.now()
    snapshotYear = str(now.year)
    snapshotMonth = str(now.month).zfill(2)
    snapshotDay = str(now.day).zfill(2)
    snapshotDate = snapshotYear + snapshotMonth + snapshotDay
    data_frame = data_frame.withColumn('snapshot_year', F.lit(snapshotYear))
    data_frame = data_frame.withColumn('snapshot_month', F.lit(snapshotMonth))
    data_frame = data_frame.withColumn('snapshot_day', F.lit(snapshotDay))
    data_frame = data_frame.withColumn('snapshot_date', F.lit(snapshotDate))
    return data_frame
    
def prepare_increments(increment_df):
    # In case there are several days worth of increments: only keep the latest version of a record
    w = Window.partitionBy('id')
    increment_df = increment_df.withColumn('latest', F.max('last_updated').over(w))\
    .where(F.col('last_updated') == F.col('latest'))\
    .drop('latest')
    return increment_df
    
def apply_increments(snapshot_df, increment_df):
    snapshot_df = snapshot_df.join(increment_df, 'id', 'left_anti')
    snapshot_df = snapshot_df.unionByName(increment_df)
    return snapshot_df
    
def loadIncrementsSinceDate(increment_table_name, name_space, date):
    increment_ddf = glueContext.create_dynamic_frame.from_catalog(
        name_space=name_space,
        table_name=increment_table_name,
        push_down_predicate = f"import_date>={date}",
        transformation_ctx = f"datasource_{increment_table_name}"
    )
    increment_df = increment_ddf.toDF()
    return increment_df

if __name__ == "__main__":
    args = getResolvedOptions(sys.argv, ['JOB_NAME'])

    table_list_string = get_glue_env_var('table_list','')
    source_catalog_database = get_glue_env_var('source_catalog_database', '')
    s3_bucket_target = get_glue_env_var('s3_bucket_target', '')


    
    sc = SparkContext.getOrCreate()
    glueContext = GlueContext(sc)
    spark = SparkSession(sc)
    logger = glueContext.get_logger()
    job = Job(glueContext)
    job.init(args['JOB_NAME'], args)

    #   load table list
    table_list = table_list_string.split(',')

    for nameOfTableToRecast in table_list:
        snapshot_table_name = f"snapshot_{nameOfTableToRecast}"
        increment_table_name = f"increment_{nameOfTableToRecast}"
        
        # Snapshot table not in glue catalogue
        if not table_exists_in_catalog(glueContext, snapshot_table_name, source_catalog_database):
            logger.info(f"Couldn't find table {snapshot_table_name} in database {source_catalog_database}, creating a snapshot from all the increments, starting from 20210101")
            # Increment table does not exist in glue catalogue
            if not table_exists_in_catalog(glueContext, increment_table_name, source_catalog_database):
                logger.info(f"No snapshot and no increment for {increment_table_name}, going to the next table")
                continue
            increment_df = loadIncrementsSinceDate(increment_table_name=increment_table_name, name_space=source_catalog_database, date="20210101")
            if increment_df.rdd.isEmpty():
                logger.info(f"No snapshot and no increment for {increment_table_name}, going to the next table")
                continue
            # create first snapshot
            increment_df = prepare_increments(increment_df)
            snapshot_df = increment_df
        
        # snapshot table in glue catalogue
        else:
            pushDownPredicate = create_pushdown_predicate(partitionDateColumn='snapshot_date',daysBuffer=10)
            #   load latest snpashot
            snapshot_ddf = glueContext.create_dynamic_frame.from_catalog(
                name_space = source_catalog_database,
                table_name = snapshot_table_name,
                push_down_predicate = pushDownPredicate
            )
            snapshot_df = snapshot_ddf.toDF()
            snapshot_df = get_latest_snapshot(snapshot_df)
            last_snapshot_date = snapshot_df.select(max('snapshot_date')).first()[0]
        
            # load increments since the last snapshot date
            if table_exists_in_catalog(glueContext, increment_table_name, source_catalog_database):
                increment_df = loadIncrementsSinceDate(increment_table_name=increment_table_name, name_space=source_catalog_database, date=last_snapshot_date)
                if increment_df.rdd.isEmpty():
                    if last_snapshot_date == now_as_string():
                        logger.info(f"No new increment in {increment_table_name}, and we already have a snapshot for today, going to the next table")
                        continue
                    else:
                        logger.info(f"No new increment in {increment_table_name}, saving same snapshot as yesterday")
                else:
                    # prepare COU
                    increment_df = prepare_increments(increment_df)
                    increment_df = add_snapshot_date_columns(increment_df)
                    # apply COU
                    logger.info(f"Applying increment {increment_table_name}")
                    snapshot_df = apply_increments(snapshot_df, increment_df)
            else:
                logger.info(f"Couldn't find table {increment_table_name} in database {source_catalog_database}, saving same snapshot as yesterday")
            
        # add currency date and set it a partition key
        snapshot_df = add_snapshot_date_columns(snapshot_df)
        PARTITION_KEYS = ["snapshot_year", "snapshot_month", "snapshot_day", "snapshot_date"]
        
        # WRITE TO S3
        resultDataFrame = DynamicFrame.fromDF(snapshot_df, glueContext, "resultDataFrame")
        target_destination = s3_bucket_target + nameOfTableToRecast
        parquetData = glueContext.write_dynamic_frame.from_options(
            frame=resultDataFrame,
            connection_type="s3",
            format="parquet",
            connection_options={"path": target_destination, "partitionKeys": PARTITION_KEYS}
        )
    
    job.commit()