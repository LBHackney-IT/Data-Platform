import sys
from awsglue.utils import getResolvedOptions
import datetime
import boto3
from pyspark.sql import functions as f
from pyspark.sql.functions import col, max

PARTITION_KEYS = ['import_year', 'import_month', 'import_day', 'import_date']


def get_glue_env_var(key, default="none"):
    if f'--{key}' in sys.argv:
        return getResolvedOptions(sys.argv, [key])[key]
    else:
        return default


def get_secret(logger, secret_name, region_name):
    session = boto3.session.Session()

    client = session.client(
        service_name='secretsmanager',
        region_name=region_name
    )

    get_secret_value_response = client.get_secret_value(
        SecretId=secret_name
    )

    if 'SecretString' in get_secret_value_response:
        return get_secret_value_response['SecretString']
    else:
        return get_secret_value_response['SecretBinary'].decode('ascii')


def convert_pandas_df_to_spark_dynamic_df(sql_context, panadas_df):
    now = datetime.datetime.now()
    importYear = str(now.year)
    importMonth = str(now.month).zfill(2)
    importDay = str(now.day).zfill(2)
    importDate = importYear + importMonth + importDay

    # Convert to SparkDynamicDataFrame
    spark_df = sql_context.createDataFrame(panadas_df)
    spark_df = spark_df.coalesce(1)
    spark_df = spark_df.withColumn('import_datetime', f.current_timestamp())
    spark_df = spark_df.withColumn('import_timestamp', f.lit(str(now.timestamp())))
    spark_df = spark_df.withColumn('import_year', f.lit(importYear))
    spark_df = spark_df.withColumn('import_month', f.lit(importMonth))
    spark_df = spark_df.withColumn('import_day', f.lit(importDay))
    spark_df = spark_df.withColumn('import_date', f.lit(importDate))

    return spark_df

def get_latest_partitions(dfa):
   dfa = dfa.where(col('import_year') == dfa.select(max('import_year')).first()[0])
   dfa = dfa.where(col('import_month') == dfa.select(max('import_month')).first()[0])
   dfa = dfa.where(col('import_day') == dfa.select(max('import_day')).first()[0])
   return dfa