import datetime
import io
import json
import sys
import time
import zipfile

import requests
from awsglue.context import GlueContext
from awsglue.dynamicframe import DynamicFrame
from awsglue.job import Job
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from pyspark.sql import SparkSession, SQLContext
from scripts.helpers.helpers import (
    PARTITION_KEYS,
    add_import_time_columns,
    clean_column_names,
    get_glue_env_var,
    get_secret,
    table_exists_in_catalog,
)


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
    return json.loads(response.text)


if __name__ == "__main__":
    args = getResolvedOptions(sys.argv, ["JOB_NAME"])
    sc = SparkContext.getOrCreate()
    glue_context = GlueContext(sc)
    sqlContext = SQLContext(sc)
    spark = SparkSession(sc)
    s3 = boto3.resource("s3")
    logger = glue_context.get_logger()
    job = Job(glue_context)
    job.init(args["JOB_NAME"], args)

    resource = get_glue_env_var("resource", "")
    bucket_target = get_glue_env_var("s3_bucket_target", "")
    alloy_download_bucket = get_glue_env_var("alloy_download_bucket", "")
    api_key = get_secret(get_glue_env_var("secret_name", ""), "eu-west-2")
    database = get_glue_env_var("database", "")
    s3_prefix = get_glue_env_var("s3_prefix", "")
    table_prefix = get_glue_env_var("table_prefix", "")
    aqs = get_glue_env_var("aqs", "")

    glue_catalogue_table_name = table_prefix + resource
    s3_target_url = "s3://" + bucket_target + "/" + s3_prefix + resource + "/"
    s3_download_url = "s3://" + bucket_target + "/" + alloy_download_bucket

    last_import_date_time = format_time(
        get_last_import_date_time(glue_context, database, glue_catalogue_table_name)
    )

    logger.info(f"last import date time: {last_import_date_time}")

    if resource == "":
        raise Exception("--resource value must be defined in the job arguments")

    logger.info(f"Getting resource {resource}")

    headers = {"Accept": "application/json", "Content-Type": "application/json"}
    region = "uk"
    post_url = f"https://api.{region}.alloyapp.io/api/export/?token={api_key}"
    aqs = json.loads(aqs)
    aqs = update_aqs(aqs, last_import_date_time)
    filename = aqs["fileName"]
    file_path = filename.split(".")[0] + "/" + filename

    response = requests.post(post_url, data=json.dumps(aqs), headers=headers)
    response = api_response_json(response)
    task_id = response["backgroundTaskId"]

    logger.info(f"task id: {task_id}")

    url = f"https://api.{region}.alloyapp.io/api/task/{task_id}?token={api_key}"
    task_status = ""
    file_id = ""

    while task_status != "Complete":
        time.sleep(60)
        response = requests.get(url)

        response = api_response_json(response)
        task_status = response["task"]["status"]

    else:
        url = f"https://api.{region}.alloyapp.io/api/export/{task_id}/file?token={api_key}"
        response = requests.get(url)
        response = api_response_json(response)
        file_id = response["fileItemId"]

        logger.info(f"file id: {file_id}")

        url_download = f"https://api.uk.alloyapp.io/api/file/{file_id}?token={api_key}"
        r = requests.get(url_download, headers=headers)

        with io.BytesIO(r.content) as z:
            with zipfile.ZipFile(z, mode="r") as zip:
                s3.meta.client.upload_fileobj(
                    zip.open(file_path),
                    Bucket=bucket_target,
                    Key=alloy_download_bucket + filename,
                )

        df = spark.read.options(header=True, inferSchema=True).csv(
            s3_download_url + filename
        )
        df = clean_column_names(df)
        df = df.replace("nan", None).replace("NaT", None)
        df = df.na.drop("all")
        df = add_import_time_columns(df)

        dataframe = DynamicFrame.fromDF(df, glue_context, f"alloy_{resource}")
        parquetData = glue_context.write_dynamic_frame.from_options(
            frame=dataframe,
            connection_type="s3",
            connection_options={
                "path": s3_target_url,
                "partitionKeys": PARTITION_KEYS,
            },
            format="parquet",
            transformation_ctx=f"alloy_{resource}_sink",
        )

    job.commit()
