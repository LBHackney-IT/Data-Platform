
from spark_example import only_hackney_addresses

from unittest.case import TestCase
from pyspark.sql import SparkSession, Row

spark = SparkSession.builder.master("local").getOrCreate()

class TestSparkExample(TestCase):
  def test_filters_only_hackney_addresses(self):
    self.assertEqual(
      [
        {'line1': '13', 'line2': 'Cheese Lane', 'postcode': 'E8 13HB', 'council': 'Hackney'}
      ],
      self.only_hackney_addresses([
        {'line1': '13', 'line2': 'Cheese Lane', 'postcode': 'E8 13HB', 'council': 'Hackney'},
        {'line1': '13', 'line2': 'Pickle Lane', 'postcode': 'E15 13HB', 'council': 'Newham'},
      ])
    )

  def only_hackney_addresses(self, addresses):
    query_addresses = spark.createDataFrame(spark.sparkContext.parallelize([Row(**i) for i in addresses]))
    return [row.asDict() for row in only_hackney_addresses(query_addresses).rdd.collect()]
