import sys
import requests
from pyspark.sql.functions import udf, col, explode, lit
from pyspark.sql.types import StructType, StructField, StringType, ArrayType
from pyspark.sql import Row
import hmac, hashlib;
import base64;
from datetime import datetime, timedelta
from dateutil import tz
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.dynamicframe import DynamicFrame
from awsglue.job import Job
from math import ceil
from helpers.helpers import get_glue_env_var, get_secret, add_import_time_columns, PARTITION_KEYS, table_exists_in_catalog
import json
from distutils.util import strtobool

def authenticate_tascomi(headers, public_key, private_key):
    auth_hash = calculate_auth_hash(public_key, private_key)
    headers['X-Public'] = public_key
    headers['X-Hash'] = auth_hash
    return headers

def not_today(date_str):
    if not date_str:
        return True
    date = datetime.strptime(date_str[:19], "%Y-%m-%d %H:%M:%S")
    return date.date() != datetime.now().date()

def get_tascomi_resource(page_number, url, body):
    global public_key
    global private_key

    print(f"Calling API to get page {page_number}")

    headers = {
        'content-type': "application/json",
        'content-length': "0",
    }

    headers = authenticate_tascomi(headers, public_key, private_key)

    res = {}
    try:
        res = requests.get(url, data=body, headers=headers)
        if not res.text or json.loads(res.text) == None:
            print(f"Null data response, with status code {res.status_code} for page {page_number}")
            return ([""], url, res.status_code, "Null data response.")
        records = json.loads(res.text)

        serialized_records = [json.dumps(remove_gis_image(record)) for record in records if not_today(record['last_updated']) ]

        return (serialized_records, url, res.status_code, "")

    except Exception as e:
        exception = str(e)
        print(f"ERROR: {exception} when getting page {page_number}. Status code {res.status_code}, response text {res.text}")
        return ([""], url, res.status_code, exception)

def calculate_auth_hash(public_key, private_key):
    tz_ldn = tz.gettz('Europe/London')
    now = datetime.now(tz_ldn)
    the_time = now.strftime("%Y%m%d%H%M").encode('utf-8')
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
    if res.status_code == 202:
        logger.info(f"received status code 202, whilst getting number of pages for {resource}, with query {query}")
        return { 'success': True, 'number_of_pages': 0 }
    if res.status_code == 200:
        number_of_results = res.headers['X-Number-Of-Results']
        results_per_page = res.headers['X-Results-Per-Page']

        return { 'success': True, 'number_of_pages': ceil(int(number_of_results) / int(results_per_page)) }
    error_message = f"Recieved status code {res.status_code} whilst trying to get number of pages for {resource}, {query}"
    logger.info(error_message)
    return { 'success': False, 'error_message': error_message }

def get_days_since_last_import(last_import_date):
    yesterday = datetime.now() - timedelta(days=1)
    last_import_datetime = datetime.strptime(last_import_date, "%Y%m%d")
    number_days_to_query = (yesterday - last_import_datetime).days
    days = [ datetime.strftime(yesterday - timedelta(days=day), "%Y-%m-%d") for day in range(1, number_days_to_query + 1)]
    days.sort()
    return days

def get_last_import_date(glue_context, database, resource):

    if not table_exists_in_catalog(glue_context, f"api_response_{resource}", database):
        logger.info(f"Couldn't find table api_response_{resource} in database {database}.")
        return None

    logger.info(f"found table for {resource} api response in {database}")
    return glue_context.sql(f"SELECT max(import_date) as max_import_date FROM `{database}`.api_response_{resource} where import_api_status_code = '200'").take(1)[0].max_import_date

def throw_if_unsuccessful(success_state, message):
    if not success_state:
        raise Exception(message)

def get_failures_from_last_import(database, resource, last_import_date):
    requests_df = glue_context.sql(f"SELECT page_number, import_api_url_requested as url, '' as body from `{database}`.api_response_{resource} where import_api_status_code != '200' and import_date={last_import_date}")
    return { "requests": requests_df, "count": requests_df.count() }
    
def get_requests_since_last_import(resource, last_import_date):
    requests_list = []
    for day in get_days_since_last_import(last_import_date):
        number_of_pages_reponse = get_number_of_pages(f"{resource}", f"?last_updated={day}")

        throw_if_unsuccessful(number_of_pages_reponse.get("success"), number_of_pages_reponse.get("error_message"))

        number_of_pages = number_of_pages_reponse["number_of_pages"]
        logger.info(f"Number of pages to retrieve for {day}: {number_of_pages}")
        requests_list += [ RequestRow(page_number, f'https://hackney-planning.tascomi.com/rest/v1/{resource}?page={page_number}&last_updated={day}', "") for page_number in range(1, number_of_pages + 1)]
    number_of_requests = len(requests_list)
    if number_of_requests == 0:
        return { "requests": [], "count": 0 }
    requests_list = sc.parallelize(requests_list)
    requests_list = glue_context.createDataFrame(requests_list)
    return { "requests": requests_list, "count": number_of_requests }

