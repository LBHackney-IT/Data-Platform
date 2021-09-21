import sys
import requests
from pyspark.sql.functions import udf, col, explode
from pyspark.sql.types import StructType, StructField, StringType, ArrayType
from pyspark.sql import Row
import hmac, hashlib;
import base64;
from datetime import datetime, timedelta
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.dynamicframe import DynamicFrame
from awsglue.job import Job
from math import ceil
from helpers import get_glue_env_var, get_secret, add_import_time_columns, PARTITION_KEYS
import json

def authenticate_tascomi(headers, public_key, private_key):
    auth_hash = calculate_auth_hash(public_key, private_key)
    headers['X-Public'] = public_key
    headers['X-Hash'] = auth_hash
    return headers

def not_today(date_str):
    print(f"date_str: {date_str}")
    if not date_str:
        return True
    date = datetime.strptime(date_str[:19], "%Y-%m-%d %H:%M:%S")
    return date.date() != datetime.now().date()

def get_tascomi_resource(page_number, url, body):
    print(f"Calling API to get page {page_number}")
    global public_key
    global private_key

    headers = {
        'content-type': "application/json",
        'content-length': "0",
    }

    headers = authenticate_tascomi(headers, public_key, private_key)

    try:
        res = requests.get(url, data=body, headers=headers)
        records = json.loads(res.text)
        if type(records) == type(None):
            print("Null data response: ")
            print(res.json())
            return ([""], url, res.status_code, f"Null data response: {json.dumps(res.json())}")

        serialized_records = [json.dumps(remove_gis_image(record)) for record in records if not_today(record['last_updated']) ]

        return (serialized_records, url, res.status_code, "")

    except Exception as e:
        exception = str(e)
        print(f"ERROR: {exception}")
        return ([""], url, "", exception)

def calculate_auth_hash(public_key, private_key):
    now_bst = datetime.now() + timedelta(hours=1)
    the_time = now_bst.strftime("%Y%m%d%H%M").encode('utf-8')
    crypt = hashlib.sha256(public_key.encode('utf-8') + the_time)
    token = crypt.hexdigest().encode('utf-8')
    return base64.b64encode(hmac.new(private_key.encode('utf-8'), token, hashlib.sha256).hexdigest().encode('utf-8'))

def get_number_of_pages(resource, query = ""):
    global public_key
    global private_key

    headers = {
        'content-type': "application/json",
        'content-length': "0"
    }

    headers = authenticate_tascomi(headers, public_key, private_key)

    url = f'https://hackney-planning.tascomi.com/rest/v1/{resource}{query}'
    res = requests.get(url, data="", headers=headers)
    number_of_results = res.headers['X-Number-Of-Results']
    results_per_page = res.headers['X-Results-Per-Page']

    return ceil(int(number_of_results) / int(results_per_page))

def get_days_since_last_import(last_import_date):
    yesterday = datetime.now() - timedelta(days=1)
    last_import_datetime = datetime.strptime(last_import_date, "%Y%m%d")
    number_days_to_query = (yesterday - last_import_datetime).days
    return [ datetime.strftime(yesterday - timedelta(days=day), "%Y-%m-%d") for day in range(0, number_days_to_query + 1)]

def get_last_import_date(glueContext, database, resource):
    tables = glueContext.tables(database)

    table_exists = tables.filter(tables.tableName == resource).count() == 1
    print(f"table_exists: {table_exists}")

    if not table_exists:
        return None

    return glueContext.sql(f"SELECT max(import_date) as max_import_date FROM `{database}`.{resource}").take(1)[0].max_import_date

