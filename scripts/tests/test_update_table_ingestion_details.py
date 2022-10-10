from scripts.helpers.database_ingestion_helpers import update_table_ingestion_details

class TestDatabaseIngestionHelpers:
  def test_update_table_ingestion_details_adds_one_table_ingestion_details(self):
    table = []

    expected_response = [
      {
        "table_name": "testTable",
        "minutes_taken": 3,
        "error": "False",
        "error_details": "None"
      }
    ]

    update_table_ingestion_details(table, table_name="testTable", minutes_taken=3, error="False", error_details="None")

    assert table == expected_response

  def test_update_table_ingestion_details_adds_multiple_table_ingestion_details(self):
    table = []

    expected_response = [
      {
        "table_name": "testTable",
        "minutes_taken": 3,
        "error": "False",
        "error_details": "None"
      },
      {
        "table_name": "testTable2",
        "minutes_taken": 0,
        "error": "True",
        "error_details": "Cannot execute query 'SELECT * FROM db.table'"
      },
    ]
    update_table_ingestion_details(table, table_name="testTable", minutes_taken=3, error="False", error_details="None")
    update_table_ingestion_details(table, table_name="testTable2", minutes_taken=0, error="True", error_details="Cannot execute query 'SELECT * FROM db.table'")

    assert table == expected_response