"""This script reads in electoral register table as exported from Xpress (in Parquet format), and then cleans,
prepares and standardises the data into a format that matches the schema in active_person_records dataset.

    Args:
        source_catalog_database: database hosting input dataset
        source_catalog_table: name of the electoral register table
        output_path: the output S3 bucket path to write the standardised dataset in Parquet format.

    Returns:
        A standardised dataset in same schema as active_person_records dataset.

"""

import argparse

from scripts.jobs.env_context import DEFAULT_MODE_AWS, LOCAL_MODE, ExecutionContextProvider
from scripts.helpers.helpers import add_import_time_columns, PARTITION_KEYS
from scripts.jobs.data_and_insight.person_matching_module import prepare_clean_electoral_register_data, \
    standardize_electoral_register_data


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--execution_mode", default=DEFAULT_MODE_AWS, choices=[DEFAULT_MODE_AWS, LOCAL_MODE], type=str,
                        required=False, metavar="set --execution_mode=aws to run on AWS")
    parser.add_argument("--source_catalog_database", default=DEFAULT_MODE_AWS, type=str,
                        required=False, metavar="set --source_catalog_database=source catalog database")
    parser.add_argument("--source_catalog_table", default=DEFAULT_MODE_AWS, type=str,
                        required=False, metavar="set --source_catalog_table=name of source table")
    parser.add_argument("--output_path", default=DEFAULT_MODE_AWS, type=str,
                        required=False, metavar="set --output_path=path data to be written")

    # set argument for each arg
    source_catalog_database_glue_arg = "source_catalog_database"
    source_catalog_table_glue_arg = "source_catalog_table"
    output_path_glue_arg = "output_path"

    glue_args = [source_catalog_database_glue_arg,
                 source_catalog_table_glue_arg,
                 output_path_glue_arg
                 ]

    local_args, _ = parser.parse_known_args()
    mode = local_args.execution_mode

    with ExecutionContextProvider(mode, glue_args, local_args) as execution_context:
        logger = execution_context.logger
        spark = execution_context.spark_session

        source_database = execution_context.get_input_args(source_catalog_database_glue_arg)
        source_table = execution_context.get_input_args(source_catalog_table_glue_arg)
        output_path = execution_context.get_input_args(output_path_glue_arg)

        logger.info('Load in electoral register data as a dynamic frame...')
        dyf = execution_context.get_dataframe(name_space=source_database,
                                              table_name=source_table
                                              )

        logger.info('Clean and preparing data...')
        dyf_cleaned = prepare_clean_electoral_register_data(dyf)

        logger.info('Standardising data...')
        dyf_standardised = standardize_electoral_register_data(dyf_cleaned)

        logger.info(f'Writing standardised data to...{output_path}')
        dyf_standardised = add_import_time_columns(dyf_standardised)
        execution_context.save_dataframe(dyf_standardised, output_path, *PARTITION_KEYS, save_mode='overwrite')


if __name__ == '__main__':
    main()
