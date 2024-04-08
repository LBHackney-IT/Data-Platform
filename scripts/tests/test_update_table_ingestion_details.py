from datetime import datetime
from scripts.helpers.database_ingestion_helpers import update_table_ingestion_details

class TestDatabaseIngestionHelpers:
    def test_update_table_ingestion_details_adds_one_table_ingestion_details(self):
        table = []
        run_datetime = datetime(2024, 3, 27, 12, 0)  

        expected_response = [
            {
                "table_name": "testTable",
                "minutes_taken": 3,
                "error": "False",
                "error_details": "None",
                "run_datetime": run_datetime.isoformat(),  
                "row_count": 100,  
                "run_id": "exampleRunId"  
            }
        ]

        update_table_ingestion_details(table, table_name="testTable", minutes_taken=3, error="False", error_details="None",
                                       run_datetime=run_datetime, row_count=100, run_id="exampleRunId")

        assert table == expected_response

    def test_update_table_ingestion_details_adds_multiple_table_ingestion_details(self):
        table = []
        run_datetime1 = datetime(2024, 3, 27, 12, 0)
        run_datetime2 = datetime(2024, 3, 27, 13, 0)  

        expected_response = [
            {
                "table_name": "testTable",
                "minutes_taken": 3,
                "error": "False",
                "error_details": "None",
                "run_datetime": run_datetime1.isoformat(),
                "row_count": 100,
                "run_id": "exampleRunId1"
            },
            {
                "table_name": "testTable2",
                "minutes_taken": 0,
                "error": "True",
                "error_details": "Cannot execute query 'SELECT * FROM db.table'",
                "run_datetime": run_datetime2.isoformat(),
                "row_count": 0, 
                "run_id": "exampleRunId2"
            },
        ]

        update_table_ingestion_details(table, table_name="testTable", minutes_taken=3, error="False", error_details="None",
                                       run_datetime=run_datetime1, row_count=100, run_id="exampleRunId1")
        update_table_ingestion_details(table, table_name="testTable2", minutes_taken=0, error="True", error_details="Cannot execute query 'SELECT * FROM db.table'",
                                       run_datetime=run_datetime2, row_count=0, run_id="exampleRunId2")

        assert table == expected_response
