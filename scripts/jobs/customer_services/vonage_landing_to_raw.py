# Basic Imports
import sys
from pyspark.context import SparkContext
from awsglue.context import GlueContext

from pyspark.sql.functions import lit
from scripts.helpers.helpers import PARTITION_KEYS, get_glue_env_var

import boto3
import re

sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session

logger = glueContext.get_logger()


######################################################
# functions
######################################################

# Get Raw zone latest partition
def find_importdate(importstring):
    import_date = re.search("[0-9]{8}", importstring).group()
    return import_date


def list_subfolders_in_directory(s3_client, bucket, prefix):
    response = s3_client.list_objects_v2(
        Bucket=bucket,
        Prefix=prefix,
        Delimiter="/")

    subfolders = response.get('CommonPrefixes')

    list_of_prefixes = []
    for dictionary in subfolders:
        list_of_prefixes.append(dictionary['Prefix'])

    return list_of_prefixes


def return_largest_prefix(prefix_list):
    prefix_list.sort(reverse=True)
    return prefix_list[0]


def get_latest_partition(s3_client, bucket, prefix):
    # This function looks weird but it drills down to the latest partition without listen every file.
    # Finds latest Year -> Month -> Day -> Date
    subfolders = list_subfolders_in_directory(s3_client, bucket, prefix)
    largest_prefix = return_largest_prefix(subfolders)

    subfolders = list_subfolders_in_directory(s3_client, bucket, largest_prefix)
    largest_prefix = return_largest_prefix(subfolders)

    subfolders = list_subfolders_in_directory(s3_client, bucket, largest_prefix)
    largest_prefix = return_largest_prefix(subfolders)

    subfolders = list_subfolders_in_directory(s3_client, bucket, largest_prefix)
    largest_prefix = return_largest_prefix(subfolders)

    return largest_prefix


def read_and_write_partition(landing_zone_bucket, partition_path, raw_zone_bucket, raw_zone_prefix):
    key_import_date = find_importdate(partition_path)
    import_day = key_import_date[6:]
    import_month = key_import_date[4:6]
    import_year = key_import_date[:4]

    print(f'Import Dates: {key_import_date}: Y{import_year} M{import_month} D{import_day}')
    connection_path = f"s3://{landing_zone_bucket}/{partition_path}"
    print(f'Connection Path: {connection_path}')

    dyf = glueContext.create_dynamic_frame.from_options(
        connection_type="s3",
        connection_options={"paths": [connection_path],
                            "recurse": True
                            },
        format="json",
        format_options={
            "jsonPath": "$.items[*]",
        }
    )

    print('Dynamic Frame Loaded')

    print('Converting the DynamicFrame back to SparkDF')
    dyf = dyf.toDF()
    dyf = dyf.withColumn("import_date", lit(key_import_date))
    dyf = dyf.withColumn("import_day", lit(import_day))
    dyf = dyf.withColumn("import_month", lit(import_month))
    dyf = dyf.withColumn("import_year", lit(import_year))

    print('Cast null categorizedAt column to string')
    dyf = dyf.withColumn('categorizedAt', dyf['categorizedAt'].cast('string'))

    raw_zone_write_path = f"s3://{raw_zone_bucket}/{raw_zone_prefix}"

    print('Begin writing to Parquet')
    dyf.write.mode("append").partitionBy(*PARTITION_KEYS).parquet(raw_zone_write_path)


def get_all_partitions(s3_client, bucket, prefix, raw_date):
    print(f'Bucket: {bucket}')
    print(f'Prefix: {prefix}')

    list_of_folders = []

    paginator = s3_client.get_paginator("list_objects_v2")
    pages = paginator.paginate(Bucket=bucket, Prefix=prefix)
    for page in pages:
        for obj in page.get("Contents", []):
            filestring = obj["Key"]
            import_date = find_importdate(filestring)
            if int(import_date) > int(raw_date):
                filestring = re.sub(string=filestring,
                                    pattern="\/(?![\s\S]*\/).*",
                                    repl="")
                list_of_folders.append(filestring)
            else:
                continue

    deduped_list = list(set(list_of_folders))

    return deduped_list


######################################################
# Main
######################################################

# basic variables
s3_client = boto3.client('s3')

landing_zone_bucket = get_glue_env_var('landing_zone_bucket', '')
raw_zone_bucket = get_glue_env_var('raw_zone_bucket', '')
landing_prefix = get_glue_env_var('landing_zone_prefix', '')
raw_prefix = get_glue_env_var('raw_zone_prefix', '')

# Gets Latest Partition. Used for Raw Zone
raw_partition = get_latest_partition(s3_client, raw_zone_bucket, raw_prefix)
raw_date = find_importdate(raw_partition)
print(f'Latest Raw Date: {raw_date}')

# get all the partitions we need to ingest
partition_list = get_all_partitions(s3_client, landing_zone_bucket, landing_prefix, raw_date)
print(partition_list)

# Loop through partitions and execute read script
print(f'We have {len(partition_list)} partitions past the raw date: {raw_date}')

for partition in partition_list:
    read_and_write_partition(landing_zone_bucket, partition, raw_zone_bucket, raw_prefix)

job.commit()