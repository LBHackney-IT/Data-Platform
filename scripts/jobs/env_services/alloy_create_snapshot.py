import sys
from datetime import datetime

import pyspark.sql.functions as F
from awsglue.context import GlueContext
from awsglue.dynamicframe import DynamicFrame
from awsglue.job import Job
from awsglue.utils import getResolvedOptions
from pyspark import SparkContext
from pyspark.sql import SparkSession, Window
from pyspark.sql.functions import col, max
from scripts.helpers.helpers import (
    create_pushdown_predicate,
    get_glue_env_var,
    table_exists_in_catalog,
)


def get_latest_snapshot(dfa, snapshot_date_col):
    """
    get the latest snapshot table based on the snapshot_date column
    """
    dfa = dfa.where(
        col(snapshot_date_col) == dfa.select(max(snapshot_date_col)).first()[0]
    )
    return dfa


def add_snapshot_date_columns(data_frame):
    """
    create columns for snapshot date
    """
    now = datetime.now()
    snapshot_year = str(now.year)
    snapshot_month = str(now.month).zfill(2)
    snapshot_day = str(now.day).zfill(2)
    snapshot_date = snapshot_year + snapshot_month + snapshot_day
    data_frame = data_frame.withColumn("snapshot_year", F.lit(snapshot_year))
    data_frame = data_frame.withColumn("snapshot_month", F.lit(snapshot_month))
    data_frame = data_frame.withColumn("snapshot_day", F.lit(snapshot_day))
    data_frame = data_frame.withColumn("snapshot_date", F.lit(snapshot_date))
    return data_frame


def prepare_increments(increment_df, id_col, increment_date_col):
    """
    create increment df with latest row for each item
    """
    id_partition = Window.partitionBy(id_col)
    increment_df = (
        increment_df.withColumn("latest", F.max(increment_date_col).over(id_partition))
        .where(F.col(increment_date_col) == F.col("latest"))
        .drop("latest")
    )
    return increment_df


def apply_increments(snapshot_df, increment_df, id_col):
    """
    update previous snapshot with increment df
    """
    snapshot_df = snapshot_df.join(increment_df, id_col, "left_anti")
    snapshot_df = snapshot_df.unionByName(increment_df)
    return snapshot_df


def load_increments_since_date(increment_table_name, name_space, date):
    """
    load all of the increments since the provided date
    """
    increment_ddf = glueContext.create_dynamic_frame.from_catalog(
        name_space=name_space,
        table_name=increment_table_name,
        push_down_predicate=f"import_date>={date}",
        transformation_ctx=f"datasource_{increment_table_name}",
    )
    increment_df = increment_ddf.toDF()
    return increment_df


def set_increment_df(
    source_catalog_database,
    increment_table_name,
    increment_date_col,
    id_col,
    last_snapshot_date="1970-01-01",
):
    """
    set increment to be applied to previous snapshot
    """
    df = load_increments_since_date(
        increment_table_name, source_catalog_database, last_snapshot_date
    )
    df = prepare_increments(df, id_col, increment_date_col)
    df = add_snapshot_date_columns(df)
    return df


def rename_columns(df, columns):
    """
    Renames columns of a dataframe as described by a dictionary of "old_name": "new_name"
    """
    if isinstance(columns, dict):
        return df.select(
            *[
                F.col(col_name).alias(columns.get(col_name, col_name))
                for col_name in df.columns
            ]
        )
    else:
        raise ValueError(
            "'columns' should be a dict, like {'old_name_1': 'new_name_1', 'old_name_2': 'new_name_2'}"
        )


if __name__ == "__main__":
    args = getResolvedOptions(sys.argv, ["JOB_NAME"])
    sc = SparkContext.getOrCreate()
    glueContext = GlueContext(sc)
    spark = SparkSession(sc)
    logger = glueContext.get_logger()
    job = Job(glueContext)
    job.init(args["JOB_NAME"], args)

    snapshot_catalog_database = get_glue_env_var("snapshot_catalog_database", "")
    increment_catalog_database = get_glue_env_var("increment_catalog_database", "")
    table_name = get_glue_env_var("table_name", "")
    increment_table_prefix = get_glue_env_var("increment_prefix", "")
    snapshot_table_prefix = get_glue_env_var("snapshot_prefix", "")
    id_col = get_glue_env_var("id_col", "")
    increment_date_col = get_glue_env_var("increment_date_col", "")
    snapshot_date_col = get_glue_env_var("snapshot_date_col", "")
    s3_bucket_target = get_glue_env_var("s3_bucket_target", "")

    increment_table_name = f"{increment_table_prefix}{table_name}"
    snapshot_table_name = f"{snapshot_table_prefix}{table_name}"
    mapping_file_key = "env-services/alloy/mapping-files/" + table_name + ".json"

    if not (
        table_exists_in_catalog(
            glueContext, snapshot_table_name, snapshot_catalog_database
        )
        or table_exists_in_catalog(
            glueContext, increment_table_name, increment_catalog_database
        )
    ):
        logger.info(f"No snapshot or increments found for {table_name}.")
        job.commit()
        raise Exception(
            f"no snapshot or increments found for {snapshot_table_name} in {snapshot_catalog_database} or {increment_table_name} in {increment_catalog_database}"
        )

    if not table_exists_in_catalog(
        glueContext, snapshot_table_name, snapshot_catalog_database
    ):
        increment_df = set_increment_df(
            increment_catalog_database, increment_table_name, increment_date_col, id_col
        )
        snapshot_df = increment_df

    else:
        pushDownPredicate = create_pushdown_predicate(
            partitionDateColumn=snapshot_date_col, daysBuffer=14
        )
        snapshot_ddf = glueContext.create_dynamic_frame.from_catalog(
            name_space=snapshot_catalog_database,
            table_name=snapshot_table_name,
            push_down_predicate=pushDownPredicate,
        )
        snapshot_df = snapshot_ddf.toDF()
        snapshot_df = get_latest_snapshot(snapshot_df, snapshot_date_col)
        last_snapshot_date = snapshot_df.select(max(snapshot_date_col)).first()[0]
        increment_df = set_increment_df(
            glueContext,
            increment_catalog_database,
            increment_table_name,
            last_snapshot_date,
        )
        snapshot_df = apply_increments(snapshot_df, increment_df, "item_id")

    try:
        s3.Object(s3_mapping_bucket, mapping_file_key).load()
    except botocore.exceptions.ClientError as e:
        if e.response["Error"]["Code"] == "404":
            logger.info(f"No mapping file for {table_name} found, {e.response}")
        else:
            logger.info(f"Error retrieving mapping file {e.response}")
    else:
        obj = s3.Object(s3_mapping_bucket, mapping_file_key).get()
        mapping = json.loads(obj["Body"].read())

        snapshot_df = rename_columns(snapshot_df, mapping)

    PARTITION_KEYS = [
        "snapshot_year",
        "snapshot_month",
        "snapshot_day",
        "snapshot_date",
    ]

    resultDataFrame = DynamicFrame.fromDF(snapshot_df, glueContext, "resultDataFrame")

    target_destination = s3_bucket_target + snapshot_table_name
    parquetData = glueContext.write_dynamic_frame.from_options(
        frame=resultDataFrame,
        connection_type="s3",
        format="parquet",
        connection_options={
            "path": target_destination,
            "partitionKeys": PARTITION_KEYS,
        },
    )

    job.commit()
