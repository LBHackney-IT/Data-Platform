from pyspark.context import SparkContext
from awsglue.context import GlueContext

from pyspark.sql import SparkSession


import boto3
import re
import pandas as pd
import json

from pyspark.sql.types import StructType, StructField, StringType, IntegerType
from pyspark.sql.functions import lit

from scripts.helpers.helpers import PARTITION_KEYS, get_glue_env_var

# Base Loads

s3_client = boto3.client('s3')

landing_zone_bucket = get_glue_env_var('landing_zone_bucket', '')
raw_zone_bucket = get_glue_env_var('raw_zone_bucket', '')
prefix = get_glue_env_var('s3_prefix', '')

sc = SparkContext.getOrCreate()
spark = SparkSession.builder.getOrCreate()
glue_context = GlueContext(sc)

logger = glue_context.get_logger()


# Get the Raw Zone latest Partition
def list_subfolders_in_directory(s3_client, bucket, directory):
    response = s3_client.list_objects_v2(
        Bucket=bucket,
        Prefix=directory,
        Delimiter="/")

    subfolders = response.get('CommonPrefixes')
    return subfolders


def get_latest_file(list_of_import_years: list) -> str:
    list_of_raw_dates = []

    if len(list_of_import_years) == 0:
        return None
    else:
        for subfolder in list_of_import_years:
            path_dictionary = dict(subfolder)

            importstring = path_dictionary["Key"]

            importstring = re.sub(string=importstring,
                                  pattern="[0-9]{4}-[0-9]{2}-[0-9]{2}\/",
                                  repl="")

            importstring = re.search("[0-9]{4}-[0-9]{2}-[0-9]{2}", importstring).group()


            list_of_raw_dates.append(importstring)

        list_of_raw_dates = sorted(list_of_raw_dates, key=lambda date: datetime.strptime(date, "%Y-%m-%d"),
                                   reverse=True)

        largest_value = list_of_raw_dates[0]
        return largest_value


def get_latest_value(list_of_import_years: list) -> str:
    list_of_raw_dates = []

    if len(list_of_import_years) == 0:
        return None
    else:
        for subfolder in list_of_import_years:
            path_dictionary = dict(subfolder)

            importstring = path_dictionary["Prefix"]

            importstring = re.search("[0-9]*\/$", importstring).group()

            importstring = re.sub(string=importstring,
                                  pattern="[^0-9.]".format(),
                                  repl="")
            list_of_raw_dates.append(importstring)

        list_of_raw_dates = sorted(list_of_raw_dates, key=int, reverse=True)

        largest_value = list_of_raw_dates[0]
        return largest_value


def get_latest_raw_zone_partition_date(s3_client, bucket, prefix):
    # Get Year
    folder_path = f'{prefix}/'

    year_subfolders = list_subfolders_in_directory(s3_client, bucket, folder_path)

    if year_subfolders == None:
        print(f'No Files Found in Raw Zone. Will pull all Data')
        latest_date = 0
    else:
        latest_year = get_latest_value(year_subfolders)
        print(f'The Latest Year is {latest_year}')

        # Get Month
        monthly_path = f'{folder_path}import_year={latest_year}/'
        monthly_subfolders = list_subfolders_in_directory(s3_client, bucket, monthly_path)
        latest_month = get_latest_value(monthly_subfolders)

        daily_path = f'{monthly_path}import_month={latest_month}/'
        daily_subfolders = list_subfolders_in_directory(s3_client, bucket, daily_path)
        latest_day = get_latest_value(daily_subfolders)

        latest_date = f'{latest_year}{latest_month}{latest_day}'
        print(f'The Raw Import Date is {latest_date}')

    return latest_date


def find_importdate(importstring):
    import_date = re.search("[0-9]{8}", importstring).group()
    return import_date


def get_landing_zone_dates(s3_client, bucket, prefix, date_to_filter_by):
    print(f'Bucket: {bucket}')
    print(f'Prefix: {prefix}')

    response = s3_client.list_objects_v2(
        Bucket=bucket,
        Prefix=prefix)

    random_dict = []

    for obj in response['Contents']:
        import_date = find_importdate(obj['Key'])
        if int(import_date) > int(date_to_filter_by):
            random_dict.append(obj['Key'])
        else:
            continue

    return random_dict


def read_vonage_filepath(s3_client, bucket, key):
    data = s3_client.get_object(Bucket=bucket, Key=key)
    contents = data['Body'].read()

    content_string = contents.decode()

    json_dict = json.loads(content_string)

    pandas_df = pd.DataFrame.from_dict(json_dict['items'])

    schema = StructType([
        StructField("categorizedAt", StringType(), True),
        StructField("channels", StringType(), True),
        StructField("connectFrom", StringType(), True),
        StructField("connectTo", StringType(), True),
        StructField("conversationGuid", StringType(), True),
        StructField("direction", StringType(), True),
        StructField("duration", IntegerType(), True),
        StructField("guid", StringType(), True),
        StructField("interactionPlanMapping", StringType(), True),
        StructField("medium", StringType(), True),
        StructField("mediumManager", StringType(), True),
        StructField("serviceName", StringType(), True),
        StructField("start", StringType(), True),
        StructField("status", StringType(), True)])

    spark_df = spark.createDataFrame(pandas_df, schema=schema)

    # Find Import Date from the Key
    key_import_date = find_importdate(key)

    import_day = key_import_date[6:]
    import_month = key_import_date[4:6]
    import_year = key_import_date[:4]

    spark_df = spark_df.withColumn("import_date", lit(key_import_date))
    spark_df = spark_df.withColumn("import_day", lit(import_day))
    spark_df = spark_df.withColumn("import_month", lit(import_month))
    spark_df = spark_df.withColumn("import_year", lit(import_year))

    return spark_df


latest_raw_date = get_latest_raw_zone_partition_date(s3_client, raw_zone_bucket, prefix)

list_of_landing_zone_files = get_landing_zone_dates(s3_client, landing_zone_bucket, prefix, latest_raw_date)

if (len(list_of_landing_zone_files) > 0):

    latest_raw_date = get_latest_raw_zone_partition_date(s3_client, raw_zone_bucket, prefix)

    list_of_landing_zone_files = get_landing_zone_dates(s3_client, landing_zone_bucket, prefix, latest_raw_date)

    file_number = 0
    full_spark_df = read_vonage_filepath(s3_client, landing_zone_bucket, list_of_landing_zone_files[file_number])
    print(f'list_of_landing_zone_files has {len(list_of_landing_zone_files)} files')

    file_number = file_number + 1

    while file_number < len(list_of_landing_zone_files):

        current_spark_df = read_vonage_filepath(s3_client, landing_zone_bucket, list_of_landing_zone_files[file_number])

        full_spark_df = full_spark_df.union(current_spark_df)

        file_number = file_number + 1

    write_location = "s3://" + raw_zone_bucket + "/" + prefix
    print(f'Write Location: {write_location}')
    full_spark_df.write.partitionBy(*PARTITION_KEYS).parquet(write_location)
else:
    print('Up to date')
