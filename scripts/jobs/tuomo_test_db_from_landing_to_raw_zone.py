import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
from helpers.helpers import get_glue_env_var, get_latest_partitions, PARTITION_KEYS

args = getResolvedOptions(sys.argv, ["JOB_NAME"])
sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args["JOB_NAME"], args)

environment = get_glue_env_var("environment")

# Script generated for node S3 bucket
S3bucket_node1 = glueContext.create_dynamic_frame.from_catalog(
    database="dataplatform-tuomo-landing-zone-database",
    table_name="testdb_dbo_dm_persons",
    transformation_ctx="S3bucket_node1",
)

# Script generated for node ApplyMapping
ApplyMapping_node2 = ApplyMapping.apply(
    frame=S3bucket_node1,
    mappings=[
        ("person_id", "long", "person_id", "long"),
        ("ssda903_id", "string", "ssda903_id", "string"),
        ("nhs_id", "decimal", "nhs_id", "decimal"),
        ("scn_id", "decimal", "scn_id", "decimal"),
        ("upn_id", "string", "upn_id", "string"),
        ("former_upn_id", "string", "former_upn_id", "string"),
        ("full_name", "string", "full_name", "string"),
        ("title", "string", "title", "string"),
        ("first_name", "string", "first_name", "string"),
        ("last_name", "string", "last_name", "string"),
        ("date_of_birth", "timestamp", "date_of_birth", "timestamp"),
        ("date_of_death", "timestamp", "date_of_death", "timestamp"),
        ("gender", "string", "gender", "string"),
        ("restricted", "string", "restricted", "string"),
        ("person_id_legacy", "string", "person_id_legacy", "string"),
        ("full_ethnicity_code", "string", "full_ethnicity_code", "string"),
        ("country_of_birth_code", "string", "country_of_birth_code", "string"),
        ("is_child_legacy", "string", "is_child_legacy", "string"),
        ("is_adult_legacy", "string", "is_adult_legacy", "string"),
        ("nationality", "string", "nationality", "string"),
        ("religion", "string", "religion", "string"),
        ("marital_status", "string", "marital_status", "string"),
        ("first_language", "string", "first_language", "string"),
        ("fluency_in_english", "string", "fluency_in_english", "string"),
        ("email_address", "string", "email_address", "string"),
        ("context_flag", "string", "context_flag", "string"),
        ("scra_id", "string", "scra_id", "string"),
        ("interpreter_required", "string", "interpreter_required", "string"),
        ("from_dm_person", "string", "from_dm_person", "string"),
        ("sccv_sexual_orientation", "string", "sccv_sexual_orientation", "string"),
        (
            "sccv_preferred_method_of_contact",
            "string",
            "sccv_preferred_method_of_contact",
            "string",
        ),
        ("sccv_created_at", "timestamp", "sccv_created_at", "timestamp"),
        ("sccv_created_by", "string", "sccv_created_by", "string"),
        ("sccv_last_modified_at", "timestamp", "sccv_last_modified_at", "timestamp"),
        ("sccv_last_modified_by", "string", "sccv_last_modified_by", "string"),
        ("pronoun", "string", "pronoun", "string"),
        ("gender_assigned_at_birth", "boolean", "gender_assigned_at_birth", "boolean"),
        ("preferred_language", "string", "preferred_language", "string"),
        ("fluent_in_english", "boolean", "fluent_in_english", "boolean"),
        ("interpreter_needed", "boolean", "interpreter_needed", "boolean"),
        (
            "communication_difficulties",
            "boolean",
            "communication_difficulties",
            "boolean",
        ),
        (
            "difficulty_making_decisions",
            "boolean",
            "difficulty_making_decisions",
            "boolean",
        ),
        (
            "communication_difficulties_details",
            "string",
            "communication_difficulties_details",
            "string",
        ),
        ("employment", "string", "employment", "string"),
        ("immigration_status", "string", "immigration_status", "string"),
        ("primary_support_reason", "string", "primary_support_reason", "string"),
        ("care_provider", "string", "care_provider", "string"),
        ("tenure_type", "string", "tenure_type", "string"),
        ("accomodation_type", "string", "accomodation_type", "string"),
        ("access_to_home", "string", "access_to_home", "string"),
        ("housing_officer", "string", "housing_officer", "string"),
        ("living_situation", "string", "living_situation", "string"),
        ("housing_staff_in_contact", "boolean", "housing_staff_in_contact", "boolean"),
        ("cautionary_alert", "boolean", "cautionary_alert", "boolean"),
        ("posession_eviction_order", "string", "posession_eviction_order", "string"),
        ("rent_record", "string", "rent_record", "string"),
        ("housing_benefit", "string", "housing_benefit", "string"),
        ("council_tenure_type", "string", "council_tenure_type", "string"),
        (
            "tenancy_household_structure",
            "string",
            "tenancy_household_structure",
            "string",
        ),
        (
            "mental_health_section_status",
            "string",
            "mental_health_section_status",
            "string",
        ),
        ("deaf_register", "string", "deaf_register", "string"),
        ("blind_register", "string", "blind_register", "string"),
        ("blue_badge", "string", "blue_badge", "string"),
        ("open_case", "boolean", "open_case", "boolean"),
        ("allocated_team", "string", "allocated_team", "string"),
        ("review_date", "timestamp", "review_date", "timestamp"),
        ("import_datetime", "timestamp", "import_datetime", "timestamp"),
        ("import_timestamp", "string", "import_timestamp", "string"),
        ("import_year", "string", "import_year", "string"),
        ("import_month", "string", "import_month", "string"),
        ("import_day", "string", "import_day", "string"),
        ("import_date", "string", "import_date", "string"),
    ],
    transformation_ctx="ApplyMapping_node2",
)

# Script generated for node S3 bucket
S3bucket_node3 = glueContext.write_dynamic_frame.from_options(
    frame=ApplyMapping_node2,
    connection_type="s3",
    format="parquet",
    connection_options={
        "path": "s3://dataplatform-tuomo-raw-zone/tuomo-test-db/testdb_dbo_dm_persons",
        "partitionKeys": PARTITION_KEYS
    },
    transformation_ctx="S3bucket_node3",
)

job.commit()