def get_requests(last_import_date, resource):
    if last_import_date:
        requests_list = []
        for day in get_days_since_last_import(last_import_date):
            number_of_pages = get_number_of_pages(f"{resource}", f"?last_updated={day}")
            print(f"Number of pages to retrieve for {day}: {number_of_pages}")
            requests_list += [ RequestRow(page_number, f'https://hackney-planning.tascomi.com/rest/v1/{resource}?page={page_number}&last_updated={day}', "") for page_number in range(1, number_of_pages + 1)]
        return requests_list
    else:
        number_of_pages = get_number_of_pages(resource)
        print(f"Number of pages to retrieve: {number_of_pages}")
        return [RequestRow(page_number, f'https://hackney-planning.tascomi.com/rest/v1/{resource}?page={page_number}', "") for page_number in range(1, number_of_pages + 1)]

def calculate_number_of_partitions(number_of_requests, number_of_workers):
    max_partitions = (2 * number_of_workers - 1) * 4

    if number_of_requests < (15 * max_partitions):
        return ceil(number_of_requests / 15)
    else:
        return max_partitions

def remove_gis_image(records):
    records.pop("gis_map_image_base64", None)
    return records

def retrieve_and_write_tascomi_data(glueContext, resource, requests_list, partitions):
    request_rdd = sc.parallelize(requests_list).repartition(partitions)
    request_df = glueContext.createDataFrame(request_rdd)

    response_df = request_df.withColumn("response", get_tascomi_resource_udf(col("page_number"), col("url"), col("body")))

    tascomi_responses_df = response_df.select( \
        col("page_number"),
        explode(col("response.response_data")).alias(f"{resource}"), \
        col("response.import_api_url_requested").alias("import_api_url_requested"), \
        col("response.import_api_status_code").alias("import_api_status_code"), \
        col("response.import_exception_thrown").alias("import_exception_thrown"))

    tascomi_responses_df = add_import_time_columns(tascomi_responses_df)

    dynamic_frame = DynamicFrame.fromDF(tascomi_responses_df, glueContext, f"tascomi_{resource}")
    bucket_target = get_glue_env_var('s3_bucket_target', '')
    prefix = get_glue_env_var('s3_prefix', '')

    glueContext.write_dynamic_frame.from_options(
        frame=dynamic_frame,
        connection_type="s3",
        format="parquet",
        connection_options={"path": "s3://" + bucket_target + "/" + prefix + resource + "/", "partitionKeys": PARTITION_KEYS},
        transformation_ctx=f"tascomi_{resource}_sink")


args = getResolvedOptions(sys.argv, ['JOB_NAME'])
sc = SparkContext.getOrCreate()
glueContext = GlueContext(sc)
logger = glueContext.get_logger()
job = Job(glueContext)
job.init(args['JOB_NAME'], args)

resource = get_glue_env_var('resource', '')
target_database_name = get_glue_env_var('target_database_name', '')
public_key = get_secret(get_glue_env_var('public_key_secret_id', ''), "eu-west-2")
private_key = get_secret(get_glue_env_var('private_key_secret_id', ''), "eu-west-2")

if resource == '':
    raise Exception("--resource value must be defined in the job aruguments")
print(f"Getting resource {resource}")


api_response_schema = StructType([
    StructField("response_data", ArrayType(StringType(), True)),
    StructField("import_api_url_requested", StringType(), True),
    StructField("import_api_status_code", StringType(), True),
    StructField("import_exception_thrown", StringType(), True)
])
get_tascomi_resource_udf = udf(get_tascomi_resource, api_response_schema)

RequestRow = Row("page_number", "url", "body")

last_import_date = get_last_import_date(glueContext, target_database_name, resource)
print(f"last import date: {last_import_date}")

requests_list = get_requests(last_import_date, resource)
number_of_workers = int(get_glue_env_var('number_of_workers', '2'))

number_of_requests = len(requests_list)
partitions = calculate_number_of_partitions(number_of_requests, number_of_workers)
print(f"Using {partitions} partitions to repartition the RDD.")

if number_of_requests > 0:
    retrieve_and_write_tascomi_data(glueContext, resource, requests_list, partitions)
else:
    print("No requests, exiting")

job.commit()