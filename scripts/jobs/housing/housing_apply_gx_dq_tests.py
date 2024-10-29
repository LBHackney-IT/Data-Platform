# flake8: noqa: F821

import awswrangler as wr
from datetime import datetime, date
import json
import logging
import sys

from awsglue.utils import getResolvedOptions
import great_expectations as gx
import pandas as pd
from pyathena import connect
from scripts.helpers.housing_gx_dq_inputs import sql_config, table_list, partition_keys, dq_dimensions_map
import scripts.jobs.housing.housing_person_reshape_gx_suite
import scripts.jobs.housing.housing_tenure_reshape_gx_suite
import scripts.jobs.housing.housing_contacts_reshape_gx_suite
import scripts.jobs.housing.housing_assets_reshape_gx_suite
import scripts.jobs.housing.housing_homeowner_record_sheet_gx_suite
import scripts.jobs.housing.housing_dwellings_list_gx_suite

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

arg_keys = ['region_name', 's3_endpoint', 's3_target_location', 's3_staging_location', 'target_database',
            'target_table', 'gx_docs_bucket', 'gx_docs_prefix']
args = getResolvedOptions(sys.argv, arg_keys)
locals().update(args)


def json_serial(obj):
    """JSON serializer for objects not serializable by default."""
    if isinstance(obj, (datetime, date)):
        return obj.isoformat()
    raise TypeError(f"Type {type(obj)} not serializable")


def main():
    # add GX context
    context = gx.get_context(mode="file", project_root_dir=s3_target_location)

    # set up data docs
    boto3_options = {
        "endpoint_url": s3_endpoint,
        "region_name": region_name
    }
    site_config = {
        "class_name": "SiteBuilder",
        "site_index_builder": {"class_name": "DefaultSiteIndexBuilder"},
        "store_backend": {
            "class_name": "TupleS3StoreBackend",
            "bucket": gx_docs_bucket,
            "prefix": gx_docs_prefix,
            "boto3_options": boto3_options,
        },
    }

    site_name = "housing_gx_dq_data_docs"
    context.add_data_docs_site(site_name=site_name, site_config=site_config)
    context.build_data_docs(site_names=site_name)
    data_source = context.data_sources.add_pandas("pandas")

    # create empty dataframe to hold results
    table_results_df_list = []

    for table in table_list:
        logger.info(f'{table} loading...')

        sql_query = sql_config.get(table).get('sql')

        conn = connect(s3_staging_dir=s3_staging_location,
                       region_name=region_name)

        df = pd.read_sql_query(sql_query, conn)

        # set up batch
        data_asset = data_source.add_dataframe_asset(name=f'{table}_df_asset')
        batch_definition = data_asset.add_batch_definition_whole_dataframe("Athena batch definition")
        batch_parameters = {"dataframe": df}

        # get expectation suite for dataset
        suite = context.suites.get(name=f'{table}_suite')

        validation_definition = gx.ValidationDefinition(
            data=batch_definition,
            suite=suite,
            name=f'validation_definition_{table}')
        validation_definition = context.validation_definitions.add(validation_definition)

        # create and start checking data with checkpoints
        actions = [
            gx.checkpoint.actions.UpdateDataDocsAction(
                name="update_my_site", site_names=[site_name]
            )
        ]

        checkpoint = context.checkpoints.add(
            gx.checkpoint.checkpoint.Checkpoint(
                name=f'{table}_checkpoint',
                validation_definitions=[validation_definition],
                actions=actions,
                result_format={"result_format": "COMPLETE",
                               "return_unexpected_index_query": False,
                               "partial_unexpected_count": 0}
            )
        )

        checkpoint_result = checkpoint.run(batch_parameters=batch_parameters)
        results_dict = checkpoint_result.describe_dict()
        # Serialize the result to handle any datetime objects
        json_results = json.dumps(results_dict, default=json_serial)
        logger.info(f"json_results: {json_results}")
        results = json.loads(json_results)
        table_results_df = pd.json_normalize(results['validation_results'][0]['expectations'])
        table_results_df_list.append(table_results_df)

        # generate id lists for each unexpected result set
        query_df = table_results_df.loc[(~table_results_df['result.unexpected_index_list'].isna()) & (
                table_results_df['result.unexpected_index_list'].values != '[]')]

        table_results_df['unexpected_id_list'] = pd.Series(dtype='object')
        for i, row in query_df.iterrows():
            table_results_df.loc[i, 'unexpected_id_list'] = str(
                list(df[sql_config.get(table).get('id_field')].iloc[row['result.unexpected_index_list']]))

    results_df = pd.concat(table_results_df_list)

    # map DQ dimension type
    results_df['dq_dimension_type'] = results_df['expectation_type'].map(dq_dimensions_map)

    # add clean dataset name
    results_df['table_name'] = results_df['kwargs.batch_id'].map(
        lambda x: x.removeprefix('pandas-').removesuffix('_df_asset'))

    results_df['import_year'] = datetime.today().year
    results_df['import_month'] = datetime.today().month
    results_df['import_day'] = datetime.today().day
    results_df['import_date'] = datetime.today().strftime('%Y%m%d')

    # set dtypes for Athena
    dtype_dict = {'expectation_type': 'string',
                  'kwargs.batch_id': 'string',
                  'kwargs.column': 'string',
                  'kwargs.min_value': 'string',
                  'kwargs.max_value': 'string',
                  'result.element_count': 'bigint',
                  'result.unexpected_count': 'bigint',
                  'result.missing_count': 'bigint',
                  'result.partial_unexpected_list': 'array<string>',
                  'result.unexpected_list': 'array<string>',
                  'result.unexpected_index_list': 'array<bigint>',
                  'result.unexpected_index_query': 'string',
                  'kwargs.regex': 'string',
                  'kwargs.value_set': 'string',
                  'kwargs.column_list': 'string',
                  'import_year': 'string',
                  'import_month': 'string',
                  'import_day': 'string',
                  'import_date': 'string'}

    # write to s3
    wr.s3.to_parquet(
        df=results_df,
        path=s3_target_location,
        dataset=True,
        database=target_database,
        table=target_table,
        mode="overwrite_partitions",
        partition_cols=partition_keys,
        dtype=dtype_dict
    )

    logger.info(f'GX Data Quality testing results written to {s3_target_location}')


if __name__ == '__main__':
    main()
