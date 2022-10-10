# Key: --additional-python-modules
# Value: gspread==3.7.0, google-auth==1.27.1, pyspark==3.1.1

# IMPORTS
import gspread
import pandas as pd
import sys
import json
from pyspark.sql import SQLContext
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.dynamicframe import DynamicFrame
from awsglue.job import Job
from google.oauth2 import service_account

from scripts.helpers.helpers import get_glue_env_var, normalize_column_name, get_secret, convert_pandas_df_to_spark_dynamic_df, add_import_time_columns, PARTITION_KEYS

sparkContext = SparkContext.getOrCreate()
glueContext = GlueContext(sparkContext)
sqlContext = SQLContext(sparkContext)

logger = glueContext.get_logger()

# SETTINGS
googleSheetsDocumentKey = get_glue_env_var('document_key', '')
googleSheetsWorksheetName = get_glue_env_var('worksheet_name', '')
headerRowNumber = get_glue_env_var('header_row_number', 1)
# OR
# googleSheetsWorksheetIndex = 0
s3BucketTarget = get_glue_env_var('s3_bucket_target', '')

# Get credentials from AWS Secret Manager
awsSecret = get_secret(get_glue_env_var('secret_id', ''), "eu-west-2")
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
scopes = ['https://spreadsheets.google.com/feeds', 'https://www.googleapis.com/auth/drive']
googleSheetsCredentials = service_account.Credentials.from_service_account_info(googleSheetsJsonCredentials)
googleSheetsScopedCredentials = googleSheetsCredentials.with_scopes(scopes)
googleSheetsClient = gspread.authorize(googleSheetsScopedCredentials)

googleSheetsDocument = googleSheetsClient.open_by_key(googleSheetsDocumentKey)
googleSheetsWorksheet = googleSheetsDocument.worksheet(googleSheetsWorksheetName)
# OR
# googleSheetsWorksheet = googleSheetsDocument.get_worksheet(googleSheetsWorksheetIndex)

# Create a data frame from the google sheet data
pandasDataFrame = pd.DataFrame(googleSheetsWorksheet.get_all_records(
    head=int(headerRowNumber)
))

# Convert all columns to strings
all_columns = list(pandasDataFrame)
pandasDataFrame[all_columns] = pandasDataFrame[all_columns].astype(str)

# Replace missing column names with valid names
pandasDataFrame.columns = ["column" + str(i) if a.strip() == "" else a.strip() for i, a in
                           enumerate(pandasDataFrame.columns)]
pandasDataFrame.columns = map(normalize_column_name, pandasDataFrame.columns)

logger.info("Using Columns: " + str(pandasDataFrame.columns))

sparkDynamicDataFrame = convert_pandas_df_to_spark_dynamic_df(sqlContext, pandasDataFrame)
sparkDynamicDataFrame = sparkDynamicDataFrame.replace('nan', None).replace('NaT', None)
sparkDynamicDataFrame = sparkDynamicDataFrame.na.drop('all') # Drop all rows where all values are null NOTE: must be done before add_import_time_columns
sparkDynamicDataFrame = add_import_time_columns(sparkDynamicDataFrame)

dataframe = DynamicFrame.fromDF(sparkDynamicDataFrame, glueContext, "googlesheets")

## @type: DataSink
## @args: [connection_type = "s3", connection_options = {"path":s3BucketTarget}, format = "parquet"]
## @return: parquetData
## @inputs: [frame = dataframe]
parquetData = glueContext.write_dynamic_frame.from_options(
    frame=dataframe,
    connection_type="s3",
    connection_options={"path": s3BucketTarget, "partitionKeys": PARTITION_KEYS},
    format="parquet",
)

job.commit()
