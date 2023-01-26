import datetime
import re
import sys
import unicodedata

import builtins
import boto3
from awsglue.utils import getResolvedOptions
from pyspark.sql import functions as f, DataFrame
from pyspark.sql.functions import col, from_json, to_date, concat, when, lit, year, month, dayofmonth, broadcast, max
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


def add_timestamp_column_from_date(data_frame, import_date_as_datetime):
    return data_frame.withColumn('import_timestamp', f.lit(str(import_date_as_datetime.timestamp())))


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


def get_max_date_partition_value_from_glue_catalogue(database_name: StringType, table_name: StringType, partition_key: StringType) -> StringType:
    """Browses S3 partitions for a given Glue database table and returns the latest partition value for the given
    partition key. This works for date partitions formatted like '2022' or '20221225'  This value can then be used in a pushdown predicate.
    
    Args:
        database_name: name of the database where the table resides in the Glue catalogue
        table_name: name of the table in the Glue catalogue
        partition_key: name of the relevant partition key, e.g. import_date or snapshot_date
        
    Returns:
        A string representing the latest partition value, e.g '20221103'
    """
    client = boto3.client('glue', region_name='eu-west-2')
    paginator = client.get_paginator('get_partitions')
    response_iterator = paginator.paginate(
        DatabaseName=database_name,
        TableName=table_name,
        Segment={
            'SegmentNumber': 0,
            'TotalSegments': 1
        },
        PaginationConfig={
            'MaxItems': 100000,
            'PageSize': 100,
            'StartingToken': ''
        }
    )
    partition_value_list = []
    for response in response_iterator:
        for partition in response['Partitions']:
            location = partition['StorageDescriptor']['Location']
            regex_group = '(\d{8})'
            found = re.search(f'{partition_key}={regex_group}', location)
            if found:
                partition_value_list.append(found.group(1))
    if partition_value_list:
        return builtins.max(partition_value_list)


def get_latest_partitions(dfa):
    dfa = dfa.where(f.col('import_year') == dfa.select(
        f.max('import_year')).first()[0])
    dfa = dfa.where(f.col('import_month') == dfa.select(
        f.max('import_month')).first()[0])
    dfa = dfa.where(f.col('import_day') == dfa.select(
        f.max('import_day')).first()[0])
    return dfa


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
            .withColumn("import_year_int", col("import_year").cast(IntegerType())) \
            .withColumn("import_month_int", col("import_month").cast(IntegerType())) \
            .withColumn("import_day_int", col("import_day").cast(IntegerType())) \
            .select(max(to_date(concat(
            col("import_year_int"),
            when(col("import_month_int") < 10, concat(lit("0"), col("import_month_int")))
                .otherwise(col("import_month_int")),
            when(col("import_day_int") < 10, concat(lit("0"), col("import_day_int")))
                .otherwise(col("import_day_int"))),
            format="yyyyMMdd")).alias("latest_partition_date")) \
            .select(year(col("latest_partition_date")).alias("latest_year_int"),
                    month(col("latest_partition_date")).alias("latest_month_int"),
                    dayofmonth(col("latest_partition_date")).alias("latest_day_int"))

        # Unblock the below code when the test environment of docker is fixed and delete the above one.
        # latest_partition = df \
        #    .select(max(to_date(concat(col("import_year"), lit("-"), col("import_month"), lit("-"), col("import_day")),
        #                         format="yyyy-L-d")).alias("latest_partition_date")) \
        #     .select(year(col("latest_partition_date")).alias("latest_year"),
        #             month(col("latest_partition_date")).alias("latest_month"),
        #             dayofmonth(col("latest_partition_date")).alias("latest_day"))

        result = df \
            .join(broadcast(latest_partition),
                  (df.import_year == latest_partition["latest_year_int"]) &
                  (df.import_month == latest_partition["latest_month_int"]) &
                  (df.import_day == latest_partition["latest_day_int"])) \
            .drop("latest_year_int", "latest_month_int", "latest_day_int")

    return result


