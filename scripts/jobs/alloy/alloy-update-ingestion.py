import sys
import json
import io
import pandas as pd
import requests
import time
import zipfile
import html
import boto3
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from pyspark.sql import SQLContext
from awsglue.dynamicframe import DynamicFrame
from awsglue.job import Job
from helpers.helpers import get_glue_env_var, get_secret, table_exists_in_catalog, normalize_column_name,  convert_pandas_df_to_spark_dynamic_df, add_import_time_columns, PARTITION_KEYS

def download_file_to_df(file_id, api_key, filename):
    url_download = f'https://api.uk.alloyapp.io/api/file/{file_id}?token={api_key}'
    r = requests.get(url_download, headers=headers)
    z = zipfile.ZipFile(io.BytesIO(r.content))
    df = pd.read_csv(html.unescape(z.extract(member=filename)), index_col=False)
    return df

def get_last_import_date_time(glue_context, database, resource):
    if not table_exists_in_catalog(glue_context, resource, database):
        logger.info(f"Couldn't find table {resource} in database {database}.")
        return None
    logger.info(f"found table for {resource} in {database}")
    return glue_context.sql(f"SELECT max(import_datetime) as max_import_date_time FROM `{database}`.{resource}").take(1)[0].max_import_date_time

def format_time(date_time):
    t = date_time.strftime('%Y-%m-%dT%H:%M:%S.%f')
    return t[:-3]+"Z"
  
def update_aqs(alloy_query, last_import_date_time):
  child_value = [
    {
      "type": "GreaterThan",
      "children": [
        {
          "type": "ItemProperty",
          "properties": {
            "itemPropertyName": "lastEditDate"
          }
        },
        {
          "type": "DateTime",
          "properties": {
            "value": []
          }
         }
      ]
    }
  ]
  child_value[0]['children'][1]['properties']['value'] = [last_import_date_time]
  alloy_query['aqs']['children'] = child_value
  return alloy_query 

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
  database = get_glue_env_var('database','')
  prefix = get_glue_env_var('s3_prefix', '')
  aqs = get_glue_env_var('aqs', '')
  filename = get_glue_env_var('filename', '')
  last_import_date_time = format_time(get_last_import_date_time(glue_context, database, resource))

  s3_target_url = "s3://" + bucket_target + "/" +  prefix + resource + "/"
  
  if resource == '':
    raise Exception("--resource value must be defined in the job aruguments")
  logger.info(f"Getting resource {resource}")
  
  headers = {'Accept': 'application/json', 'Content-Type': 'application/json'}
  region = 'uk'
  post_url = f'https://api.{region}.alloyapp.io/api/export/?token={api_key}'
  aqs = update_aqs(aqs, last_import_date_time)
  response = requests.post(post_url, data=json.dumps(aqs), headers=headers)

  if response.status_code == 200:
      # If success - check the task status
      logger.info(f'json load')
      json_output = json.loads(response.text)
      logger.info(f'json load complete')
      task_id = json_output["backgroundTaskId"]
      logger.info(str(json_output))
      task_status = ''
      file_id = ''
      # check task status every minute
      while task_status != 'Complete':
          time.sleep(60)
          url = f'https://api.{region}.alloyapp.io/api/task/{task_id}?token={api_key}'
          response = requests.get(url)
          if response.status_code == 200:
              json_output = json.loads(response.text)
              json_output_str = str(json_output)
              logger.info(f'reponse = 200: {json_output_str}')
              task_status = json_output["task"]["status"]
          else:
              pass
      if task_status == 'Complete':
          # get fileItemId once file prep complete
          url = f'https://api.{region}.alloyapp.io/api/export/{task_id}/file?token={api_key}'
          response = requests.get(url)
          if response.status_code == 200:
              json_output = json.loads(response.text)
              json_output_str = str(json_output)
              logger.info(f'reponse = 200: {json_output_str}')
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

              dataframe = DynamicFrame.fromDF(sparkDynamicDataFrame, glueContext, "alloyDWeducation")

              ## @type: DataSink
              ## @args: [connection_type = "s3", connection_options = {"path":s3BucketTarget}, format = "parquet"]
              ## @return: parquetData
              ## @inputs: [frame = dataframe]
              parquetData = glueContext.write_dynamic_frame.from_options(
                  frame=dataframe,
                  connection_type="s3",
                  connection_options={"path": bucket_target, "partitionKeys": PARTITION_KEYS},
                  format="parquet",
              )
          else:
              pass
      else:
          pass
  else:
      pass

  job.commit()


