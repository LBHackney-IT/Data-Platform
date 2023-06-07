"""
This script prepares and standardises input datasets containing data about housing repairs and tenancies,
 which are unioned into a single dataset ready for use. Appropriate vector arrays of features are output for
 use in ML models.

Input datasets:
* Housing disrepair for 2013-2019
* Tenure Information snapshot for 2019
* Data processed for either street_or_estate property types.

Output:
* Single standardised dataset containing a row for each Council-managed property with secure tenancy from all input
 datasets listed above.
* Data filtered using street_or_estate variable.
* Includes a vectorised features and target columns
* Dataframe written as Parquet in S3.

"""

import argparse

from great_expectations.dataset import SparkDFDataset

from scripts.jobs.env_context import DEFAULT_MODE_AWS, LOCAL_MODE, ExecutionContextProvider
from scripts.helpers.helpers import add_import_time_columns, PARTITION_KEYS, \
    create_pushdown_predicate_for_max_date_partition_value
import scripts.helpers.damp_and_mould_inputs as inputs
from scripts.helpers.housing_disrepair_helpers import prepare_input_datasets, set_target, \
    get_total_occupants_housing_benefit, get_total_occupants, group_number_of_bedrooms, get_external_walls, \
    get_communal_area, get_roof_insulation, get_boilers, get_open_air_walkways, get_vulnerability_score, \
    get_main_fuel, clean_boolean_features, drop_rows_with_nulls, impute_missing_values, \
    prepare_index_field, assign_confidence_score


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--execution_mode", default=DEFAULT_MODE_AWS, choices=[DEFAULT_MODE_AWS, LOCAL_MODE], type=str,
                        required=False, metavar="set --execution_mode=aws to run on AWS")
    parser.add_argument("--source_catalog_table_ti_output_2019", default=DEFAULT_MODE_AWS, type=str,
                        required=False)
    parser.add_argument("--source_catalog_table_housing_disrepair", default=DEFAULT_MODE_AWS, type=str,
                        required=False)
    parser.add_argument("--output_path", default=DEFAULT_MODE_AWS, type=str,
                        required=False)

    # set argument for each arg
    source_catalog_database_data_and_insight_glue_arg = "source_catalog_database_data_and_insight"
    source_catalog_table_housing_disrepair_glue_arg = "source_catalog_table_housing_disrepair"
    source_catalog_table_ti_output_2019_glue_arg = "source_catalog_table_ti_output_2019"
    output_path_glue_arg = "output_path"

    glue_args = [
        source_catalog_database_data_and_insight_glue_arg,
        source_catalog_table_housing_disrepair_glue_arg,
        source_catalog_table_ti_output_2019_glue_arg,
        output_path_glue_arg
    ]

    local_args, _ = parser.parse_known_args()
    mode = local_args.execution_mode

    street_or_estate_list = ['estate']
    hb_occupants = False
    local = True

    with ExecutionContextProvider(mode, glue_args, local_args) as execution_context:
        logger = execution_context.logger
        spark = execution_context.spark_session
        spark.conf.set("spark.sql.broadcastTimeout", 7200)

        # get input datasets
        source_catalog_database_data_and_insight = execution_context.get_input_args(
            source_catalog_database_data_and_insight_glue_arg)
        source_catalog_table_housing_disrepair = execution_context.get_input_args(
            source_catalog_table_housing_disrepair_glue_arg)
        source_catalog_table_ti_output_2019 = execution_context.get_input_args(
            source_catalog_table_ti_output_2019_glue_arg)

        if local:
            repairs_df = execution_context.get_dataframe(source_catalog_table_housing_disrepair)
            tenure_df = execution_context.get_dataframe(source_catalog_table_ti_output_2019)
        else:
            repairs_df = execution_context.get_dataframe(name_space=source_catalog_database_data_and_insight,
                                                         table_name=source_catalog_table_housing_disrepair,
                                                         push_down_predicate=create_pushdown_predicate_for_max_date_partition_value(
                                                             source_catalog_database_data_and_insight,
                                                             source_catalog_table_housing_disrepair, 'import_date'))

            tenure_df = execution_context.get_dataframe(name_space=source_catalog_database_data_and_insight,
                                                        table_name=source_catalog_table_ti_output_2019,
                                                        push_down_predicate=create_pushdown_predicate_for_max_date_partition_value(
                                                            source_catalog_database_data_and_insight,
                                                            source_catalog_table_ti_output_2019, 'import_date'))

        for prop_type in street_or_estate_list:
            df = prepare_input_datasets(repairs_df, tenure_df,
                                        repairs_df_columns=inputs.repairs_cols,
                                        tenure_df_columns=inputs.ti_cols,
                                        deleted_estates=inputs.deleted_estates,
                                        street_or_estate=prop_type)

            df = set_target(dataframe=df, target_col=inputs.target[0])

            df = prepare_index_field(dataframe=df, column='uprn')

            df = assign_confidence_score(dataframe=df, leak_flag='flag_leak_pre_2019',
                                         damp_mould_flag='flag_damp_mould_pre_2019',
                                         leak_weighting=0.3)

            df = get_total_occupants_housing_benefit(dataframe=df, hb_num_children='no_of_children',
                                                     hb_num_adults='no_of_adults')

            df = get_total_occupants(dataframe=df, new_column_name='total_occupants',
                                     occupancy_columns=inputs.occupants, child_count='child_count')

            df = group_number_of_bedrooms(dataframe=df, bedroom_column='number_of_bedrooms',
                                          new_column_name='number_bedrooms_bands')

            df = get_external_walls(dataframe=df, attachment_column='Attachment',
                                    new_column_name='flag_has_external_walls')

            df = get_communal_area(dataframe=df, communal_area_column='type_of_communal_area',
                                   new_column_name='flag_communal_area')

            df = get_roof_insulation(dataframe=df, roof_insulation_column='roof_insulation',
                                     new_column_name='flag_roof_insulation_or_dwelling_above')

            df = get_main_fuel(dataframe=df, fuel_column='main_fuel_type',
                               new_column_name='flag_main_fuel_gas_individual')

            df = get_boilers(dataframe=df, heating_column='Heating',
                             new_column_name='flag_heating_boilers')

            df = get_open_air_walkways(dataframe=df, open_walkways_column='open_to_air_walkways',
                                       new_column_name='flag_open_to_air_walkways')

            df = get_vulnerability_score(dataframe=df, vulnerability_dict=inputs.vulnerability_cols,
                                         new_column_name='vulnerability_score')

            # keep features required for machine learning model
            df = df.select(*inputs.ml_cols)

            # clean boolean features
            df = clean_boolean_features(dataframe=df, bool_list=inputs.bool_cols)

            # drop rows with null values in specific columns
            df = drop_rows_with_nulls(dataframe=df, features_list=['number_bedrooms_bands',
                                                                   'total_occupants', 'typologies'])

            # impute missing values
            columns_to_impute = []
            if len(columns_to_impute) > 0:
                df = impute_missing_values(dataframe=df, features_to_impute=columns_to_impute, strategy='median',
                                           suffix='')

            # make data quality checks using Great Expectations
            df_ge = SparkDFDataset(df)

            # check for uniqueness and record any anomalies
            result_unique = df_ge.expect_column_values_to_be_unique(column='uprn',
                                                                    result_format={"result_format": "BOOLEAN_ONLY"})
            assert result_unique["success"] == True, \
                'The UPRN (ID) field is not unique.'
            logger.info(f'Column "uprn" contains unique values: {result_unique["success"]}')

            # check for completeness
            result_not_null = df_ge.expect_column_values_to_not_be_null(column='uprn',
                                                                        mostly=1,
                                                                        result_format={"result_format": "BASIC"})

            assert result_not_null["success"] == True, \
                'The UPRN (ID) field contains null values.'
            logger.info(f'Column "uprn" values not null: {result_not_null["success"]}')

            # write output to parquet
            df = add_import_time_columns(df)
            output_path = execution_context.get_input_args(output_path_glue_arg)
            execution_context.save_dataframe(df,
                                             f'{output_path}/{prop_type}',
                                             *PARTITION_KEYS,
                                             save_mode='overwrite')
            logger.info(f'Prepared dataframe for {prop_type} written successfully to {output_path}/{prop_type}')
            logger.info(f'Prepared dataset for {prop_type} number of rows: {df.count()}')
            df.show(10, truncate=False)


if __name__ == '__main__':
    main()
