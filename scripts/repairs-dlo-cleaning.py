import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
from pyspark.ml import Pipeline
from pyspark.ml.feature import RegexTokenizer, NGram, HashingTF, MinHashLSH
from pyspark.sql.window import Window
from pyspark.sql.functions import rank, col, trim, when, max
import pyspark.sql.functions as F
from pyspark.sql.types import StringType
from awsglue.dynamicframe import DynamicFrame
from helpers import get_glue_env_var


def getLatestPartitions(dfa):
    dfa = dfa.where(col('import_year') == dfa.select(
        max('import_year')).first()[0])
    dfa = dfa.where(col('import_month') == dfa.select(
        max('import_month')).first()[0])
    dfa = dfa.where(col('import_day') == dfa.select(
        max('import_day')).first()[0])
    return dfa


args = getResolvedOptions(sys.argv, ['JOB_NAME'])

source_catalog_database = get_glue_env_var('source_catalog_database', '')
source_catalog_table = get_glue_env_var('source_catalog_table', '')
cleaned_repairs_s3_bucket_target = get_glue_env_var(
    'cleaned_repairs_s3_bucket_target', '')

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

logger.info(df.printSchema())

# clean up column names
logger.info('clean up column names')
df2 = df.toDF(*[c.lower().replace(' ', '_') for c in df.columns])
df2 = df.toDF(*[c.lower().replace('-', '_') for c in df.columns])
df2 = df.toDF(*[c.lower().replace('__', '_') for c in df.columns])

logger.info('convert timestamp column to a datetime field type')
df2 = df2.withColumn('timestamp', F.to_timestamp(
    "timestamp", "dd/MM/yyyy HH:mm:ss"))

# convert resident name to title case
df2 = df2.withColumn('name_of_resident', F.initcap(F.col('name_of_resident')))

# add new data source column to specify which repairs sheet the repair came from
df2 = df2.withColumn('data_source', F.lit('DLO'))

# rename column names
logger.info('Rename column names')
df2 = df2.withColumnRenamed('name_of_resident', 'name_full') \
    .withColumnRenamed('job_description', 'description_of_work') \
    .withColumnRenamed('which_trade_needs_to_respond_to_repair?', 'trade_description') \
    .withColumnRenamed('what_is_the_priority_for_the_repair?', 'work_priority_description') \
    .withColumnRenamed('date_of_appointment', 'appointment_date') \
    .withColumnRenamed('if_there_is_a_cautionary_contact_alert,_what_is_the_nature_of_it?',
                       'alert_regarding_person_notes') \
    .withColumnRenamed('if_yes,_what_vulnerabilities_do_they_have?', 'vulnerability_notes') \
    .withColumnRenamed('postcode_of_property', 'postal_code_raw') \
    .withColumnRenamed('planners_to_allocate_to_operatives', 'operative') \
    .withColumnRenamed('does_the_resident_have_any_vulnerabilities?', 'vulnerability_flag') \
    .withColumnRenamed('is_there_a_cautionary_contact_alert_at_this_address?', 'alert_regarding_person') \
    .withColumnRenamed('planners_to_allocate_to_operatives', 'operative') \
    .withColumnRenamed(
    'make_a_note_if_the_resident_is_reporting_any_coronavirus_symptoms_in_the_household_and_advise_residents_to_wear_a_face_mask_when_the_operative_is_in_the_property_and_to_maintain_social_distancing_',
    'covid_notes') \
    .withColumnRenamed(
    'have_you_read_the_coronavirus_statement_to_the_resident?_please_advise_the_resident_to_wear_a_face_mask_when_the_operative_is_in_the_property_and_to_maintain_social_distancing_',
    'covid_statement_given') \
    .withColumnRenamed('uh_property_reference', 'property_reference_uh') \
    .withColumnRenamed('housing_status:_is_the_resident_a..._select_as_many_as_apply_', 'property_address_type') \
    .withColumnRenamed('is_the_job_a_recharge_or_sus_recharge?', 'recharge') \
    .withColumnRenamed('form_reference_-_do_not_alter', 'form_ref') \
    .withColumnRenamed('phone_number_of_resident', 'phone_1') \
    .withColumnRenamed('address_of_repair', 'property_address') \
    .withColumnRenamed('time_of_appointment', 'appointment_time') \
    .withColumnRenamed('planners_notes', 'notes') \
    .withColumnRenamed('email_address', 'email_staff') \
    .withColumnRenamed('uh_phone_number_1', 'phone_2') \
    .withColumnRenamed('uh_phone_number_2', 'phone_3') \
    .withColumnRenamed('timestamp', 'datetime_raised') \
 \
    # create a new column for repair priority code, based on repair priority description column


def map_repair_priority(code):
    if code == 'Immediate (2hr response)':
        return 1
    elif code == 'Emergency (24hrs)':
        return 2
    elif code == 'Urgent (5 working days)':
        return 3
    elif code == 'Normal (21 working days)':
        return 4
    else:
        return None


# # convert to a UDF Function by passing in the function and the return type of function (string in this case)
udf_map_repair_priority = F.udf(map_repair_priority, StringType())
# apply function
df2 = df2.withColumn('work_priority_code',
                     udf_map_repair_priority('work_priority_description'))

# write data into S3
logger.info('Write data into S3')
cleanedDataframe = DynamicFrame.fromDF(df2, glueContext, "cleanedDataframe")
parquetData = glueContext.write_dynamic_frame.from_options(
    frame=cleanedDataframe,
    connection_type="s3",
    format="parquet",
    connection_options={"path": cleaned_repairs_s3_bucket_target,
                        "partitionKeys": ["import_year", "import_month", "import_day", "import_date"]},
    transformation_ctx="parquetData")
job.commit()
