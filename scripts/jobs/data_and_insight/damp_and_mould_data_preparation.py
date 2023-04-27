"""
This script prepares and standardises input datasets containing data about , and then unions into
a single dataset ready for use.

Input datasets:
* Housing disrepair for 2013-2019
* Tenure Information snapshot for 2019

Output:
* single standardised dataset containing a row for each Council-managed property with secure tenancy from all input datasets listed above.
Dataframe written as Parquet in S3.

"""

import argparse

from pyspark.ml.feature import Imputer
# from great_expectations.dataset import SparkDFDataset

from pyspark.sql.functions import col, when, trim, length, lit, expr
from pyspark.sql.types import IntegerType

from scripts.jobs.env_context import DEFAULT_MODE_AWS, LOCAL_MODE, ExecutionContextProvider
from scripts.helpers.helpers import add_import_time_columns, PARTITION_KEYS, \
    create_pushdown_predicate_for_latest_written_partition, \
    create_pushdown_predicate_for_max_date_partition_value
import scripts.helpers.damp_and_mould_inputs as inputs
from scripts.helpers.housing_disrepair_helpers import prepare_input_datasets, set_target, \
    get_total_occupants_housing_benefit, get_total_occupants, group_number_of_bedrooms, get_external_walls, \
    get_communal_area, get_roof_insulation, get_boilers, get_open_air_walkways, get_vulnerability_score, get_main_fuel, \
    clean_boolean_features, drop_rows_with_nulls, impute_missing_values, one_hot_encode_categorical_features, \
    prepare_index_field, assemble_vector_of_features, scale_continuous_features


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--execution_mode", default=DEFAULT_MODE_AWS, choices=[DEFAULT_MODE_AWS, LOCAL_MODE], type=str,
                        required=False, metavar="set --execution_mode=aws to run on AWS")
    parser.add_argument("--source_catalog_table_housing_disrepair", type=str, required=True,
                        metavar="set --source_catalog_table_housing_disrepair=path to disrepair dataset")
    parser.add_argument("--source_catalog_table_ti_output_2019", type=str, required=True,
                        metavar="set --source_catalog_table_ti_output_2019=path to tenure dataset")
    parser.add_argument("--output_path", type=str, required=False,
                        metavar=f"set --output_path=path to output folder")

    # set argument for each arg
    # source_catalog_database_data_and_insight_glue_arg = "source_catalog_database_data_and_insight"
    source_catalog_table_housing_disrepair_glue_arg = "source_catalog_table_housing_disrepair"
    source_catalog_table_ti_output_2019_glue_arg = "source_catalog_table_ti_output_2019"
    output_path_glue_arg = "output_path"

    glue_args = [source_catalog_table_housing_disrepair_glue_arg,
                 source_catalog_table_ti_output_2019_glue_arg,
                 output_path_glue_arg
                 ]

    local_args, _ = parser.parse_known_args()
    mode = local_args.execution_mode

    impute_data = False

    with ExecutionContextProvider(mode, glue_args, local_args) as execution_context:
        logger = execution_context.logger
        spark = execution_context.spark_session
        spark.conf.set("spark.sql.broadcastTimeout", 7200)

        # get input datasets
        source_catalog_table_housing_disrepair = execution_context.get_input_args(
            source_catalog_table_housing_disrepair_glue_arg)
        source_catalog_table_ti = execution_context.get_input_args(
            source_catalog_table_ti_output_2019_glue_arg)

        repairs_df = execution_context.get_dataframe(source_catalog_table_housing_disrepair)
        tenure_df = execution_context.get_dataframe(source_catalog_table_ti)

        df = prepare_input_datasets(repairs_df, tenure_df, repairs_cols=inputs.repairs_cols,
                                    tenure_df_columns=inputs.ti_cols,
                                    deleted_estates=inputs.deleted_estates)

        df = set_target(dataframe=df, target=inputs.target)

        df = prepare_index_field(dataframe=df, column='uprn')

        df = get_total_occupants_housing_benefit(dataframe=df, hb_num_children='no_of_children',
                                                 hb_num_adults='no_of_adults')

        df = get_total_occupants(dataframe=df, new_column_name='total_occupants',
                                 occupancy_columns=inputs.occupants, child_count='child_count',
                                 inputs_list_to_update=inputs.cont_cols)

        df = group_number_of_bedrooms(dataframe=df, bedroom_column='number_of_bedrooms',
                                      new_column_name='number_bedrooms_bands',
                                      inputs_list_to_update=inputs.cat_cols)

        df = get_external_walls(dataframe=df, attachment_column='Attachment', new_column_name='flag_has_external_walls')

        df = get_communal_area(dataframe=df, communal_area_column='type_of_communal_area',
                               new_column_name='flag_communal_area')

        df = get_roof_insulation(dataframe=df, roof_insulation_column='roof_insulation',
                                 new_column_name='flag_roof_insulation_or_dwelling_above')

        df = get_main_fuel(dataframe=df, fuel_column='main_fuel_type', new_column_name='flag_main_fuel_gas_individual')

        df = get_boilers(dataframe=df, heating_column='Heating', new_column_name='flag_heating_boilers')

        df = get_open_air_walkways(dataframe=df, open_walkways_column='open_to_air_walkways',
                                   new_column_name='flag_open_to_air_walkways')

        df = get_vulnerability_score(dataframe=df, vulnerability_dict=inputs.vulnerability_cols,
                                     new_column_name='vulnerability_score')

        # keep features of interest
        df = df.select(*inputs.ml_cols)

        # clean boolean features
        df = clean_boolean_features(dataframe=df, bool_list=inputs.bool_cols)

        df = drop_rows_with_nulls(dataframe=df, features_list=['number_bedrooms_bands', 'band_tenancy_length',
                                                               'total_occupants', 'typologies'])

        # impute missing values
        if impute_data:
            columns_to_impute = []
            df = impute_missing_values(dataframe=df, features_to_impute=columns_to_impute, strategy='median', suffix='')

        # One Hot Encode categorical features
        df = one_hot_encode_categorical_features(dataframe=df, string_columns=inputs.cat_cols)

        df = scale_continuous_features(dataframe=df, cols_to_scale=['total_occupants', 'vulnerability_score'])

        df = assemble_vector_of_features(dataframe=df, cols_to_omit=['uprn', 'target'])

        # df.summary().show()
        df.show(10)
        # df.printSchema()
        logger.info(f'{df.count()}')
        #

        # # make data quality checks using Great Expectations
        # df_ge = SparkDFDataset(standard_df)
        # # check for uniqueness and record any anomalies
        # id_uniqueness_result = df_ge.expect_column_values_to_be_unique(column='source_id',
        #                                                                result_format={"result_format": "COMPLETE"})
        # logger.info(f'Uniqueness: {id_uniqueness_result}')
        # duplicate_ids = id_uniqueness_result["result"]["unexpected_list"]
        # # flag where source_ids are present more than once (duplicates) so they can be investigated later on
        # standard_df = standard_df.withColumn('is_duplicated',
        #                                      when(col('source_id').isin(duplicate_ids), True).otherwise(False))
        # # check for completeness
        # id_not_null_result = df_ge.expect_column_values_to_not_be_null(column='source_id',
        #                                                                result_format={"result_format": "COMPLETE"})
        # logger.info(f'Completeness: {id_not_null_result}')
        #
        # standard_df = add_import_time_columns(standard_df)
        # output_path = execution_context.get_input_args(output_path_glue_arg)
        # execution_context.save_dataframe(standard_df, output_path, *PARTITION_KEYS, save_mode='overwrite')
        # logger.info(f"Standardized dataframe written successfully to {output_path}")


if __name__ == '__main__':
    main()
