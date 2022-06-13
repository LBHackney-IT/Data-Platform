import argparse

from pyspark.sql import DataFrame, Window
from pyspark.sql.functions import col, concat_ws, length, levenshtein, lit, rank, substring, trim, when

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
    # Compare source and addresses
    cross_with_same_postcode = source.join(addresses, source["query_postcode"] == addresses["target_postcode"],
                                           how="full_outer")

    cross_compare = cross_with_same_postcode \
        .withColumn("levenshtein_full", levenshtein(col("query_address"), col("target_address"))) \
        .withColumn("levenshtein_short", levenshtein(col("query_address"), col("target_address_short"))) \
        .withColumn("levenshtein_medium", levenshtein(col("query_address"), col("target_address_medium"))) \
        .withColumn("levenshtein_10char", levenshtein(substring(col("query_address"), 1, 10),
                                                      substring(col("target_address"), 1, 10)))

    # Round 0 - look for perfect
    perfect_full = cross_compare \
        .filter(col("levenshtein_full") == 0) \
        .dropDuplicates(['prinx']) \
        .withColumn("match_type", lit("perfect")) \
        .select(col("prinx"), col("query_address"), col("uprn").alias("matched_uprn"),
                col("target_address").alias("matched_address"), col("blpu_class").alias("matched_blpu_class"),
                col("match_type"))

    perfect_short = cross_compare \
        .join(perfect_full, "prinx", how="left_anti") \
        .filter(col("levenshtein_short") == 0) \
        .dropDuplicates(['prinx']). \
        withColumn("match_type", lit("perfect on first line and postcode")) \
        .select(col("prinx"), col("query_address"), col("uprn").alias("matched_uprn"),
                col("target_address").alias("matched_address"), col("blpu_class").alias("matched_blpu_class"),
                col("match_type"))

    perfect_medium = cross_compare \
        .join(perfect_full, "prinx", how="left_anti") \
        .join(perfect_short, "prinx", how="left_anti") \
        .filter(col("levenshtein_medium") == 0) \
        .dropDuplicates(['prinx']) \
        .withColumn("match_type", lit("perfect on first 2 lines and postcode")) \
        .select(col("prinx"), col("query_address"), col("uprn").alias("matched_uprn"),
                col("target_address").alias("matched_address"), col("blpu_class").alias("matched_blpu_class"),
                col("match_type"))

    perfect10char = cross_compare \
        .join(perfect_full, "prinx", how="left_anti") \
        .join(perfect_short, "prinx", how="left_anti") \
        .join(perfect_medium, "prinx", how="left_anti") \
        .filter(col("levenshtein_10char") == 0) \
        .dropDuplicates(['prinx']) \
        .withColumn("match_type", lit("perfect on first 10 characters and postcode")). \
        select(col("prinx"), col("query_address"), col("uprn").alias("matched_uprn"),
               col("target_address").alias("matched_address"), col("blpu_class").alias("matched_blpu_class"),
               col("match_type"))

    # Put all 'perfect' together
    perfect_match = perfect_full \
        .union(perfect_short) \
        .union(perfect_medium) \
        .union(perfect10char) \
        .withColumn("round", lit("round 0"))
    logger.info("End of Round 0")

    # Round 1 - now look at imperfect with same postcode
    cross_compare = cross_compare.join(perfect_match, "prinx", how="left_anti")
    window = Window.partitionBy('prinx').orderBy("levenshtein_full")
    best_match_round1 = cross_compare \
        .filter(col("levenshtein_full") < 3) \
        .withColumn("rank", rank().over(window)) \
        .filter(col("rank") == 1) \
        .dropDuplicates(['prinx']) \
        .withColumn("match_type", lit("Levenshtein < 3 on full address, same postcode")) \
        .withColumn("round", lit("round 1")) \
        .select("prinx", "query_address", col("uprn").alias("matched_uprn"),
                col("target_address").alias("matched_address"), col("blpu_class").alias("matched_blpu_class"),
                col("match_type"), col("round"))
    logger.info("End of Round 1")

    # Round 2
    cross_compare = cross_compare.join(best_match_round1, "prinx", how="left_anti")
    window = Window.partitionBy('prinx').orderBy("levenshtein_short")
    best_match_round2 = cross_compare \
        .filter(col("levenshtein_short") < 3) \
        .withColumn("rank", rank().over(window)) \
        .filter(col("rank") == 1) \
        .dropDuplicates(['prinx']) \
        .withColumn("match_type", lit("Levenshtein < 3 on first address line, same postcode")) \
        .withColumn("round", lit("round 2")) \
        .select(col("prinx"), col("query_address"), col("uprn").alias("matched_uprn"),
                col("target_address").alias("matched_address"), col("blpu_class").alias("matched_blpu_class"),
                col("match_type"), col("round"))
    logger.info("End of Round 2")

    # Round 3
    # take all the unmatched, still keep same postcode, try match to line1 and line 2
    cross_compare = cross_compare.join(best_match_round2, "prinx", how="left_anti")
    window = Window.partitionBy('prinx').orderBy("levenshtein_medium")
    best_match_round3 = cross_compare \
        .filter(col("levenshtein_medium") < 3) \
        .withColumn("rank", rank().over(window)) \
        .filter(col("rank") == 1) \
        .dropDuplicates(['prinx']) \
        .withColumn("match_type", lit("Levenshtein < 3 on first 2 address lines, same postcode")) \
        .withColumn("round", lit("round 3")) \
        .select(col("prinx"), col("query_address"), col("uprn").alias("matched_uprn"),
                col("target_address").alias("matched_address"), col("blpu_class").alias("matched_blpu_class"),
                col("match_type"), col("round"))
    logger.info("End of Round 3")

    # Prepare rounds 4 to 7: take all the unmatched, allow mismatched postcodes
    cross_compare = source \
        .join(perfect_match, "prinx", "left_anti") \
        .join(best_match_round1, "prinx", "left_anti") \
        .join(best_match_round2, "prinx", "left_anti") \
        .join(best_match_round3, "prinx", "left_anti") \
        .crossJoin(addresses) \
        .withColumn("levenshtein_full", levenshtein(col("query_address"), col("target_address"))) \
        .withColumn("levenshtein_short", levenshtein(col("query_address"), col("target_address_short"))) \
        .withColumn("levenshtein_medium", levenshtein(col("query_address"), col("target_address_medium"))) \
        .filter((col("levenshtein_full") < 5) | (col("levenshtein_short") < 5) | (col("levenshtein_medium") < 5))

    # Round 4
    window = Window.partitionBy('prinx').orderBy("levenshtein_full")
    best_match_round4 = cross_compare \
        .filter(col("levenshtein_full") < 5) \
        .withColumn("rank", rank().over(window)) \
        .filter(col("rank") == 1) \
        .dropDuplicates(['prinx']) \
        .withColumn("match_type", lit("Levenshtein < 5 on full address, postcode may differ")) \
        .withColumn("round", lit("round 4")) \
        .select(col("prinx"), col("query_address"), col("uprn").alias("matched_uprn"),
                col("target_address").alias("matched_address"), col("blpu_class").alias("matched_blpu_class"),
                col("match_type"), col("round"))
    logger.info("End of Round 4")

    # Round 5
    # take all the unmatched, allow mismatched postcodes, match to line 1 and postcode only
    cross_compare = cross_compare.join(best_match_round4, "prinx", how="left_anti")
    window = Window.partitionBy('prinx').orderBy("levenshtein_short")
    best_match_round5 = cross_compare \
        .filter(col("levenshtein_short") < 5) \
        .withColumn("rank", rank().over(window)) \
        .filter(col("rank") == 1) \
        .dropDuplicates(['prinx']) \
        .withColumn("match_type", lit("Levenshtein < 5 on first address line, postcode may differ")) \
        .withColumn("round", lit("round 5")) \
        .select(col("prinx"), col("query_address"), col("uprn").alias("matched_uprn"),
                col("target_address").alias("matched_address"), col("blpu_class").alias("matched_blpu_class"),
                col("match_type"), col("round"))
    logger.info("End of Round 5")

    # Round 6
    # take all the unmatched, allow mismatched postcodes, match to line 1 and 2 and postcode
    cross_compare = cross_compare.join(best_match_round5, "prinx", how="left_anti")
    window = Window.partitionBy('prinx').orderBy("levenshtein_medium")
    best_match_round6 = cross_compare \
        .filter(col("levenshtein_medium") < 5) \
        .withColumn("rank", rank().over(window)) \
        .filter(col("rank") == 1) \
        .dropDuplicates(['prinx']) \
        .withColumn("match_type", lit("Levenshtein < 5 on first 2 address lines, postcode may differ")) \
        .withColumn("round", lit("round 6")) \
        .select(col("prinx"), col("query_address"), col("uprn").alias("matched_uprn"),
                col("target_address").alias("matched_address"), col("blpu_class").alias("matched_blpu_class"),
                col("match_type"), col("round"))
    logger.info("End of Round 6")

    # Round 7 - last chance
    # take all the rest (including empty postcodes) and mark as unmatched
    unmatched = source \
        .join(perfect_match, "prinx", how="left_anti") \
        .join(best_match_round1, "prinx", how="left_anti") \
        .join(best_match_round2, "prinx", how="left_anti") \
        .join(best_match_round3, "prinx", how="left_anti") \
        .join(best_match_round4, "prinx", how="left_anti") \
        .join(best_match_round5, "prinx", how="left_anti") \
        .join(best_match_round6, "prinx", how="left_anti")

    last_chance_compare = unmatched.crossJoin(addresses)
    cross_compare = last_chance_compare \
        .withColumn("levenshtein_full", levenshtein(col("query_address"), col("target_address")))
    window = Window.partitionBy('prinx').orderBy("levenshtein_full")
    best_match_last_chance = cross_compare \
        .withColumn("rank", rank().over(window)) \
        .filter(col("rank") == 1) \
        .dropDuplicates(['prinx']) \
        .withColumn("match_type", lit("Best match after all constrained rounds. Postcode may differ.")) \
        .withColumn("round", lit("last chance")) \
        .select(col("prinx"), col("query_address"), col("uprn").alias("matched_uprn"),
                col("target_address").alias("matched_address"), col("blpu_class").alias("matched_blpu_class"),
                col("match_type"), col("round"))
    logger.info("End of Round 7")

    # Put results of all rounds together
    all_best_match = perfect_match \
        .union(best_match_round1) \
        .union(best_match_round2) \
        .union(best_match_round3) \
        .union(best_match_round4) \
        .union(best_match_round5) \
        .union(best_match_round6) \
        .union(best_match_last_chance)

    return all_best_match


