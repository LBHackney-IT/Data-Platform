import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
from pyspark.sql.types import StringType
from pyspark.sql.functions import col, lit
import pyspark.sql.functions as F
from awsglue.dynamicframe import DynamicFrame

from scripts.helpers.helpers import get_glue_env_var, get_latest_partitions, PARTITION_KEYS



def clean_addresses(df, source_address_column_header, source_postcode_column_header, logger):
    df = get_latest_partitions(df)

    logger.info('adding address column')
    df = df.withColumn('address', col(source_address_column_header))

    logger.info('extract postcode into a new column')
    df = df.withColumn('postcode', F.regexp_extract(F.col('address'), '([A-Za-z][A-Ha-hJ-Yj-y]?[0-9][A-Za-z0-9]? ?[0-9][A-Za-z]{2}|[Gg][Ii][Rr] ?0[Aa]{2})', 1))

    logger.info('remove postcode from address')
    df = df.withColumn('address', F.regexp_replace(F.col('address'), '([A-Za-z][A-Ha-hJ-Yj-y]?[0-9][A-Za-z0-9]? ?[0-9][A-Za-z]{2}|[Gg][Ii][Rr] ?0[Aa]{2})', ''))

    if source_postcode_column_header != 'None':
        logger.info('populate empty postcode with postcode from the other PC column')
        df = df.withColumn("postcode", \
        F.when(F.col("postcode")=="", None) \
            .otherwise(F.col("postcode")))
        logger.info('extract native postcode if there is one into a new column')
        df = df.withColumn('initial_postcode_cleaned', F.regexp_extract(F.col(source_postcode_column_header), '([A-Za-z][A-Ha-hJ-Yj-y]?[0-9][A-Za-z0-9]? ?[0-9][A-Za-z]{2}|[Gg][Ii][Rr] ?0[Aa]{2})', 1))
        df = df.withColumn("postcode", F.coalesce(F.col('postcode'),F.col('initial_postcode_cleaned')))
        df = df.drop("initial_postcode_cleaned")

    logger.info('postcode formatting')
    df = df.withColumn("postcode", F.upper(F.col("postcode")))
    df = df.withColumn("postcode_nospace", F.regexp_replace(F.col("postcode"), " +", ""))
    df = df.withColumn("postcode_length", F.length(F.col("postcode_nospace")))
    df = df.withColumn("postcode_start", F.expr("substring(postcode_nospace, 1, postcode_length -3)"))
    df = df.withColumn("postcode_end", F.expr("substring(postcode_nospace, -3, 3)"))
    df = df.withColumn("postcode", F.concat_ws(" ", "postcode_start", "postcode_end"))
    df = df.withColumn("postcode", F.regexp_replace(F.col("postcode"), "\A +\z", ''))
    df = df.drop("postcode_length")
    df = df.drop("postcode_start")
    df = df.drop("postcode_end")

    logger.info('address line formatting - remove commas and extra spaces')
    df = df.withColumn("address", F.upper(F.col("address")))
    df = df.withColumn("address", F.regexp_replace(F.col("address"), ",", ""))
    df = df.withColumn("address", F.regexp_replace(F.col("address"), " +", " "))
    df = df.withColumn("address", F.regexp_replace(F.col("address"), " ?- ?$", ""))
    df = df.withColumn("address", F.trim(F.col("address")))

    logger.info('address line formatting - remove LONDON at the end (dont do this for out of London matching)')
    df = df.withColumn("address_length", F.length(F.col("address")))
    df = df.withColumn("address", \
        F.when(F.col("address").endswith(" LONDON"), F.expr("substring(address, 1, address_length -7)")) \
            .otherwise(F.col("address")))

    logger.info('address line formatting - remove HACKNEY at the end (dont necessarily this for out of borough matching)')
    df = df.withColumn("address", F.trim(F.col("address")))
    df = df.withColumn("address_length", F.length(F.col("address")))
    df = df.withColumn("address", \
        F.when(F.col("address").endswith(" HACKNEY"), F.expr("substring(address, 1, address_length -8)")) \
            .otherwise(F.col("address")))

    logger.info('address line formatting - dashes between numbers: remove extra spaces')
    df = df.withColumn("address", F.regexp_replace(F.col("address"), '(\\d+) ?- ?(\\d+)', '$1-$2'))

    logger.info('deal with abbreviations')

    logger.info('for \'street\': we only replace st if it is at the end of the string, if not there is a risk of confusion with saint')
    df = df.withColumn("address", F.regexp_replace(F.col("address"), " ST.?$", " STREET"))

    df = df.withColumn("address", F.regexp_replace(F.col("address"), " RD.? ", " ROAD "))
    df = df.withColumn("address", F.regexp_replace(F.col("address"), " RD.?$", " ROAD"))

    df = df.withColumn("address", F.regexp_replace(F.col("address"), " AVE ", " AVENUE "))
    df = df.withColumn("address", F.regexp_replace(F.col("address"), " AVE$", " AVENUE"))

    df = df.withColumn("address", F.regexp_replace(F.col("address"), " HSE ", " HOUSE "))
    df = df.withColumn("address", F.regexp_replace(F.col("address"), " HSE$", " HOUSE"))

    df = df.withColumn("address", F.regexp_replace(F.col("address"), " CT.? ", " COURT "))
    df = df.withColumn("address", F.regexp_replace(F.col("address"), " CT.?$", " COURT"))

    # df = df.withColumn("address", F.regexp_replace(F.col("address"), " ST.? ", " SAINT "))

    df = df.withColumnRenamed("address", "concatenated_string_to_match")

    logger.info('create a unique ID')
    df = df.withColumn("prinx", F.monotonically_increasing_id())

    logger.info('create an empty uprn column')
    df = df.withColumn("uprn", lit(None).cast(StringType()))
    return df

## write into the log file with:
## @params: [JOB_NAME]
if __name__ == "__main__":
    args = getResolvedOptions(sys.argv, ['JOB_NAME'])

    cleaned_addresses_s3_bucket_target = get_glue_env_var('cleaned_addresses_s3_bucket_target', '')
    source_catalog_database = get_glue_env_var('source_catalog_database', '')
    source_catalog_table = get_glue_env_var('source_catalog_table', '')


    sc = SparkContext.getOrCreate()
    glueContext = GlueContext(sc)
    logger = glueContext.get_logger()
    job = Job(glueContext)
    job.init(args['JOB_NAME'], args)

    logger.info('Fetch Source Data')
    source_dataset = glueContext.create_dynamic_frame.from_catalog(
        name_space=source_catalog_database,
        table_name=source_catalog_table,
    )

    df = source_dataset.toDF()
    source_dataset.printSchema()

    logger.info('write into parquet')
    cleanedDataframe = DynamicFrame.fromDF(
        clean_addresses(df, get_glue_env_var('source_address_column_header', ''), get_glue_env_var('source_postcode_column_header', ''), logger),
        glueContext,
        "cleanedDataframe"
    )

    parquetData = glueContext.write_dynamic_frame.from_options(
        frame=cleanedDataframe,
        connection_type="s3",
        format="parquet",
        connection_options={"path": cleaned_addresses_s3_bucket_target, "partitionKeys": PARTITION_KEYS},
        transformation_ctx="parquetData")

    job.commit()
