from helpers.database_ingestion_helpers import update_table_ingestion_details

class TestDatabaseIngestionHelpers:
  def test_update_table_ingestion_details_adds_one_table_ingestion_details(self):
    table = []
    table_name = "testTable"
    minutes_taken = 3
    error = "False"
    error_details = "None"

    expected_response = [
      {
        "table_name": "testTable",
        "minutes_taken": 3,
        "error": "False",
        "error_details": "None"
      }
    ]
    response = update_table_ingestion_details(table, table_name, minutes_taken, error, error_details)

    assert response == expected_response