def match_addresses_gb(source: DataFrame, addresses: DataFrame, logger) -> DataFrame:
    logger.debug("Starting address matching")
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
        .withColumn("round", lit("last chance")) \
        .withColumn("match_type", lit("Best match after all constrained rounds. Postcode may differ.")) \
        .select(col("prinx"), col("query_address"), col("uprn").alias("matched_uprn"),
                col("target_address").alias("matched_address"), col("blpu_class").alias("matched_blpu_class"),
                col("match_type"), col("round"))

    result = matching_with_same_postcode.union(matching_with_similar_postcode).union(matching_with_missing_postcode)

    return result


def main():
    parser = argparse.ArgumentParser(description="Perform matching of addresses from source to gazetteer")
    parser.add_argument("--mode", default=DEFAULT_MODE_AWS, choices=[DEFAULT_MODE_AWS, LOCAL_MODE], type=str,
                        required=False, metavar="set --mode=local to run locally")
    parser.add_argument(f"--addresses_data_path", type=str, required=False,
                        metavar=f"set --addresses_data_path=/path/to/directory/containing address data to run locally")
    parser.add_argument(f"--source_data_path", type=str, required=False,
                        metavar=f"set --source_data_path=/path/to/directory/containing source data to run locally")
    parser.add_argument(f"--target_destination", type=str, required=False,
                        metavar=f"set --target_destination=/path/to/output_folder")
    parser.add_argument(f"--match_to_property_shell", type=str, required=False,
                        metavar=f"set --match_to_property_shell=property to match")

    addresses_data_path_local_arg = "addresses_data_path"  # gazetteer (master) dataset path
    source_data_path_local_arg = "source_data_path"  # source (to be matched) dataset path

    addresses_api_data_database_glue_arg = "addresses_api_data_database"  # gazetteer (master) database name
    addresses_api_data_table_glue_arg = "addresses_api_data_table"  # gazetteer (master) table name
    source_catalog_database_glue_arg = "source_catalog_database"  # source (to be matched) table name
    source_catalog_table_glue_arg = "source_catalog_table"  # gazetteer (to be matched) table name

    target_destination_arg = "target_destination"  # output location (S3 path or local)
    match_to_property_shell_arg = "match_to_property_shell"  # property to match location common to both local and glue

    glue_args = [addresses_api_data_database_glue_arg, addresses_api_data_table_glue_arg,
                 source_catalog_database_glue_arg, source_catalog_table_glue_arg, target_destination_arg,
                 match_to_property_shell_arg]
    local_args, _ = parser.parse_known_args()
    mode = local_args.mode

    with ExecutionContextProvider(mode, glue_args, local_args) as execution_context:
        logger = execution_context.logger
        target_destination = execution_context.get_input_args(target_destination_arg)
        if not target_destination:
            logger.error("target_destination is empty")
            raise ValueError("target_destination cannot be empty")

        # Prepare source data
        source_data_path_local = execution_context.get_input_args(source_data_path_local_arg)
        source_catalog_database = execution_context.get_input_args(source_catalog_database_glue_arg)
        source_catalog_table = execution_context.get_input_args(source_catalog_table_glue_arg)

        source_addresses_raw = execution_context.get_dataframe(local_path_parquet=source_data_path_local,
                                                               name_space=source_catalog_database,
                                                               table_name=source_catalog_table)
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
            .filter(push_down_predicate)
        addresses_data_latest = get_latest_partitions_optimized(addresses_data_raw)

        match_to_property_shell = execution_context.get_input_args(match_to_property_shell_arg)
        addresses = prep_addresses_api_data(addresses_data_latest, match_to_property_shell)

        # Match source
        all_best_match = match_addresses_gb(source, addresses, logger)

        # Join match results with initial dataset
        matching_results = source_addresses_latest.join(all_best_match, "prinx", how="left")

        partitions_columns = PARTITION_KEYS + ["data_source"]

        execution_context.save_dataframe(matching_results, target_destination, *partitions_columns)


if __name__ == '__main__':
    main()
