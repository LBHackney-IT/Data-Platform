"""This script reads in raw electoral register data as exported from Xpress (in Parquet format), and then cleans,
prepares and standardises the data into a format that matches the schema in active_person_records dataset.

    Args:
        source_input_path: raw electoral register data in S3 bucket (Parguet)
        output_path: the output S3 bucket path to write the standardised dataset (Parguet)

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
    parser.add_argument("--source_input_path", default=DEFAULT_MODE_AWS, type=str,
                        required=False, metavar="set --source_input_path=path of input data")
    parser.add_argument("--output_path", default=DEFAULT_MODE_AWS, type=str,
                        required=False, metavar="set --output_path=output path of standardised dataset")

    # set argument for each arg
    source_input_path_glue_arg = "source_input_path"
    output_path_glue_arg = "output_path"

    glue_args = [source_input_path_glue_arg,
                 output_path_glue_arg
                 ]

    local_args, _ = parser.parse_known_args()
    mode = local_args.execution_mode

    with ExecutionContextProvider(mode, glue_args, local_args) as execution_context:
        logger = execution_context.logger
        spark = execution_context.spark_session

        input_path = execution_context.get_input_args(source_input_path_glue_arg)
        output_path = execution_context.get_input_args(output_path_glue_arg)

        logger.info('Load in electoral register data as a dynamic frame...')
        dyf = execution_context.get_dataframe(local_path_parquet=input_path)

        logger.info('Clean and preparing data...')
        dyf_cleaned = prepare_clean_electoral_register_data(dyf)

        logger.info('Standardising data...')
        dyf_standardised = standardize_electoral_register_data(dyf_cleaned)

        logger.info(f'Writing standardisd data to...{output_path}')
        dyf_standardised = add_import_time_columns(dyf_standardised)
        execution_context.save_dataframe(dyf_standardised, output_path, *PARTITION_KEYS, save_mode='overwrite')


if __name__ == '__main__':
    main()
