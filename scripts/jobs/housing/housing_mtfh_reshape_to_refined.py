import sys

import boto3
from awsglue.context import GlueContext
from awsglue.dynamicframe import DynamicFrame
from awsglue.job import Job
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from pyspark.sql.functions import (
    arrays_zip,
    col,
    concat_ws,
    element_at,
    explode_outer,
    when,
)

from scripts.helpers.helpers import (
    create_pushdown_predicate_for_max_date_partition_value,
    get_glue_env_var,
)


def clear_target_folder(s3_bucket_target):
    s3 = boto3.resource("s3")
    folderString = s3_bucket_target.replace("s3://", "")
    bucketName = folderString.split("/")[0]
    prefix = folderString.replace(bucketName + "/", "") + "/"
    bucket = s3.Bucket(bucketName)
    bucket.objects.filter(Prefix=prefix).delete()
    return


def load_table_view(source_catalog_database, table_name, glueContext):
    push_down_predicate_expression = (
        create_pushdown_predicate_for_max_date_partition_value(
            source_catalog_database, table_name, "import_date"
        )
    )

    df = glueContext.create_data_frame.from_catalog(
        database=source_catalog_database,
        table_name=table_name,
        transformation_ctx=f"{table_name}_source",
        push_down_predicate=push_down_predicate_expression,
    )
    df.createOrReplaceTempView(table_name)


def write_dynamic_frame(s3_bucket_target, glue_context, dynamic_frame, table_path):
    glue_context.write_dynamic_frame.from_options(
        frame=dynamic_frame,
        connection_type="s3",
        format="parquet",
        connection_options={
            "path": s3_bucket_target + table_path,
            "partitionKeys": [
                "import_year",
                "import_month",
                "import_day",
                "import_date",
            ],
        },
        transformation_ctx=f"target_data_to_write{target_path}",
    )


def process_table(
    source_catalog_database,
    table_name,
    glue_context,
    transformation_function,
    spark_session,
    s3_bucket_target,
    table_path,
    failed_tables,
):
    try:
        load_table_view(source_catalog_database, table_name, glue_context)
        transformed_df = transformation_function(spark_session)
        dynamic_frame = DynamicFrame.fromDF(
            transformed_df.repartition(1), glue_context, "target_data_to_write"
        )
        clear_target_folder(s3_bucket_target + table_path)
        write_dynamic_frame(s3_bucket_target, glue_context, dynamic_frame, table_path)
    except Exception as e:
        error_type = type(e).__name__
        error_message = str(e)
        logger.error(
            f"Error processing table {table_name}: {error_type} - {error_message}"
        )
        failed_tables.append(
            f"{table_name} failed with error: {error_type} - {error_message}"
        )


def transform_tenureinformation(spark_session):
    max_date = spark_session.sql(
        "SELECT max(import_date) as max_date FROM mtfh_tenureinformation"
    ).collect()[0]["max_date"]

    ten = spark_session.sql(
        f"""
        SELECT *, element_at(legacyreferences, 1).value as uh_ten_ref, element_at(legacyreferences, 2).value as saffron_pay_ref
        FROM mtfh_tenureinformation
        WHERE import_date = '{max_date}'
    """
    )

    ten = (
        ten.withColumn("members", explode_outer("householdmembers"))
        .withColumn("notices", explode_outer("notices"))
        .withColumnRenamed("id", "tenancy_id")
        .selectExpr(
            "tenancy_id",
            "paymentreference",
            "uh_ten_ref",
            "saffron_pay_ref",
            "startOfTenureDate",
            "endOfTenureDate as endoftenuredate",
            "evictiondate",
            "potentialenddate",
            "ismutualexchange",
            "subletenddate",
            "tenuretype.code as tenure_code",
            "tenuretype.description",
            "members.fullname",
            "members.isresponsible",
            "members.dateofbirth",
            "members.persontenuretype",
            "members.id as person_id",
            "members.type as member_type",
            "notices.expirydate as notice_expiry_date",
            "notices.serveddate as notice_served_date",
            "notices.effectivedate as notice_effective_date",
            "tenuredasset.uprn",
            "tenuredasset.propertyReference as property_reference",
            "tenuredasset.fullAddress as full_address",
            "tenuredasset.id as asset_id",
            "tenuredasset.type as asset_type",
            "charges.currentbalance",
            "charges.billingfrequency",
            "charges.combinedrentcharges",
            "charges.tenancyinsurancecharge",
            "charges.servicecharge",
            "charges.othercharges",
            "charges.combinedservicecharges",
            "terminated.isterminated",
            "terminated.reasonfortermination",
            "import_year",
            "import_month",
            "import_day",
            "import_date",
        )
    )
    for charge_type in [
        "currentbalance",
        "combinedrentcharges",
        "tenancyinsurancecharge",
        "servicecharge",
        "othercharges",
        "combinedservicecharges",
    ]:
        ten = (
            ten.withColumn(
                f"{charge_type}_double", col(f"{charge_type}.double").cast("double")
            )
            .drop(charge_type)
            .withColumnRenamed(f"{charge_type}_double", charge_type)
        )

    return ten


