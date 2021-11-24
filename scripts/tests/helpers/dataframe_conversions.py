from pyspark.sql import Row

def list_to_dataframe(spark, list_data):
    return spark.createDataFrame(spark.sparkContext.parallelize(
        [Row(**i) for i in list_data]
    ))

def dataframe_to_list(df):
    return [row.asDict() for row in df.rdd.collect()]