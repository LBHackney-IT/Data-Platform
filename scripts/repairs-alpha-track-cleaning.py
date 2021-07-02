import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
from pyspark.ml import Pipeline
from pyspark.ml.feature import RegexTokenizer, NGram, HashingTF, MinHashLSH
from pyspark.sql.window import Window
from pyspark.sql.functions import rank, col, trim, when, max, trim
import pyspark.sql.functions as F
from pyspark.sql.types import StringType
from awsglue.dynamicframe import DynamicFrame

def get_glue_env_var(key, default="none"):
    if f'--{key}' in sys.argv:
        return getResolvedOptions(sys.argv, [key])[key]
    else:
        return default

def getLatestPartitions(dfa):
   dfa = dfa.where(col('import_year') == dfa.select(max('import_year')).first()[0])
   dfa = dfa.where(col('import_month') == dfa.select(max('import_month')).first()[0])
   dfa = dfa.where(col('import_day') == dfa.select(max('import_day')).first()[0])
   return dfa

args = getResolvedOptions(sys.argv, ['JOB_NAME'])

source_catalog_database = get_glue_env_var('source_catalog_database', '')
source_catalog_table    = get_glue_env_var('source_catalog_table', '')
cleaned_repairs_s3_bucket_target = get_glue_env_var('cleaned_repairs_s3_bucket_target', '')


sc = SparkContext.getOrCreate()
glueContext = GlueContext(sc)
logger = glueContext.get_logger()
job = Job(glueContext)
job.init(args['JOB_NAME'], args)

logger.info('Fetch Source Data')

source_data = glueContext.create_dynamic_frame.from_catalog(
    name_space=source_catalog_database,
    table_name=source_catalog_table,
#     push_down_predicate="import_date==max(import_date)"
)

df = source_data.toDF()
df = getLatestPartitions(df)

# clean up column names
logger.info('clean up column names')
df2 = df.toDF(*[c.lower().replace(' ', '_') for c in df.columns])
df2 = df2.toDF(*[c.lower().replace('-', '_') for c in df.columns])
df2 = df2.toDF(*[c.lower().replace('__', '_') for c in df.columns])

logger.info('convert timestamp and date columns to datetime / date field types')
df2 = df2.withColumn('timestamp', F.to_timestamp("timestamp", "dd/MM/yyyy HH:mm:ss"))
df2 = df2.withColumn('date_-_temp_order_reference_', F.to_date('date_-_temp_order_reference_', "dd/MM/yyyy"))

# convert contact details to title case
df2 = df2.withColumn('contact_information', F.initcap(F.col('contact_information')))

# split out phone number from contact field
df2 = df2.withColumn("phone_1", F.regexp_extract("contact_information", "(\d+)", 0))

# keep name only from contact field
df2 = df2.withColumn("name_full", F.regexp_extract("contact_information", "[a-zA-Z]+(?:\s[a-zA-Z]+)*", 0))

# add new data source column to specify which repairs sheet the repair came from
df2 = df2.withColumn('data_source', F.lit('Alphatrack'))

# rename column names
df2 = df2.withColumnRenamed('email_address', 'email_staff') \
    .withColumnRenamed('date_-_temp_order_reference_', 'temp_order_number_date') \
    .withColumnRenamed('time_-_temp_order_reference_', 'temp_order_number_time') \
    .withColumnRenamed('temporary_order_number_if_required_', 'temp_order_number_full') \
    .withColumnRenamed('call_out_sors', 'sor') \
    .withColumnRenamed('priority_code', 'work_priority_description') \
    .withColumnRenamed('notes_and_information', 'notes')
#     .withColumnRenamed('contact_information', '') \

# drop columns not needed
df2 = df2.drop('contact_information')

def map_repair_priority(code):
    if code == 'Immediate':
        return 1
    elif code == 'Emergency':
        return 2
    elif code == 'Urgent':
        return 3
    elif code == 'Normal':
        return 4
    else:
        return None

# # convert to a UDF Function by passing in the function and the return type of function (string in this case)
udf_map_repair_priority = F.udf(map_repair_priority, StringType())
# apply function
df2 = df2.withColumn('work_priority_priority_code', udf_map_repair_priority('work_priority_description'))

cleanedDataframe = DynamicFrame.fromDF(df2, glueContext, "cleanedDataframe")
parquetData = glueContext.write_dynamic_frame.from_options(
    frame=cleanedDataframe,
    connection_type="s3",
    format="parquet",
    connection_options={"path": cleaned_repairs_s3_bucket_target,"partitionKeys": ["import_year", "import_month", "import_day", "import_date"]},
    transformation_ctx="parquetData")
job.commit()