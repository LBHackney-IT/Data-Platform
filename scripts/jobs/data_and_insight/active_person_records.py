"""
This script prepares and standardises various input datasets containing person records, and then unions into
a single dataset ready for use.

All records are 'live' records at the time of reading, and each dataset is prepared, cleaned and standardised with
bespoke functions from scripts.jobs.ml_jobs.person_matching_module.

Input datasets:
* Council Tax - all members on live accounts.
* Housing Benefit - all members on live accounts receiving payments
* Housing Tenancies - all members on live tenancies
* Parking permits - members on live permits

Output:
* single standardised dataset containing active records from all input datasets listed above.
Dataframe written as Parquet in S3.
* Please note there is a column called is_duplicate which flags duplicate source_ids. This happens when
the source data contains more than one record for a person_id. Since this may be deliberate, these records
are kept within the output dataset but flagged in this column, so they can be filtered out if required.

# Outstanding improvements
- Calculate Council Tax ID without using party_ref
- do something with the completeness check output
"""

import argparse

from great_expectations.dataset import SparkDFDataset

from pyspark.sql.functions import col, when

from scripts.jobs.env_context import DEFAULT_MODE_AWS, LOCAL_MODE, ExecutionContextProvider
from scripts.jobs.ml_jobs.person_matching_module import remove_deceased,\
    prepare_clean_council_tax_data, standardize_council_tax_data,\
    prepare_clean_housing_benefit_data, standardize_housing_benefit_data, \
    prepare_clean_parking_permit_data, standardize_parking_permit_data, prepare_clean_housing_data, \
    standardize_housing_data
