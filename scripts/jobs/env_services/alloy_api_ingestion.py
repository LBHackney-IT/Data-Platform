import sys
import json
import io
import time
import zipfile
import html
import datetime
import pandas as pd
import requests
import boto3
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from awsglue.context import GlueContext
from awsglue.dynamicframe import DynamicFrame
from awsglue.job import Job
from pyspark.context import SparkContext
from pyspark.sql import SQLContext
from helpers.helpers import get_glue_env_var, get_secret, table_exists_in_catalog, normalize_column_name,  convert_pandas_df_to_spark_dynamic_df, add_import_time_columns, PARTITION_KEYS


def download_file_to_df(file_id, api_key, filename):
    """
    download export from api, extract csv from zip, read csv as pandas df
    """
    url_download = f'https://api.uk.alloyapp.io/api/file/{file_id}?token={api_key}'
    r = requests.get(url_download, headers=headers)
    z = zipfile.ZipFile(io.BytesIO(r.content))
    df = pd.read_csv(html.unescape(
        z.extract(member=filename)), index_col=False)
    return df


def get_last_import_date_time(glue_context, database, resource):
    """
    get last import date from aws table
    """
    if not table_exists_in_catalog(glue_context, resource, database):
        logger.info(f"Couldn't find table {resource} in database {database}.")
        return datetime.datetime(1970, 1, 1)
    logger.info(f"found table for {resource} in {database}")
    return glue_context.sql(f"SELECT max(import_datetime) as max_import_date_time FROM `{database}`.{resource}").take(1)[0].max_import_date_time


def format_time(date_time):
    """
    change date time to format expected in api payload
    """
    t = date_time.strftime('%Y-%m-%dT%H:%M:%S.%f')
    return t[:-3]+"Z"


def update_aqs(alloy_query, last_import_date_time):
    """
    update the aqs query with parameters so that only updated items are returned
    """
    child_value = [{"type": "GreaterThan", "children": [{"type": "ItemProperty", "properties": {
        "itemPropertyName": "lastEditDate"}}, {"type": "DateTime", "properties": {"value": []}}]}]
    child_value[0]['children'][1]['properties']['value'] = [
        last_import_date_time]
    alloy_query['aqs']['children'] = child_value
    return alloy_query


def get_task_id(response):
    """
    get the task id from the api response
    """
    if response.status_code != 200:
        logger.info(
            f"Request unsuccessful while getting task id with status code: {response.status_code}")
        return

    json_output = json.loads(response.text)
    task_id = json_output["backgroundTaskId"]
    return task_id


def get_task_status(response):
    """
    get the task status from the api response
    """
    if response.status_code != 200:
        logger.info(
            f"Request unsuccessful while getting task status with status code: {response.status_code}")
        return

    json_output = json.loads(response.text)
    task_status = json_output["task"]["status"]
    return task_status


def get_file_item_id(response):
    """
    get the file item id from the api response
    """
    if response.status_code != 200:
        logger.info(
            f"Request unsuccessful while getting file item id with status code: {response.status_code}")
        return

    json_output = json.loads(response.text)
    file_id = json_output["fileItemId"]
    return file_id


if __name__ == "__main__":
    args = getResolvedOptions(sys.argv, ['JOB_NAME'])
    sc = SparkContext.getOrCreate()
    glue_context = GlueContext(sc)
    logger = glue_context.get_logger()
    job = Job(glue_context)
    job.init(args['JOB_NAME'], args)
    sparkContext = SparkContext.getOrCreate()
    glueContext = GlueContext(sparkContext)
    sqlContext = SQLContext(sparkContext)

    resource = get_glue_env_var('resource', '')
    bucket_target = get_glue_env_var('s3_bucket_target', '')
    api_key = get_secret(get_glue_env_var('secret_name', ''), "eu-west-2")
    database = get_glue_env_var('database', '')
    prefix = get_glue_env_var('s3_prefix', '')
    aqs = get_glue_env_var('aqs', '')
    filename = get_glue_env_var('filename', '')
    last_import_date_time = format_time(
        get_last_import_date_time(glue_context, database, resource))

    s3_target_url = "s3://" + bucket_target + "/" + prefix + resource + "/"

    if resource == '':
        raise Exception(
            "--resource value must be defined in the job aruguments")

    logger.info(f"Getting resource {resource}")

    headers = {'Accept': 'application/json',
               'Content-Type': 'application/json'}
    region = 'uk'
    post_url = f'https://api.{region}.alloyapp.io/api/export/?token={api_key}'
    aqs = json.loads(aqs)
    aqs = update_aqs(aqs, last_import_date_time)
    response = requests.post(post_url, data=json.dumps(aqs), headers=headers)

    task_id = get_task_id(response)
    url = f'https://api.{region}.alloyapp.io/api/task/{task_id}?token={api_key}'
    task_status = ''
    file_id = ''

    while task_status != 'Complete':
        time.sleep(60)
        response = requests.get(url)
        task_status = get_task_status(response)

        if response.status_code != 200:
            logger.info(f'breaking with api status: {response.status_code}')
            break

    else:
        url = f'https://api.{region}.alloyapp.io/api/export/{task_id}/file?token={api_key}'
        response = requests.get(url)
        file_id = get_file_item_id(response)

        pandasDataFrame = download_file_to_df(file_id, api_key, filename)

        all_columns = list(pandasDataFrame)
        pandasDataFrame[all_columns] = pandasDataFrame[all_columns].astype(str)
        pandasDataFrame.columns = ["column" + str(i) if a.strip(
        ) == "" else a.strip() for i, a in enumerate(pandasDataFrame.columns)]
        pandasDataFrame.columns = map(
            normalize_column_name, pandasDataFrame.columns)
        sparkDynamicDataFrame = convert_pandas_df_to_spark_dynamic_df(
            sqlContext, pandasDataFrame)
        sparkDynamicDataFrame = sparkDynamicDataFrame.replace(
            'nan', None).replace('NaT', None)
        # Drop all rows where all values are null NOTE: must be done before add_import_time_columns
        sparkDynamicDataFrame = sparkDynamicDataFrame.na.drop('all')
        sparkDynamicDataFrame = add_import_time_columns(sparkDynamicDataFrame)
        dataframe = DynamicFrame.fromDF(
            sparkDynamicDataFrame, glueContext, f"alloy_{resource}")
        parquetData = glueContext.write_dynamic_frame.from_options(
            frame=dataframe,
            connection_type="s3",
            connection_options={"path": s3_target_url,
                                "partitionKeys": PARTITION_KEYS},
            format="parquet",
            transformation_ctx=f"alloy_{resource}_sink"
        )

    job.commit()
