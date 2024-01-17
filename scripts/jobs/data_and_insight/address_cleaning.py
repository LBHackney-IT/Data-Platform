import argparse
import pyspark.sql.functions as F
from scripts.jobs.env_context import DEFAULT_MODE_AWS, LOCAL_MODE, ExecutionContextProvider
import scripts.helpers.address_cleaning_inputs as inputs


def main():
    parser = argparse.ArgumentParser(description=__doc__)

    parser.add_argument("--execution_mode", default=DEFAULT_MODE_AWS, choices=[DEFAULT_MODE_AWS, LOCAL_MODE], type=str,
                        required=False, metavar="set --execution_mode=local to run locally")
    parser.add_argument("--source_data_path", type=str, required=True,
                        metavar=f"set --source_data_path=path of the dataset")
    parser.add_argument(f"--output_path", type=str, required=False,
                        metavar=f"set --output=path to write the result")

    source_data_path_arg = "source_data_path"
    output_path_arg = "output_path"

    glue_args = [source_data_path_arg,
                 output_path_arg]

    local_args, _ = parser.parse_known_args()
    mode = local_args.execution_mode

    with ExecutionContextProvider(mode, glue_args, local_args) as execution_context:
        logger = execution_context.logger
        spark = execution_context.spark_session

        # set up paths
        source_data_path = execution_context.get_input_args(source_data_path_arg)
        output_path = execution_context.get_input_args(output_path_arg)

        # read in all data needed
        logger.info(f'Read in data needed... source_df')
        source_df = spark.read.parquet(source_data_path)

        source_df = source_df["source", "source_id", "uprn", "full_address"]
        source_df = source_df.withColumn("clean_full_address", source_df["full_address"])

        logger.info('address line formatting - remove commas and extra spaces')
        source_df = source_df.withColumn("clean_full_address", F.lower(F.col("clean_full_address")))

        for reg in inputs.full_address_regex_clean:
            source_df = source_df.withColumn("clean_full_address",
                                             F.regexp_replace(F.col("clean_full_address"), reg[0], reg[1]))

        source_df = source_df.withColumn("clean_full_address", F.trim(F.col("clean_full_address")))

        logger.info('address line formatting - remove LONDON at the end (dont do this for out of London matching)')
        source_df = source_df.withColumn("clean_full_address", F.trim(F.col("clean_full_address")))
        source_df = source_df.withColumn("address_length", F.length(F.col("clean_full_address")))
        source_df = source_df.withColumn("clean_full_address",
                                         F.when(F.col("clean_full_address").endswith(" london"),
                                                F.expr("substring(clean_full_address, 1, address_length -7)"))
                                         .otherwise(F.col("clean_full_address")))

        logger.info(
            'address line formatting - remove HACKNEY at the end (dont necessarily this for out of borough matching)')
        source_df = source_df.withColumn("clean_full_address", F.trim(F.col("clean_full_address")))
        source_df = source_df.withColumn("address_length", F.length(F.col("clean_full_address")))
        source_df = source_df.withColumn("clean_full_address",
                                         F.when(F.col("clean_full_address").endswith(" hackney"),
                                                F.expr("substring(clean_full_address, 1, address_length -8)"))
                                         .otherwise(F.col("clean_full_address")))

        # rerun for london to catch when address has '... london hackney'
        logger.info('address line formatting - rerun remove LONDON at the end')
        source_df = source_df.withColumn("clean_full_address", F.trim(F.col("clean_full_address")))
        source_df = source_df.withColumn("address_length", F.length(F.col("clean_full_address")))
        source_df = source_df.withColumn("clean_full_address",
                                         F.when(F.col("clean_full_address").endswith(" london"),
                                                F.expr("substring(clean_full_address, 1, address_length -7)"))
                                         .otherwise(F.col("clean_full_address")))

        source_df = source_df.drop("address_length")

        logger.info(
            'for \'street\': we only replace st if it is at the end of the string, if not there is a risk of confusion with saint')
        for reg in inputs.full_address_regex_streets:
            source_df = source_df.withColumn("clean_full_address",
                                             F.regexp_replace(F.col("clean_full_address"), reg[0], reg[1]))

        logger.info('for \'subbuilding\': replace abbreviations')
        for reg in inputs.full_address_regex_subs:
            source_df = source_df.withColumn("clean_full_address",
                                             F.regexp_replace(F.col("clean_full_address"), reg[0], reg[1]))

        # tidy up extra spaces
        source_df = source_df.withColumn("clean_full_address",
                                         F.regexp_replace(F.col("clean_full_address"), " ?- ?$", ""))
        source_df = source_df.withColumn("clean_full_address", F.trim(F.col("clean_full_address")))

        # Add new column for trimmed version of clean_full_address
        logger.info('Add new column for trimmed version of clean_full_address')
        source_df = source_df.withColumn("clean_trim_address", source_df["clean_full_address"])

        for reg in inputs.clean_trim_address_regex_subs:
            source_df = source_df.withColumn("clean_trim_address",
                                             F.regexp_replace(F.col("clean_trim_address"), reg[0], reg[1]))

        # tidy up extra spaces
        source_df = source_df.withColumn("clean_trim_address",
                                         F.regexp_replace(F.col("clean_trim_address"), " ?- ?$", ""))
        source_df = source_df.withColumn("clean_trim_address", F.trim(F.col("clean_trim_address")))

        # output data
        logger.info('output data')
        source_df.write.parquet(f'{output_path}cleaned_address_data/', mode='overwrite')


if __name__ == '__main__':
    main()
