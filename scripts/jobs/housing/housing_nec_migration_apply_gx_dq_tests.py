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
from scripts.helpers.housing_nec_migration_gx_dq_inputs import (
    sql_config,
    data_load_list,
    table_list,
)
import scripts.jobs.housing.housing_nec_migration_properties_data_load_gx_suite
import scripts.jobs.housing.housing_nec_migration_tenancies_data_load_gx_suite
import scripts.jobs.housing.housing_nec_migration_people_data_load_gx_suite

# import scripts.jobs.housing.housing_nec_migration_contacts_data_load_gx_suite
# import scripts.jobs.housing.housing_nec_migration_arrears_actions_data_load_gx_suite
# import scripts.jobs.housing.housing_nec_migration_revenue_accounts_data_load_gx_suite
#
# # import scripts.jobs.housing.housing_nec_migration_transactions_data_load_gx_suite
# import scripts.jobs.housing.housing_nec_migration_addresses_data_load_gx_suite

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

arg_keys = [
    "region_name",
    "s3_endpoint",
    "s3_target_location",
    "s3_staging_location",
    "target_database",
    "target_table",
    "target_table_metadata",
    "s3_target_location_metadata",
    "s3_target_location_results",
]
args = getResolvedOptions(sys.argv, arg_keys)
locals().update(args)


def get_sql_query(sql_config, data_load, table):
    query = f"SELECT * FROM housing_nec_migration_outputs.{table}"
    id_field = sql_config.get(data_load).get("id_field")
    return query, id_field


def json_serial(obj):
    """JSON serializer for objects not serializable by default."""
    if isinstance(obj, (datetime, date)):
        return obj.isoformat()
    raise TypeError(f"Type {type(obj)} not serializable")


