import sys
from awsglue.utils import getResolvedOptions
import pyspark.sql.functions as F
from pyspark import SparkContext
from pyspark.sql.window import Window
from awsglue.context import GlueContext
from awsglue.dynamicframe import DynamicFrame
from awsglue.job import Job
from pyspark.sql.functions import col, max
from pyspark.sql.types import StringType

from helpers.helpers import get_glue_env_var, get_latest_partitions, PARTITION_KEYS, create_pushdown_predicate


def prep_source_data(query_addresses):
    query_addresses_sample = query_addresses.filter(
        "concatenated_string_to_match != ''")
    query_addresses_sample = query_addresses_sample.filter("uprn is null")

    query_concat = query_addresses_sample.withColumn(
        "query_address",
        F.concat_ws(" ", "concatenated_string_to_match", "postcode")
    )

    query_concat = query_concat.select(
        "prinx", "query_address", "postcode").withColumnRenamed("postcode", "query_postcode")
    
    return query_concat

def prep_addresses_api_data(target_addresses, match_to_property_shell):
    
    # set property shell preferences
    if match_to_property_shell == 'force': 
        target_addresses = target_addresses.where("blpu_class LIKE 'P%'")
    elif match_to_property_shell == 'forbid':
        target_addresses = target_addresses.where("blpu_class NOT LIKE 'P%'")   

    # keep blpu class
    target_concat = target_addresses.select("line1", "line2", "line3", "postcode", "uprn", "blpu_class")


    target_concat = target_concat.withColumn(
        "concat_lines",
        F.concat_ws(" ", "line1", "line2", "line3")
    )

    target_concat = target_concat.withColumn(
        "concat_lines", F.trim(F.col("concat_lines")))
    target_concat = target_concat.withColumn(
        "address_length", F.length(F.col("concat_lines")))
    target_concat = target_concat.withColumn("concat_lines",
                                            F.when(F.col("concat_lines").endswith(" HACKNEY"), F.expr(
                                                "substring(concat_lines, 1, address_length -8)"))
                                            .otherwise(F.col("concat_lines")))

    target_concat = target_concat.withColumn(
        "target_address",
        F.concat_ws(" ", "concat_lines", "postcode")
    )

    target_concat = target_concat.withColumn(
        "target_address_short",
        F.concat_ws(" ", "line1", "postcode")
    )

    target_concat = target_concat.withColumn(
        "target_address_medium",
        F.concat_ws(" ", "line1", "line2", "postcode")
    )

    target_concat = target_concat.select("target_address", "target_address_short", "target_address_medium", 
                                        "postcode", "uprn", "blpu_class").withColumnRenamed("postcode", "target_postcode")
    return target_concat

