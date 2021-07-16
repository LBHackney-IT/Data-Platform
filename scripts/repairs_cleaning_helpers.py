import re
import pyspark.sql.functions as F
from pyspark.sql.types import StringType
from pyspark.sql import types as t
from datetime import datetime
from pyspark.sql.types import TimestampType


def map_repair_priority(code):
    if code == 'Immediate':
        return 1
    elif code == 'Emergency':
        return 2
    elif code == 'Urgent':
        return 3
    elif code == 'Normal':
        return 4
    else:
        return None


# convert to a UDF Function by passing in the function and the return type of function (string in this case)
udf_map_repair_priority = F.udf(map_repair_priority, StringType())


def clean_column_names(df):
    # remove full stops from column names
    df = df.select([F.col("`{0}`".format(c)).alias(
        c.replace('.', '')) for c in df.columns])
    # remove trialing underscores
    df = df.select([F.col(col).alias(re.sub("_$", "", col))
                   for col in df.columns])
    # lowercase and remove double underscores
    df2 = df.select([F.col(col).alias(
        re.sub("[^0-9a-zA-Z$]+", "_", col.lower())) for col in df.columns])
    return df2
