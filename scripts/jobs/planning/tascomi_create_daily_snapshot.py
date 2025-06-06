import logging
import sys
from datetime import datetime

import pyspark.sql.functions as F
from awsglue.context import GlueContext
from awsglue.dynamicframe import DynamicFrame
from awsglue.job import Job
from awsglue.utils import getResolvedOptions
from pydeequ.checks import Check, CheckLevel
from pydeequ.repository import FileSystemMetricsRepository, ResultKey
from pydeequ.verification import VerificationResult, VerificationSuite
from pyspark import SparkContext
from pyspark.sql import SparkSession, Window
from pyspark.sql.functions import col, max

from scripts.helpers.data_quality_testing import (
    cancel_job_if_failing_quality_checks,
    get_data_quality_check_results,
    get_metrics_target_location,
    get_success_metrics,
)
from scripts.helpers.helpers import (
    create_pushdown_predicate,
    get_glue_env_var,
    table_exists_in_catalog,
)

logging.basicConfig(
    level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger(__name__)


def get_latest_snapshot(dfa):
    dfa = dfa.where(col("snapshot_date") == dfa.select(max("snapshot_date")).first()[0])
    return dfa


def add_snapshot_date_columns(data_frame):
    now = datetime.now()
    snapshotYear = str(now.year)
    snapshotMonth = str(now.month).zfill(2)
    snapshotDay = str(now.day).zfill(2)
    snapshotDate = snapshotYear + snapshotMonth + snapshotDay
    data_frame = data_frame.withColumn("snapshot_year", F.lit(snapshotYear))
    data_frame = data_frame.withColumn("snapshot_month", F.lit(snapshotMonth))
    data_frame = data_frame.withColumn("snapshot_day", F.lit(snapshotDay))
    data_frame = data_frame.withColumn("snapshot_date", F.lit(snapshotDate))
    return data_frame


def deduplicate_by_id_and_last_updated(df):
    """
    Deduplicates rows with the same (id, last_updated) combination by keeping the one with the latest import_date.
    To resolve: spotted duplicated rows with same id and last_updated timestamp in some incremental tables (e.g. documents)
    """
    window_spec = Window.partitionBy("id", "last_updated").orderBy(
        F.col("import_date").desc()
    )

    deduplicated_df = (
        df.withColumn("row_num", F.row_number().over(window_spec))
        .filter(F.col("row_num") == 1)
        .drop("row_num")
    )

    return deduplicated_df


def prepare_increments(increment_df):
    # In case there are several days worth of increments: only keep the latest version of a record
    id_partition = Window.partitionBy("id")
    # preparation step: create a temporary column to replace NULL last_updated values with 01/01/2020
    increment_df = increment_df.withColumn(
        "last_updated_nonull",
        F.when(
            F.isnull("last_updated"), F.to_timestamp(F.lit("2020-01-01 00:00:00.000"))
        ).otherwise(F.col("last_updated")),
    )
    # order and only keep most recent
    increment_df = (
        increment_df.withColumn(
            "latest", F.max("last_updated_nonull").over(id_partition)
        )
        .where(F.col("last_updated_nonull") == F.col("latest"))
        .drop("latest", "last_updated_nonull")
    )

    # Check for residual duplicates - print and further de-duplicate
    duplicate_ids = increment_df.groupBy("id").count().filter("count > 1")
    if duplicate_ids.limit(1).count() > 0:
        duplicate_ids.join(increment_df, "id").show(truncate=False)
        increment_df = deduplicate_by_id_and_last_updated(increment_df)
    else:
        logger.info("No duplicated rows after initial deduplication.")

    return increment_df


def apply_increments(snapshot_df, increment_df):
    snapshot_df = snapshot_df.join(increment_df, "id", "left_anti")
    snapshot_df = snapshot_df.unionByName(increment_df)
    return snapshot_df


def loadIncrementsSinceDate(increment_table_name, name_space, date):
    increment_ddf = glueContext.create_dynamic_frame.from_catalog(
        name_space=name_space,
        table_name=increment_table_name,
        push_down_predicate=f"import_date>={date}",
        transformation_ctx=f"datasource_{increment_table_name}",
    )
    increment_df = increment_ddf.toDF()
    return increment_df


def purge_today_partition(
    glueContext: GlueContext, target_destination: str, retentionPeriod: int = 0
) -> None:
    """
    Purges (delete) only today's partition under the given target destination.
    Parameters:
      glueContext: GlueContext instance.
      target_destination: Base S3 path (e.g., "s3://your-bucket/path").
      retentionPeriod: Retention period in hours (default 0, meaning delete all files immediately).
    Returns:
      partition_path: The S3 partition path that was purged.
    """
    now = datetime.now()
    snapshot_year = str(now.year)
    snapshot_month = str(now.month).zfill(2)
    snapshot_day = str(now.day).zfill(2)
    snapshot_date = snapshot_year + snapshot_month + snapshot_day

    partition_path = f"{target_destination}/snapshot_year={snapshot_year}/snapshot_month={snapshot_month}/snapshot_day={snapshot_day}/snapshot_date={snapshot_date}"

    glueContext.purge_s3_path(partition_path, {"retentionPeriod": retentionPeriod})


# dict containing parameters for DQ checks
dq_params = {
    "appeals": {"unique": ["id"]},
    "applications": {"unique": ["id"], "complete": "application_reference_number"},
    "appeal_decision": {"unique": ["id"]},
    "appeal_status": {"unique": ["id"]},
    "appeal_types": {"unique": ["id"]},
    "committees": {"unique": ["id"]},
    "communications": {"unique": ["id"]},
    "communication_types": {"unique": ["id"]},
    "contacts": {"unique": ["id"]},
    "contact_types": {"unique": ["id"]},
    "decision_types": {"unique": ["id"]},
    "documents": {"unique": ["id"]},
    "document_types": {"unique": ["id"]},
    "dtf_locations": {"unique": ["id"]},
    "emails": {"unique": ["id"]},
    "enforcements": {"unique": ["id"]},
    "fees": {"unique": ["id"]},
    "fee_payments": {"unique": ["id"]},
    "fee_types": {"unique": ["id"]},
    "ps_development_codes": {"unique": ["id"]},
    "public_comments": {"unique": ["id"]},
    "public_consultations": {"unique": ["id"], "complete": "document_id"},
    "users": {"unique": ["id"]},
    "committee_application_map": {"unique": ["id"]},
    "user_teams": {"unique": ["id"]},
    "user_team_map": {"unique": ["id"]},
    "application_types": {"unique": ["id"]},
    "pre_applications": {"unique": ["id"]},
    "pre_application_categories": {"unique": ["id"]},
    "asset_constraints": {"unique": ["id"]},
    "nature_of_enquiries": {"unique": ["id"]},
    "enquiry_outcome": {"unique": ["id"]},
    "enquiry_stage": {"unique": ["id"]},
    "wards": {"unique": ["id"]},
    "appeal_formats": {"unique": ["id"]},
    "enforcement_outcome_types": {"unique": ["id"]},
    "enforcement_protocols": {"unique": ["id"]},
    "priority_statuses": {"unique": ["id"]},
    "complaint_sources": {"unique": ["id"]},
    "file_closure_reasons": {"unique": ["id"]},
    "enforcement_case_statuses": {"unique": ["id"]},
    "enforcement_breaches": {"unique": ["id"]},
    "enforcement_outcomes": {"unique": ["id"]},
    "enforcement_actions_taken": {"unique": ["id"]},
    "enforcement_breach_details": {"unique": ["id"]},
}

if __name__ == "__main__":
    args = getResolvedOptions(sys.argv, ["JOB_NAME"])

    table_list_string = get_glue_env_var("table_list", "")
    source_catalog_database = get_glue_env_var("source_catalog_database", "")
    s3_bucket_target = get_glue_env_var("s3_bucket_target", "")
    metrics_target_location = get_metrics_target_location()

    sc = SparkContext.getOrCreate()
    glueContext = GlueContext(sc)
    spark = SparkSession(sc)
    job = Job(glueContext)
    job.init(args["JOB_NAME"], args)

    #   load table list
    table_list = table_list_string.split(",")
    failed_tables = []

    # create list to contain success metrics and constrain messages for each table
    dq_errors = []
    try:
        for table_name in table_list:
            snapshot_table_name = table_name
            increment_table_name = f"increment_{table_name}"

            # Snapshot table not in glue catalogue
            if not table_exists_in_catalog(
                glueContext, snapshot_table_name, source_catalog_database
            ):
                logger.info(
                    f"Couldn't find table {snapshot_table_name} in database {source_catalog_database}, creating a snapshot from all the increments, starting from 20210101"
                )
                # Increment table does not exist in glue catalogue
                if not table_exists_in_catalog(
                    glueContext, increment_table_name, source_catalog_database
                ):
                    logger.info(
                        f"No snapshot and no increment for {increment_table_name}, going to the next table"
                    )
                    continue
                increment_df = loadIncrementsSinceDate(
                    increment_table_name=increment_table_name,
                    name_space=source_catalog_database,
                    date="20210101",
                )
                if increment_df.rdd.isEmpty():
                    logger.info(
                        f"No snapshot and no increment for {increment_table_name}, going to the next table"
                    )
                    continue
                # create first snapshot
                increment_df = prepare_increments(increment_df)
                snapshot_df = increment_df

            # snapshot table in glue catalogue
            else:
                pushDownPredicate = create_pushdown_predicate(
                    partitionDateColumn="snapshot_date", daysBuffer=14
                )
                #   load latest snpashot
                snapshot_ddf = glueContext.create_dynamic_frame.from_catalog(
                    name_space=source_catalog_database,
                    table_name=snapshot_table_name,
                    push_down_predicate=pushDownPredicate,
                )
                snapshot_df = snapshot_ddf.toDF()
                snapshot_df = get_latest_snapshot(snapshot_df)
                last_snapshot_date = snapshot_df.select(max("snapshot_date")).first()[0]

                # load increments since the last snapshot date
                if table_exists_in_catalog(
                    glueContext, increment_table_name, source_catalog_database
                ):
                    increment_df = loadIncrementsSinceDate(
                        increment_table_name=increment_table_name,
                        name_space=source_catalog_database,
                        date=last_snapshot_date,
                    )
                    if increment_df.rdd.isEmpty():
                        if last_snapshot_date == datetime.strftime(
                            datetime.now(), "%Y%m%d"
                        ):
                            logger.info(
                                f"No new increment in {increment_table_name} and we already have a snapshot for today, going to the next table"
                            )
                            continue
                        else:
                            logger.info(
                                f"No new increment in {increment_table_name}, saving same snapshot as yesterday"
                            )
                    else:
                        # prepare COU
                        increment_df = prepare_increments(increment_df)
                        increment_df = add_snapshot_date_columns(increment_df)
                        # apply COU
                        logger.info(f"Applying increment {increment_table_name}")
                        snapshot_df = apply_increments(snapshot_df, increment_df)
                else:
                    logger.info(
                        f"Couldn't find table {increment_table_name} in database {source_catalog_database}, saving same snapshot as yesterday"
                    )

            # add currency date and set it a partition key
            snapshot_df = add_snapshot_date_columns(snapshot_df)
            PARTITION_KEYS = [
                "snapshot_year",
                "snapshot_month",
                "snapshot_day",
                "snapshot_date",
            ]

            # DQ checks with Pydeequ
            metricsRepository = FileSystemMetricsRepository(
                spark, metrics_target_location
            )
            resultKey = ResultKey(
                spark,
                ResultKey.current_milli_time(),
                {
                    "job_timestamp": datetime.now(),
                    "source_database": source_catalog_database,
                    "source_table": snapshot_table_name,
                    "glue_job_id": args["JOB_RUN_ID"],
                },
            )

            check = Check(spark, CheckLevel.Error, "Data quality failure")
            if dq_params.get(snapshot_table_name, {}).get("unique"):
                check = check.hasUniqueness(
                    dq_params[snapshot_table_name]["unique"],
                    lambda x: x == 1,
                    f"{dq_params[snapshot_table_name]['unique']} are not unique",
                )
            if dq_params.get(snapshot_table_name, {}).get("complete"):
                check = check.hasCompleteness(
                    dq_params[snapshot_table_name]["complete"],
                    lambda x: x >= 0.99,
                    f"{dq_params[snapshot_table_name]['complete']} has missing values",
                )

            verificationSuite = (
                VerificationSuite(spark)
                .onData(snapshot_df)
                .useRepository(metricsRepository)
                .addCheck(check)
            )

            try:
                verificationRun = verificationSuite.run()

                # check if any errors and raise exception if true
                cancel_job_if_failing_quality_checks(
                    VerificationResult.checkResultsAsDataFrame(spark, verificationRun)
                )

                logger.info(
                    f"Data quality checks applied to {snapshot_table_name}. Data quality test results: {get_data_quality_check_results(VerificationResult.checkResultsAsDataFrame(spark, verificationRun))}"
                )
                logger.info(
                    f"Success metrics for {snapshot_table_name}: {get_success_metrics(VerificationResult.successMetricsAsDataFrame(spark, verificationRun))}"
                )

            except Exception as verificationError:
                logger.info(
                    "Job cancelled due to data quality test failure, continuing to next table."
                )
                message = verificationError.args
                logger.info(f"{message[0]}")
                dq_errors.append(
                    f"Job for table {snapshot_table_name} cancelled due to data quality test failure."
                )
                dq_errors.append(f"{message[0]}...Continuing to next table...")

            else:
                logger.info(
                    "Data quality tests passed, appending data quality results to JSON and moving on to writing data"
                )
                verificationSuite.saveOrAppendResult(resultKey).run()

                # if data quality tests succeed, write to S3
                snapshot_df = snapshot_df.repartition(200)

                resultDataFrame = DynamicFrame.fromDF(
                    snapshot_df, glueContext, "resultDataFrame"
                )
                target_destination = s3_bucket_target + table_name

                # Clean up today's partition before writing
                purge_today_partition(glueContext, target_destination)
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
    finally:
        if len(dq_errors) > 0:
            logger.error(f"Errors: {dq_errors}")
            spark.stop()
            raise SystemExit(f"Failed: {'; '.join(dq_errors)}")
        spark.sparkContext._gateway.close()
        spark.stop()
