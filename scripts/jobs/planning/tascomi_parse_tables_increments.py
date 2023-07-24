import datetime
import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from awsglue.context import GlueContext
from awsglue.job import Job
from pydeequ.checks import Check, CheckLevel
from pydeequ.repository import FileSystemMetricsRepository, ResultKey
from pydeequ.verification import VerificationSuite, VerificationResult
from pyspark.context import SparkContext
from pyspark.sql import SparkSession
from awsglue.dynamicframe import DynamicFrame

from scripts.helpers.data_quality_testing import get_metrics_target_location, cancel_job_if_failing_quality_checks, \
    get_data_quality_check_results, get_success_metrics
from scripts.helpers.helpers import get_glue_env_var, PARTITION_KEYS, parse_json_into_dataframe, table_exists_in_catalog, \
    create_pushdown_predicate


# dict containing parameters for DQ checks
dq_params = {'appeals': {'unique': ['id', 'import_date'], 'complete': 'id'},
             'applications': {'unique': ['id', 'import_date'], 'complete': 'application_reference_number'},
             'appeal_decision': {'unique': ['id', 'import_date'], 'complete': 'id'},
             'appeal_status': {'unique': ['id', 'import_date'], 'complete': 'id'},
             'appeal_types': {'unique': ['id', 'import_date'], 'complete': 'id'},
             'committees': {'unique': ['id', 'import_date'], 'complete': 'id'},
             'communications': {'unique': ['id', 'import_date'], 'complete': 'id'},
             'communication_types': {'unique': ['id', 'import_date'], 'complete': 'id'},
             'contacts': {'unique': ['id', 'import_date'], 'complete': 'id'},
             'contact_types': {'unique': ['id', 'import_date'], 'complete': 'id'},
             'decision_types': {'unique': ['id', 'import_date'], 'complete': 'id'},
             'documents': {'unique': ['id', 'import_date'], 'complete': 'id'},
             'document_types': {'unique': ['id', 'import_date'], 'complete': 'id'},
             'dtf_locations': {'unique': ['id', 'import_date'], 'complete': 'id'},
             'emails': {'unique': ['id', 'import_date'], 'complete': 'id'},
             'enforcements': {'unique': ['id', 'import_date'], 'complete': 'id'},
             'fees': {'unique': ['id', 'import_date'], 'complete': 'id'},
             'fee_payments': {'unique': ['id', 'import_date'], 'complete': 'id'},
             'fee_types': {'unique': ['id', 'import_date'], 'complete': 'id'},
             'ps_development_codes': {'unique': ['id', 'import_date'], 'complete': 'id'},
             'public_comments': {'unique': ['id', 'import_date'], 'complete': 'id'},
             'public_consultations': {'unique': ['id', 'import_date'], 'complete': 'document_id'},
             'users': {'unique': ['id', 'import_date'], 'complete': 'id'},
             'committee_application_map': {'unique': ['id', 'import_date'], 'complete': 'id'},
             'user_teams': {'unique': ['id', 'import_date'], 'complete': 'id'},
             'user_team_map': {'unique': ['id', 'import_date'], 'complete': 'id'},
             'application_types': {'unique': ['id', 'import_date'], 'complete': 'id'},
             'pre_applications': {'unique': ['id', 'import_date'], 'complete': 'id'},
             'pre_application_categories': {'unique': ['id', 'import_date'], 'complete': 'id'},
             'asset_constraints': {'unique': ['id', 'import_date'], 'complete': 'id'},
             'nature_of_enquiries': {'unique': ['id', 'import_date'], 'complete': 'id'},
             'enquiry_outcome': {'unique': ['id', 'import_date'], 'complete': 'id'},
             'enquiry_stage': {'unique': ['id', 'import_date'], 'complete': 'id'},
             'wards': {'unique': ['id', 'import_date'], 'complete': 'id'},
             'appeal_formats': {'unique': ['id', 'import_date'], 'complete': 'id'},
             'enforcement_outcome_types': {'unique': ['id', 'import_date'], 'complete': 'id'},
             'enforcement_protocols': {'unique': ['id', 'import_date'], 'complete': 'id'},
             'priority_statuses': {'unique': ['id', 'import_date'], 'complete': 'id'},
             'complaint_sources': {'unique': ['id', 'import_date'], 'complete': 'id'},
             'file_closure_reasons': {'unique': ['id', 'import_date'], 'complete': 'id'},
             'enforcement_case_statuses': {'unique': ['id', 'import_date'], 'complete': 'id'},
             'enforcement_breaches': {'unique': ['id', 'import_date'], 'complete': 'id'},
             'enforcement_outcomes': {'unique': ['id', 'import_date'], 'complete': 'id'},
             'enforcement_actions_taken': {'unique': ['id', 'import_date'], 'complete': 'id'},
             'enforcement_breach_details': {'unique': ['id', 'import_date'], 'complete': 'id'}
             }


