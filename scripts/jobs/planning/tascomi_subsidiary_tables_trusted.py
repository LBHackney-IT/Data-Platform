import sys
import boto3
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
from awsglue.dynamicframe import DynamicFrame
from pyspark.sql.functions import *
import pyspark.sql.functions as F
from scripts.helpers.helpers import get_glue_env_var, get_latest_partitions, create_pushdown_predicate, add_import_time_columns, \
    check_if_dataframe_empty, PARTITION_KEYS_SNAPSHOT


def get_latest_rows_by_date(df, column):
    """
    Filters dataframe to keep rows byt specifying a date column. E.g. to get the
    latest snapshot_date, column='snapshot_date'
    """
    date_filter = df.select(max(column)).first()[0]
    df = df.where(col(column) == date_filter)
    return df


def clear_target_folder(s3_bucket_target, output_table):
    """clears the target folder in S3"""
    s3 = boto3.resource('s3')
    folder_string = s3_bucket_target.replace('s3://', '')
    bucket_name = folder_string.split('/')[0]
    prefix = f"{folder_string.replace(bucket_name + '/', '')}{output_table}/"
    bucket = s3.Bucket(bucket_name)
    print(f'bucket: {bucket}')
    print(f' prefix: {prefix}')
    bucket.objects.filter(Prefix=prefix).delete()