from scripts.helpers.helpers import add_import_time_columns, PARTITION_KEYS,\
    create_pushdown_predicate_for_latest_written_partition, \
    create_pushdown_predicate_for_max_date_partition_value


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--execution_mode", default=DEFAULT_MODE_AWS, choices=[DEFAULT_MODE_AWS, LOCAL_MODE], type=str,
                        required=False, metavar="set --execution_mode=aws to run on AWS")

    # set argument for each arg
    source_catalog_database_housing_glue_arg = "source_catalog_database_housing"
    source_catalog_table_person_reshape_glue_arg = "source_catalog_table_person_reshape"
    source_catalog_table_assets_reshape_glue_arg = "source_catalog_table_assets_reshape"
    source_catalog_table_tenure_reshape_glue_arg = "source_catalog_table_tenure_reshape"
    source_catalog_database_council_tax_glue_arg = "source_catalog_database_council_tax"
    source_catalog_table_ctax_account_glue_arg = "source_catalog_table_ctax_account"
    source_catalog_table_ctax_liability_person_glue_arg = "source_catalog_table_ctax_liability_person"
    source_catalog_table_ctax_non_liability_person_glue_arg = "source_catalog_table_ctax_non_liability_person"
    source_catalog_table_ctax_occupation_glue_arg = "source_catalog_table_ctax_occupation"
    source_catalog_table_ctax_property_glue_arg = "source_catalog_table_ctax_property"
    source_catalog_database_housing_benefit_glue_arg = "source_catalog_database_housing_benefit"
    source_catalog_table_hb_member_glue_arg = "source_catalog_table_hb_member"
    source_catalog_table_hb_household_glue_arg = "source_catalog_table_hb_household"
    source_catalog_table_hb_rent_assessment_glue_arg = "source_catalog_table_hb_rent_assessment"
    source_catalog_table_hb_tax_calc_stmt_glue_arg = "source_catalog_table_hb_tax_calc_stmt"
    source_catalog_database_parking_glue_arg = "source_catalog_database_parking"
    source_catalog_table_parking_permit_glue_arg = "source_catalog_table_parking_permit"
    output_path_glue_arg = "output_path"

    glue_args = [source_catalog_database_housing_glue_arg,
                 source_catalog_table_person_reshape_glue_arg,
                 source_catalog_table_assets_reshape_glue_arg,
                 source_catalog_table_tenure_reshape_glue_arg,
                 source_catalog_database_council_tax_glue_arg,
                 source_catalog_table_ctax_account_glue_arg,
                 source_catalog_table_ctax_liability_person_glue_arg,
                 source_catalog_table_ctax_non_liability_person_glue_arg,
                 source_catalog_table_ctax_occupation_glue_arg,
                 source_catalog_table_ctax_property_glue_arg,
                 source_catalog_database_housing_benefit_glue_arg,
                 source_catalog_table_hb_member_glue_arg,
                 source_catalog_table_hb_household_glue_arg,
                 source_catalog_table_hb_rent_assessment_glue_arg,
                 source_catalog_table_hb_tax_calc_stmt_glue_arg,
                 source_catalog_database_parking_glue_arg,
                 source_catalog_table_parking_permit_glue_arg,
                 output_path_glue_arg
                 ]

    local_args, _ = parser.parse_known_args()
    mode = local_args.execution_mode

    with ExecutionContextProvider(mode, glue_args, local_args) as execution_context:
        logger = execution_context.logger
        spark = execution_context.spark_session
        spark.conf.set("spark.sql.broadcastTimeout", 7200)

        # get housing tenancy data
        source_catalog_database_housing = execution_context.get_input_args(source_catalog_database_housing_glue_arg)
        source_catalog_table_person_reshape = execution_context.get_input_args(
            source_catalog_table_person_reshape_glue_arg)
        source_catalog_table_assets_reshape = execution_context.get_input_args(
            source_catalog_table_assets_reshape_glue_arg)
        source_catalog_table_tenure_reshape = execution_context.get_input_args(
            source_catalog_table_tenure_reshape_glue_arg)

        person_df = execution_context.get_dataframe(name_space=source_catalog_database_housing,
                                                    table_name=source_catalog_table_person_reshape,
                                                    push_down_predicate=create_pushdown_predicate_for_max_date_partition_value(
                                                        source_catalog_database_housing,
                                                        source_catalog_table_person_reshape, 'import_date'))

        assets_df = execution_context.get_dataframe(name_space=source_catalog_database_housing,
                                                    table_name=source_catalog_table_assets_reshape,
                                                    push_down_predicate=create_pushdown_predicate_for_max_date_partition_value(
                                                        source_catalog_database_housing,
                                                        source_catalog_table_assets_reshape, 'import_date'))

        tenure_df = execution_context.get_dataframe(name_space=source_catalog_database_housing,
                                                    table_name=source_catalog_table_tenure_reshape,
                                                    push_down_predicate=create_pushdown_predicate_for_max_date_partition_value(
                                                        source_catalog_database_housing,
                                                        source_catalog_table_tenure_reshape, 'import_date'))

        housing_cleaned = prepare_clean_housing_data(person_df, assets_df, tenure_df)
        housing_cleaned = remove_deceased(housing_cleaned)
        housing = standardize_housing_data(housing_cleaned)
        logger.info(f'housing df cleaned and standardised')

        # # get Council Tax data
        source_catalog_database_council_tax = execution_context.get_input_args(
            source_catalog_database_council_tax_glue_arg)
        source_catalog_table_ctax_account = execution_context.get_input_args(source_catalog_table_ctax_account_glue_arg)
        source_catalog_table_ctax_liability_person = execution_context.get_input_args(
            source_catalog_table_ctax_liability_person_glue_arg)
        source_catalog_table_ctax_non_liability_person = execution_context.get_input_args(
            source_catalog_table_ctax_non_liability_person_glue_arg)
        source_catalog_table_ctax_occupation = execution_context.get_input_args(
            source_catalog_table_ctax_occupation_glue_arg)
        source_catalog_table_ctax_property = execution_context.get_input_args(
            source_catalog_table_ctax_property_glue_arg)

        council_tax_account_df = execution_context.get_dataframe(name_space=source_catalog_database_council_tax,
                                                                 table_name=source_catalog_table_ctax_account,
                                                                 push_down_predicate=create_pushdown_predicate_for_max_date_partition_value(
                                                                     source_catalog_database_council_tax,
                                                                     source_catalog_table_ctax_account, 'import_date'))

        council_tax_liability_person_df = execution_context.get_dataframe(
            name_space=source_catalog_database_council_tax,
            table_name=source_catalog_table_ctax_liability_person,
            push_down_predicate=create_pushdown_predicate_for_max_date_partition_value(
                source_catalog_database_council_tax,
                source_catalog_table_ctax_liability_person, 'import_date'))

        council_tax_non_liability_person_df = execution_context.get_dataframe(
            name_space=source_catalog_database_council_tax,
            table_name=source_catalog_table_ctax_non_liability_person,
            push_down_predicate=create_pushdown_predicate_for_max_date_partition_value(
                source_catalog_database_council_tax,
                source_catalog_table_ctax_non_liability_person, 'import_date'))

        council_tax_occupation_df = execution_context.get_dataframe(name_space=source_catalog_database_council_tax,
                                                                    table_name=source_catalog_table_ctax_occupation,
                                                                    push_down_predicate=create_pushdown_predicate_for_max_date_partition_value(
                                                                        source_catalog_database_council_tax,
                                                                        source_catalog_table_ctax_occupation,
                                                                        'import_date'))

        council_tax_property_df = execution_context.get_dataframe(name_space=source_catalog_database_council_tax,
                                                                  table_name=source_catalog_table_ctax_property,
                                                                  push_down_predicate=create_pushdown_predicate_for_max_date_partition_value(
                                                                      source_catalog_database_council_tax,
                                                                      source_catalog_table_ctax_property,
                                                                      'import_date'))

        council_tax_cleaned = prepare_clean_council_tax_data(spark, council_tax_account_df,
                                                             council_tax_liability_person_df,
                                                             council_tax_non_liability_person_df,
                                                             council_tax_occupation_df, council_tax_property_df)
        council_tax_cleaned = remove_deceased(council_tax_cleaned)
        council_tax = standardize_council_tax_data(council_tax_cleaned)

        logger.info(f'council_tax df cleaned and standardised')

        # get housing benefit data
        source_catalog_database_housing_benefit = execution_context.get_input_args(
            source_catalog_database_housing_benefit_glue_arg)
        source_catalog_table_hb_member = execution_context.get_input_args(source_catalog_table_hb_member_glue_arg)
        source_catalog_table_hb_household = execution_context.get_input_args(source_catalog_table_hb_household_glue_arg)
        source_catalog_table_hb_rent_assessment = execution_context.get_input_args(
            source_catalog_table_hb_rent_assessment_glue_arg)
        source_catalog_table_hb_tax_calc_stmt = execution_context.get_input_args(
            source_catalog_table_hb_tax_calc_stmt_glue_arg)

        hb_member_df = execution_context.get_dataframe(name_space=source_catalog_database_housing_benefit,
                                                       table_name=source_catalog_table_hb_member,
                                                       push_down_predicate=create_pushdown_predicate_for_max_date_partition_value(
                                                           source_catalog_database_housing_benefit,
                                                           source_catalog_table_hb_member, 'import_date'))
        hb_household_df = execution_context.get_dataframe(name_space=source_catalog_database_housing_benefit,
                                                          table_name=source_catalog_table_hb_household,
                                                          push_down_predicate=create_pushdown_predicate_for_max_date_partition_value(
                                                              source_catalog_database_housing_benefit,
                                                              source_catalog_table_hb_household, 'import_date'))
        hb_rent_assessment_df = execution_context.get_dataframe(name_space=source_catalog_database_housing_benefit,
                                                                table_name=source_catalog_table_hb_rent_assessment,
                                                                push_down_predicate=create_pushdown_predicate_for_max_date_partition_value(
                                                                    source_catalog_database_housing_benefit,
                                                                    source_catalog_table_hb_rent_assessment,
                                                                    'import_date'))
        hb_tax_calc_stmt_df = execution_context.get_dataframe(name_space=source_catalog_database_housing_benefit,
                                                              table_name=source_catalog_table_hb_tax_calc_stmt,
                                                              push_down_predicate=create_pushdown_predicate_for_max_date_partition_value(
                                                                  source_catalog_database_housing_benefit,
                                                                  source_catalog_table_hb_tax_calc_stmt, 'import_date'))

        housing_benefit_cleaned = prepare_clean_housing_benefit_data(hb_member_df,
                                                                     hb_household_df,
                                                                     hb_rent_assessment_df,
                                                                     hb_tax_calc_stmt_df)
        housing_benefit_cleaned = remove_deceased(housing_benefit_cleaned)
        housing_benefit = standardize_housing_benefit_data(housing_benefit_cleaned)
        logger.info(f'Housing benefit df cleaned and standardised')

        # get parking data
        source_catalog_database_parking = execution_context.get_input_args(source_catalog_database_parking_glue_arg)
        source_catalog_table_parking_permit = execution_context.get_input_args(
            source_catalog_table_parking_permit_glue_arg)

        parking_permit_df = execution_context.get_dataframe(name_space=source_catalog_database_parking,
                                                            table_name=source_catalog_table_parking_permit,
                                                            push_down_predicate=create_pushdown_predicate_for_latest_written_partition(
                                                                database_name=source_catalog_database_parking,
                                                                table_name=source_catalog_table_parking_permit))

        parking_permit_cleaned = prepare_clean_parking_permit_data(parking_permit_df)

        parking_permit = standardize_parking_permit_data(parking_permit_cleaned)
        logger.info(f'Parking df cleaned and standardised')
        logger.info(f'Parking preview: {parking_permit.show(10, truncate=False)}')

        logger.info(f'Starting to union dataframes...')
        standard_df = housing.union(council_tax).union(housing_benefit).union(parking_permit).coalesce(10)
        logger.info(f'Standard df ready...starting dq tests')

        # make data quality checks using Great Expectations
        df_ge = SparkDFDataset(standard_df)
        # check for uniqueness and record any anomalies
        id_uniqueness_result = df_ge.expect_column_values_to_be_unique(column='source_id',
                                                                       result_format={"result_format": "COMPLETE"})
        logger.info(f'Uniqueness: {id_uniqueness_result}')
        duplicate_ids = id_uniqueness_result["result"]["unexpected_list"]
        # flag where source_ids are present more than once (duplicates) so they can be investigated later on
        standard_df = standard_df.withColumn('is_duplicated',
                                             when(col('source_id').isin(duplicate_ids), True).otherwise(False))
        # check for completeness
        id_not_null_result = df_ge.expect_column_values_to_not_be_null(column='source_id',
                                                                       result_format={"result_format": "COMPLETE"})
        logger.info(f'Completeness: {id_not_null_result}')

        standard_df = add_import_time_columns(standard_df)
        output_path = execution_context.get_input_args(output_path_glue_arg)
        execution_context.save_dataframe(standard_df, output_path, *PARTITION_KEYS, save_mode='overwrite')
        logger.info(f"Standardized dataframe written successfully to {output_path}")


if __name__ == '__main__':
    main()
