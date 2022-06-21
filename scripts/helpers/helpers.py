import datetime
import re
import sys
import unicodedata

import boto3
from awsglue.utils import getResolvedOptions
from pyspark.sql import functions as f, DataFrame
from pyspark.sql.functions import col, from_json, to_date, concat, when, lit, year, month, dayofmonth, broadcast
from pyspark.sql.types import StringType, StructType, IntegerType

PARTITION_KEYS = ['import_year', 'import_month', 'import_day', 'import_date']
PARTITION_KEYS_SNAPSHOT = ['snapshot_year', 'snapshot_month', 'snapshot_day', 'snapshot_date']


def format_name(col_name):
    non_alpha_num_chars_stripped = re.sub('[^a-zA-Z0-9]+', "_", col_name)
    no_trailing_underscores = re.sub("_$", "", non_alpha_num_chars_stripped)
    return no_trailing_underscores.lower()


def clean_column_names(df):
    for col_name in df.columns:
        df = df.withColumnRenamed(col_name, format_name(col_name))
    return df


def normalize_column_name(column: str) -> str:
    """
    Normalize column name by replacing all non alphanumeric characters with underscores
    strips accents and make lowercase
    :param column: column name
    :return: normalized column name
    Example of applying: df.columns = map(clean_column_names, panada_df.columns)
    """
    formatted_name = format_name(column)
    return unicodedata.normalize('NFKD', formatted_name).encode('ASCII', 'ignore').decode()


def get_glue_env_var(key, default=None):
    """
    Looks for a single variable passed in as a job parameters.
    The key given will match to any parameter that the key is a sub string of.
    So if you have two parameter keys where one is a substring of another it could return the wrong value.
    :param key: The key of the parameter to retrieve
    :param default: A value to return if the given key doesn't exist. Optional.
    :return: The value of the parameter
    Example of applying: source_catalog_database = get_glue_env_var("source_catalog_database", "")
    """
    if f'--{key}' in sys.argv:
        return getResolvedOptions(sys.argv, [key])[key]
    else:
        return default

def get_glue_env_vars(*keys):
    """
    Retrieves values for the given keys passed in as job parameters.
    This will error if a given key can't be found in the job parameters.
    :param keys: The keys of the parameters to retrieve passed as separate arguments
    :return: A tuple containing the values for the parameters
    Example of applying: (source_catalog_database, source_catalog_table) = get_glue_env_vars("source_catalog_database", "source_catalog_table")
    """
    vars = getResolvedOptions(sys.argv, [*keys])
    return (vars[key] for key in keys)

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


# def get_latest_partitions(dfa):
#     dfa = dfa.where(f.col('import_year') == dfa.select(
#         f.max('import_year')).first()[0])
#     dfa = dfa.where(f.col('import_month') == dfa.select(
#         f.max('import_month')).first()[0])
#     dfa = dfa.where(f.col('import_day') == dfa.select(
#         f.max('import_day')).first()[0])
#     return dfa


def get_latest_partitions_optimized(df: DataFrame) -> DataFrame:
    """Filters the DataFrame based on the latest (most recent) partition. It uses import_date if available else it uses
    import_year, import_month, import_day to calculate the latest partition.

    Args:
        df: Input DataFrame

    Returns:
        DataFrame belonging to the most recent partition.

    """

    if "import_date" in df.columns:
        latest_partition = df.select(max(col("import_date")).alias("latest_import_date"))
        result = df \
            .join(broadcast(latest_partition), (df["import_date"] == latest_partition["latest_import_date"])) \
            .drop("latest_import_date")
    else:
        # The below code is temporary fix till docker test environment is fixed, post which delete this and use the one
        # below which is commented as of now.
        latest_partition = df \
            .withColumn("import_year", col("import_year").cast(IntegerType())) \
            .withColumn("import_month", col("import_month").cast(IntegerType())) \
            .withColumn("import_day", col("import_day").cast(IntegerType())) \
            .select(max(to_date(concat(
            col("import_year"),
            when(col("import_month") < 10, concat(lit("0"), col("import_month"))).otherwise(col("import_month")),
            when(col("import_day") < 10, concat(lit("0"), col("import_day"))).otherwise(col("import_day"))),
            format="yyyyMMdd")).alias("latest_partition_date")) \
            .select(year(col("latest_partition_date")).alias("latest_year"),
                    month(col("latest_partition_date")).alias("latest_month"),
                    dayofmonth(col("latest_partition_date")).alias("latest_day"))\
            .select(year(col("latest_partition_date")).alias("latest_year"),
                    month(col("latest_partition_date")).alias("latest_month"),
                    dayofmonth(col("latest_partition_date")).alias("latest_day"))

        # Unblock the below code when the test environment of docker is fixed and delete the above one.
        # latest_partition = df \
        #    .select(max(to_date(concat(col("import_year"), lit("-"), col("import_month"), lit("-"), col("import_day")),
        #                         format="yyyy-L-d")).alias("latest_partition_date")) \
        #     .select(year(col("latest_partition_date")).alias("latest_year"),
        #             month(col("latest_partition_date")).alias("latest_month"),
        #             dayofmonth(col("latest_partition_date")).alias("latest_day"))

        result = df \
            .join(broadcast(latest_partition),
                  (df.import_year == latest_partition["latest_year"]) &
                  (df.import_month == latest_partition["latest_month"]) &
                  (df.import_day == latest_partition["latest_day"])) \
            .drop("latest_year", "latest_month", "latest_day")

    return result


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


def table_exists_in_catalog(glue_context, table, database):
    tables = glue_context.tables(database)

    return tables.filter(tables.tableName == table).count() == 1


def create_pushdown_predicate(partitionDateColumn, daysBuffer):
    """
    This method creates a pushdown predicate to pass when reading data and creating a DDF.
    The partition date column will in most cases be 'import_date'.
    The daysBuffer is the number of days we want to load before the current day.
    If passing daysBuffer=0, we create no pushdown predicate and the whole dataset will be loaded.
    """
    if daysBuffer > 0:
        push_down_predicate = f"{partitionDateColumn}>=date_format(date_sub(current_date, {daysBuffer}), 'yyyyMMdd')"
    else:
        push_down_predicate = ''
    return push_down_predicate


def check_if_dataframe_empty(df):
    """
    This method returns an exception if the dataframe is empty.
    """
    if df.rdd.isEmpty():
        raise Exception('Dataframe is empty')


def get_latest_rows_by_date(df, column):
    """
    Filters dataframe to keep rows byt specifying a date column. E.g. to get the
    latest snapshot_date, column='snapshot_date'
    """
    date_filter = df.select(max(column)).first()[0]
    df = df.where(col(column) == date_filter)
    return df
