import sys
from awsglue.utils import getResolvedOptions
from pyspark import SparkContext
from pyspark.sql import SparkSession
from awsglue.context import GlueContext
from awsglue.dynamicframe import DynamicFrame
from awsglue.job import Job
import pyspark.sql.functions as F
from pyspark.sql.functions import col, max
from pyspark.sql import Window
from datetime import datetime
from helpers.helpers import get_glue_env_var, table_exists_in_catalog, create_pushdown_predicate


def get_latest_snapshot(dfa):
    dfa = dfa.where(col('snapshot_date') == dfa.select(
        max('snapshot_date')).first()[0])
    return dfa


def add_snapshot_date_columns(data_frame):
    now = datetime.now()
    snapshotYear = str(now.year)
    snapshotMonth = str(now.month).zfill(2)
    snapshotDay = str(now.day).zfill(2)
    snapshotDate = snapshotYear + snapshotMonth + snapshotDay
    data_frame = data_frame.withColumn('snapshot_year', F.lit(snapshotYear))
    data_frame = data_frame.withColumn('snapshot_month', F.lit(snapshotMonth))
    data_frame = data_frame.withColumn('snapshot_day', F.lit(snapshotDay))
    data_frame = data_frame.withColumn('snapshot_date', F.lit(snapshotDate))
    return data_frame


def prepare_increments(increment_df, id_col, increment_date_col):
    id_partition = Window.partitionBy(id_col)
    increment_df = increment_df.withColumn('latest', F.max(increment_date_col).over(
        id_partition)).where(F.col(increment_date_col) == F.col('latest')).drop('latest')
    return increment_df


def apply_increments(snapshot_df, increment_df, id_col):
    snapshot_df = snapshot_df.join(increment_df, id_col, 'left_anti')
    snapshot_df = snapshot_df.unionByName(increment_df)
    return snapshot_df


def loadIncrementsSinceDate(increment_table_name, name_space, date):
    increment_ddf = glueContext.create_dynamic_frame.from_catalog(
        name_space=name_space,
        table_name=increment_table_name,
        push_down_predicate=f"import_date>={date}",
        transformation_ctx=f"datasource_{increment_table_name}"
    )
    increment_df = increment_ddf.toDF()
    return increment_df


def set_increment_df(glueContext, source_catalog_database, table_name, increment_table_name, last_snapshot_date=None):
    if not (table_exists_in_catalog(glueContext, table_name, source_catalog_database) or table_exists_in_catalog(glueContext, increment_table_name, source_catalog_database)):
        logger.info(f'No snapshot or increments found for {table_name}.')
        return None

    if not table_exists_in_catalog(glueContext, table_name, source_catalog_database):
        logger.info(
            f'no snapshot found for {table_name}, returning all increments')
        increment_df = loadIncrementsSinceDate(
            f'increment_{table_name}', source_catalog_database, "20210101")
        increment_df = prepare_increments(increment_df)
        increment_df = add_snapshot_date_columns(increment_df)
        return increment_df

    logger.info(
        f'snapshot for {table_name} found, returning subsequent increments')
    increment_df = loadIncrementsSinceDate(
        increment_table_name, source_catalog_database, last_snapshot_date)
    increment_df = prepare_increments(increment_df)
    increment_df = add_snapshot_date_columns(increment_df)
    return increment_df


if __name__ == "__main__":
    args = getResolvedOptions(sys.argv, ['JOB_NAME'])
    sc = SparkContext.getOrCreate()
    glueContext = GlueContext(sc)
    spark = SparkSession(sc)
    logger = glueContext.get_logger()
    job = Job(glueContext)
    job.init(args['JOB_NAME'], args)

    table_name = get_glue_env_var('table_name', '')
    id_col = get_glue_env_var('id_col', '')
    increment_date_col = get_glue_env_var('increment_date_col',)
    source_catalog_database = get_glue_env_var('source_catalog_database', '')
    s3_bucket_target = get_glue_env_var('s3_bucket_target', '')

    increment_table_name = f'increment_{table_name}'

    if not (table_exists_in_catalog(glueContext, table_name, source_catalog_database) or table_exists_in_catalog(glueContext, increment_table_name, source_catalog_database)):
        logger.info(f'No snapshot or increments found for {table_name}.')
        job.commit()
        os._exit()

    if not table_exists_in_catalog(glueContext, table_name, source_catalog_database):
        increment_df = set_increment_df(
            glueContext, source_catalog_database, table_name, increment_table_name)
        snapshot_df = increment_df

    else:
        pushDownPredicate = create_pushdown_predicate(
            partitionDateColumn='snapshot_date', daysBuffer=14)
        snapshot_ddf = glueContext.create_dynamic_frame.from_catalog(
            name_space=source_catalog_database,
            table_name=table_name,
            push_down_predicate=pushDownPredicate
        )
        snapshot_df = snapshot_ddf.toDF()
        snapshot_df = get_latest_snapshot(snapshot_df)
        last_snapshot_date = snapshot_df.select(
            max('snapshot_date')).first()[0]
        increment_df = set_increment_df(
            glueContext, source_catalog_database, table_name, increment_table_name, last_snapshot_date)
        snapshot_df = apply_increments(snapshot_df, increment_df)

    PARTITION_KEYS = ["snapshot_year", "snapshot_month",
                      "snapshot_day", "snapshot_date"]

    resultDataFrame = DynamicFrame.fromDF(
        snapshot_df, glueContext, "resultDataFrame")
    target_destination = s3_bucket_target + table_name
    parquetData = glueContext.write_dynamic_frame.from_options(
        frame=resultDataFrame,
        connection_type="s3",
        format="parquet",
        connection_options={"path": target_destination,
                            "partitionKeys": PARTITION_KEYS}
    )

    job.commit()
