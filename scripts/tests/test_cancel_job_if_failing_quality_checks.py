import pytest
from pyspark.sql import Row
from scripts.helpers.data_quality_testing import cancel_job_if_failing_quality_checks

class TestCancelJobIfFailingQualityChecks:
  def test_all_checks_passed(self, spark):
    df = spark.createDataFrame([Row(constraint_status = "Success")])
    assert cancel_job_if_failing_quality_checks(df) == None

  def test_throws_exception_on_failure(self, spark):
    df = spark.createDataFrame([Row(constraint_status = "Failure")])
    with pytest.raises(Exception):
      cancel_job_if_failing_quality_checks(df)

  def test_combines_check_description_and_constraint_message_on_failure(self, spark):
    df = spark.createDataFrame([Row(constraint_status = "Failure", check = "D", constraint_message = "Was too large")])
    with pytest.raises(Exception, match = "D. Was too large"):
      cancel_job_if_failing_quality_checks(df)

  def test_combines_constraint_messages_on_multiple_failures(self, spark):
    df = spark.createDataFrame([
      Row(constraint_status = "Failure", check = "A", constraint_message = "Non-unique value for id"),
      Row(constraint_status = "Failure", check = "B", constraint_message = "Was ridiculously large"),
    ])
    with pytest.raises(Exception, match = "A. Non-unique value for id | B. Was ridiculously large"):
      cancel_job_if_failing_quality_checks(df)
