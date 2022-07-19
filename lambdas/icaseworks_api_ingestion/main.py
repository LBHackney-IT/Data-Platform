import sys

sys.path.append('./lib/')

import pybase64
import boto3
#from dotenv import load_dotenv
from os import getenv
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, lambda_context):
    #load_dotenv()
    #glue_job_name = getenv("GLUE_JOB_NAME")

    trigger_name = getenv("TRIGGER_NAME")

    # Trigger glue job to copy from landing to raw and convert to parquet
    glue_client = boto3.client('glue')
    
    trigger_id = glue_client.start_trigger(Name=trigger_name)
    logger.info(f"tuomo: lambda finished and firing trigger: {trigger_id}")

    #job_run_id = glue_client.start_job_run(JobName=glue_job_name)
    #logger.info(f"Glue job run ID: {job_run_id}")
    #logger.info(f"tuomo: lambda finished and starting glue job: {glue_job_name}")
