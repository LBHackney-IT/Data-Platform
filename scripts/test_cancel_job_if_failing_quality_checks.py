import pytest
from pyspark.sql import Row
from pyspark.sql import DataFrame

def cancel_job_if_failing_quality_checks(df: DataFrame):
  has_error = df.where(df.check_status == "Failure")
  if (has_error.count() > 0):
    raise Exception('Was a big cheese')

class TestCancelJobIfFailingQualityChecks:
  def test_all_checks_passed(self, spark):
    df = spark.createDataFrame([Row(check_status = "Success")])
    assert cancel_job_if_failing_quality_checks(df) == None

  def test_throws_exception_on_failure(self, spark):
    df = spark.createDataFrame([Row(check_status = "Failure")])
    with pytest.raises(Exception):
      cancel_job_if_failing_quality_checks(df)

  def test_gives_constraint_message_on_failure(self, spark):
    df = spark.createDataFrame([Row(check_status = "Failure", constraint_message = "Was a big cheese")])
    with pytest.raises(Exception, match = "Was a big cheese"):
      cancel_job_if_failing_quality_checks(df)


# {
#  'check_status': 'Error',
#  'check_level': 'Error',
#  'constraint_status': 'Failure',
#  'check': 'data quality checks',
#  'constraint_message': 'Value: 4.0 does not meet the constraint requirement! Priority codes can only be turned up to 3',
#  'constraint': 'MaximumConstraint(Maximum(work_priority_priority_code,None))'
# }
