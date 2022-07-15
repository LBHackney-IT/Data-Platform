import datetime
import html
import io
import json
import sys
import time
import zipfile

import boto3
import pandas as pd
import requests
from awsglue.context import GlueContext
from awsglue.dynamicframe import DynamicFrame
from awsglue.job import Job
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from helpers.helpers import (
    PARTITION_KEYS,
    add_import_time_columns,
    clean_column_names,
    get_glue_env_var,
    get_secret,
    table_exists_in_catalog,
)
from pyspark.context import SparkContext
from pyspark.sql import SparkSession, SQLContext


def get_last_import_date_time(glue_context, database, glue_catalogue_table_name):
    """
    get last import date from aws table
    """
    if not table_exists_in_catalog(glue_context, glue_catalogue_table_name, database):
        logger.info(
            f"Couldn't find table {glue_catalogue_table_name} in database {database}."
        )
        return datetime.datetime(1970, 1, 1)
    logger.info(f"found table for {glue_catalogue_table_name} in {database}")
    return (
        glue_context.sql(
            f"SELECT max(import_datetime) as max_import_date_time FROM `{database}`.{glue_catalogue_table_name}"
        )
        .take(1)[0]
        .max_import_date_time
    )


def format_time(date_time):
    """
    change date time to format expected in api payload
    """
    t = date_time.strftime("%Y-%m-%dT%H:%M:%S.%f")
    return t[:-3] + "Z"


def update_aqs(alloy_query, last_import_date_time):
    """
    update the aqs query with parameters so that only updated items are returned
    """
    child_value = [
        {
            "type": "GreaterThan",
            "children": [
                {
                    "type": "ItemProperty",
                    "properties": {"itemPropertyName": "lastEditDate"},
                },
                {"type": "DateTime", "properties": {"value": []}},
            ],
        }
    ]
    child_value[0]["children"][1]["properties"]["value"] = [last_import_date_time]
    alloy_query["aqs"]["children"] = child_value
    return alloy_query


def api_response_json(response):
    """
    checks the api resonse for exceptions, returns the response as json
    """
    try:
        response.raise_for_status()
    except requests.exceptions.HTTPError as ehttp:
        logger.info(f"Http Error: {ehttp} \n {response.json()}")

    except requests.exceptions.RequestException as e:
        logger.info(str(e))
        raise
    return response.json()


def number_unnamed_columns(df):
    for i, col_name in enumerate(df.columns):
        if col_name.strip() != "":
            col_name
        else:
            "column_" + str(i)


if __name__ == "__main__":
    args = getResolvedOptions(sys.argv, ["JOB_NAME"])
    sc = SparkContext.getOrCreate()
    glue_context = GlueContext(sc)
    spark = SparkSession(sc)
    logger = glue_context.get_logger()
    job = Job(glue_context)
    job.init(args["JOB_NAME"], args)
    sparkContext = SparkContext.getOrCreate()
    glueContext = GlueContext(sparkContext)
    sqlContext = SQLContext(sparkContext)

    resource = get_glue_env_var("resource", "")
    bucket_target = get_glue_env_var("s3_bucket_target", "")
    api_key = get_secret(get_glue_env_var("secret_name", ""), "eu-west-2")
    database = get_glue_env_var("database", "")
    s3_prefix = get_glue_env_var("s3_prefix", "")
    table_prefix = get_glue_env_var("table_prefix", "")
    aqs = get_glue_env_var("aqs", "")

    s3_target_url = "s3://" + bucket_target + "/" + s3_prefix + resource + "/"
    glue_catalogue_table_name = table_prefix + resource

    last_import_date_time = format_time(
        get_last_import_date_time(glue_context, database, glue_catalogue_table_name)
    )

    if resource == "":
        raise Exception("--resource value must be defined in the job aruguments")

    logger.info(f"Getting resource {resource}")

    headers = {"Accept": "application/json", "Content-Type": "application/json"}
    region = "uk"
    post_url = f"https://api.{region}.alloyapp.io/api/export/?token={api_key}"
    aqs = json.loads(aqs)
    aqs = update_aqs(aqs, last_import_date_time)
    filename = aqs["fileName"]

    response = requests.post(post_url, data=json.dumps(aqs), headers=headers)
    response = api_response_json(response)
    task_id = response["backgroundTaskId"]

    url = f"https://api.{region}.alloyapp.io/api/task/{task_id}?token={api_key}"
    task_status = ""
    file_id = ""

    while task_status != "Complete":
        time.sleep(60)
        response = requests.get(url)
        response = api_response_json(response)
        task_status = response["task"]["status"]

        if response.status_code != 200:
            logger.info(f"breaking with api status: {response.status_code}")
            break

    else:
        url = f"https://api.{region}.alloyapp.io/api/export/{task_id}/file?token={api_key}"
        response = requests.get(url)
        response = api_response_json(response)
        file_id = response["fileItemId"]

        url_download = f"https://api.uk.alloyapp.io/api/file/{file_id}?token={api_key}"
        r = requests.get(url_download, headers=headers)

        with zipfile.ZipFile(io.BytesIO(r.content)) as z:
            returned_csv = z.extract(member=f"{filename[:-4]}/{filename}")

        returned_csv = html.unescape(returned_csv)
        sc.addFile(returned_csv)

        sparkDynamicDataFrame = spark.read.csv(
            SparkFiles.get(filename), header=True, inferSchema=True
        )
        sparkDynamicDataFrame = number_unnamed_columns(sparkDynamicDataFrame)
        sparkDynamicDataFrame = clean_column_names(sparkDynamicDataFrame)
        sparkDynamicDataFrame = sparkDynamicDataFrame.replace("nan", None).replace(
            "NaT", None
        )
        # Drop all rows where all values are null NOTE: must be done before add_import_time_columns
        sparkDynamicDataFrame = sparkDynamicDataFrame.na.drop("all")
        sparkDynamicDataFrame = add_import_time_columns(sparkDynamicDataFrame)
        dataframe = DynamicFrame.fromDF(
            sparkDynamicDataFrame, glueContext, f"alloy_{resource}"
        )
        parquetData = glueContext.write_dynamic_frame.from_options(
            frame=dataframe,
            connection_type="s3",
            connection_options={"path": s3_target_url, "partitionKeys": PARTITION_KEYS},
            format="parquet",
            transformation_ctx=f"alloy_{resource}_sink",
        )

    job.commit()
