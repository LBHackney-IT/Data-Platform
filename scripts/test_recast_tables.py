from recast_tables import castColumns
from pyspark.sql import Row
from pyspark.sql.types import TimestampType
from datetime import datetime

class TestRecastTables:
  
  def test_castColumns_timestamp(self, spark):
    response = self.castColumns(spark, [{'submit_date': '2021-09-24 08:58:47'}], "timestamp", TimestampType())
    expected = [{'submit_date': datetime(2021, 9, 24, 8, 58, 47)}]
    assert (
      response
      ==
      expected
    )

  def castColumns(self, spark, data, typeName, dataType):
    # The column dictionary is saved in JSON format in a separate file in this directory.
    # Then we are using the same code that is used in the script to access this file just with a relative path
    # instead of an S3 path.

    columnsDictionary = spark.read.option("multiline", "true").json("./recast_columns_mock_column_type.json")
    query_data = spark.createDataFrame(spark.sparkContext.parallelize([Row(**i) for i in data]))
    return [row.asDict() for row in castColumns(columnsDictionary, "MyTable", query_data, typeName, dataType).rdd.collect()]