if __name__ == "__main__":

    # read job parameters
    args = getResolvedOptions(sys.argv, ['JOB_NAME'])
    source_catalog_table_list = get_glue_env_var('source_catalog_table_list', '')
    source_catalog_database = get_glue_env_var('source_catalog_database', '')
    s3_bucket_target = get_glue_env_var('s3_bucket_target', '')

    # start the Spark session and the logger
    glueContext = GlueContext(SparkContext.getOrCreate())
    logger = glueContext.get_logger()
    job = Job(glueContext)
    job.init(args['JOB_NAME'], args)
    logger.info(f'The job is starting...')

    # mapping tables
    dev_map = {
        '(E)Major Development (TDC)': 'Other',
        '(E)Minor (Housing-Led) (PIP)': 'Other',
        '(E)Minor (Housing-Led) (TDC)': 'Other',
        '(E)Minor Gypsy and Traveller sites development': 'Minor',
        '(E)Relevant Demolition In A Conservation Area (Other)': 'Other',
        'Advertisements': 'Other',
        'All Others': 'Other',
        'Certificate of Lawful Development': 'Other',
        'Certificates of Appropriate Alternative Development': 'Other',
        'Certificates of Lawfuless of Proposed Works to Listed Buildings': 'Other',
        'Change of use': 'Other',
        'Conservation Area Consents': 'Other',
        'Extended construction hours': 'Other',
        'Householder': 'Other',
        'Larger Household Extensions': 'Other',
        'Listed Building Alterations': 'Other',
        'Listed Building Consent to Demolish': 'Other',
        'Major Dwellings': 'Major',
        'Major Gypsy and Traveller sites development': 'Major',
        'Major Industrial': 'Major',
        'Major Office': 'Major',
        'Major Retail': 'Major',
        'Minerals': 'Other',
        'Minor Industrial': 'Minor',
        'Minor Office': 'Minor',
        'Minor Residential': 'Minor',
        'Minor Retail': 'Minor',
        'Non-Material Amendments': 'Other',
        'Not Required On Statutory Returns': 'Not Req. on Stat Returns',
        'Notifications': 'Other',
        'Office to Residential': 'Other',
        'Other Major Developments': 'Major',
        'Other Minor Developments': 'Minor',
        'Prior notification - new dwellings': 'Other',
        'Retail and Sui Generis Uses to Residential': 'Other',
        'Storage or Distribution Centres to Residential': 'Other',
        'To State-Funded School or Registered Nursery': 'Other'}

    # dictionary containing parameters for each table transformation
    processing_dict = {'decision_levels': {'output_tables': ['decision_levels'],
                                           'decision_levels': {'rename_cols': [['id', 'decision_level_id'],
                                                                               ['name', 'decision_level']],
                                                               'select_cols': ['decision_level_id', 'committee',
                                                                               'last_updated',
                                                                               'last_updated_by', 'import_year',
                                                                               'import_datetime',
                                                                               'import_timestamp', 'snapshot_date'],
                                                               'calc_fields': [
                                                                   ['counter_decision_level', lit("1").cast("int")],
                                                                   ['flag_delegated',
                                                                    when(col('decision_level') == "Delegated",
                                                                         lit("1")).otherwise(lit("0"))]]
                                                               }},
                       'decision_types': {'output_tables': ['decision_types'],
                                          'decision_types': {'rename_cols': [['id', 'decision_type_id'],
                                                                             ['exacom_code', 'decision_exacom_code']],
                                                             'select_cols': ['decision_type_id', 'approval_decision',
                                                                             'last_updated',
                                                                             'last_updated_by', 'decision_type',
                                                                             'decision_exacom_code', 'withdrawal',
                                                                             'refusal_decision', 'import_date',
                                                                             'import_day',
                                                                             'import_timestamp', 'import_datetime',
                                                                             'snapshot_date'],
                                                             'calc_fields': [
                                                                 ['counter_decision_type', lit("1").cast('int')],
                                                                 ['flag_dec_withdrawn',
                                                                  when(col('decision_exacom_code') == "Withdrawn",
                                                                       lit("1")).otherwise(lit("0"))],
                                                                 ['flag_dec_granted',
                                                                  when(col('decision_exacom_code') == "Granted",
                                                                       lit("1")).otherwise(lit("0"))],
                                                                 ['flag_dec_refused',
                                                                  when(col('decision_exacom_code') == "Refused",
                                                                       lit("1")).otherwise(lit("0"))]]
                                                             }},
                       'ps_development_codes': {'output_tables': ['ps_development_codes'],
                                                'ps_development_codes': {
                                                    'rename_cols': [['id', 'ps_development_code_id'],
                                                                    ['name', 'development_type']],
                                                    'select_cols': ['ps_development_code_id', 'expiry_days', 'major',
                                                                    'minor', 'exclude_from_stat_returns',
                                                                    'import_date', 'import_day', 'import_month',
                                                                    'import_year', 'import_datetime',
                                                                    'import_timestamp', 'import_datetime',
                                                                    'snapshot_date', 'development_type'],
                                                    'calc_fields': [['counter_ps_code', lit("1").cast('int')]],
                                                    'map_fields': [["to_replace=dev_map", "subset=['dev_type']"]]
                                                    }},
                       'contacts': {'output_tables': ['agents', 'applicants'],
                                    'agents': {'rename_cols': [['id', 'agent_id'],
                                                               ['name', 'development_type']],
                                               'filter_rows': [[2, 32]]},
                                    'applicants': {'rename_cols': [['id', 'applicant_id'],
                                                                   ['name', 'development_type']],
                                                   'filter_rows': [[1, 31]]}
                                    }
                       }

    # split tables string into list
    table_list = source_catalog_table_list.split(',')
    logger.info(f'Table list: {table_list}')

    # loop through each table
    for table in table_list:
        logger.info(f'Table being ingested is: {table} in database {source_catalog_database}.')

        # load data from Glue catalog
        data_source = glueContext.create_dynamic_frame.from_catalog(
            name_space=source_catalog_database,
            table_name=table,
            push_down_predicate=create_pushdown_predicate('snapshot_date', 3)
        )

        # convert to a data frame and filter by snapshot_date
        df = data_source.toDF()
        df = get_latest_rows_by_date(df=df, column='snapshot_date')

        # loop through the list of input tables, and the output tables to be generated
        for output_table in processing_dict.get(table, {}).get('output_tables', {}):

            logger.info(f'Output table {output_table} is being created from {table} and transformed.')

            #         start transformations
            #         rename columns
            for rename_col in processing_dict.get(output_table, {}).get('rename_cols', {}):
                df = df.withColumnRenamed([rename_col][0][0], [rename_col][0][1])

                # select columns to keep
            for select_col in processing_dict.get(output_table, {}).get('select_cols', {}):
                df = df.select(select_col)

            # create calculated fields for reporting
            for calc_field in processing_dict.get(output_table, {}).get('calc_fields', {}):
                df = df.withColumn([calc_field][0][0], [calc_field][0][1])

            # map values to selected fields
            for map_field in processing_dict.get(output_table, {}).get('map_fields', {}):
                df = df.replace([map_field][0][0], [map_field][0][1])

            # filter rows
            for filter_row in processing_dict.get(output_table, {}).get('filter_rows', {}):
                df = df[df.contact_type_id.isin(filter_row)]

            # Convert data frame to dynamic frame
            dynamic_frame = DynamicFrame.fromDF(df, glueContext, "target_data_to_write")

            # empty the target folder in the trusted zone as we are not storing snapshots
            logger.info(f'clearing target bucket')
            clear_target_folder(s3_bucket_target, output_table)

            # Write the data to S3
            parquet_data = glueContext.write_dynamic_frame.from_options(
                frame=dynamic_frame,
                connection_type="s3",
                format="parquet",
                connection_options={"path": s3_bucket_target + output_table, "partitionKeys": PARTITION_KEYS_SNAPSHOT},
                transformation_ctx="target_data_to_write")

            logger.info(
                f'Table {table} has been extracted and transformed. Data written into output table {output_table} in {s3_bucket_target}')

        job.commit()
