"""This job matches the addresses (source) against the master data (gazetteer or target). The job provides a score of
matching in a column called round. The lower the round number the better match it is i.e. matches with value "round 0"
is better than "round 4". This job uses `Levenshtein Distance <https://en.wikipedia.org/wiki/Levenshtein_distance/>`_
to calculate similarity.

The job can be run in local mode (i.e. on your local environment) and also on AWS (see Usage below).

Usage:
To run in local mode:
set the mode to 'local' and provide the path od data set of your local machine
--execution_mode=local --addresses_data_path=</path/to/gazetteer_address> --source_data_path=</path/to/source_address> \
--target_destination=</path/to/save/output> --match_to_property_shell=<property_name>
e.g. use below to run on test data
--execution_mode=local --addresses_data_path=test_data/levenshtein_address_matching/addresses/ \
--source_data_path=test_data/levenshtein_address_matching/source/ \
--target_destination=/tmp --match_to_property_shell=forbid

To run in AWS mode:
No need to provide mode (or optionally set it to 'aws')
--addresses_api_data_database=<gazetteer_db_name> --addresses_api_data_table=<gazetteer_table_name> \
--source_catalog_database=<source_db_name> --source_catalog_table=<source_table_name> \
--target_destination=</path/to/save/output> --match_to_property_shell=<property_name>
"""

import argparse

from pyspark.sql import DataFrame, Window
from pyspark.sql.functions import col, concat_ws, length, levenshtein, lit, min, substring, trim, when

from scripts.jobs.env_context import ExecutionContextProvider, DEFAULT_MODE_AWS, LOCAL_MODE
from scripts.helpers.helpers import get_latest_partitions_optimized, create_pushdown_predicate, PARTITION_KEYS


def prep_source_data(query_addresses: DataFrame) -> DataFrame:
    result = query_addresses \
        .filter((col("concatenated_string_to_match").isNotNull()) &
                (length(trim(col("concatenated_string_to_match"))) > 0) &
                (col("uprn").isNull())) \
        .withColumn("query_address", concat_ws(" ", col("concatenated_string_to_match"), col("postcode"))) \
        .select(col("prinx"), col("query_address"), col("postcode").alias("query_postcode"))

    return result


def prep_addresses_api_data(target_addresses: DataFrame, match_to_property_shell: str) -> DataFrame:
    target_columns = target_addresses.select("line1", "line2", "line3", "postcode", "uprn", "blpu_class")
    # set property shell preferences
    if match_to_property_shell == 'force':
        target_columns = target_columns.where("blpu_class LIKE 'P%'")
    elif match_to_property_shell == 'forbid':
        target_columns = target_columns.where("blpu_class NOT LIKE 'P%'")

    result = target_columns \
        .withColumn("concat_lines", trim(concat_ws(" ", "line1", "line2", "line3"))) \
        .withColumn("address_length", length(col("concat_lines"))) \
        .withColumn("concat_lines",
                    when(col("concat_lines").endswith(" HACKNEY"),
                         col("concat_lines").substr(lit(1), col("address_length") - 8))
                    .otherwise(col("concat_lines"))) \
        .withColumn("target_address", concat_ws(" ", "concat_lines", "postcode")) \
        .withColumn("target_address_short", concat_ws(" ", "line1", "postcode")) \
        .withColumn("target_address_medium", concat_ws(" ", "line1", "line2", "postcode")) \
        .select(col("target_address"), col("target_address_short"), col("target_address_medium"), col("uprn"),
                col("blpu_class"), col("postcode").alias("target_postcode"))

    return result


