import sys
from typing import Dict

import pyspark
from awsglue.context import GlueContext
from awsglue.job import Job
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from pyspark.sql import DataFrame, SparkSession
from pyspark.sql.functions import *
from pyspark.sql.types import *

spark = (
    SparkSession.builder.master("local[1]").appName("SparkByExamples.com").getOrCreate()
)

sys.argv.append("--JOB_NAME")
sys.argv.append("tenure-restructure")

if __name__ == "__main__":
    args = getResolvedOptions(sys.argv, ["JOB_NAME"])

    glueContext = GlueContext(SparkContext.getOrCreate())
    logger = glueContext.get_logger()
    job = Job(glueContext)
    job.init(args["JOB_NAME"], args)

    # Log something. This will be ouput in the logs of this Glue job [search in the Runs tab: all logs>xxxx_driver]
    logger.info(f"The job is starting.")

tennure_snapshot = glueContext.create_dynamic_frame.from_catalog(
    name_space="dataplatform-stg-landing-zone-database",
    table_name="mtfh_tenureinformation"
    # pushdown_predicate = create_pushdown_predicate('import_date', 2)
)
tennure_snapshot_df = tennure_snapshot.toDF()

tenure_streaming = glueContext.create_dynamic_frame.from_catalog(
    name_space="dataplatform-stg-landing-zone-database",
    table_name="tenure_api"
    # pushdown_predicate = create_pushdown_predicate('import_date', 2)
)
tenure_streaming_df = tenure_streaming.toDF()

mapping = dict(
    zip(
        ["paymentReference", "PaymentReference"],
        ["householdMembers", "HouseholdMembers"],
        ["tenuredAsset", "TenuredAsset"],
        ["charges", "Charges"],
        ["startOfTenureDate", "StartOfTenureDate"],
        ["endOfTenureDate", "EndOfTenureDate"],
        ["tenureType", "TenureType"],
        ["isTenanted", "IsTenanted"],
        ["terminated", "Terminated"],
        ["successionDate", "SuccessionDate"],
        ["evictionDate", "EvictionDate"],
        ["potentialEndDate", "PotentialEndDate"],
        ["notices", "Notices"],
        ["legacyReferences", "LegacyReferences"],
        ["isMutualExchange", "IsMutualExchange"],
        ["informHousingBenefitsForChanges", "InformHousingBenefitsForChanges"],
        ["isSublet", "IsSublet"],
        ["subletEndDate", "SubletEndDate"],
    )
)
tennure_df_renamed_cols = tennure_snapshot_df.select(
    [col(c).alias(mapping.get(c, c)) for c in data.columns]
)


# schema of structures found in streaming data
household_members_schema = "array<struct<Id:string, Type:string, FullName:string, IsResponsible:boolean, DateOfBirth:int, PersonTenureType:string>>"
tenured_asset_schema = "struct<Id:string,Type:string,FullAddress:string,Uprn:string,PropertyReference:string>"
notices_schema = "array<struct<Type:string,ServedDate:int,ExpiryDate:int,EffectiveDate:int,EndDate:int>>"
legacy_ref_schema = "array<struct<Name:string,Value:string>>"
charges_schema = "struct<Rent:float,CurrentBalance:float,BillingFrequency:string,ServiceCharge:float,OtherCharges:float,CombinedServiceCharges:float,CombinedRentCharges:float,TenancyInsuranceCharge:float,OriginalRentCharge:float,OriginalServiceCharge:float>"
tenure_type_schema = "struct<Code:string,Description:string>"
terminated_schema = "struct<IsTerminated:boolean,ReasonForTermination:string>"

tenure_df = tennure_df_renamed_cols.select(
    "Id",
    "PaymentReference",
    col("HouseholdMembers").cast(household_members_schema),
    col("TenuredAsset").cast(tenured_asset_schema),
    col("Charges"),
    col("StartOfTenureDate").cast("int"),
    col("EndOfTenureDate").cast("int"),
    col("TenureType").cast(tenure_type_schema),
    "IsTenanted",
    col("Terminated").cast(terminated_schema),
    col("SuccessionDate").cast("int"),
    col("EvictionDate").cast("int"),
    col("PotentialEndDate").cast("int"),
    col("Notices"),
    col("LegacyReferences").cast(legacy_ref_schema),
    "IsMutualExchange",
    "InformHousingBenefitsForChanges",
    col("IsSublet").cast("boolean"),
    col("SubletEndDate").cast("int"),
)

tenure_df = tenure_df.withColumn(
    "Notices", f.struct(f.col("Notices.*"), f.lit("").alias("EndDate"))
)

"""

"""