def match_addresses(query_concat, target_concat, logger):

    # COMPARE QUERY AND TARGET

    cross_with_same_postcode = query_concat.join(
        target_concat, query_concat.query_postcode == target_concat.target_postcode, "fullouter")


    cross_compare = cross_with_same_postcode.withColumn(
        "levenshtein", F.levenshtein(F.col("query_address"), F.col("target_address")))
    cross_compare = cross_compare.withColumn("levenshtein_short", F.levenshtein(
        F.col("query_address"), F.col("target_address_short")))
    cross_compare = cross_compare.withColumn("levenshtein_medium", F.levenshtein(
        F.col("query_address"), F.col("target_address_medium")))
    cross_compare = cross_compare.withColumn("levenshtein_10char", F.levenshtein(
        F.substring(F.col("query_address"), 1, 10), F.substring(F.col("target_address"), 1, 10)))


    # ROUND 0 - look for perfect
    perfectFull = cross_compare.filter("levenshtein = 0").dropDuplicates(['prinx'])
    perfectFull = perfectFull.withColumn("match_type", F.lit("perfect"))
    perfectFull = perfectFull.select(F.col("prinx"), F.col("query_address"), F.col("uprn").alias("matched_uprn"), F.col("target_address").alias("matched_address"), F.col("blpu_class").alias("matched_blpu_class"), "match_type")



    perfectShort = cross_compare\
        .join(perfectFull, "prinx", "left_anti")\
        .filter("levenshtein_short = 0")\
        .dropDuplicates(['prinx'])

    perfectShort = perfectShort.withColumn("match_type", F.lit("perfect on first line and postcode"))
    perfectShort = perfectShort.select(F.col("prinx"), F.col("query_address"), F.col("uprn").alias("matched_uprn"), F.col("target_address").alias("matched_address"), F.col("blpu_class").alias("matched_blpu_class"), "match_type")



    perfectMedium = cross_compare\
        .join(perfectFull, "prinx", "left_anti")\
        .join(perfectShort, "prinx", "left_anti")\
        .filter("levenshtein_medium = 0")\
        .dropDuplicates(['prinx'])

    perfectMedium = perfectMedium.withColumn("match_type", F.lit("perfect on first 2 lines and postcode"))
    perfectMedium = perfectMedium.select(F.col("prinx"), F.col("query_address"), 
    F.col("uprn").alias("matched_uprn"), F.col("target_address").alias("matched_address"), F.col("blpu_class").alias("matched_blpu_class"), "match_type")


    perfect10char = cross_compare\
        .join(perfectFull, "prinx", "left_anti")\
        .join(perfectShort, "prinx", "left_anti")\
        .join(perfectMedium, "prinx", "left_anti")\
        .filter("levenshtein_10char = 0").dropDuplicates(['prinx'])

    perfect10char = perfect10char.withColumn("match_type", F.lit("perfect on first 10 characters and postcode"))
    perfect10char = perfect10char.select(F.col("prinx"), F.col("query_address"), F.col("uprn").alias("matched_uprn"), F.col("target_address").alias("matched_address"), F.col("blpu_class").alias("matched_blpu_class"), "match_type")


    # put all 'perfect' together
    perfectMatch = perfectFull.union(perfectShort).union(
        perfectMedium).union(perfect10char)
    perfectMatch = perfectMatch.withColumn("round", F.lit("round 0"))

    logger.info("End of Round 0")

    # ROUND 1 - now look at imperfect with same postcode

    cross_compare = cross_compare\
        .join(perfectMatch, "prinx", "left_anti")

    window = Window.partitionBy('prinx').orderBy("levenshtein")

    bestMatch_round1 = cross_compare.filter("levenshtein < 3").withColumn('rank', F.rank().over(window))\
        .filter('rank = 1')\
        .dropDuplicates(['prinx'])

    bestMatch_round1 = bestMatch_round1.withColumn("match_type", F.lit("Levenshtein < 3 on full address, same postcode"))
    bestMatch_round1 = bestMatch_round1.withColumn("round", F.lit("round 1"))

    bestMatch_round1 = bestMatch_round1.select("prinx", "query_address", F.col("uprn").alias("matched_uprn"), F.col("target_address").alias("matched_address"), F.col("blpu_class").alias("matched_blpu_class"), "match_type", "round")

    logger.info("End of Round 1")
    
    # ROUND 2

    cross_compare = cross_compare.join(bestMatch_round1, "prinx", "left_anti")

    window = Window.partitionBy('prinx').orderBy("levenshtein_short")

    bestMatch_round2 = cross_compare.filter("levenshtein_short < 3").withColumn('rank', F.rank().over(window))\
        .filter('rank = 1')\
        .dropDuplicates(['prinx'])

    bestMatch_round2 = bestMatch_round2.withColumn("match_type", F.lit("Levenshtein < 3 on first address line, same postcode"))
    bestMatch_round2 = bestMatch_round2.withColumn("round", F.lit("round 2"))
    bestMatch_round2 = bestMatch_round2.select(F.col("prinx"), F.col("query_address"), F.col("uprn").alias("matched_uprn"), F.col("target_address").alias("matched_address"), F.col("blpu_class").alias("matched_blpu_class"), F.col("match_type"), "round")

    logger.info("End of Round 2")

    # ROUND 3

    # take all the unmatched, still keep same postcode, try match to line1 and line 2
    cross_compare = cross_compare.join(bestMatch_round2, "prinx", "left_anti")

    window = Window.partitionBy('prinx').orderBy("levenshtein_medium")

    bestMatch_round3 = cross_compare.filter("levenshtein_medium < 3").withColumn('rank', F.rank().over(window))\
        .filter('rank = 1')\
        .dropDuplicates(['prinx'])

    bestMatch_round3 = bestMatch_round3.withColumn("match_type", F.lit("Levenshtein < 3 on first 2 address lines, same postcode"))
    bestMatch_round3 = bestMatch_round3.withColumn("round", F.lit("round 3"))
    bestMatch_round3 = bestMatch_round3.select(F.col("prinx"), F.col("query_address"), F.col("uprn").alias("matched_uprn"), F.col("target_address").alias("matched_address"), F.col("blpu_class").alias("matched_blpu_class"), F.col("match_type"), "round")

    logger.info("End of Round 3")

    # Prepare rounds 4 to 7: take all the unmatched, allow mismatched postcodes
    cross_compare = query_concat\
        .join(perfectMatch, "prinx", "left_anti")\
        .join(bestMatch_round1, "prinx", "left_anti")\
        .join(bestMatch_round2, "prinx", "left_anti")\
        .join(bestMatch_round3, "prinx", "left_anti")\
        .crossJoin(target_concat)

    cross_compare = cross_compare.withColumn(
        "levenshtein", F.levenshtein(F.col("query_address"), F.col("target_address")))
    cross_compare = cross_compare.withColumn("levenshtein_short", F.levenshtein(
        F.col("query_address"), F.col("target_address_short")))
    cross_compare = cross_compare.withColumn("levenshtein_medium", F.levenshtein(
        F.col("query_address"), F.col("target_address_medium")))

    cross_compare = cross_compare.filter(
        "levenshtein<5 or levenshtein_short<5 or levenshtein_medium<5")

    # ROUND 4

    window = Window.partitionBy('prinx').orderBy("levenshtein")

    bestMatch_round4 = cross_compare.filter("levenshtein < 5").withColumn('rank', F.rank().over(window))\
        .filter('rank = 1')\
        .dropDuplicates(['prinx'])

    bestMatch_round4 = bestMatch_round4.withColumn(
        "match_type", F.lit("Levenshtein < 5 on full address, postcode may differ"))
    bestMatch_round4 = bestMatch_round4.withColumn("round", F.lit("round 4"))

    bestMatch_round4 = bestMatch_round4.select(F.col("prinx"), F.col("query_address"), F.col("uprn").alias("matched_uprn"), F.col("target_address").alias("matched_address"), F.col("blpu_class").alias("matched_blpu_class"), F.col("match_type"), "round")

    logger.info("End of Round 4")

    # ROUND 5

    # take all the unmatched, allow mismatched postcodes, match to line 1 and postcode only
    cross_compare = cross_compare.join(bestMatch_round4, "prinx", "left_anti")

    window = Window.partitionBy('prinx').orderBy("levenshtein_short")

    bestMatch_round5 = cross_compare.filter("levenshtein_short < 5").withColumn('rank', F.rank().over(window))\
        .filter('rank = 1')\
        .dropDuplicates(['prinx'])

    bestMatch_round5 = bestMatch_round5.withColumn(
        "match_type", F.lit("Levenshtein < 5 on first address line, postcode may differ"))
    bestMatch_round5 = bestMatch_round5.withColumn("round", F.lit("round 5"))

    bestMatch_round5 = bestMatch_round5.select(F.col("prinx"), F.col("query_address"), F.col("uprn").alias("matched_uprn"), F.col("target_address").alias("matched_address"), F.col("blpu_class").alias("matched_blpu_class"), F.col("match_type"), "round")

    logger.info("End of Round 5")

    # ROUND 6

    # take all the unmatched, allow mismatched postcodes, match to line 1 and 2 and postcode
    cross_compare = cross_compare.join(bestMatch_round5, "prinx", "left_anti")

    window = Window.partitionBy('prinx').orderBy("levenshtein_medium")

    # logger.info('sort and filter')
    bestMatch_round6 = cross_compare.filter("levenshtein_medium < 5").withColumn('rank', F.rank().over(window))\
        .filter('rank = 1')\
        .dropDuplicates(['prinx'])

    bestMatch_round6 = bestMatch_round6.withColumn(
        "match_type", F.lit("Levenshtein < 5 on first 2 address lines, postcode may differ"))
    bestMatch_round6 = bestMatch_round6.withColumn("round", F.lit("round 6"))

    bestMatch_round6 = bestMatch_round6.select(F.col("prinx"), F.col("query_address"), F.col("uprn").alias("matched_uprn"), F.col("target_address").alias("matched_address"), F.col("blpu_class").alias("matched_blpu_class"), F.col("match_type"), "round")

    logger.info("End of Round 6")
    
    # ROUND 7 - last chance

    # take all the rest (including empty postcodes) and mark as unmatched
    unmatched = query_concat\
        .join(perfectMatch, "prinx", "left_anti")\
        .join(bestMatch_round1, "prinx", "left_anti")\
        .join(bestMatch_round2, "prinx", "left_anti")\
        .join(bestMatch_round3, "prinx", "left_anti")\
        .join(bestMatch_round4, "prinx", "left_anti")\
        .join(bestMatch_round5, "prinx", "left_anti")\
        .join(bestMatch_round6, "prinx", "left_anti")

    lastChanceCompare = unmatched.crossJoin(target_concat)
    cross_compare = lastChanceCompare.withColumn(
        "levenshtein", F.levenshtein(F.col("query_address"), F.col("target_address")))

    window = Window.partitionBy('prinx').orderBy("levenshtein")

    bestMatch_lastChance = cross_compare.withColumn('rank', F.rank().over(window))\
        .filter('rank = 1')\
        .dropDuplicates(['prinx'])

    bestMatch_lastChance = bestMatch_lastChance.withColumn("match_type", F.lit("Best match after all constrained rounds. Postcode may differ."))
    bestMatch_lastChance = bestMatch_lastChance.withColumn("round", F.lit("last chance"))
    bestMatch_lastChance = bestMatch_lastChance.select(F.col("prinx"), F.col("query_address"), F.col("uprn").alias("matched_uprn"), F.col("target_address").alias("matched_address"), F.col("blpu_class").alias("matched_blpu_class"), F.col("match_type"), "round")

    logger.info("End of Round 7")

    # PUT RESULTS OF ALL ROUNDS TOGETHER

    all_best_match = perfectMatch.union(bestMatch_round1).union(bestMatch_round2).union(bestMatch_round3).union(
        bestMatch_round4).union(bestMatch_round5).union(bestMatch_round6).union(bestMatch_lastChance)
    
    return all_best_match
    
