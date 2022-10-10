import sys
from awsglue.utils import getResolvedOptions
from pyspark import SparkContext
from pyspark.sql import SparkSession
from awsglue.context import GlueContext
from awsglue.dynamicframe import DynamicFrame
from awsglue.job import Job
from pyspark.sql.functions import col
from pyspark.sql.types import IntegerType, BooleanType, DateType, TimestampType, LongType, DoubleType
from scripts.helpers.helpers import get_glue_env_var, PARTITION_KEYS, table_exists_in_catalog, create_pushdown_predicate


def castColumns(columnDict,tableName,df,typeName,dataType):
    # check if this datatype is represented in the dictionary and if the table is represented for this data type in the dictionary
    if typeName not in columnDict or tableName not in columnDict[typeName]:
        return df
    # iterate on columns of this type
    for colName in columnDict[typeName][tableName]:
        # recast
        df = df.withColumn(colName, col(colName).cast(dataType))
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


    sc = SparkContext.getOrCreate()
    glueContext = GlueContext(sc)
    spark = SparkSession(sc)
    logger = glueContext.get_logger()
    job = Job(glueContext)
    job.init(args['JOB_NAME'], args)

    #   load table list
    table_list = table_list_string.split(',')
    #   load columns dictionary
    columnsDictionary = spark.read.option("multiline", "true").json(column_dict_path).rdd.collect()[0]
    # Prepare pushdown predicate for loading
    pushDownPredicate = create_pushdown_predicate(partitionDateColumn='import_date',daysBuffer=14)
    
    for nameOfTableToRecast in table_list:
        if not table_exists_in_catalog(glueContext, nameOfTableToRecast, source_catalog_database):
            logger.info(f"Couldn't find table {nameOfTableToRecast} in database {source_catalog_database}, moving onto next table.")
            continue

        #   load data

        source_ddf = glueContext.create_dynamic_frame.from_catalog(
            name_space = source_catalog_database,
            table_name = nameOfTableToRecast,
            push_down_predicate = pushDownPredicate,
            transformation_ctx = f"datasource_{nameOfTableToRecast}"
        )
        source_df = source_ddf.toDF()


        
        if (source_df.count() > 0):
            #  recast
            source_df = castColumnsAllTypes(columnDict=columnsDictionary, tableName=nameOfTableToRecast, df=source_df)

            # WRITE TO S3
            resultDataFrame = DynamicFrame.fromDF(source_df, glueContext, "resultDataFrame")
            target_destination = s3_bucket_target + nameOfTableToRecast
    
            parquetData = glueContext.write_dynamic_frame.from_options(
                frame=resultDataFrame,
                connection_type="s3",
                format="parquet",
                connection_options={"path": target_destination,
                        "partitionKeys": PARTITION_KEYS},
                transformation_ctx = "parquetData")

    job.commit()