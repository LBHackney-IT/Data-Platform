import io
import json
import os
import re
import sys
import time
import zipfile
from datetime import date

import boto3
import requests
from awsglue.context import GlueContext
from awsglue.job import Job
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext

from scripts.helpers.helpers import (
    PARTITION_KEYS,
    add_import_time_columns,
    clean_column_names,
    get_glue_env_var,
    get_secret,
)


def api_response_json(response):
    """
    checks the api response for exceptions, returns the response as json
    """
    try:
        response.raise_for_status()
    except requests.exceptions.HTTPError as ehttp:
        logger.info(f"Http Error: {ehttp} \n {response.json()}")

    except requests.exceptions.RequestException as e:
        logger.info(str(e))
        raise
    return json.loads(response.text)


def create_s3_key(
    s3_prefix, file, prefix_to_remove=None, import_date=False, include_file_name=False
):
    """
    creates the key argument for saving output files to s3
    """
    file_basename = os.path.basename(file)
    file_table_name = os.path.splitext(file_basename)
    file_table_name = file_table_name[0]
    file_table_name = file_table_name.lower()

    if prefix_to_remove == None:
        pass
    else:
        pre = prefix_to_remove.lower()

        if not file_table_name.startswith(pre):
            pass
        else:
            file_table_name = file_table_name[len(pre) :]

    file_table_name = re.sub(r"[^A-Za-z0-9]+", "_", file_table_name)

    if import_date and include_file_name:
        s3_key = f"{s3_prefix}{file_table_name}/import_year={import_date:%Y}/import_month={import_date:%m}/import_day={import_date:%d}/import_date={import_date:%Y%m%d}/{file_basename}"
    elif import_date:
        s3_key = f"{s3_prefix}{file_table_name}/import_year={import_date:%Y}/import_month={import_date:%m}/import_day={import_date:%d}/import_date={import_date:%Y%m%d}/"
    else:
        s3_key = f"{s3_prefix}{file_table_name}/"

    return s3_key


if __name__ == "__main__":
    sc = SparkContext.getOrCreate()
    glueContext = GlueContext(sc)
    spark = glueContext.spark_session

    args = getResolvedOptions(sys.argv, ["JOB_NAME"])
    job = Job(glueContext)
    job.init(args["JOB_NAME"], args)

    logger = glueContext.get_logger()
    s3 = boto3.resource("s3")

    secret_name = get_glue_env_var("secret_name", "")
    aqs = get_glue_env_var("aqs", "")
    s3_raw_zone_bucket = get_glue_env_var("s3_raw_zone_bucket", "")
    s3_downloads_prefix = get_glue_env_var("s3_downloads_prefix", "")
    s3_parquet_prefix = get_glue_env_var("s3_parquet_prefix", "")
    prefix_to_remove = get_glue_env_var("prefix_to_remove", "")

    region = "uk"
    api_key = get_secret(secret_name, "eu-west-2")
    headers = {
        "Accept": "application/json",
        "Content-Type": "application/json",
        "Authorization": api_key,
    }

    post_url = f"https://api.{region}.alloyapp.io/api/export"

    aqs = json.loads(aqs)

    response = requests.post(post_url, data=json.dumps(aqs), headers=headers)
    response = api_response_json(response)

    task_id = response["backgroundTaskId"]

    logger.info(f"task id: {task_id}")

    url = f"https://api.{region}.alloyapp.io/api/task/{task_id}"
    task_status = ""
    file_id = ""

    while task_status != "Complete":
        time.sleep(60)
        response = requests.get(url, headers=headers)

        response = api_response_json(response)
        task_status = response["task"]["status"]

    else:
        url = f"https://api.{region}.alloyapp.io/api/export/{task_id}/file"
        response = requests.get(url, headers=headers)
        response = api_response_json(response)
        file_id = response["fileItemId"]

        logger.info(f"file id: {file_id}")

        url_download = f"https://api.uk.alloyapp.io/api/file/{file_id}"
        r = requests.get(url_download, headers=headers)

        import_date = date.today()

        with io.BytesIO(r.content) as z:
            zip = zipfile.ZipFile(z, mode="r")
            file_list = zip.namelist()

            for file in file_list:
                raw_key = create_s3_key(
                    s3_downloads_prefix,
                    file,
                    prefix_to_remove,
                    import_date,
                    include_file_name=True,
                )

                s3.meta.client.upload_fileobj(
                    zip.open(file),
                    Bucket=s3_raw_zone_bucket,
                    Key=raw_key,
                )

                df = (
                    spark.read.option("header", "true")
                    .option("multiline", "true")
                    .csv(f"s3://{s3_raw_zone_bucket}/{raw_key}")
                )

                df = clean_column_names(df)
                df = add_import_time_columns(df)

                s3_parquet_key = create_s3_key(
                    s3_parquet_prefix, file, prefix_to_remove
                )

                df = (
                    df.write.partitionBy(PARTITION_KEYS)
                    .mode("append")
                    .parquet(f"s3://{s3_raw_zone_bucket}/{s3_parquet_key}")
                )

    job.commit()