def main():
    # add GX context
    context = gx.get_context(mode="file", project_root_dir=s3_target_location)

    table_results_df_list = []
    df_all_suite_list = []

    for data_load in data_load_list:
        logger.info(f"{data_load} loading...")

        for table in table_list.get(data_load):
            logger.info(f"{table} processing...")

            try:
                sql_query, id_field = get_sql_query(
                    sql_config=sql_config, data_load=data_load, table=table
                )
                conn = connect(
                    s3_staging_dir=s3_staging_location, region_name=region_name
                )
                df = pd.read_sql_query(sql_query, conn)
            except Exception as e:
                logger.error(f"SQL/Connection error for {table}: {e}. Skipping.")
                continue  # Skip to next table

            # --- STEP 2: GX ASSET SETUP ---
            try:
                data_source = context.data_sources.add_pandas(f"{table}_pandas")
                data_asset = data_source.add_dataframe_asset(name=f"{table}_df_asset")
                batch_definition = data_asset.add_batch_definition_whole_dataframe(
                    "Athena batch definition"
                )
                batch_parameters = {"dataframe": df}
            except Exception as e:
                logger.error(f"GX Asset Setup error for {table}: {e}. Skipping.")
                continue
            try:
                suite = context.suites.get(name=f"{data_load}_data_load_suite")
                expectations = suite.expectations  # Get this now to ensure it exists
            except Exception as e:
                logger.error(
                    f"GX Suite retrieval error for {data_load}: {e}. Skipping."
                )
                continue

            # VALIDATION & CHECKPOINT
            try:
                validation_definition = gx.ValidationDefinition(
                    data=batch_definition,
                    suite=suite,
                    name=f"validation_definition_{table}",
                )
                # Use add_or_update to avoid duplicates
                validation_definition = context.validation_definitions.add_or_update(
                    validation_definition
                )

                checkpoint = context.checkpoints.add_or_update(
                    gx.checkpoint.checkpoint.Checkpoint(
                        name=f"{table}_checkpoint",
                        validation_definitions=[validation_definition],
                        result_format={
                            "result_format": "COMPLETE",
                            "return_unexpected_index_query": False,
                            "partial_unexpected_count": 0,
                        },
                    )
                )
                checkpoint_result = checkpoint.run(batch_parameters=batch_parameters)
            except Exception as e:
                logger.error(f"Checkpoint Run error for {table}: {e}. Skipping.")
                continue

            # PROCESS RESULTS
            try:
                results_dict = list(checkpoint_result.run_results.values())[
                    0
                ].to_json_dict()
                table_results_df = pd.json_normalize(results_dict["results"])

                # Guard clause: If table passed perfectly, results might be empty or structure different
                if table_results_df.empty:
                    logger.info(
                        f"No results to process for {table} (possibly empty batch)."
                    )
                    continue

                cols_not_needed = ["result.unexpected_list", "result.observed_value"]
                cols_to_drop = [
                    c
                    for c in table_results_df.columns
                    if c.startswith("exception_info") or c in cols_not_needed
                ]

                table_results_df = table_results_df.drop(columns=cols_to_drop)
                table_results_df_list.append(table_results_df)

                # Filter for rows that actually have unexpected indices
                query_df = table_results_df.loc[
                    (~table_results_df["result.unexpected_index_list"].isna())
                    & (
                        table_results_df["result.unexpected_index_list"].astype(str)
                        != "[]"
                    )
                ]

                table_results_df["unexpected_id_list"] = pd.Series(dtype="string")

                for i, row in query_df.iterrows():
                    try:
                        indices = row["result.unexpected_index_list"]
                        # Safety check: Ensure indices are integers
                        if isinstance(indices, list):
                            mapped_ids = df[id_field].iloc[indices].tolist()
                            table_results_df.at[i, "unexpected_id_list"] = str(
                                mapped_ids
                            )
                    except KeyError:
                        logger.error(
                            f"ID Field '{id_field}' not found in DataFrame for {table}."
                        )
                    except IndexError:
                        logger.error(f"Indices out of bounds for {table}.")
                    except Exception as e:
                        logger.warning(f"Mapping error for {table} row {i}: {e}")

                # METADATA PROCESSING
                cols_to_drop_meta = [
                    "notes",
                    "result_format",
                    "catch_exceptions",
                    "rendered_content",
                    "windows",
                ]
                suite_df = pd.DataFrame()

                # 'expectations' variable is guaranteed to exist from Step 3
                for exp in expectations:
                    temp_df = pd.json_normalize(dict(exp))
                    temp_df["expectation_type"] = exp.expectation_type
                    temp_df["dataset_name"] = table
                    temp_df["expectation_id_full"] = f"{exp.expectation_type}_{table}"
                    temp_df = temp_df.drop(columns=cols_to_drop_meta, errors="ignore")
                    suite_df = pd.concat([suite_df, temp_df])

                df_all_suite_list.append(suite_df)

            except Exception as e:
                logger.error(f"Result Processing Error for {table}: {e}")
                continue

    # END LOOPS
    if not table_results_df_list:
        logger.error("No tables were processed successfully. Exiting.")
        return

    results_df = pd.concat(table_results_df_list)
    metadata_df = pd.concat(df_all_suite_list)

    metadata_df["import_date"] = datetime.today().strftime("%Y%m%d")

    # set dtypes for Athena with default of string
    dict_values = ["string" for _ in range(len(metadata_df.columns))]
    dtype_dict_metadata = dict(zip(metadata_df.columns, dict_values))

    # add clean dataset name
    results_df["dataset_name"] = results_df["expectation_config.kwargs.batch_id"].map(
        lambda x: x.removeprefix("pandas-").removesuffix("_df_asset")
    )

    # add composite key for each test (so can be tracked over time)
    results_df.insert(
        loc=0,
        column="expectation_key",
        value=results_df.set_index(
            ["expectation_config.type", "dataset_name"]
        ).index.factorize()[0]
        + 1,
    )
    results_df["expectation_id"] = (
        results_df["expectation_config.type"] + "_" + results_df["dataset_name"]
    )
    results_df["import_date"] = datetime.today().strftime("%Y%m%d")

    # # set dtypes for Athena
    dtype_dict_results = {
        "expectation_config.type": "string",
        "expectation_config.kwargs.batch_id": "string",
        "expectation_config.kwargs.column": "string",
        "expectation_config.kwargs.min_value": "string",
        "expectation_config.kwargs.max_value": "string",
        "result.element_count": "bigint",
        "result.unexpected_count": "bigint",
        "result.missing_count": "bigint",
        "result.details_mismatched": "string",
        "result.partial_unexpected_list": "array<string>",
        "result.unexpected_index_list": "array<bigint>",
        "result.unexpected_index_query": "string",
        "expectation_config.kwargs.regex": "string",
        "expectation_config.kwargs.value_set": "string",
        "expectation_config.kwargs.column_list": "string",
        "import_date": "string",
    }

    wr.s3.to_parquet(
        df=results_df,
        path=s3_target_location_results,
        dataset=True,
        database=target_database,
        table=target_table,
        mode="overwrite",
        dtype=dtype_dict_results,
    )

    wr.s3.to_parquet(
        df=metadata_df,
        path=s3_target_location_metadata,
        dataset=True,
        database=target_database,
        table=target_table_metadata,
        mode="overwrite",
        dtype=dtype_dict_metadata,
    )


if __name__ == "__main__":
    main()
