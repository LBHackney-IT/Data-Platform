import sys
from awsglue.utils import getResolvedOptions
import pyspark.sql.functions as F
from pyspark import SparkContext
from pyspark.ml import Pipeline
from pyspark.ml.feature import RegexTokenizer, NGram, HashingTF, MinHashLSH
from pyspark.sql.window import Window
from awsglue.context import GlueContext
from awsglue.dynamicframe import DynamicFrame
from awsglue.job import Job
from pyspark.sql.functions import col, max
from pyspark.sql.types import StringType

from helpers import get_glue_env_var, PARTITION_KEYS

PARTITION_KEYS.append("data_source")

glueContext = GlueContext(SparkContext.getOrCreate())
job = Job(glueContext)


def get_latest_partitions(dfa):
    dfa = dfa.where(col('import_year') == dfa.select(
        max('import_year')).first()[0])
    dfa = dfa.where(col('import_month') == dfa.select(
        max('import_month')).first()[0])
    dfa = dfa.where(col('import_day') == dfa.select(
        max('import_day')).first()[0])
    return dfa

# create a classification function


def match_type(levenshtein):
    if levenshtein == 0:
        return 'perfect match'
    elif levenshtein > 15:
        return 'unmatched'
    else:
        return 'imperfect match'

# convert the classification function to a UDF Function by passing in the function and the return type of function (string in this case)
udf_matchtype = F.udf(match_type, StringType())

addresses_api_data_database = get_glue_env_var('addresses_api_data_database', '')

addresses_api_data_table = get_glue_env_var('addresses_api_data_table', '')
source_catalog_database = get_glue_env_var('source_catalog_database', '')
source_catalog_table = get_glue_env_var('source_catalog_table', '')
target_destination = get_glue_env_var('target_destination', '')
match_to_property_shell = get_glue_env_var('match_to_property_shell', '')

query_addresses_ddf = glueContext.create_dynamic_frame.from_catalog(
    name_space=source_catalog_database,
    table_name=source_catalog_table,
)

query_addresses = query_addresses_ddf.toDF()
query_addresses = get_latest_partitions(query_addresses)
query_addresses.count()

query_addresses_sample = query_addresses.filter(
    "concatenated_string_to_match != ''")

query_concat = query_addresses_sample.withColumn(
    "query_address",
    F.concat_ws(" ", "concatenated_string_to_match", "postcode")
)

query_concat = query_concat.select(
    "prinx", "query_address", "postcode").withColumnRenamed("postcode", "query_postcode")


# PREP ADDRESSES API DATA

target_addresses_ddf = glueContext.create_dynamic_frame.from_catalog(
    name_space=addresses_api_data_database,
    table_name=addresses_api_data_table,
)

target_addresses = target_addresses_ddf.toDF()
target_addresses = get_latest_partitions(target_addresses)

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
perfectFull = perfectFull.withColumn("match_type", udf_matchtype("levenshtein"))
perfectFull = perfectFull.select(F.col("prinx"), F.col("query_address"), F.col("uprn").alias("matched_uprn"), F.col("target_address").alias("matched_address"), F.col("blpu_class").alias("matched_blpu_class"), "match_type")



perfectShort = cross_compare\
    .join(perfectFull, "prinx", "left_anti")\
    .filter("levenshtein_short = 0")\
    .dropDuplicates(['prinx'])

perfectShort = perfectShort.withColumn("match_type", udf_matchtype("levenshtein"))
perfectShort = perfectShort.select(F.col("prinx"), F.col("query_address"), F.col("uprn").alias("matched_uprn"), F.col("target_address").alias("matched_address"), F.col("blpu_class").alias("matched_blpu_class"), "match_type")



perfectMedium = cross_compare\
    .join(perfectFull, "prinx", "left_anti")\
    .join(perfectShort, "prinx", "left_anti")\
    .filter("levenshtein_medium = 0")\
    .dropDuplicates(['prinx'])