def get_latest_snapshot_optimized(df: DataFrame) -> DataFrame:
    """Filters the DataFrame based on the latest (most recent) snapshot_date partition. It uses snapshot_date if available else it uses
    snapshot_year, snapshot_month, snapshot_day to calculate the latest partition.

    Args:
        df: Input DataFrame

    Returns:
        DataFrame belonging to the most recent partition.

    """

    if "snapshot_date" in df.columns:
        latest_partition = df.select(max(col("snapshot_date")).alias("latest_snapshot_date"))
        result = df \
            .join(broadcast(latest_partition), (df["snapshot_date"] == latest_partition["latest_snapshot_date"])) \
            .drop("latest_snapshot_date")
    else:
        # The below code is temporary fix till docker test environment is fixed, post which delete this and use the one
        # below which is commented as of now.
        latest_partition = df \
            .withColumn("snapshot_year_int", col("snapshot_year").cast(IntegerType())) \
            .withColumn("snapshot_month_int", col("snapshot_month").cast(IntegerType())) \
            .withColumn("snapshot_day_int", col("snapshot_day").cast(IntegerType())) \
            .select(max(to_date(concat(
            col("snapshot_year_int"),
            when(col("snapshot_month_int") < 10, concat(lit("0"), col("snapshot_month_int")))
                .otherwise(col("snapshot_month_int")),
            when(col("snapshot_day_int") < 10, concat(lit("0"), col("snapshot_day_int")))
                .otherwise(col("snapshot_day_int"))),
            format="yyyyMMdd")).alias("latest_snapshot_date")) \
            .select(year(col("latest_snapshot_date")).alias("latest_year_int"),
                    month(col("latest_snapshot_date")).alias("latest_month_int"),
                    dayofmonth(col("latest_snapshot_date")).alias("latest_day_int"))

        # Unblock the below code when the test environment of docker is fixed and delete the above one.
        # latest_partition = df \
        #    .select(max(to_date(concat(col("snapshot_year"), lit("-"), col("snapshot_month"), lit("-"), col("snapshot_day")),
        #                         format="yyyy-L-d")).alias("latest_partition_date")) \
        #     .select(year(col("latest_partition_date")).alias("latest_year"),
        #             month(col("latest_partition_date")).alias("latest_month"),
        #             dayofmonth(col("latest_partition_date")).alias("latest_day"))

        result = df \
            .join(broadcast(latest_partition),
                  (df.snapshot_year == latest_partition["latest_year_int"]) &
                  (df.snapshot_month == latest_partition["latest_month_int"]) &
                  (df.snapshot_day == latest_partition["latest_day_int"])) \
            .drop("latest_year_int", "latest_month_int", "latest_day_int")

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


def create_pushdown_predicate_for_max_date_partition_value(database_name: str, table_name: str, partition_key: str) -> str:
    """Creates an expression to use in a pushdown predicate filtering by date the data to load from S3. The date is
    the maximum date for which a partition exists. This date value is fetched from the Glue catalogue using boto3 and
    the function get_max_date_partition_value_from_glue_catalogue. The partition key used (i.e. import_date) must
    have values in the following format: yyyymmdd. The max of these values will be picked. NB: This function doesn't
    consider the creation timestamp (date when the partition was created), only the partition value.
    
    Args:
        database_name: name of the database where the table resides in the Glue catalogue
        table_name: name of the table in the Glue catalogue
        partition_key: name of the relevant partition key, e.g. import_date or snapshot_date
        
    Returns:
        A string representing a pushdown predicate expression, e.g 'import_date=20221103'
    """
    date = get_max_date_partition_value_from_glue_catalogue(database_name, table_name, partition_key)
    return f'{partition_key}={date}'


def create_pushdown_predicate_for_latest_written_partition(database_name: str, table_name: str):
    """Creates an expression to use in a pushdown predicate filtering the data to load from S3. This predicate means
    that Glue will only load the latest written partition, whatever the partition keys and values are. Unlike the
    create_pushdown_predicate_for_max_date_partition_value() function, this function only relies on the partition
    creation date.
    It is handy if you don't have a date partition (yyyymmdd) or if you don't know your partition keys.
    Limitation: Consider using create_pushdown_predicate_for_max_date_partition_value() instead if the S3 bucket is
    not being written in chronological order (e.g. if a partition from the past is being rewritten at a later date).

    Args:
        database_name: name of the database where the table resides in the Glue catalogue
        table_name: name of the table in the Glue catalogue

    Returns:
        A string representing a pushdown predicate expression,
        e.g "import_year == '2023' and import_month == '1' and import_day == '25'"
    """
    client = boto3.client('glue', region_name='eu-west-2')
    # call boto get_table to get the names of the partition keys
    response = client.get_table(
        DatabaseName=database_name,
        Name=table_name
    )
    partition_key_names = (response['Table']['PartitionKeys'])

    # create a dict to hold partition created dates and values
    creation_date_dict = {}

    # call boto get_partitions to get all partitions of the given table
    paginator = client.get_paginator('get_partitions')
    response_iterator = paginator.paginate(
        DatabaseName=database_name,
        TableName=table_name,
        Segment={
            'SegmentNumber': 0,
            'TotalSegments': 1
        },
        ExcludeColumnSchema=True,
        PaginationConfig={
            'MaxItems': 100000,
            'PageSize': 10,
            'StartingToken': ''
        }
    )
    for response in response_iterator:
        for partition in response['Partitions']:
            creation_date_dict[partition['CreationTime']] = partition['Values']

    # retrieve the latest partition based on the max writing date.
    max_values = creation_date_dict[max(creation_date_dict)]

    # Create a pushdown predicate string using all the partition keys and their respective values
    # We are assuming that all these values are strings
    pushdown_predicate_list = []
    for i in range(len(partition_key_names)):
        pushdown_predicate_list.append(partition_key_names[i]['Name'] + " == '" + max_values[i] + "'")
    separator = ' and '
    pushdown_predicate_string = separator.join(pushdown_predicate_list)

    print(f'Generated the following pushdown predicate by browsing the Glue catalogue: {pushdown_predicate_string}')
    return pushdown_predicate_string


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


