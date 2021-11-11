import re
import pyspark.sql.functions as F


def map_repair_priority(data_frame, origin_column, target_column):
    return data_frame.withColumn(target_column, F.when(data_frame[origin_column] == "Immediate", 1)
                                 .when(data_frame[origin_column] == "Emergency", 2)
                                 .when(data_frame[origin_column] == "Urgent", 3)
                                 .when(data_frame[origin_column] == "Normal", 4)
                                 .otherwise(None))


def clean_column_names(df):
    # remove full stops from column names
    df = df.select([F.col("`{0}`".format(c)).alias(
        c.replace('.', '')) for c in df.columns])
    # remove trialing underscores
    df = df.select([F.col(col).alias(re.sub("_$", "", col))
                   for col in df.columns])
    # lowercase and remove double underscores
    df = df.select([F.col(col).alias(
        re.sub("[^0-9a-zA-Z$]+", "_", col.lower())) for col in df.columns])
    return df
