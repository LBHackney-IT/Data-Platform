import sys
from awsglue.utils import getResolvedOptions
from pyspark import SparkContext, SparkConf
from pyspark.sql import SparkSession
from awsglue.context import GlueContext
from awsglue.dynamicframe import DynamicFrame
from awsglue.job import Job
from pyspark.sql.functions import col, max
from pyspark.sql.types import StringType, IntegerType, BooleanType, DateType, FloatType, TimestampType, LongType, DoubleType, MapType
from helpers import get_latest_partitions, get_glue_env_var, PARTITION_KEYS


def castColumns(columnDict,tableName,df,typeName,dataType):
    # check if this datatype is represented in the dictionary
    if typeName not in columnDict.columns:
        return df
        # check if this table is represented for this data type in the dictionary
    if tableName+":" not in columnDict.select(typeName).schema.simpleString():
        return df
            # iterate on columns of this type
    for colName in columnDict.select(typeName+'.'+tableName).first()[0].split(','):
        # recast
        df = df.withColumn(colName ,col(colName).cast(dataType))
    return df

def castColumnsAllTypes(columnDict,tableName,df):
    df = castColumns(columnDict=columnDict, tableName=tableName, df=df, typeName="timestamp", dataType=TimestampType())
    df = castColumns(columnDict=columnDict, tableName=tableName, df=df, typeName="integer", dataType=IntegerType())
    df = castColumns(columnDict=columnDict, tableName=tableName, df=df, typeName="boolean", dataType=BooleanType())
    df = castColumns(columnDict=columnDict, tableName=tableName, df=df, typeName="float", dataType=DoubleType())
    df = castColumns(columnDict=columnDict, tableName=tableName, df=df, typeName="long", dataType=LongType())
    df = castColumns(columnDict=columnDict, tableName=tableName, df=df, typeName="double", dataType=DoubleType())
    df = castColumns(columnDict=columnDict, tableName=tableName, df=df, typeName="date", dataType=DateType())
    return df

if __name__ == "__main__":
    args = getResolvedOptions(sys.argv, ['JOB_NAME'])

    table_list_string = get_glue_env_var('table_list','')
    source_catalog_database = get_glue_env_var('source_catalog_database', '')
    s3_bucket_target = get_glue_env_var('s3_bucket_target', '')
    column_dict_path = get_glue_env_var('column_dict_path', '')

    conf = SparkConf().set("spark.sql.sources.partitionOverwriteMode","dynamic")
    sc = SparkContext.getOrCreate(conf)
    glueContext = GlueContext(sc)
    spark = SparkSession(sc)
    logger = glueContext.get_logger()
    job = Job(glueContext)
    job.init(args['JOB_NAME'], args)

    #   load table list
    table_list = table_list_string.split(',')
    #   load columns dictionary
    columnsDictionary = spark.read.option("multiline", "true").json(column_dict_path)


    for nameOfTableToRecast in table_list:
        #   load data
        source_ddf = glueContext.create_dynamic_frame.from_catalog(
            name_space=source_catalog_database,
            table_name=nameOfTableToRecast
        )
        source_df = source_ddf.toDF()


        #   recast
        source_df = castColumnsAllTypes(columnDict=columnsDictionary, tableName=nameOfTableToRecast, df=source_df)

        # WRITE TO S3
        resultDataFrame = DynamicFrame.fromDF(source_df, glueContext, "resultDataFrame")
        target_destination = s3_bucket_target + nameOfTableToRecast
    
        resultDataFrame.toDF().write.mode("overwrite").format("parquet").partitionBy(PARTITION_KEYS).save(target_destination)
    
    job.commit()