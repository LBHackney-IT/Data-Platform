# flake8: noqa: F821

import awswrangler as wr
from datetime import datetime
import logging
import sys

from awsglue.utils import getResolvedOptions
import great_expectations as gx
import pandas as pd
from scripts.helpers.housing_gx_dq_inputs import table_list, partition_keys
import scripts.jobs.housing.housing_person_reshape_gx_suite
import scripts.jobs.housing.housing_tenure_reshape_gx_suite
import scripts.jobs.housing.housing_contacts_reshape_gx_suite
import scripts.jobs.housing.housing_assets_reshape_gx_suite
import scripts.jobs.housing.housing_homeowner_record_sheet_gx_suite
import scripts.jobs.housing.housing_dwellings_list_gx_suite

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

arg_keys = ['region_name', 's3_endpoint', 's3_target_location', 's3_staging_location', 'target_database',
            'target_table']
args = getResolvedOptions(sys.argv, arg_keys)
locals().update(args)


def main():
    # add GX context
    context = gx.get_context(mode="file", project_root_dir=s3_target_location)

    df_all_suite_list = []

    for table in table_list:

        # get expectation suite for dataset
        suite = context.suites.get(name=f'{table}_suite')
        expectations = suite.expectations

        # drop columns not needed
        cols_to_drop = ['notes', 'result_format', 'catch_exceptions',
                        'rendered_content', 'windows', 'batch_id']

        suite_df = pd.DataFrame()
        for i in expectations:
            temp_i = i
            temp_df = pd.json_normalize(dict(temp_i))
            temp_df['expectation_type'] = temp_i.expectation_type
            temp_df['dataset_name'] = table
            temp_df = temp_df.drop(columns=cols_to_drop)
            suite_df = pd.concat([suite_df, temp_df])

        df_all_suite_list.append(suite_df)

    df = pd.concat(df_all_suite_list)

    # add expectation_id
    df['expectation_id'] = df['expectation_type'] + "_" + df['dataset_name']

    df['import_year'] = datetime.today().year
    df['import_month'] = datetime.today().month
    df['import_day'] = datetime.today().day
    df['import_date'] = datetime.today().strftime('%Y%m%d')

    # set dtypes for Athena with default of string
    dict_values = ['string' for _ in range(len(df.columns))]
    dtype_dict = dict(zip(df.columns, dict_values))

    # write to s3
    wr.s3.to_parquet(
        df=df,
        path=s3_target_location,
        dataset=True,
        database=target_database,
        table=target_table,
        mode="overwrite_partitions",
        partition_cols=partition_keys,
        dtype=dtype_dict
    )

    logger.info(f'GX Data Quality test metadata written to {s3_target_location}')


if __name__ == '__main__':
    main()
