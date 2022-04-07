# IMPORTS

import pandas as pd
import sys
import time
import json
import zipfile
import html
import requests
import boto3
import io
from pyspark.sql import SQLContext
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.dynamicframe import DynamicFrame
from awsglue.job import Job

from helpers.helpers import get_glue_env_var, normalize_column_name, get_secret, convert_pandas_df_to_spark_dynamic_df, add_import_time_columns, PARTITION_KEYS

def download_file_to_df(file_id, api_key, filename):
    url_download = f'https://api.uk.alloyapp.io/api/file/{file_id}?token={api_key}'
    r = requests.get(url_download, headers=headers)
    z = zipfile.ZipFile(io.BytesIO(r.content))
    df = pd.read_csv(html.unescape(z.extract(member=filename)), index_col=False)
    return df
    
sparkContext = SparkContext.getOrCreate()
glueContext = GlueContext(sparkContext)
sqlContext = SQLContext(sparkContext)

logger = glueContext.get_logger()


# SETTINGS
s3BucketTarget = get_glue_env_var('s3_bucket_target', '')

# Get credentials from AWS Secret Manager
api_key = get_secret(get_glue_env_var('secret_name', ''), "eu-west-2")

# CODE

## @params: [JOB_NAME]
args = getResolvedOptions(sys.argv, ['JOB_NAME'])

job = Job(glueContext)
job.init(args['JOB_NAME'], args)

url = "https://api.uk.alloyapp.io/api/export/?token=" + api_key
region = 'uk'
headers = {'Accept': 'application/json', 'Content-Type': 'application/json'}
aqs = {"aqs":{
  "type": "Join",
  "properties": {
    "attributes": [
      "attributes_itemsTitle",
      "attributes_itemsSubtitle",
      "attributes_itemsGeometry",
      "attributes_inspectionsInspectionNumber",
      "attributes_tasksStatus",
      "attributes_tasksTeam",
      "attributes_tasksRaisedTime",
      "attributes_tasksStartTime",
      "attributes_tasksCompletionTime",
      "attributes_wasteEducationInspectionServiceOutcome_6032eba956a338006661f6f8",
      "attributes_wasteEducationInspectionResidentAvailable_6034de1cca290e006b10eaa5",
      "attributes_wasteEducationInspectionBarriersToRRW_6034e4f16668f2006c62013b",
      "attributes_wasteEducationInspectionEnforcementOutcome_6036a88b267b37006a951ac8",
      "attributes_wasteEducationInspectionEnforcementIssue_603c11fa306e42000a19ee8e",
      "attributes_tasksDescription"
    ],
    "collectionCode": [
      "Live"
    ],
    "dodiCode": "designs_wasteEducationInspection_6032eb1356a338006661f6e4",
    "joinAttributes": [
      "root.attributes_tasksStatus.attributes_taskStatusesStatus",
      "root.attributes_tasksTeam.attributes_teamsTeamName",
      "root.attributes_wasteEducationInspectionServiceOutcome_6032eba956a338006661f6f8.attributes_serviceOutcomeServiceOutcome_602eaaad3cf282006c40f4f0",
      "root.attributes_wasteEducationInspectionBarriersToRRW_6034e4f16668f2006c62013b.attributes_barriersToRRWBarriersToRRW_6034e1c96668f2006c61f949",
      "root.attributes_wasteEducationInspectionEnforcementOutcome_6036a88b267b37006a951ac8.attributes_enforcementOutcomeEnforcementOutcome_602ea67d3cf282006c40f3f3",
      "root.attributes_wasteEducationInspectionEnforcementIssue_603c11fa306e42000a19ee8e.attributes_enforcementIssueEnforcementIssue_603c0f135b27c7000aed8475"
    ],
    "sortInfo": {
      "attributeCode": "attributes_inspectionsInspectionNumber",
      "sortOrder": "Ascending"
    }
  },
  "children": [
    {
      "type": "GreaterThan",
      "properties": {
        "__dataExplorerFilter": "attributes_tasksRaisedTime"
      },
      "children": [
        {
          "type": "Attribute",
          "properties": {
            "attributeCode": "attributes_tasksRaisedTime"
          }
        },
        {
          "type": "DateTime",
          "properties": {
            "value": [
              "2022-02-01T00:00:00.000Z"
            ]
          }
        }
      ]
    }
  ]
},"fileName":"DW Education&Compliance Inspection.csv","exportHeaderType":"Name"}
post_url = f'https://api.{region}.alloyapp.io/api/export/?token={api_key}'
# url_download = f'https://api.uk.alloyapp.io/api/export/@Value({task_id})/file'
filename = "DW Education&Compliance Inspection/DW Education&Compliance Inspection.csv"

# call to export data
response = requests.post(post_url, data=json.dumps(aqs), headers=headers)

# check if valid response returned
if response.status_code == 200:
    # If success - check the task status
    json_output = json.loads(response.text)
    task_id = json_output["backgroundTaskId"]
    logger.info(json_output)
    task_status = ''
    file_id = ''
    # check task status every minute
    while task_status != 'Complete':
        time.sleep(60)
        url = f'https://api.{region}.alloyapp.io/api/task/{task_id}?token={api_key}'
        response = requests.get(url)
        if response.status_code == 200:
            json_output = json.loads(response.text)
            logger.info(f'reponse = 200: {json_output}')
            task_status = json_output["task"]["status"]
        else:
            pass
    if task_status == 'Complete':
        # get fileItemId once file prep complete
        url = f'https://api.{region}.alloyapp.io/api/export/{task_id}/file?token={api_key}'
        response = requests.get(url)
        if response.status_code == 200:
            json_output = json.loads(response.text)
            logger.info(f'reponse = 200: {json_output}')
            file_id = json_output["fileItemId"]
            # download file
            pandasDataFrame = download_file_to_df(file_id, api_key, filename)
            #print("File download and extraction complete")
            #df.to_csv(out_path, index=False)
            #print('File uploaded to Google Drive')
            # Convert all columns to strings
            all_columns = list(pandasDataFrame)
            pandasDataFrame[all_columns] = pandasDataFrame[all_columns].astype(str)
            
            # Replace missing column names with valid names
            pandasDataFrame.columns = ["column" + str(i) if a.strip() == "" else a.strip() for i, a in
                                       enumerate(pandasDataFrame.columns)]
            pandasDataFrame.columns = map(normalize_column_name, pandasDataFrame.columns)
            
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

        else:
            pass
    else:
        pass
else:
    pass


job.commit()
