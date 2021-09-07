import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
import pyspark.sql.functions as F
from awsglue.dynamicframe import DynamicFrame
from pyspark.sql.types import StringType
from helpers import get_glue_env_var, get_latest_partitions, PARTITION_KEYS
from repairs_cleaning_helpers import map_repair_priority, clean_column_names
from pydeequ.checks import *

from pydeequ.analyzers import Size
from pydeequ.repository import FileSystemMetricsRepository, ResultKey
from pydeequ.verification import RelativeRateOfChangeStrategy


source_catalog_database = get_glue_env_var('source_catalog_database', '')
source_catalog_table = get_glue_env_var('source_catalog_table', '')
cleaned_repairs_s3_bucket_target = get_glue_env_var(
    'cleaned_repairs_s3_bucket_target', '')


args = getResolvedOptions(sys.argv, ['JOB_NAME'])
sc = SparkContext.getOrCreate()
glueContext = GlueContext(sc)
spark_session = glueContext.spark_session
logger = glueContext.get_logger()
job = Job(glueContext)
job.init(args['JOB_NAME'], args)

source_data = glueContext.create_dynamic_frame.from_catalog(
    name_space=source_catalog_database,
    table_name=source_catalog_table,
)

df = source_data.toDF()

df = get_latest_partitions(df)

df2 = clean_column_names(df)

# convert date column to datetime format
df2 = df2.withColumn('data_source', F.lit('ElecMechFire - TV Aerials'))
df2 = df2.withColumn('datetime_raised', F.to_timestamp(
    'date', 'yyyy-MM-dd HH:mm:ss'))
# rename column names to reflect harmonised column banes

df2 = df2.withColumn('status_of_completed_y_n', F.when(df2['status_of_completed_y_n'] == 'Y', 'Completed').otherwise(''))\

df2 = df2.withColumnRenamed('requested_by', 'operative') \
    .withColumnRenamed('address', 'property_address') \
    .withColumnRenamed('description', 'description_of_work') \
    .withColumnRenamed('priority_code', 'work_priority_description') \
    .withColumnRenamed('temp_order_number', 'temp_order_number_full') \
    .withColumnRenamed('cost_of_repairs_work', 'order_value') \
    .withColumnRenamed('status_of_completed_y_n', 'order_status') \

df2 = df2.withColumn('order_value', df2['order_value'].cast(StringType()))

df2 = map_repair_priority(df2, 'work_priority_description', 'work_priority_priority_code')

df2 = df2.select("data_source", "datetime_raised",
                 "operative", "property_address", "order_value",
                 "description_of_work", "work_priority_description",
                 "work_priority_priority_code",
                 "temp_order_number_full", "order_value",
                 "work_priority_priority_code",
                 "import_datetime", "import_timestamp", "import_year",
                 "import_month", "import_day", "import_date",
                 )

metrics_target_location = "s3://dataplatform-stg-refined-zone/quality-metrics/department=housing-repairs/dataset=tv-aerials-cleaned/deequ-metrics.json"

metricsRepository = FileSystemMetricsRepository(spark_session, metrics_target_location)
resultKey = ResultKey(spark_session, ResultKey.current_milli_time(), {})

checkResult = VerificationSuite(spark_session) \
    .onData(df) \
    .useRepository(metricsRepository) \
    .addCheck(Check(spark_session, CheckLevel.Error, "data quality checks") \
        .hasMin("work_priority_priority_code", lambda x: x >= 1) \
        .hasMax("work_priority_priority_code", lambda x: x <= 4)  \
        .isComplete("description_of_work")) \
    .saveOrAppendResult(resultKey) \
    .run()

checkResult_df = VerificationResult.checkResultsAsDataFrame(spark_session, checkResult)
checkResult_df.show()

anomalyCheckResult = VerificationSuite(spark_session) \
    .onData(df) \
    .useRepository(metricsRepository) \
    .addAnomalyCheck(RelativeRateOfChangeStrategy(maxRateIncrease = 2.0), Size()) \
    .saveOrAppendResult(resultKey) \
    .run()

anomalyCheckResult_df = VerificationResult.checkResultsAsDataFrame(spark_session, anomalyCheckResult)
anomalyCheckResult_df.show()

cleanedDataframe = DynamicFrame.fromDF(df2, glueContext, "cleanedDataframe")
parquetData = glueContext.write_dynamic_frame.from_options(
    frame=cleanedDataframe,
    connection_type="s3",
    format="parquet",
    connection_options={
        "path": cleaned_repairs_s3_bucket_target, "partitionKeys": PARTITION_KEYS},
    transformation_ctx="parquetData")
job.commit()

spark_session.sparkContext._gateway.close()
spark_session.stop()