if __name__ == "__main__":

    args = getResolvedOptions(sys.argv, ['JOB_NAME'])

    table_list_string = get_glue_env_var('table_list', '')
    source_catalog_database = get_glue_env_var('source_catalog_database', '')
    s3_bucket_target = get_glue_env_var('s3_bucket_target', '')
    metrics_target_location = get_metrics_target_location()

    sc = SparkContext.getOrCreate()
    spark = SparkSession.builder.getOrCreate()
    glueContext = GlueContext(sc)
    logger = glueContext.get_logger()
    job = Job(glueContext)
    job.init(args['JOB_NAME'], args)

    # create table list
    table_list = table_list_string.split(',')
    failed_tables = []

    # create list to contain success metrics and constrain messages for each table
    dq_errors = []
    try:
        # loop through each table
        for table in table_list:
            logger.info(f"Table being processed is: {table} in database {source_catalog_database}.")

            # Add prefix to table name to retrieve API data
            source_table_name = f'api_response_{table}'

            if not table_exists_in_catalog(glueContext, source_table_name, source_catalog_database):
                logger.info(f"Couldn't find table {source_table_name} in database {source_catalog_database}, moving onto next table.")
                continue

            pushdown_predicate = create_pushdown_predicate(partitionDateColumn='import_date', daysBuffer=14)
            source_data = glueContext.create_dynamic_frame.from_catalog(
                name_space=source_catalog_database,
                table_name=source_table_name,
                transformation_ctx = "data_source" + source_table_name,
                push_down_predicate = pushdown_predicate
            )

            df = source_data.toDF()
            logger.info(f"{source_table_name} - number of rows: {df.count()}")

            if df.rdd.isEmpty():
                logger.info(f"No increment found for {source_table_name}, moving onto next table.")
                continue

            # keep only rows where api_response_code == 200
            df = df.where(df.import_api_status_code == '200')

            # parse data
            df = parse_json_into_dataframe(spark=spark, column=table, dataframe=df)

            metricsRepository = FileSystemMetricsRepository(spark, metrics_target_location)
            resultKey = ResultKey(spark, ResultKey.current_milli_time(), {
                "job_timestamp": datetime.datetime.now(),
                "source_database": source_catalog_database,
                "source_table": table,
                "glue_job_id": args['JOB_RUN_ID']
            })

            check = Check(spark, CheckLevel.Error, "Data quality failure") 
            if(dq_params.get(table, {}).get("unique")):
                check = check.hasUniqueness(dq_params[table]["unique"], lambda x: x == 1, f'{dq_params[table]["unique"]} are not unique')
            if(dq_params.get(table, {}).get("complete")):
                check = check.hasCompleteness(dq_params[table]["complete"], lambda x: x >= 0.99, f'{dq_params[table]["complete"]} has missing values')

            verificationSuite = VerificationSuite(spark) \
                .onData(df) \
                .useRepository(metricsRepository) \
                .addCheck(check)

            try:

                verificationRun = verificationSuite.run()

                # check if any errors and raise exception if true
                cancel_job_if_failing_quality_checks(VerificationResult.checkResultsAsDataFrame(spark, verificationRun))

                logger.info(f'Data quality checks applied to {table}. Data quality test results: {get_data_quality_check_results(VerificationResult.checkResultsAsDataFrame(spark, verificationRun))}')
                logger.info(f'Success metrics for {table}: {get_success_metrics(VerificationResult.successMetricsAsDataFrame(spark, verificationRun))}')

            except Exception as verificationError:
                logger.info(f'Job cancelled due to data quality test failure, continuing to next table.')
                message = verificationError.args
                logger.info(f"{message[0]}")
                dq_errors.append(f'Job for table {table} cancelled due to data quality test failure.')
                dq_errors.append(f'{message[0]}...Continuing to next table...')

            else:
                logger.info(f'Data quality tests passed, appending data quality results to JSON and moving onto data parsing.')
                verificationSuite.saveOrAppendResult(resultKey).run()

                # if data quality tests succeed, write to S3
                target_destination = s3_bucket_target + table

                parsed_df = DynamicFrame.fromDF(df, glueContext, "cleanedDataframe")

                parquet_data = glueContext.write_dynamic_frame.from_options(
                    frame=parsed_df,
                    connection_type="s3",
                    format="parquet",
                    connection_options={"path": target_destination, "partitionKeys": PARTITION_KEYS},
                    transformation_ctx="parquet_data")
        job.commit()
    finally:
        if len(dq_errors) > 0:
            logger.error(f'DQ Errors: {dq_errors}')
        spark.sparkContext._gateway.close()
        spark.stop()
