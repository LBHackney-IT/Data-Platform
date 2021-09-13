import pytest
from pyspark.sql import Row
from pyspark.sql import DataFrame

def cancel_job_if_failing_quality_checks(df: DataFrame):
  has_error = df.where(df.constraint_status == "Failure")
  if (has_error.count() > 0):
    messages = [ message['constraint_message'] for message in has_error.collect() ]
    raise Exception(' | '.join(messages))

class TestCancelJobIfFailingQualityChecks:
  def test_all_checks_passed(self, spark):
    df = spark.createDataFrame([Row(constraint_status = "Success")])
    assert cancel_job_if_failing_quality_checks(df) == None

  def test_throws_exception_on_failure(self, spark):
    df = spark.createDataFrame([Row(constraint_status = "Failure")])
    with pytest.raises(Exception):
      cancel_job_if_failing_quality_checks(df)

  def test_gives_constraint_message_on_failure(self, spark):
    df = spark.createDataFrame([Row(constraint_status = "Failure", constraint_message = "Was too large")])
    with pytest.raises(Exception, match = "Was too large"):
      cancel_job_if_failing_quality_checks(df)

  def test_combines_constraint_messages_on_multiple_failures(self, spark):
    df = spark.createDataFrame([
      Row(constraint_status = "Failure", constraint_message = "Non-unique value for id"),
      Row(constraint_status = "Failure", constraint_message = "Was ridiculously large"),
    ])
    with pytest.raises(Exception, match = "Non-unique value for id | Was ridiculously large"):
      cancel_job_if_failing_quality_checks(df)
