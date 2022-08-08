from scripts.helpers.helpers import clean_column_names
from scripts.tests.helpers.dataframe_conversions import list_to_dataframe, dataframe_to_list

class TestCleanColumnNames:
  def test_lowercases_a_column_name(self, spark):
    input_data = [{"Col": 3}]
    expected_response = [{"col": 3}]
    response = dataframe_to_list(clean_column_names(list_to_dataframe(spark, input_data)))
    assert response == expected_response

  def test_lowercases_many_column_name(self, spark):
    input_data = [{"Col": 3, "THING": "my data", "already_lower": True}]
    expected_response = [{"col": 3, "thing": "my data", "already_lower": True}]
    response = dataframe_to_list(clean_column_names(list_to_dataframe(spark, input_data)))
    assert response == expected_response

  def test_removes_all_non_alphanumeric_character_expect_underscores(self, spark):
    input_data = [
      {"Col?2": 6, "for -this": "hello", "percentage%%diff": 45, "period.stop": "end"}
    ]
    expected_response = [
      { "col_2": 6, "for_this": "hello", "percentage_diff": 45, "period_stop": "end"}
    ]
    response = dataframe_to_list(clean_column_names(list_to_dataframe(spark, input_data)))
    assert response == expected_response

  def test_will_only_have_one_underscore_in_a_row(self, spark):
    input_data = [
      {"Col?three": 6, "for -this": "hello", "percentage%%diff": 45, "my_/data": True}
    ]
    expected_response = [
      { "col_three": 6, "for_this": "hello", "percentage_diff": 45, "my_data": True}
    ]
    response = dataframe_to_list(clean_column_names(list_to_dataframe(spark, input_data)))
    assert response == expected_response

  def test_removes_trailing_underscores(self, spark):
    input_data = [
      {"Col?": 6, "for - this": "hello", "percentage ( % )": 45}
    ]
    expected_response = [
      { "col": 6, "for_this": "hello", "percentage": 45}
    ]
    response = dataframe_to_list(clean_column_names(list_to_dataframe(spark, input_data)))
    assert response == expected_response