def transform_persons(spark_session):
    max_date = spark_session.sql(
        "SELECT max(import_date) as max_date FROM mtfh_persons"
    ).collect()[0]["max_date"]

    df2 = spark_session.sql(
        f"SELECT * FROM mtfh_persons WHERE import_date = '{max_date}'"
    )

    per = (
        df2.withColumn("combined", arrays_zip("tenures", "persontypes"))
        .withColumn("combined_exploded", explode_outer("combined"))
        .withColumn("tenure", col("combined_exploded.tenures"))
        .withColumn("person_type", col("combined_exploded.persontypes"))
        .drop("combined", "combined_exploded")
        .withColumnRenamed("id", "person_id")
        .withColumn("persontypes2", concat_ws(",", col("persontypes")))
        .withColumn(
            "new_person_type",
            when(col("person_type").isNull(), col("persontypes2")).otherwise(
                col("person_type")
            ),
        )
        .withColumn("endDate", col("tenure.endDate"))
        .select(
            col("person_id"),
            col("preferredTitle"),
            col("firstName"),
            col("middleName"),
            col("surname"),
            col("dateOfBirth"),
            col("placeOfBirth"),
            col("isOrganisation"),
            col("reason"),
            col("tenure.id").alias("tenancy_id"),
            col("tenure.uprn"),
            col("tenure.propertyReference"),
            col("tenure.paymentReference"),
            col("tenure.startDate"),
            col("endDate"),
            col("tenure.assetId"),
            col("tenure.type"),
            col("tenure.assetFullAddress"),
            col("new_person_type").alias("person_type"),
            col("import_year"),
            col("import_month"),
            col("import_day"),
            col("import_date"),
        )
    )
    return per


def transform_contactdetails(spark_session):
    max_date = spark_session.sql(
        "SELECT max(import_date) as max_date FROM mtfh_contactdetails"
    ).collect()[0]["max_date"]

    cont = spark_session.sql(
        f"SELECT * FROM mtfh_contactdetails WHERE import_date = '{max_date}'"
    )

    cont2 = cont.select(
        col("id"),
        col("targetid"),
        col("createdby.createdAt"),
        col("contactinformation.contacttype"),
        col("contactinformation.subtype"),
        col("contactinformation.value"),
        col("contactinformation"),
        col("lastmodified"),
        col("targettype"),
        col("isactive"),
        col("import_datetime"),
        col("import_timestamp"),
        col("import_year"),
        col("import_month"),
        col("import_day"),
        col("import_date"),
    ).withColumn(
        "person_id", when(col("targettype") == "person", col("targetid")).otherwise("")
    )
    return cont2


