from scripts.jobs.spark_example import only_hackney_addresses
from pyspark.sql import Row

class TestSparkExample:
  def test_filters_only_hackney_addresses(self, spark):
    assert (
      [
        {'line1': '13', 'line2': 'Cheese Lane', 'postcode': 'E8 13HB', 'council': 'Hackney'}
      ]
      ==
      self.only_hackney_addresses(spark, [
        {'line1': '13', 'line2': 'Cheese Lane', 'postcode': 'E8 13HB', 'council': 'Hackney'},
        {'line1': '13', 'line2': 'Pickle Lane', 'postcode': 'E15 13HB', 'council': 'Newham'},
      ])
    )

  def only_hackney_addresses(self, spark, addresses):
    query_addresses = spark.createDataFrame(spark.sparkContext.parallelize([Row(**i) for i in addresses]))
    return [row.asDict() for row in only_hackney_addresses(query_addresses).rdd.collect()]
