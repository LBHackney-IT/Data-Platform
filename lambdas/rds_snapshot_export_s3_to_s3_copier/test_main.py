import pytest
from main import get_date_time


class TestGetDateTime:
    def test_get_date_time_yy_format_with_time(self):
        source_identifier = "sql-to-parquet-23-12-25-143000"
        year, month, day, date = get_date_time(source_identifier)

        assert year == "2023"
        assert month == "12"
        assert day == "25"
        assert date == "20231225"



    def test_get_date_time_yyyy_format_backdated(self):
        source_identifier = "sql-to-parquet-2023-12-25-backdated"
        year, month, day, date = get_date_time(source_identifier)

        assert year == "2023"
        assert month == "12"
        assert day == "25"
        assert date == "20231225"

    def test_get_date_time_yyyy_format_backdated_different_date(self):
        source_identifier = "sql-to-parquet-2024-01-15-backdated"
        year, month, day, date = get_date_time(source_identifier)

        assert year == "2024"
        assert month == "01"
        assert day == "15"
        assert date == "20240115"

    def test_get_date_time_yy_format_different_time(self):
        source_identifier = "sql-to-parquet-24-03-10-090000"
        year, month, day, date = get_date_time(source_identifier)

        assert year == "2024"
        assert month == "03"
        assert day == "10"
        assert date == "20240310"

    def test_get_date_time_invalid_format_raises_error(self):
        invalid_identifiers = [
            "sql-to-parquet-2023-12-25",  # Missing -backdated for yyyy format
            "sql-to-parquet-23-12-25",  # Missing time for yy format
            "sql-to-parquet-23-12-25-143000-backdated",  # Invalid: yy format cannot have -backdated
            "invalid-format-23-12-25-143000",  # Wrong prefix
            "sql-to-parquet-23-12-25-14300",  # Wrong time format (5 digits)
            "sql-to-parquet-23-12-25-1430000",  # Wrong time format (7 digits)
            "sql-to-parquet-2023-12-backdated",  # Missing day
            "sql-to-parquet-123-12-25-143000",  # 3-digit year
        ]

        for invalid_id in invalid_identifiers:
            with pytest.raises(ValueError, match="Invalid source identifier format"):
                get_date_time(invalid_id)

    def test_get_date_time_edge_cases(self):
        # Test with single digit month/day (should still work with zero padding)
        source_identifier = "sql-to-parquet-23-01-05-000000"
        year, month, day, date = get_date_time(source_identifier)

        assert year == "2023"
        assert month == "01"
        assert day == "05"
        assert date == "20230105"

    def test_get_date_time_leap_year(self):
        # Test leap year date
        source_identifier = "sql-to-parquet-2024-02-29-backdated"
        year, month, day, date = get_date_time(source_identifier)

        assert year == "2024"
        assert month == "02"
        assert day == "29"
        assert date == "20240229"