def transform_assets(spark_session):
    max_date = spark_session.sql(
        "SELECT max(import_date) as max_date FROM mtfh_assets"
    ).collect()[0]["max_date"]

    ass = spark_session.sql(
        f"""
        SELECT *
        FROM mtfh_assets
        WHERE import_date = '{max_date}'
    """
    )

    ass = ass.withColumnRenamed("id", "asset_id").select(
        "*",
        col("assetAddress.*"),
        col("tenure.*"),
        col("assetManagement.*"),
        col("assetLocation.*"),
        col("assetCharacteristics.*"),
    )

    ass2 = (
        ass.withColumn("parentAssets", explode_outer("assetLocation.parentAssets"))
        .withColumn("parentAssets_name", col("parentAssets.name"))
        .withColumn("parentAssets_id", col("parentAssets.id"))
        .withColumn("parentAssets_type", col("parentAssets.type"))
    )

    estate = (
        ass2.filter(col("parentAssets_type") == "Estate")
        .withColumnRenamed("parentAssets_name", "estate_name")
        .withColumnRenamed("parentAssets_id", "estate_id")
    )

    ass3 = (
        ass.join(estate, ass["asset_id"] == estate["asset_id"], "left")
        .select(ass["*"], estate["estate_name"], estate["estate_id"])
        .withColumnRenamed("id", "tenancy_id")
    )

    ass3 = ass3.withColumn(
        "endoftenuredate", col("tenure.endoftenuredate.string").cast("string")
    )

    output = ass3.select(
        "asset_id",
        "assetId",
        "assetType",
        "parentAssetIds",
        "uprn",
        "postPreamble",
        "addressLine1",
        "addressLine2",
        "addressLine3",
        "addressLine4",
        "postCode",
        "tenancy_id",
        "startOfTenureDate",
        "endoftenuredate",
        "paymentReference",
        "type",
        "owner",
        "agent",
        "isNoRepairsMaintenance",
        "propertyOccupiedStatus",
        "isCouncilProperty",
        "isTMOManaged",
        "managingOrganisation",
        "managingOrganisationId",
        "areaOfficeName",
        "totalBlockFloors",
        "floorNo",
        "numberOfLifts",
        "numberOfLivingRooms",
        "numberOfKitchens",
        "numberOfBedrooms",
        "numberOfBedSpaces",
        "numberOfShowers",
        "numberOfFloors",
        "numberOfDoubleBeds",
        "numberOfSingleBeds",
        "numberOfBathrooms",
        "yearConstructed",
        "hasCommunalAreas",
        "hasPrivateKitchen",
        "hasPrivateBathroom",
        "hasRampAccess",
        "isStepFree",
        "hasStairs",
        "Heating",
        "numberOfCots",
        "windowType",
        "estate_name",
        "estate_id",
        "import_year",
        "import_month",
        "import_day",
        "import_date",
    )
    return output


if __name__ == "__main__":
    # read job parameters
    args = getResolvedOptions(sys.argv, ["JOB_NAME"])
    source_catalog_database = get_glue_env_var("source_catalog_database", "")
    s3_bucket_target = get_glue_env_var("s3_bucket_target", "")

    # start the Spark session and the logger
    glueContext = GlueContext(SparkContext.getOrCreate())
    spark = glueContext.spark_session
    logger = glueContext.get_logger()
    job = Job(glueContext)

    logger.info(
        f"The job is starting. The source database is {source_catalog_database}"
    )

    table_transformations = {
        "mtfh_tenureinformation": {
            "function": transform_tenureinformation,
            "path": "/tenure_reshape",
        },
        "mtfh_persons": {"function": transform_persons, "path": "/person_reshape"},
        "mtfh_contactdetails": {
            "function": transform_contactdetails,
            "path": "/contacts_reshape",
        },
        "mtfh_assets": {"function": transform_assets, "path": "/assets_reshape"},
    }

    failed_tables = []

    for table_name, params in table_transformations.items():
        process_table(
            source_catalog_database,
            table_name,
            glueContext,
            params["function"],
            spark,
            s3_bucket_target,
            params["path"],
            failed_tables,
        )

    if failed_tables:
        logger.error(f"Failed tables: {failed_tables}")
        raise Exception(f"Failed tables: {failed_tables}")

    job.commit()
