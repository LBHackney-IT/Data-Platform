import awswrangler as wr
from datetime import datetime
import json
import logging
import sys

from awsglue.utils import getResolvedOptions
import great_expectations as gx
import pandas as pd
from pyathena import connect
from scripts.helpers.housing_gx_dq_inputs import gx_dq_housing_config, table_list
from housing_person_reshape_gx_suite import suite as person_reshape_suite
from housing_tenure_reshape_gx_suite import suite as tenure_reshape_suite
from housing_contacts_reshape_gx_suite import suite as contacts_reshape_suite

args = getResolvedOptions(sys.argv,
                          ['region_name',
                           's3_endpoint',
                           's3_target_location',
                           's3_staging_location',
                           'target_database',
                           'tables_list',
                           'gx_docs_bucket',
                           'gx_docs_prefix'])

region_name = args['region_name']
s3_endpoint = args['s3_endpoint']
s3_target_location = args['s3_target_location']
gx_docs_bucket = args['gx_docs_bucket']
gx_docs_prefix = args['gx_docs_prefix']
s3_staging_location = args['s3_staging_location']
target_database = args['target_database']
target_table = args['target_table']


def main():
    logging.basicConfig(level=logging.INFO)
    logger = logging.getLogger(__name__)

    # create GX context
    context = gx.get_context(mode="file")

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
    results_df = pd.DataFrame()

    for table in table_list:
        logger.info(f'{table} loading...')

        sql_query = gx_dq_housing_config.get(table).get('sql')

        conn = connect(s3_staging_dir=s3_staging_location,
                       region_name=region_name)

        df = pd.read_sql_query(f'{sql_query}', conn)

        # set up batch
        data_asset = data_source.add_dataframe_asset(name=f'{table}_df_asset')
        batch_definition = data_asset.add_batch_definition_whole_dataframe("Athena batch definition")
        batch_parameters = {"dataframe": df}

        # get expectation suite for dataset
        suite = context.suites.add(gx_dq_housing_config.get(table).get('suite'))

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
                actions=actions
            )
        )

        checkpoint_result = checkpoint.run(batch_parameters=batch_parameters)
        results = json.loads(checkpoint_result.describe())
        table_results_df = pd.json_normalize(results['validation_results'][0]['expectations'])
        results_df = pd.concat([results_df, table_results_df])

    date_today = datetime.today().strftime('%Y%m%d')
    results_df['import_date'] = date_today

    # write to s3
    wr.s3.to_parquet(
        df=results_df,
        path=s3_target_location,
        dataset=True,
        database=target_database,
        table=target_table,
        mode="overwrite_partitions",
        partition_cols=["import_date"]
    )

    logger.info(f'GX Data Quality testing results written to {s3_target_location}')


if __name__ == '__main__':
    main()
