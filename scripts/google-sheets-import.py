# Key: --additional-python-modules
# Value: gspread==3.7.0, google-auth==1.27.1, pyspark==3.1.1

# IMPORTS
import gspread
import pandas as pd
import sys
import boto3
import base64
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

# HELPER FUNCTIONS
def get_glue_env_var(key, default="none"):
    if f'--{key}' in sys.argv:
        return getResolvedOptions(sys.argv, [key])[key]
    else:
        return default

def get_secret(secret_name, region_name):

    # Create a Secrets Manager client
    session = boto3.session.Session()
    client = session.client(
        service_name='secretsmanager',
        region_name=region_name
    )

    # In this sample we only handle the specific exceptions for the 'GetSecretValue' API.
    # See https://docs.aws.amazon.com/secretsmanager/latest/apireference/API_GetSecretValue.html
    # We rethrow the exception by default.

    try:
        get_secret_value_response = client.get_secret_value(
            SecretId=secret_name
        )
    except ClientError as e:
        if e.response['Error']['Code'] == 'DecryptionFailureException':
            # Secrets Manager can't decrypt the protected secret text using the provided KMS key.
            # Deal with the exception here, and/or rethrow at your discretion.
            raise e
        elif e.response['Error']['Code'] == 'InternalServiceErrorException':
            # An error occurred on the server side.
            # Deal with the exception here, and/or rethrow at your discretion.
            raise e
        elif e.response['Error']['Code'] == 'InvalidParameterException':
            # You provided an invalid value for a parameter.
            # Deal with the exception here, and/or rethrow at your discretion.
            raise e
        elif e.response['Error']['Code'] == 'InvalidRequestException':
            # You provided a parameter value that is not valid for the current state of the resource.
            # Deal with the exception here, and/or rethrow at your discretion.
            raise e
        elif e.response['Error']['Code'] == 'ResourceNotFoundException':
            # We can't find the resource that you asked for.
            # Deal with the exception here, and/or rethrow at your discretion.
            raise e
    else:
        # Decrypts secret using the associated KMS CMK.
        # Depending on whether the secret is a string or binary, one of these fields will be populated.
        if 'SecretString' in get_secret_value_response:
            secret = get_secret_value_response['SecretString']
            return secret
        else:
            decoded_binary_secret = base64.b64decode(get_secret_value_response['SecretBinary'])
            return decoded_binary_secret
            
    # Your code goes here. 


# SETTINGS
googleSheetsDocumentKey = get_glue_env_var('document_key', '1linzV5jbl5JuRA_yeeQ4QyC-vAK5qwlr6JVYc_tU0yw')
googleSheetsWorksheetName = get_glue_env_var('worksheet_name', 'Form responses 1')
# OR
#googleSheetsWorksheetIndex = 0
s3BucketTarget = get_glue_env_var('s3_bucket_target', '')

# No, this should not be here and in production this should be moved to something like AWS Secret and imported in at run time
googleSheetsJsonCredentials = get_secret("dataengineers-dataplatform-stg-housing-json-credentials-secret", "eu-west-2")

