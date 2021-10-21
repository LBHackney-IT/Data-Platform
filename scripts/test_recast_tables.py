from recast_tables import castColumns
from pyspark.sql import Row

class TestRecastTables:
  
  jsonDict = '[{"timestamp":{"applications": "submit_date,advertisement_to","contacts": "ceased_date,last_updated, submit_date"}, "long":{"applications": "id","contacts": "id"}}]'

  def test_castColumns_timestamp(self, spark):
    response = self.castColumns(spark, [{'submit_date': '2021-09-24 08:58:47'}])
    expected = [{'submit_date': datetime.datetime(2021, 9, 24, 8, 58, 47)}]
    assert (
      response
      ==
      expected
    )

  def castColumns(self, spark, data):
    dict = 
    query_data = spark.createDataFrame(spark.sparkContext.parallelize([Row(**i) for i in data]))
    return [row.asDict() for row in castColumns(query_data).rdd.collect()]