def get_requests_for_full_load(resource):
    number_of_pages_reponse = get_number_of_pages(resource)

    throw_if_unsuccessful(number_of_pages_reponse.get("success"), number_of_pages_reponse.get("error_message"))

    number_of_pages = number_of_pages_reponse["number_of_pages"]
    logger.info(f"Number of pages to retrieve: {number_of_pages}")
    requests_list = [RequestRow(page_number, f'https://hackney-planning.tascomi.com/rest/v1/{resource}?page={page_number}', "") for page_number in range(1, number_of_pages + 1)]
    number_of_requests = len(requests_list)
    requests_list = sc.parallelize(requests_list)
    requests_list = glue_context.createDataFrame(requests_list)
    return { "requests": requests_list, "count": number_of_requests }


def get_requests(last_import_date, resource, database):
    retry_arg_value = get_glue_env_var('retry_failure_from_previous_import', 'false')
    try:
        retry_failures = strtobool(retry_arg_value)
    except ValueError:
        raise Exception(f"--retry_failure_from_previous_import value must be recognised as a bool, received: {retry_arg_value}.")

    if not last_import_date:
        logger.info(f"Retrieving full load of data")
        return get_requests_for_full_load(resource)
    if retry_failures:
        logger.info(f"Getting failed requests from import on date {last_import_date}")
        return get_failures_from_last_import(database, resource, last_import_date)

    logger.info(f"Getting any records updated since {last_import_date}")
    return get_requests_since_last_import(resource, last_import_date)


def calculate_number_of_partitions(number_of_requests, number_of_workers):
    max_partitions = (2 * number_of_workers - 1) * 4

    if number_of_requests < (15 * max_partitions):
        return ceil(number_of_requests / 15)
    else:
        return max_partitions

def remove_gis_image(records):
    records.pop("gis_map_image_base64", None)
    return records

def retrieve_and_write_tascomi_data(glue_context, s3_target_url, resource, requests_list, partitions):
    request_df = requests_list.repartition(partitions)
    response_df = request_df.withColumn("response", get_tascomi_resource_udf(col("page_number"), col("url"), col("body")))

    tascomi_responses_df = response_df.select( \
        col("page_number"),
        explode(col("response.response_data")).alias(f"{resource}"), \
        col("response.import_api_url_requested").alias("import_api_url_requested"), \
        col("response.import_api_status_code").alias("import_api_status_code"), \
        col("response.import_exception_thrown").alias("import_exception_thrown"))

    tascomi_responses_df = add_import_time_columns(tascomi_responses_df)

    glue_context.write_dynamic_frame.from_options(
        frame=DynamicFrame.fromDF(tascomi_responses_df, glue_context, f"tascomi_{resource}"),
        connection_type="s3",
        format="parquet",
        connection_options={"path": s3_target_url, "partitionKeys": PARTITION_KEYS},
        transformation_ctx=f"tascomi_{resource}_sink")

    return tascomi_responses_df

def get_failed_requests(data_frame):
    return data_frame\
        .where((data_frame.import_api_status_code != '200') & (data_frame.import_api_status_code != '202'))\
        .select(data_frame.page_number.alias("page_number"), data_frame.import_api_url_requested.alias("url"), lit("").alias("body"))

args = getResolvedOptions(sys.argv, ['JOB_NAME'])
sc = SparkContext.getOrCreate()
glue_context = GlueContext(sc)
logger = glue_context.get_logger()
job = Job(glue_context)
job.init(args['JOB_NAME'], args)
spark_session = glue_context.spark_session

resource = get_glue_env_var('resource', '')
target_database_name = get_glue_env_var('target_database_name', '')
public_key = get_secret(get_glue_env_var('public_key_secret_id', ''), "eu-west-2")
private_key = get_secret(get_glue_env_var('private_key_secret_id', ''), "eu-west-2")
bucket_target = get_glue_env_var('s3_bucket_target', '')
prefix = get_glue_env_var('s3_prefix', '')
s3_target_url = "s3://" + bucket_target + "/" + prefix + resource + "/"

if resource == '':
    raise Exception("--resource value must be defined in the job aruguments")
logger.info(f"Getting resource {resource}")

api_response_schema = StructType([
    StructField("response_data", ArrayType(StringType(), True)),
    StructField("import_api_url_requested", StringType(), True),
    StructField("import_api_status_code", StringType(), True),
    StructField("import_exception_thrown", StringType(), True)
])
get_tascomi_resource_udf = udf(get_tascomi_resource, api_response_schema)

RequestRow = Row("page_number", "url", "body")

last_import_date = get_last_import_date(glue_context, target_database_name, resource)
logger.info(f"Maximum import date found: {last_import_date}")

requests_list = get_requests(last_import_date, resource, target_database_name)

if requests_list["count"] > 0:
    number_of_workers = int(get_glue_env_var('number_of_workers', '2'))
    partitions = calculate_number_of_partitions(requests_list["count"], number_of_workers)
    logger.info(f"Using {partitions} partitions to repartition the RDD.")

    tascomi_responses = retrieve_and_write_tascomi_data(glue_context, s3_target_url, resource, requests_list["requests"], partitions)
else:
    logger.info("No requests, exiting job")

job.commit()