# {
#   "type": "service_account",
#   "project_id": "hackneyprototype",
#   "private_key_id": "b574c3e4e47d72cc207948590e48b0e1ede0f9b3",
#   "private_key": "-----BEGIN PRIVATE KEY-----\nMIIEvwIBADANBgkqhkiG9w0BAQEFAASCBKkwggSlAgEAAoIBAQCqKW5Htdae6zc3\n5cLZM3tRLK7KRe88cank5/X5C3AEoJJnuI4x/GPZHCBHjfegxEYo2lclbaeIf2nu\nM2xg8RilS4/fLj3fOck3cTZN7WCMx26u/7v9WI/EX7Yok6JP1AY2JrsGc1LCXSYu\n/WOcpDsewZ1dylZIjYsDzfuHDIMgd8FMUqBgwftr/rFZ585nnBGqjootXv+GXQfK\nPYPI9TVdVNxx9wUuMi/eFduYjs1FL7/OOBka4LR+khxV+FM/+ckEjhjSafWFVUm8\nzZWUSzK8ou8kMbAUuNtf1FKlaIuEWvF72N9k6BDfANwQd06dI4k5Be4jWxO54fTQ\nX0MyDVplAgMBAAECggEABQDKrjSVlB7F2kX45JJ72SSSGhPpfL05zydr0cVT50BC\nYGbVKs6T2qXApDdIyohi01+CFEa6WDbTf5kG9323PrWZ9r2rvN+8f727fe88Dr+W\nt0dWeL83xkDAgMZrIrjmRYV+K7/MdTcFwPgbIOyqPqqs12he1kDFJNjpAOztq7tq\ntX/UWLAm4lk8RwvwTJCvEZ8P/h915ZhJJOQ+e28NBWqwYH0pJf8rgYUbTaNReJHF\nn75oJ6qDn9KtavSzMVQL0B6I6SliF8oq9V4we2gsnjgpRC4bnJHlmTFvCWPxVubd\naWSLAbPKJ5yhjC+mmIG0bgnRg8G0Aco9gKcV9uNVeQKBgQDcJ2SxrJSHwsLlIVM+\nbzyzrahRvfmSobKrzqpG5q84TFqrxaGlWOP44DsJ37V4SGjHkHm4s/oCu3esffui\n1ERuT2OSAh4WiU1tBJGKV4b8xedZ/XL8eRqe8CxDtus8fequGaXE064HWWZCVdkN\nwXFpjr9bKbc0cNF6uLmmxihyfQKBgQDF3jwJzckXtBFHToF+/1xZWk/bp+ByO7dn\nFfNaVPSy0N5+xKQSkX8J349b7MdtKOWiKQlPHC5dOMLriTBFvBCbVKJYtYgIDtQG\n5XOyXe0X8RJLXE1WdtPJkj/yetHtw08E2i8+AcVJtwKSROTDA0TK7UdraF4k0Eno\npx5IbXLkCQKBgQCeQ29+zssEAb3rzBY0tvDTVk6/XKuyfq2cFviP+bwS48j23R9E\nZ2+TdVbb1Ud2jc9NT45BepiLKEty5CpmtuPuzQGOcBlDKDdR3MvnwN5YjsivB6WG\n3GSHx656i1/2X6q6t9NUeLwNqnX50A82dU7bjHQBzC5Y85WT/IHx41gmXQKBgQC2\nutyBRU0fmciXLJYEnXlAf1nehbOOaz2dcrURSAHPHXtMYPcQutMyYAY5o3osgidH\nUVRqfaEHsEK6WDB/RgWkHU3sVIDyyBbg44esQneRs6zscapuXkCKF4j8upYiWEsi\nNQiJ4AK9Z8h1IjCNM/iU2voo4/KFVuHafHNH+eOvWQKBgQCpbS0Ga/ANAYm/N26e\n0hT8nr5o0ry+eRTA3TUdlN1Vff4LM5j5KIO8LisPYPM9GOMWGmXb8xAKRZAn7/dv\n9ZGesX6Ir6o1AncU3W+J7+uNfgd1Ejv8sK4EhP7pyGcZkaU9kl6HedAiI8Ht9plW\nXa/VAvnth1GWEd40oiBqx5oFyQ==\n-----END PRIVATE KEY-----\n",
#   "client_email": "hackneyprototype@hackneyprototype.iam.gserviceaccount.com",
#   "client_id": "101769111652306406575",
#   "auth_uri": "https://accounts.google.com/o/oauth2/auth",
#   "token_uri": "https://oauth2.googleapis.com/token",
#   "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
#   "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/hackneyprototype%40hackneyprototype.iam.gserviceaccount.com"
# }

# CODE

## @params: [JOB_NAME]
args = getResolvedOptions(sys.argv, ['JOB_NAME'])

sparkContext = SparkContext.getOrCreate()
glueContext = GlueContext(sparkContext)
sqlContext = SQLContext(sparkContext)

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

pandasDataFrame = pd.DataFrame(googleSheetsWorksheet.get_all_records())
sparkDynamicDataFrame = sqlContext.createDataFrame(pandasDataFrame)
sparkDynamicDataFrame = sparkDynamicDataFrame.coalesce(1).withColumn('date', f.current_timestamp()).repartition('date')

dataframe = DynamicFrame.fromDF(sparkDynamicDataFrame, glueContext, "googlesheets")

## @type: DataSink
## @args: [connection_type = "s3", connection_options = {"path":s3BucketTarget}, format = "parquet"]
## @return: parquetData
## @inputs: [frame = dataframe]
parquetData = glueContext.write_dynamic_frame.from_options(
    frame = dataframe,
    connection_type = "s3",
    connection_options = {"path":s3BucketTarget},
    format = "parquet",
)

job.commit()