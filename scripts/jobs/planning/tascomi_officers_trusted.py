import sys

import boto3
import pyspark.sql.functions as F
from awsglue.context import GlueContext
from awsglue.dynamicframe import DynamicFrame
from awsglue.job import Job
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from pyspark.sql.functions import col, concat, lit, max, trim

from scripts.helpers.helpers import create_pushdown_predicate, get_glue_env_var


# Function to ensure we only return the lates snapshot
def get_latest_snapshot(df):
    df = df.where(col("snapshot_date") == df.select(max("snapshot_date")).first()[0])
    return df


# Creates a function that removes any columns that are entirely null values - useful for large tables
def drop_null_columns(df):
    _df_length = df.count()
    null_counts = (
        df.select([F.count(F.when(F.col(c).isNull(), c)).alias(c) for c in df.columns])
        .collect()[0]
        .asDict()
    )
    to_drop = [k for k, v in null_counts.items() if v >= _df_length]
    df = df.drop(*to_drop)

    return df


# function to clear target
def clear_target_folder(s3_bucket_target):
    s3 = boto3.resource("s3")
    folderString = s3_bucket_target.replace("s3://", "")
    bucketName = folderString.split("/")[0]
    prefix = folderString.replace(bucketName + "/", "") + "/"
    bucket = s3.Bucket(bucketName)
    bucket.objects.filter(Prefix=prefix).delete()
    return


if __name__ == "__main__":

    # read job parameters
    args = getResolvedOptions(sys.argv, ["JOB_NAME"])
    source_catalog_table = get_glue_env_var("source_catalog_table", "")
    source_catalog_table2 = get_glue_env_var("source_catalog_table2", "")
    source_catalog_table3 = get_glue_env_var("source_catalog_table3", "")
    source_catalog_database = get_glue_env_var("source_catalog_database", "")
    s3_bucket_target = get_glue_env_var("s3_bucket_target", "")
    days_to_load = 30

    # start the Spark session and the logger
    glueContext = GlueContext(SparkContext.getOrCreate())
    logger = glueContext.get_logger()
    job = Job(glueContext)
    job.init(args["JOB_NAME"], args)

    logger.info(
        f"The job is starting. The source table is {source_catalog_database}.{source_catalog_table}"
    )

    # Create a predicate to filter data for the last days_to_load days
    predicate = create_pushdown_predicate("snapshot_date", days_to_load)
    logger.info(
        f"Loading data with predicate: {predicate} to filter for last {days_to_load} days"
    )

    # Load data from glue catalog
    data_source = glueContext.create_dynamic_frame.from_catalog(
        name_space=source_catalog_database,
        table_name=source_catalog_table,
        push_down_predicate=predicate,
    )
    data_source2 = glueContext.create_dynamic_frame.from_catalog(
        name_space=source_catalog_database,
        table_name=source_catalog_table2,
        push_down_predicate=predicate,
    )

    data_source3 = glueContext.create_dynamic_frame.from_catalog(
        name_space=source_catalog_database,
        table_name=source_catalog_table3,
        push_down_predicate=predicate,
    )

    # Load Officers Table

    # convert to a data frame
    df = data_source.toDF()

    # Rename columns
    df = (
        df.withColumnRenamed("id", "officer_id")
        .withColumnRenamed("forename", "officer_forename")
        .withColumnRenamed("surname", "officer_surname")
    )

    # Specify Columns to Keep
    df = df.select(
        "officer_id",
        "officer_forename",
        "officer_surname",
        "username",
        "email",
        "mobile",
        "phone",
        "job_title",
        "import_date",
        "import_day",
        "import_month",
        "import_year",
        "snapshot_date",
        "snapshot_year",
        "snapshot_month",
        "snapshot_day",
    )

    # Return only latest snapshot

    df = get_latest_snapshot(df)
    df = df.withColumn("counter_officer", lit(1))
    df = df.withColumn(
        "officer_name",
        concat(trim(col("officer_forename")), lit(" "), trim(col("officer_surname"))),
    )
    # Load User Teams Map Table
    # convert to a data frame
    df2 = data_source2.toDF()

    # drop old snapshots

    df2 = get_latest_snapshot(df2)

    # Rename Relevant Columns
    # df2 = df2.withColumnRenamed("user_id","officer_id")

    # Keep Only Relevant Columns
    df2 = df2.select("user_id", "user_team_id")

    # convert to a data frame
    df3 = data_source3.toDF()

    # drop old snapshots

    df3 = get_latest_snapshot(df3)

    df3 = (
        df3.withColumnRenamed("id", "team_id")
        .withColumnRenamed("name", "team_name")
        .withColumnRenamed("description", "team_description")
    )

    # Keep Only Relevant Columns
    df3 = df3.select("team_id", "team_name", "team_description", "location")
    # Transform data using the functions defined outside the main block
    # Join
    df2 = df2.join(df3, df2.user_team_id == df3.team_id, "left")
    df = df.join(df2, df.officer_id == df2.user_id, "left")
    df = df.drop("team_id", "user_id")
    # Data Processing Ends
    # Convert data frame to dynamic frame
    dynamic_frame = DynamicFrame.fromDF(df, glueContext, "target_data_to_write")

    # wipe out the target folder in the trusted zone
    logger.info("clearing target bucket")
    clear_target_folder(s3_bucket_target)

    # Write the data to S3
    parquet_data = glueContext.write_dynamic_frame.from_options(
        frame=dynamic_frame,
        connection_type="s3",
        format="parquet",
        connection_options={
            "path": s3_bucket_target,
            "partitionKeys": [
                "snapshot_year",
                "snapshot_month",
                "snapshot_day",
                "snapshot_date",
            ],
        },
        transformation_ctx="target_data_to_write",
    )
    job.commit()
