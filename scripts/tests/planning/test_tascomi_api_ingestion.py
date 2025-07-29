from freezegun import freeze_time

from scripts.jobs.planning.tascomi_api_ingestion import get_days_since_last_import


class TestTascomiApiIngestion:
    def test_get_days_since_last_import_no_days(self):
        today = "2012-01-14"
        last_import_date = "20120114"
        with freeze_time(today):
            actual_response = get_days_since_last_import(last_import_date)
            assert actual_response == []

    def test_get_days_since_last_import_two_days(self):
        today = "2018-03-15"
        last_import_date = "20180313"
        with freeze_time(today):
            actual_response = get_days_since_last_import(last_import_date)
            assert actual_response == ["2018-03-13", "2018-03-14"]