def round_0(query_concat, target_concat, logger):
    # COMPARE QUERY AND TARGET

    cross_with_same_postcode = query_concat.join(
        target_concat, query_concat.query_postcode == target_concat.target_postcode, "fullouter")


    cross_compare = cross_with_same_postcode.withColumn(
        "levenshtein", F.levenshtein(F.col("query_address"), F.col("target_address")))
    cross_compare = cross_compare.withColumn("levenshtein_short", F.levenshtein(
        F.col("query_address"), F.col("target_address_short")))
    cross_compare = cross_compare.withColumn("levenshtein_medium", F.levenshtein(
        F.col("query_address"), F.col("target_address_medium")))
    cross_compare = cross_compare.withColumn("levenshtein_10char", F.levenshtein(
        F.substring(F.col("query_address"), 1, 10), F.substring(F.col("target_address"), 1, 10)))


    # ROUND 0 - look for perfect
    perfectFull = cross_compare.filter("levenshtein = 0").dropDuplicates(['prinx'])
    perfectFull = perfectFull.withColumn("match_type", F.lit("perfect"))
    perfectFull = perfectFull.select(F.col("prinx"), F.col("query_address"), F.col("uprn").alias("matched_uprn"), F.col("target_address").alias("matched_address"), F.col("blpu_class").alias("matched_blpu_class"), "match_type")



    perfectShort = cross_compare\
        .join(perfectFull, "prinx", "left_anti")\
        .filter("levenshtein_short = 0")\
        .dropDuplicates(['prinx'])

    perfectShort = perfectShort.withColumn("match_type", F.lit("perfect on first line and postcode"))
    perfectShort = perfectShort.select(F.col("prinx"), F.col("query_address"), F.col("uprn").alias("matched_uprn"), F.col("target_address").alias("matched_address"), F.col("blpu_class").alias("matched_blpu_class"), "match_type")



    perfectMedium = cross_compare\
        .join(perfectFull, "prinx", "left_anti")\
        .join(perfectShort, "prinx", "left_anti")\
        .filter("levenshtein_medium = 0")\
        .dropDuplicates(['prinx'])

    perfectMedium = perfectMedium.withColumn("match_type", F.lit("perfect on first 2 lines and postcode"))
    perfectMedium = perfectMedium.select(F.col("prinx"), F.col("query_address"), 
    F.col("uprn").alias("matched_uprn"), F.col("target_address").alias("matched_address"), F.col("blpu_class").alias("matched_blpu_class"), "match_type")


    perfect10char = cross_compare\
        .join(perfectFull, "prinx", "left_anti")\
        .join(perfectShort, "prinx", "left_anti")\
        .join(perfectMedium, "prinx", "left_anti")\
        .filter("levenshtein_10char = 0").dropDuplicates(['prinx'])

    perfect10char = perfect10char.withColumn("match_type", F.lit("perfect on first 10 characters and postcode"))
    perfect10char = perfect10char.select(F.col("prinx"), F.col("query_address"), F.col("uprn").alias("matched_uprn"), F.col("target_address").alias("matched_address"), F.col("blpu_class").alias("matched_blpu_class"), "match_type")


    # put all 'perfect' together
    perfectMatch = perfectFull.union(perfectShort).union(
        perfectMedium).union(perfect10char)
    perfectMatch = perfectMatch.withColumn("round", F.lit("round 0"))

    all_best_match = perfectMatch
    return all_best_match

