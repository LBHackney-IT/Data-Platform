import re
import sys
import boto3
import datetime
import unicodedata
from awsglue.utils import getResolvedOptions
from pyspark.sql import functions as f
from pyspark.sql.functions import col, from_json
from pyspark.sql import DataFrame
from pyspark.sql.types import StringType, StructType, StructField

PARTITION_KEYS = ['import_year', 'import_month', 'import_day', 'import_date']


def clean_column_names(df):
    # remove full stops from column names
    df = df.select([f.col("`{0}`".format(c)).alias(
        c.replace('.', '')) for c in df.columns])
    # remove trialing underscores
    df = df.select([f.col(col).alias(re.sub("_$", "", col))
                   for col in df.columns])
    # lowercase and remove double underscores
    df2 = df.select([f.col(col).alias(
        re.sub("[^0-9a-zA-Z$]+", "_", col.lower())) for col in df.columns])
    return df2


def get_metrics_target_location():
    metrics_target_location = get_glue_env_var('deequ_metrics_location')
    if (metrics_target_location == None):
        raise ValueError("deequ_metrics_location not set. Please define in the glue job arguments.")
    return metrics_target_location


def get_glue_env_var(key, default=None):
    if f'--{key}' in sys.argv:
        return getResolvedOptions(sys.argv, [key])[key]
    else:
        return default


def get_secret(secret_name, region_name):
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


def normalize_column_name(column: str) -> str:
    """
    Normalize column name by replacing invalid characters with underscore
    strips accents and make lowercase
    :param column: column name
    :return: normalized column name
    Example of applying: df.columns = map(normalize, panada_df.columns)
    """
    n = re.sub(r"[ .',;{}()\n\t=_-]+", '_', column.lower().strip())
    return unicodedata.normalize('NFKD', n).encode('ASCII', 'ignore').decode()


def add_timestamp_column(data_frame):
    now = datetime.datetime.now()
    return data_frame.withColumn('import_timestamp', f.lit(str(now.timestamp())))


def add_import_time_columns(data_frame):
    now = datetime.datetime.now()
    importYear = str(now.year)
    importMonth = str(now.month).zfill(2)
    importDay = str(now.day).zfill(2)
    importDate = importYear + importMonth + importDay

    data_frame = data_frame.withColumn(
        'import_datetime', f.current_timestamp())
    data_frame = data_frame.withColumn(
        'import_timestamp', f.lit(str(now.timestamp())))
    data_frame = data_frame.withColumn('import_year', f.lit(importYear))
    data_frame = data_frame.withColumn('import_month', f.lit(importMonth))
    data_frame = data_frame.withColumn('import_day', f.lit(importDay))
    data_frame = data_frame.withColumn('import_date', f.lit(importDate))
    return data_frame


def convert_pandas_df_to_spark_dynamic_df(sql_context, panadas_df):
    # Convert to SparkDynamicDataFrame
    spark_df = sql_context.createDataFrame(panadas_df)
    spark_df = spark_df.coalesce(1)
    return spark_df


def get_s3_subfolders(s3_client, bucket_name, prefix):
    there_are_more_objects_in_the_bucket_to_fetch = True
    folders = []
    continuation_token = {}
    while there_are_more_objects_in_the_bucket_to_fetch:
        list_objects_response = s3_client.list_objects_v2(
            Bucket=bucket_name,
            Delimiter='/',
            Prefix=prefix,
            **continuation_token
        )

        folders.extend(x['Prefix']
                       for x in list_objects_response.get('CommonPrefixes', []))
        there_are_more_objects_in_the_bucket_to_fetch = list_objects_response['IsTruncated']
        continuation_token['ContinuationToken'] = list_objects_response.get(
            'NextContinuationToken')

    return set(folders)


def get_latest_partitions(dfa):
    dfa = dfa.where(f.col('import_year') == dfa.select(
        f.max('import_year')).first()[0])
    dfa = dfa.where(f.col('import_month') == dfa.select(
        f.max('import_month')).first()[0])
    dfa = dfa.where(f.col('import_day') == dfa.select(
        f.max('import_day')).first()[0])
    return dfa


def cancel_job_if_failing_quality_checks(check_results: DataFrame):
    """
    This method will check if there are any failing constraints
    on the provided PyDeequ Verification Result.
    If there are any, it will cause the Glue job to fail by
    throwing an exception with the constraint message.

    Example of usage:
    cancel_job_if_failing_quality_checks(VerificationResult.checkResultsAsDataFrame(spark_session, checkResult))
    """
    has_error = check_results.where(check_results.constraint_status == "Failure")
    if (has_error.count() > 0):
        messages = [
            f"{message['check']}. {message['constraint_message']}"
            for message in has_error.collect()
        ]
        raise Exception(' | '.join(messages))


def parse_json_into_dataframe(spark, column, dataframe):
    """
    This method parses in a dataframe containing a JSON formatted column and expands JSON into own columns by
    examining the JSON schema.
    :param spark: spark instance from pyspark sql SparkSession.
    :param column: the name of the column that contains the JSON formatted data.
    :param dataframe: the input dataframe that contains a column of JSON formatted data to be
    expanded into columns.
    :return: dataframe containing original columns in addition to expanded JSON columns. The original
    JSON formatted column is dropped along with the interim 'json' column.
    """
    # get schema from input json column
    json_schema = spark.read.json(dataframe.rdd.map(lambda row: row[column]))
    json_schema.printSchema()
    # get column names from schema as list
    schema_cols = json_schema.columns
    # create schema for use in from_json method
    schema = StructType()
    for i in schema_cols:
        schema.add(i, StringType(), True)
    # create df with all expanded JSON columns as well as original columns. A new 'json' column also created.
    dataframe = dataframe.withColumn("json", from_json(col(column), schema)).select("json.*", '*')
    # drop columns no longer needed
    dataframe = dataframe.drop(column, 'json')
    return dataframe


def remove_prefix(string, prefix):
    """
    Removes a prefix from a string.
    :param string: the string with a prefix to be removed.
    :param prefix: the prefix to be removed.
    :return: string without prefix.
    """
    if string.startswith(prefix):
        return string[len(prefix):]
    else:
        return string[:]