def match_addresses(source: DataFrame, addresses: DataFrame, logger) -> DataFrame:
    logger.info("Starting address matching")
    # Compare source and addresses
    data_with_same_postcode = addresses.join(source, source["query_postcode"] == addresses["target_postcode"])

    similar_postcode_condition = (source["query_postcode"] != addresses["target_postcode"]) & \
                                 (source["query_postcode"].substr(1, 2) == addresses["target_postcode"].substr(1, 2))
    data_with_similar_postcode = addresses.join(source, similar_postcode_condition)

    missing_postcode_condition = (source["query_postcode"].isNull() | (length(trim(source["query_postcode"])) == 0)) & \
                                 (addresses["target_postcode"].isNull() |
                                  (length(trim(addresses["target_postcode"])) == 0))
    data_with_missing_postcode = addresses.join(source, missing_postcode_condition)

    # Round 0 to 3 - where postcode matches perfectly
    round0_condition = (col("levenshtein_full") == 0) | (col("levenshtein_short") == 0) | \
                       (col("levenshtein_medium") == 0) | (col("levenshtein_10char") == 0)
    round1_condition = col("levenshtein_full") < 3
    round2_condition = col("levenshtein_short") < 3
    round3_condition = col("levenshtein_medium") < 3

    matching_with_same_postcode = data_with_same_postcode \
        .withColumn("levenshtein_full", levenshtein(col("query_address"), col("target_address"))) \
        .withColumn("levenshtein_short", levenshtein(col("query_address"), col("target_address_short"))) \
        .withColumn("levenshtein_medium", levenshtein(col("query_address"), col("target_address_medium"))) \
        .withColumn("levenshtein_10char", levenshtein(substring(col("query_address"), 1, 10),
                                                      substring(col("target_address"), 1, 10))) \
        .filter(round0_condition | round1_condition | round2_condition | round3_condition) \
        .withColumn("round",
                    when(round0_condition, lit("round 0"))
                    .when(round1_condition, lit("round 1"))
                    .when(round2_condition, lit("round 2"))
                    .when(round3_condition, lit("round 3"))) \
        .withColumn("match_type",
                    when(col("levenshtein_full") == 0, lit("perfect"))
                    .when(col("levenshtein_short") == 0, lit("perfect on first line and postcode"))
                    .when(col("levenshtein_medium") == 0, lit("perfect on first 2 lines and postcode"))
                    .when(col("levenshtein_10char") == 0, lit("perfect on first 10 characters and postcode"))
                    .when(round1_condition, lit("Levenshtein < 3 on full address, same postcode"))
                    .when(round2_condition, lit("Levenshtein < 3 on first address line, same postcode"))
                    .when(round3_condition, lit("Levenshtein < 3 on first 2 address lines, same postcode"))) \
        .select(col("prinx"), col("query_address"), col("uprn").alias("matched_uprn"),
                col("target_address").alias("matched_address"), col("blpu_class").alias("matched_blpu_class"),
                col("match_type"), col("round"))

    # Round 4 to 6 - where post code is similar i.e. N16 9HS is similar to N16 6HT
    round4_condition = col("levenshtein_full") < 5
    round5_condition = col("levenshtein_short") < 5
    round6_condition = col("levenshtein_medium") < 5

    matching_with_similar_postcode = data_with_similar_postcode \
        .withColumn("levenshtein_full", levenshtein(col("query_address"), col("target_address"))) \
        .withColumn("levenshtein_short", levenshtein(col("query_address"), col("target_address_short"))) \
        .withColumn("levenshtein_medium", levenshtein(col("query_address"), col("target_address_medium"))) \
        .filter(round4_condition | round5_condition | round6_condition) \
        .withColumn("round",
                    when(round4_condition, lit("round 4"))
                    .when(round5_condition, lit("round 5"))
                    .when(round6_condition, lit("round 6"))) \
        .withColumn("match_type",
                    when(round4_condition, lit("Levenshtein < 5 on full address, postcode may differ"))
                    .when(round5_condition, lit("Levenshtein < 5 on first address line, postcode may differ"))
                    .when(round6_condition, lit("Levenshtein < 5 on first 2 address lines, postcode may differ"))) \
        .select(col("prinx"), col("query_address"), col("uprn").alias("matched_uprn"),
                col("target_address").alias("matched_address"), col("blpu_class").alias("matched_blpu_class"),
                col("match_type"), col("round"))

    matching_with_missing_postcode = data_with_missing_postcode \
        .withColumn("levenshtein_full", levenshtein(col("query_address"), col("target_address"))) \
        .filter(col("levenshtein_full") < 5) \
        .withColumn("round", lit("round 7")) \
        .withColumn("match_type", lit("Best match after all constrained rounds. Postcode may differ.")) \
        .select(col("prinx"), col("query_address"), col("uprn").alias("matched_uprn"),
                col("target_address").alias("matched_address"), col("blpu_class").alias("matched_blpu_class"),
                col("match_type"), col("round"))

    combined = matching_with_same_postcode.union(matching_with_similar_postcode).union(matching_with_missing_postcode)
    # Select the best match if matched more than once, lower the round better the match
    window = Window.partitionBy(col("prinx"))
    result = combined \
        .withColumn("best_match", min(col("round")).over(window)) \
        .filter(col("round") == col("best_match")) \
        .drop(col("best_match"))

    return result


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--execution_mode", default=DEFAULT_MODE_AWS, choices=[DEFAULT_MODE_AWS, LOCAL_MODE], type=str,
                        required=False, metavar="set --execution_mode=local to run locally")
    parser.add_argument(f"--addresses_data_path", type=str, required=False,
                        metavar=f"set --addresses_data_path=/path/to/directory/containing address data to run locally")
    parser.add_argument(f"--source_data_path", type=str, required=False,
                        metavar=f"set --source_data_path=/path/to/directory/containing source data to run locally")
    parser.add_argument(f"--target_destination", type=str, required=False,
                        metavar=f"set --target_destination=/path/to/output_folder")
    parser.add_argument(f"--match_to_property_shell", type=str, required=False,
                        metavar=f"set --match_to_property_shell=property to match")
    parser.add_argument(f"--partition_source", default=1, type=int, required=False,
                        metavar=f"set --match_to_property_shell=number of partitions for source data (optimization)")
    parser.add_argument(f"--partition_address", default=1, type=int, required=False,
                        metavar=f"set --match_to_property_shell=number of partitions for address data (optimization)")
    parser.add_argument(f"--partition_destination", default=1, type=int, required=False,
                        metavar=f"set --match_to_property_shell=number of partitions destination (optimization)")

    addresses_data_path_local_arg = "addresses_data_path"  # gazetteer (master) dataset path
    source_data_path_local_arg = "source_data_path"  # source (to be matched) dataset path

    addresses_api_data_database_glue_arg = "addresses_api_data_database"  # gazetteer (master) database name
    addresses_api_data_table_glue_arg = "addresses_api_data_table"  # gazetteer (master) table name
    source_catalog_database_glue_arg = "source_catalog_database"  # source (to be matched) table name
    source_catalog_table_glue_arg = "source_catalog_table"  # gazetteer (to be matched) table name

    target_destination_arg = "target_destination"  # output location (S3 path or local)
    match_to_property_shell_arg = "match_to_property_shell"  # property to match location common to both local and glue
    partition_source_arg = "partition_source"  # number of partitions for source data common to both local and glue
    partition_address_arg = "partition_address"  # number of partitions for source data common to both local and glue
    partition_destination_arg = "partition_destination"  # number of partitions for source data common to both

    glue_args = [addresses_api_data_database_glue_arg, addresses_api_data_table_glue_arg,
                 source_catalog_database_glue_arg, source_catalog_table_glue_arg, target_destination_arg,
                 match_to_property_shell_arg]
    local_args, _ = parser.parse_known_args()
    mode = local_args.execution_mode

    with ExecutionContextProvider(mode, glue_args, local_args) as execution_context:
        logger = execution_context.logger
        target_destination = execution_context.get_input_args(target_destination_arg)
        if not target_destination:
            logger.error("target_destination is empty")
            raise ValueError("target_destination cannot be empty")

        partition_source = int(execution_context.get_input_args(partition_source_arg)) or 5
        partition_address = int(execution_context.get_input_args(partition_address_arg)) or 5
        partition_destination = int(execution_context.get_input_args(partition_destination_arg)) or 2

        # Prepare source data
        source_data_path_local = execution_context.get_input_args(source_data_path_local_arg)
        source_catalog_database = execution_context.get_input_args(source_catalog_database_glue_arg)
        source_catalog_table = execution_context.get_input_args(source_catalog_table_glue_arg)

        source_addresses_raw = execution_context \
            .get_dataframe(local_path_parquet=source_data_path_local,
                           name_space=source_catalog_database,
                           table_name=source_catalog_table)\
            .coalesce(partition_source)
        source_addresses_latest = get_latest_partitions_optimized(source_addresses_raw)
        source = prep_source_data(source_addresses_latest)

        # Prepare gazetteer data
        push_down_predicate = create_pushdown_predicate(partitionDateColumn="import_date", daysBuffer=3)
        addresses_data_path_local = execution_context.get_input_args(addresses_data_path_local_arg)
        addresses_api_data_database = execution_context.get_input_args(addresses_api_data_database_glue_arg)
        addresses_api_data_table = execution_context.get_input_args(addresses_api_data_table_glue_arg)
        addresses_data_raw = execution_context \
            .get_dataframe(local_path_parquet=addresses_data_path_local,
                           name_space=addresses_api_data_database,
                           table_name=addresses_api_data_table) \
            .coalesce(partition_address) \
            .filter(push_down_predicate)
        addresses_data_latest = get_latest_partitions_optimized(addresses_data_raw)

        match_to_property_shell = execution_context.get_input_args(match_to_property_shell_arg)
        addresses = prep_addresses_api_data(addresses_data_latest, match_to_property_shell)

        # Match source
        all_best_match = match_addresses(source, addresses, logger)

        # Join match results with initial dataset
        matching_results = source_addresses_latest.join(all_best_match, "prinx", how="left")\
            .coalesce(partition_destination)

        execution_context.save_dataframe(matching_results, target_destination, *PARTITION_KEYS)


if __name__ == '__main__':
    main()
