import argparse
import pyspark.sql.functions as F

from scripts.helpers.helpers import create_pushdown_predicate_for_max_date_partition_value, PARTITION_KEYS, \
    add_import_time_columns
from scripts.jobs.env_context import DEFAULT_MODE_AWS, LOCAL_MODE, ExecutionContextProvider
from scripts.helpers.address_cleaning_inputs import full_address_regex_locality, full_address_regex_clean, \
    full_address_regex_streets, \
    full_address_regex_subs, clean_trim_address_regex_subs


def main():
    parser = argparse.ArgumentParser(description=__doc__)

    parser.add_argument("--execution_mode", default=DEFAULT_MODE_AWS, choices=[DEFAULT_MODE_AWS, LOCAL_MODE], type=str,
                        required=False, metavar="set --execution_mode=local to run locally")
    parser.add_argument("--source_catalog_database_active_person_records", type=str, required=True,
                        metavar=f"set --source_catalog_database_active_person_records=catalog database")
    parser.add_argument("--source_catalog_table_active_person_records", type=str, required=True,
                        metavar=f"set --source_catalog_table_active_person_records=catalog table")
    parser.add_argument(f"--output_path", type=str, required=False,
                        metavar=f"set --output=path to write the result")

    source_data_catalog_arg = "source_catalog_database_active_person_records"
    source_data_table_arg = "source_catalog_table_active_person_records"
    output_path_arg = "output_path"

    glue_args = [source_data_catalog_arg,
                 source_data_table_arg,
                 output_path_arg]

    local_args, _ = parser.parse_known_args()
    mode = local_args.execution_mode

    with ExecutionContextProvider(mode, glue_args, local_args) as execution_context:
        logger = execution_context.logger
        spark = execution_context.spark_session

        # set up paths
        source_data_catalog = execution_context.get_input_args(source_data_catalog_arg)
        source_data_table = execution_context.get_input_args(source_data_table_arg)
        output_path = execution_context.get_input_args(output_path_arg)

        # read in all data needed
        logger.info(f'Read in data needed... source_df')

        source_df = execution_context.get_dataframe(name_space=source_data_catalog,
                                                    table_name=source_data_table,
                                                    push_down_predicate=create_pushdown_predicate_for_max_date_partition_value(
                                                        source_data_catalog,
                                                        source_data_table, 'import_date'))

        source_df = source_df["source", "source_id", "uprn", "title", "first_name", "middle_name", "last_name", "name",
        "date_of_birth", "post_code", "address_line_1", "address_line_2", "address_line_3", "address_line_4",
        "full_address", "source_filter", "is_duplicated"]
        source_df = source_df.withColumn("clean_full_address", source_df["full_address"])

        logger.info('address line formatting - remove commas and extra spaces')
        source_df = source_df.withColumn("clean_full_address", F.lower(F.col("clean_full_address")))

        for reg in full_address_regex_clean:
            source_df = source_df.withColumn("clean_full_address",
                                             F.regexp_replace(F.col("clean_full_address"), reg[0], reg[1]))

        source_df = source_df.withColumn("clean_full_address", F.trim(F.col("clean_full_address")))

        logger.info(
            'address line formatting - remove LONDON and HACKNEY at the end (dont do this for out of London matching)')
        for reg in full_address_regex_locality:
            source_df = source_df.withColumn("clean_full_address",
                                             F.regexp_replace(F.col("clean_full_address"), reg[0], reg[1]))

        logger.info(
            'for \'street\': we only replace st if it is at the end of the string, if not there is a risk of confusion with saint')
        for reg in full_address_regex_streets:
            source_df = source_df.withColumn("clean_full_address",
                                             F.regexp_replace(F.col("clean_full_address"), reg[0], reg[1]))

        logger.info('for \'subbuilding\': replace abbreviations')
        for reg in full_address_regex_subs:
            source_df = source_df.withColumn("clean_full_address",
                                             F.regexp_replace(F.col("clean_full_address"), reg[0], reg[1]))

        # tidy up extra spaces
        source_df = source_df.withColumn("clean_full_address",
                                         F.regexp_replace(F.col("clean_full_address"), " ?- ?$", ""))
        source_df = source_df.withColumn("clean_full_address", F.trim(F.col("clean_full_address")))

        # Add new column for trimmed version of clean_full_address
        logger.info('Add new column for trimmed version of clean_full_address')
        source_df = source_df.withColumn("clean_trim_address", source_df["clean_full_address"])

        for reg in clean_trim_address_regex_subs:
            source_df = source_df.withColumn("clean_trim_address",
                                             F.regexp_replace(F.col("clean_trim_address"), reg[0], reg[1]))

        # tidy up extra spaces
        source_df = source_df.withColumn("clean_trim_address",
                                         F.regexp_replace(F.col("clean_trim_address"), " ?- ?$", ""))
        source_df = source_df.withColumn("clean_trim_address", F.trim(F.col("clean_trim_address")))

        # output data
        logger.info('output data')
        source_df = add_import_time_columns(source_df)

        execution_context.save_dataframe(source_df,
                                         f'{output_path}',
                                         *PARTITION_KEYS,
                                         save_mode='overwrite')


if __name__ == '__main__':
    main()
