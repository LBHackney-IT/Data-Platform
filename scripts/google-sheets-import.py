# Key: --additional-python-modules
# Value: gspread==3.7.0, google-auth==1.27.1, pyspark==3.1.1

# IMPORTS
import gspread
import pandas as pd
import sys
import boto3
import base64
import logging
import json
import datetime
from botocore.exceptions import ClientError
from awsglue.utils import getResolvedOptions
from pyspark.sql import SQLContext
from pyspark.sql import functions as f
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.dynamicframe import DynamicFrame
from awsglue.job import Job
from google.oauth2 import service_account

sparkContext = SparkContext.getOrCreate()
glueContext = GlueContext(sparkContext)
sqlContext = SQLContext(sparkContext)

logger = glueContext.get_logger()
now = datetime.datetime.now()

# HELPER FUNCTIONS
def get_glue_env_var(key, default="none"):
    if f'--{key}' in sys.argv:
        return getResolvedOptions(sys.argv, [key])[key]
    else:
        return default

def get_secret(logger, secret_name, region_name):
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


# SETTINGS
googleSheetsDocumentKey = get_glue_env_var('document_key', '')
googleSheetsWorksheetName = get_glue_env_var('worksheet_name', '')
headerRowNumber = get_glue_env_var('header_row_number', 1)
# OR
#googleSheetsWorksheetIndex = 0
s3BucketTarget = get_glue_env_var('s3_bucket_target', '')

# Get credentials from AWS Secret Manager
awsSecret = get_secret(logger, get_glue_env_var('secret_id', ''), "eu-west-2")
googleSheetsJsonCredentials = json.loads(awsSecret)

# CODE

## @params: [JOB_NAME]
args = getResolvedOptions(sys.argv, ['JOB_NAME'])

job = Job(glueContext)
job.init(args['JOB_NAME'], args)

## @type: DataSource
## @args: [googleSheetsDocumentKey = "", googleSheetsWorksheetName = ""]
## @return: dataframe
## @inputs: []
scopes = ['https://spreadsheets.google.com/feeds','https://www.googleapis.com/auth/drive']
googleSheetsCredentials = service_account.Credentials.from_service_account_info(googleSheetsJsonCredentials)
googleSheetsScopedCredentials = googleSheetsCredentials.with_scopes(scopes)
googleSheetsClient = gspread.authorize(googleSheetsScopedCredentials)

googleSheetsDocument = googleSheetsClient.open_by_key(googleSheetsDocumentKey)
googleSheetsWorksheet = googleSheetsDocument.worksheet(googleSheetsWorksheetName)
# OR
#googleSheetsWorksheet = googleSheetsDocument.get_worksheet(googleSheetsWorksheetIndex)

# Create a data frame from the google sheet data
pandasDataFrame = pd.DataFrame(googleSheetsWorksheet.get_all_records(
    head = int(headerRowNumber)
))

# Convert all columns to strings
all_columns = list(pandasDataFrame)
pandasDataFrame[all_columns] = pandasDataFrame[all_columns].astype(str)

# Replace missing column names with valid names
pandasDataFrame.columns = ["column" + str(i) if a.strip() == "" else a.strip() for i, a in enumerate(pandasDataFrame.columns)]

# Convert to SparkDynamicDataFrame
sparkDynamicDataFrame = sqlContext.createDataFrame(pandasDataFrame)
sparkDynamicDataFrame = sparkDynamicDataFrame.coalesce(1)
sparkDynamicDataFrame = sparkDynamicDataFrame.withColumn('import_date', f.current_timestamp())
sparkDynamicDataFrame = sparkDynamicDataFrame.withColumn('import_timestamp', f.lit(str(now.timestamp())))
sparkDynamicDataFrame = sparkDynamicDataFrame.withColumn('import_year', f.lit(str(now.year)))
sparkDynamicDataFrame = sparkDynamicDataFrame.withColumn('import_month', f.lit(str(now.month).zfill(2)))
sparkDynamicDataFrame = sparkDynamicDataFrame.withColumn('import_day', f.lit(str(now.day).zfill(2)))

dataframe = DynamicFrame.fromDF(sparkDynamicDataFrame, glueContext, "googlesheets")

## @type: DataSink
## @args: [connection_type = "s3", connection_options = {"path":s3BucketTarget}, format = "parquet"]
## @return: parquetData
## @inputs: [frame = dataframe]
parquetData = glueContext.write_dynamic_frame.from_options(
    frame = dataframe,
    connection_type = "s3",
    connection_options = {"path":s3BucketTarget, "partitionKeys": ['import_year', 'import_month', 'import_day']},
    format = "parquet",
)

job.commit()