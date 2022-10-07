import pytest
from pyspark.sql import SparkSession
import os

@pytest.fixture(scope='session')
def spark():
  event_log_dir = os.path.dirname(__file__) + '/../spark_events'
  s = SparkSession.builder.config("spark.eventLog.dir", event_log_dir).config("spark.eventLog.enabled", True).master("local").getOrCreate()
  yield s
  s.stop()
