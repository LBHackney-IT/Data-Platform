import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
from pyspark.sql.functions import col, lit, when, concat
from pyspark.sql.types import IntegerType
from pyspark.sql import SparkSession
import boto3

s3_client = boto3.client('s3')
sc = SparkContext.getOrCreate()
spark = SparkSession.builder.getOrCreate()
glue_context = GlueContext(sc)

logger = glue_context.get_logger()
args = getResolvedOptions(sys.argv, ['JOB_NAME'])

job = Job(glue_context)
job.init(args['JOB_NAME'], args)

logger.info("tuomo: Job finished successfully")
job.commit()