def rename_file(source_bucket, src_prefix, filename):
    print("S3 Bucket: ", source_bucket)
    print("Prefix: ", src_prefix)
    print("Filename: ", filename)
    try:
        client = boto3.client('s3')

        ## Get a list of files with prefix (we know there will be only one file)
        response = client.list_objects(
            Bucket=source_bucket,
            Prefix=src_prefix
        )
        name = response["Contents"][0]["Key"]

        print("Found File: ", name)

        ## Store Target File File Prefix, this is the new name of the file
        target_source = {'Bucket': source_bucket, 'Key': name}

        target_key = src_prefix + filename

        print("New Filename: ", target_key)

        ### Now Copy the file with New Name
        client.copy(CopySource=target_source, Bucket=source_bucket, Key=target_key)

        ### Delete the old file
        client.delete_object(Bucket=source_bucket, Key=name)

    except Exception as error:
        ## do nothing
        print('Error Occured: rename_file', error)


def move_file(bucket, source_path, target_path, filename):
    print("S3 Bucket: ", bucket)
    print("Source Path: ", source_path)
    print("Target Path: ", target_path)
    try:
        client = boto3.client('s3')

        source_key = source_path + filename
        target_key = target_path + filename
        ## Store Target File File Prefix, this is the new name of the file
        target_source = {
            'Bucket': bucket,
            'Key': source_key
        }

        ### Now Copy the file with New Name
        client.copy(CopySource=target_source, Bucket=bucket, Key=target_key)

        ### Delete the old file
        client.delete_object(Bucket=bucket, Key=source_key)
        print("File Moved to: ", target_key)
    except Exception as error:
        ## do nothing
        print('Error Occured: rename_file', error)


def working_days_diff(dataframe, id_column, date_from_column, date_to_column, result_column, bank_holiday_dataframe):
    """
    This function calculates the number of working days between 2 dates.
    The id_column in the source table must be UNIQUE.
    The function requires a dataframe of bank holidays. You can find Hackney bank holidays
    in csv format in data platform raw zone/unrestricted
    and load it before calling the function using:
    bank_holiday_dataframe = execution_context.spark_session.read.format("csv").option("header", "true").load(
            "s3://dataplatform-stg-raw-zone/unrestricted/util/hackney_bank_holiday.csv")
    Args:
        dataframe: The input dataframe
        id_column: The column from the input dataframe acting as a unique ID
        date_from_column: the column from the input dataframe representing the starting date for the calculation
        date_to_column: the column from the input dataframe representing the ending date for the calculation
        result_column: the column that will be used to store the days count result
        bank_holiday_dataframe: an external dataframe containing a list of bank holidays in date format stored in a column called 'date'

    Returns: dataframe - the input dataframe with the result_column added and populated

    """
    # Prepare a working table containing only the required columns from the input table
    df_dates = dataframe.select(id_column, date_from_column, date_to_column)

    # Explode the table creating one row per day between date_from and date_to
    df_exploded = df_dates.withColumn('exploded', f.explode(
        f.sequence(f.to_date(date_from_column), f.to_date(date_to_column))))

    # turn bank holidays into a list
    bank_holiday_list = bank_holiday_dataframe.rdd.map(lambda x: x.date).collect()
    # Filter out line that are bank weekends or bank holidays (filter is faster than left_anti join)
    df_exploded = df_exploded.filter(~f.dayofweek('exploded').isin([1, 7])) \
        .filter(~df_exploded.exploded.isin(bank_holiday_list))

    # Re-group the exploded lines and count days, including the first day
    df_dates = df_exploded.groupBy(id_column).agg(
        f.count('exploded').alias(result_column))
    # Join result back to the full input table using the id column
    dataframe = dataframe.join(df_dates, id_column, 'left')
    return dataframe


def clear_target_folder(s3_bucket_target):
    s3 = boto3.resource('s3')
    folder_string = s3_bucket_target.replace('s3://', '')
    bucket_name = folder_string.split('/')[0]
    prefix = folder_string.replace(bucket_name + '/', '') + '/'
    bucket = s3.Bucket(bucket_name)
    bucket.objects.filter(Prefix=prefix).delete()
    return

def copy_file(source_bucket, source_path, source_filename,target_bucket,target_path, target_filename):
    print("S3 Source Bucket: ", source_bucket)
    print("Source Path: ", source_path)
    print("Source File: ", source_filename)
    print("S3 Target Bucket: ", target_bucket)
    print("Target Path: ", target_path)
    print("Target File: ", target_filename)
    try:
        client = boto3.client('s3')

        source_key = source_path + source_filename
        target_key = target_path + target_filename
        ## Store Target File File Prefix, this is the new name of the file
        target_source = {
            'Bucket': source_bucket,
            'Key': source_key
        }

        ### Now Copy the file with New Name
        client.copy(CopySource=target_source, Bucket=target_bucket, Key=target_key)

        
        print("File Copied to: ", target_bucket+'/'+target_key)
    except Exception as error:
        ## do nothing
        print('Error Occured: copy_file', error)
