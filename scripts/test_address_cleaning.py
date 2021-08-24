from address_cleaning import clean_addresses

class TestCleanAddresses:
  def test_has_concatenated_string_to_match_column(self, spark):
    assert (
      self.clean_addresses(spark, [
        {'address': 'CRANLEIGH COURT'}
      ])
      ==
      [
        {'concatenated_string_to_match': 'CRANLEIGH COURT'}
      ]
    )

  def clean_addresses(self, spark, addresses):
      query_addresses = spark.createDataFrame(spark.sparkContext.parallelize([Row(**i) for i in addresses]))
      return [row.asDict() for row in clean_addresses(query_addresses).rdd.collect()]


