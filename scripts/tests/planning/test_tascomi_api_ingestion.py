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

    def test_get_days_since_last_import_with_max_lookback(self):
        """Test that max_lookback_days limits the number of days queried"""
        today = "2025-01-15"
        last_import_date = "20241201"  # 45 days ago
        max_lookback_days = 7

        with freeze_time(today):
            actual_response = get_days_since_last_import(
                last_import_date, max_lookback_days
            )
            # Should only return the last 7 days, not all 45 days
            expected_days = [
                "2025-01-08",
                "2025-01-09",
                "2025-01-10",
                "2025-01-11",
                "2025-01-12",
                "2025-01-13",
                "2025-01-14",
            ]
            assert actual_response == expected_days