if __name__ == "__main__":
    glueContext = GlueContext(SparkContext.getOrCreate())
    logger = glueContext.get_logger()
    job = Job(glueContext)


    addresses_api_data_database = get_glue_env_var('addresses_api_data_database', '')
    addresses_api_data_table = get_glue_env_var('addresses_api_data_table', '')
    source_catalog_database = get_glue_env_var('source_catalog_database', '')
    source_catalog_table = get_glue_env_var('source_catalog_table', '')
    target_destination = get_glue_env_var('target_destination', '')
    match_to_property_shell = get_glue_env_var('match_to_property_shell', '')

    PARTITION_KEYS.append("data_source")


    # PREP QUERY DATA

    query_addresses = glueContext.create_dynamic_frame.from_catalog(
        name_space=source_catalog_database,
        table_name=source_catalog_table,
    )

    query_addresses = query_addresses.toDF()
    query_addresses = get_latest_partitions(query_addresses)

    query_concat = prep_source_data(query_addresses)

    # PREP ADDRESSES API DATA

    pushDownPredicate = create_pushdown_predicate(partitionDateColumn='import_date',daysBuffer=3)
    target_addresses = glueContext.create_dynamic_frame.from_catalog(
        name_space=addresses_api_data_database,
        table_name=addresses_api_data_table,
        push_down_predicate = pushDownPredicate
    )

    target_addresses = target_addresses.toDF()
    target_addresses = get_latest_partitions(target_addresses)

    target_concat = prep_addresses_api_data(target_addresses, match_to_property_shell)

    # MATCH QUERY AND TARGET
    all_best_match = match_addresses(query_concat, target_concat, logger)

    # JOIN MATCH RESULTS WITH INITIAL DATASET
    matchingResults = query_addresses.join(all_best_match, "prinx", "left")


    # WRITE RESULTS
    resultDataFrame = DynamicFrame.fromDF(
        matchingResults, glueContext, "resultDataFrame")

    logger.info("writing result dataframe")
    parquetData = glueContext.write_dynamic_frame.from_options(
        frame=resultDataFrame,
        connection_type="s3",
        format="parquet",
        connection_options={"path": target_destination,
                            "partitionKeys": PARTITION_KEYS},
        transformation_ctx="parquetData")

    job.commit()
