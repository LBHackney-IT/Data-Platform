"""
This script prepares input data suitable for the damp and mould ML model, and then applies the trained model to the
prepared data.

Input datasets:
* Data for which predictions are to be made on

Output:
* Prepared dataset ready for ML model plus predictions.

"""

import argparse
import pyspark.sql.functions as f

from great_expectations.dataset import SparkDFDataset
from pyspark.ml import PipelineModel
from pyspark.ml.functions import vector_to_array
from pyspark.ml.tuning import CrossValidatorModel

from scripts.jobs.env_context import DEFAULT_MODE_AWS, LOCAL_MODE, ExecutionContextProvider
from scripts.helpers.helpers import add_import_time_columns, PARTITION_KEYS, \
    create_pushdown_predicate_for_max_date_partition_value
import scripts.helpers.damp_and_mould_inputs as inputs
from scripts.helpers.housing_disrepair_helpers import prepare_input_datasets, set_target, \
    get_total_occupants, group_number_of_bedrooms, get_external_walls, \
    get_communal_area, get_roof_insulation, get_boilers, get_open_air_walkways, get_vulnerability_score, \
    get_main_fuel, clean_boolean_features, drop_rows_with_nulls, impute_missing_values, \
    prepare_index_field, get_child_count, rename_void_column


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--execution_mode", default=DEFAULT_MODE_AWS, choices=[DEFAULT_MODE_AWS, LOCAL_MODE], type=str,
                        required=False, metavar="set --execution_mode=aws to run on AWS")
    parser.add_argument("--source_catalog_table_household_input", default=DEFAULT_MODE_AWS, type=str,
                        required=False)
    parser.add_argument("--source_catalog_table_housing_disrepair", default=DEFAULT_MODE_AWS, type=str,
                        required=False)
    parser.add_argument("--input_data_path", default=DEFAULT_MODE_AWS, type=str,
                        required=False)
    parser.add_argument("--output_path", default=DEFAULT_MODE_AWS, type=str,
                        required=False)
    parser.add_argument("--meta_model_path", default=DEFAULT_MODE_AWS, type=str,
                        required=False)
    parser.add_argument("--base_model_path", default=DEFAULT_MODE_AWS, type=str,
                        required=False)

    # set argument for each arg
    source_catalog_database_data_and_insight_glue_arg = "source_catalog_database_data_and_insight"
    source_catalog_table_household_input_glue_arg = "source_catalog_table_household_input"
    source_catalog_table_housing_disrepair_glue_arg = "source_catalog_table_housing_disrepair"
    meta_model_path_glue_arg = "meta_model_path"
    base_model_path_glue_arg = "base_model_path"
    input_data_path_glue_arg = "input_data_path"
    output_path_glue_arg = "output_path"

    glue_args = [
        source_catalog_database_data_and_insight_glue_arg,
        source_catalog_table_household_input_glue_arg,
        source_catalog_table_housing_disrepair_glue_arg,
        meta_model_path_glue_arg,
        base_model_path_glue_arg,
        input_data_path_glue_arg,
        output_path_glue_arg
    ]

    local_args, _ = parser.parse_known_args()
    mode = local_args.execution_mode

    with ExecutionContextProvider(mode, glue_args, local_args) as execution_context:
        logger = execution_context.logger
        spark = execution_context.spark_session
        spark.conf.set("spark.sql.broadcastTimeout", 7200)

        # set additional variables
        prepare_inputs = False
        local = True
        make_predictions = True

        # get input datasets
        source_catalog_database_data_and_insight = execution_context.get_input_args(
            source_catalog_database_data_and_insight_glue_arg)
        source_catalog_table_household_input = execution_context.get_input_args(
            source_catalog_table_household_input_glue_arg)
        source_catalog_table_housing_disrepair = execution_context.get_input_args(
            source_catalog_table_housing_disrepair_glue_arg)

        if prepare_inputs:

            if local:
                household_df = execution_context.get_dataframe(source_catalog_table_household_input)
                repairs_df = execution_context.get_dataframe(source_catalog_table_housing_disrepair)

            else:
                household_df = execution_context.get_dataframe(name_space=source_catalog_database_data_and_insight,
                                                               table_name=source_catalog_table_household_input,
                                                               push_down_predicate=create_pushdown_predicate_for_max_date_partition_value(
                                                                   source_catalog_database_data_and_insight,
                                                                   source_catalog_table_household_input, 'import_date'))
                repairs_df = execution_context.get_dataframe(name_space=source_catalog_database_data_and_insight,
                                                             table_name=source_catalog_table_housing_disrepair,
                                                             push_down_predicate=create_pushdown_predicate_for_max_date_partition_value(
                                                                 source_catalog_database_data_and_insight,
                                                                 source_catalog_table_housing_disrepair, 'import_date'))

            df = prepare_input_datasets(repairs_df=repairs_df, tenure_df=household_df,
                                        repairs_df_columns=inputs.repairs_cols + inputs.repairs_input_cols,
                                        tenure_df_columns=inputs.household_input_cols,
                                        deleted_estates=inputs.deleted_estates,
                                        street_or_estate='estate',
                                        year_subset='_post_2019')

            df = set_target(dataframe=df, target_col='flag_dam_mould_repair_post_2019')
            df = prepare_index_field(dataframe=df, column='uprn')

            # keep only rows with council tenants
            df = df.filter(df.council_tenant == 1).select('*')

            # keep only rows relating to Council tenancies
            df = df.filter(df.council_tenant == 1).select('*')

            df = rename_void_column(dataframe=df, void_column='flag_void_since_2019')

            df = group_number_of_bedrooms(dataframe=df, bedroom_column='number_of_bedrooms',
                                          new_column_name='number_bedrooms_bands')

            df = get_external_walls(dataframe=df, attachment_column='Attachment',
                                    new_column_name='flag_has_external_walls')

            df = get_communal_area(dataframe=df, communal_area_column='type_of_communal_area',
                                   new_column_name='flag_communal_area')

            df = get_roof_insulation(dataframe=df, roof_insulation_column='Roof Insulation',
                                     new_column_name='flag_roof_insulation_or_dwelling_above')

            df = get_main_fuel(dataframe=df, fuel_column='main_fuel_type',
                               new_column_name='flag_main_fuel_gas_individual')

            df = get_boilers(dataframe=df, heating_column='Heating',
                             new_column_name='flag_heating_boilers')

            df = get_open_air_walkways(dataframe=df, open_walkways_column='open_to_air_walkways',
                                       new_column_name='flag_open_to_air_walkways')

            # get flag for children present in household
            child_cols = ['hb_current_children', 'hb_no_of_disabled_chidren', 'cfs_child_allocations',
                          'cfs_allocations',
                          'SEN_cases', 'EHCP_cases', 'SEN_support_cases', 'FSM_cases', 'child_count']

            df = get_child_count(dataframe=df, child_columns=child_cols, new_column_name='child_count_all')

            df = get_total_occupants(dataframe=df, new_column_name='total_occupants',
                                     occupancy_columns=['er_records_at_prop', 'hb_total_occupants',
                                                        'ta_number_in_family'],
                                     child_count='child_count_all')

            df = get_vulnerability_score(dataframe=df, vulnerability_dict=inputs.vulnerability_cols_input,
                                         new_column_name='vulnerability_score')

            # keep features required for machine learning model
            df = df.select(*inputs.ml_cols_inputs)

            # clean boolean features
            df = clean_boolean_features(dataframe=df,
                                        bool_list=['flag_void',
                                                   'flag_has_external_walls',
                                                   'flag_communal_area',
                                                   'flag_roof_insulation_or_dwelling_above',
                                                   'flag_main_fuel_gas_individual',
                                                   'flag_heating_boilers',
                                                   'flag_open_to_air_walkways', 'target']
                                        )

            # drop rows with null values in specific columns
            df = drop_rows_with_nulls(dataframe=df, features_list=['number_bedrooms_bands',
                                                                   'total_occupants',
                                                                   'typologies'])

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
                                             f'{output_path}',
                                             *PARTITION_KEYS,
                                             save_mode='overwrite')
            logger.info(f'Prepared dataframe for written successfully to {output_path}')
            logger.info(f'Prepared dataset for number of rows: {df.count()}')

        if make_predictions:
            meta_model_path = execution_context.get_input_args(meta_model_path_glue_arg)
            base_model_path = execution_context.get_input_args(base_model_path_glue_arg)
            output_path = execution_context.get_input_args(output_path_glue_arg)
            input_data_path = execution_context.get_input_args(input_data_path_glue_arg)

            # load data
            input_df = execution_context.get_dataframe(input_data_path)
            input_df.show(5)

            # load models
            base_model = PipelineModel.load(base_model_path)
            meta_model = CrossValidatorModel.load(meta_model_path)
            meta_model_cols = ['pred_log_reg', 'pred_rf', 'pred_gbt', 'pred_lsvm', 'prob_log_reg', 'prob_rf']

            logger.info('Make predictions using base_model...')
            base_preds = base_model.transform(input_df)
            base_preds_df = base_preds.select('uprn', *meta_model_cols)

            logger.info('Make predictions on base_model preds using meta_model...')
            meta_preds = meta_model.transform(base_preds_df)
            meta_preds.write.parquet(f'{output_path}/parquet/', mode='overwrite')
            meta_preds = meta_preds.select('uprn', 'probability', 'meta_predictions')
            meta_preds = meta_preds.withColumn('probability_', vector_to_array(f.col('probability')))\
                .select(['uprn', 'meta_predictions'] + [f.col('probability_')[i] for i in range(1)])
            meta_preds.coalesce(1).write.csv(header=True, mode='overwrite',
                                             path=f'{output_path}/csv/')

if __name__ == '__main__':
    main()