perfectMedium = perfectMedium.withColumn("match_type", udf_matchtype("levenshtein"))
perfectMedium = perfectMedium.select(F.col("prinx"), F.col("query_address"), 
   F.col("uprn").alias("matched_uprn"), F.col("target_address").alias("matched_address"), F.col("blpu_class").alias("matched_blpu_class"), "match_type")


perfect10char = cross_compare\
    .join(perfectFull, "prinx", "left_anti")\
    .join(perfectShort, "prinx", "left_anti")\
    .join(perfectMedium, "prinx", "left_anti")\
    .filter("levenshtein_10char = 0").dropDuplicates(['prinx'])

perfect10char = perfect10char.withColumn("match_type", udf_matchtype("levenshtein"))
perfect10char = perfect10char.select(F.col("prinx"), F.col("query_address"), F.col("uprn").alias("matched_uprn"), F.col("target_address").alias("matched_address"), F.col("blpu_class").alias("matched_blpu_class"), "match_type")


# put all 'perfect' together
perfectMatch = perfectFull.union(perfectShort).union(
    perfectMedium).union(perfect10char)
perfectMatch = perfectMatch.withColumn("round", F.lit("round 0"))

# ROUND 1 - now look at imperfect with same postcode

cross_compare = cross_compare\
    .join(perfectMatch, "prinx", "left_anti")

window = Window.partitionBy('prinx').orderBy("levenshtein")

bestMatch_round1 = cross_compare.filter("levenshtein < 3").withColumn('rank', F.rank().over(window))\
    .filter('rank = 1')\
    .dropDuplicates(['prinx'])

# apply function for match_type
bestMatch_round1 = bestMatch_round1.withColumn(
    "match_type", udf_matchtype("levenshtein"))
bestMatch_round1 = bestMatch_round1.withColumn("round", F.lit("round 1"))

bestMatch_round1 = bestMatch_round1.select("prinx", "query_address", F.col("uprn").alias("matched_uprn"), F.col("target_address").alias("matched_address"), F.col("blpu_class").alias("matched_blpu_class"), "match_type", "round")


# ROUND 2

cross_compare = cross_compare.join(bestMatch_round1, "prinx", "left_anti")

window = Window.partitionBy('prinx').orderBy("levenshtein_short")

bestMatch_round2 = cross_compare.filter("levenshtein_short < 3").withColumn('rank', F.rank().over(window))\
    .filter('rank = 1')\
    .dropDuplicates(['prinx'])

bestMatch_round2 = bestMatch_round2.withColumn(
    "match_type", udf_matchtype("levenshtein_short"))
bestMatch_round2 = bestMatch_round2.withColumn("round", F.lit("round 2"))
bestMatch_round2 = bestMatch_round2.select(F.col("prinx"), F.col("query_address"), F.col("uprn").alias("matched_uprn"), F.col("target_address").alias("matched_address"), F.col("blpu_class").alias("matched_blpu_class"), F.col("match_type"), "round")


# ROUND 3

# take all the unmatched, still keep same postcode, try match to line1 and line 2
cross_compare = cross_compare.join(bestMatch_round2, "prinx", "left_anti")

window = Window.partitionBy('prinx').orderBy("levenshtein_medium")

bestMatch_round3 = cross_compare.filter("levenshtein_medium < 3").withColumn('rank', F.rank().over(window))\
    .filter('rank = 1')\
    .dropDuplicates(['prinx'])

bestMatch_round3 = bestMatch_round3.withColumn(
    "match_type", udf_matchtype("levenshtein_medium"))
bestMatch_round3 = bestMatch_round3.withColumn("round", F.lit("round 3"))
bestMatch_round3 = bestMatch_round3.select(F.col("prinx"), F.col("query_address"), F.col("uprn").alias("matched_uprn"), F.col("target_address").alias("matched_address"), F.col("blpu_class").alias("matched_blpu_class"), F.col("match_type"), "round")


# Prepare rounds 4 to 7: take all the unmatched, allow mismatched postcodes
cross_with_any_postcode = query_concat\
    .join(perfectMatch, "prinx", "left_anti")\
    .join(bestMatch_round1, "prinx", "left_anti")\
    .join(bestMatch_round2, "prinx", "left_anti")\
    .join(bestMatch_round3, "prinx", "left_anti")\
    .crossJoin(target_concat)

