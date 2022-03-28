from pyspark.sql import DataFrame


def only_hackney_addresses(dataframe: DataFrame) -> DataFrame:
  """Used to demonstrate pytest + pyspark.  See test_spark_example.py
  """
  return dataframe.filter(dataframe.council == 'Hackney')