cross_compare = cross_with_any_postcode.withColumn(
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
    "match_type", F.lit("imperfect match"))
bestMatch_round4 = bestMatch_round4.withColumn("round", F.lit("round 4"))

bestMatch_round4 = bestMatch_round4.select(F.col("prinx"), F.col("query_address"), F.col("uprn").alias("matched_uprn"), F.col("target_address").alias("matched_address"), F.col("blpu_class").alias("matched_blpu_class"), F.col("match_type"), "round")


# ROUND 5

# take all the unmatched, allow mismatched postcodes, match to line 1 and postcode only
cross_compare = cross_compare.join(bestMatch_round4, "prinx", "left_anti")

window = Window.partitionBy('prinx').orderBy("levenshtein_short")

bestMatch_round5 = cross_compare.filter("levenshtein_short < 5").withColumn('rank', F.rank().over(window))\
    .filter('rank = 1')\
    .dropDuplicates(['prinx'])

bestMatch_round5 = bestMatch_round5.withColumn(
    "match_type", F.lit("imperfect match"))
bestMatch_round5 = bestMatch_round5.withColumn("round", F.lit("round 5"))

bestMatch_round5 = bestMatch_round5.select(F.col("prinx"), F.col("query_address"), F.col("uprn").alias("matched_uprn"), F.col("target_address").alias("matched_address"), F.col("blpu_class").alias("matched_blpu_class"), F.col("match_type"), "round")


# ROUND 6

# take all the unmatched, allow mismatched postcodes, match to line 1 and 2 and postcode
cross_compare = cross_compare.join(bestMatch_round5, "prinx", "left_anti")

window = Window.partitionBy('prinx').orderBy("levenshtein_medium")

# logger.info('sort and filter')
bestMatch_round6 = cross_compare.filter("levenshtein_medium < 5").withColumn('rank', F.rank().over(window))\
    .filter('rank = 1')\
    .dropDuplicates(['prinx'])

bestMatch_round6 = bestMatch_round6.withColumn(
    "match_type", F.lit("imperfect match"))
bestMatch_round6 = bestMatch_round6.withColumn("round", F.lit("round 6"))

bestMatch_round6 = bestMatch_round6.select(F.col("prinx"), F.col("query_address"), F.col("uprn").alias("matched_uprn"), F.col("target_address").alias("matched_address"), F.col("blpu_class").alias("matched_blpu_class"), F.col("match_type"), "round")


# ROUND 7 - last chance

# take all the rest and mark as unmatched
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

bestMatch_lastChance = bestMatch_lastChance.withColumn("match_type", udf_matchtype("levenshtein"))
bestMatch_lastChance = bestMatch_lastChance.withColumn("round", F.lit("last chance"))
bestMatch_lastChance = bestMatch_lastChance.select(F.col("prinx"), F.col("query_address"), F.col("uprn").alias("matched_uprn"), F.col("target_address").alias("matched_address"), F.col("blpu_class").alias("matched_blpu_class"), F.col("match_type"), "round")


# PUT RESULTS OF ALL ROUNDS TOGETHER

all_best_match = perfectMatch.union(bestMatch_round1).union(bestMatch_round2).union(bestMatch_round3).union(
    bestMatch_round4).union(bestMatch_round5).union(bestMatch_round6).union(bestMatch_lastChance)

# JOIN MATCH RESULTS WITH INITIAL DATASET

matchingResults = query_addresses.join(all_best_match, "prinx", "left")

resultDataFrame = DynamicFrame.fromDF(
    matchingResults, glueContext, "resultDataFrame")

parquetData = glueContext.write_dynamic_frame.from_options(
    frame=resultDataFrame,
    connection_type="s3",
    format="parquet",
    connection_options={"path": target_destination,
                        "partitionKeys": PARTITION_KEYS},
    transformation_ctx="parquetData")

job.commit()
