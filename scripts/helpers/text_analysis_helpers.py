from datetime import datetime, date


def add_import_time_columns(df):
    today = datetime.today()
    year, month, day = today.year, str(today.month).zfill(2), str(today.day).zfill(2)
    import_date = str(year) + str(month) + str(day)
    df['import_datetime'] = str(import_date)
    df['import_timestamp'] = str(today.timestamp())
    df['import_year'] = str(year)
    df['import_month'] = str(month)
    df['import_day'] = str(day)
    df['import_date'] = str(import_date)
    return df


def get_date_today_formatted():
    today = datetime.today()
    year, month, day = today.year, str(today.month).zfill(2), str(today.day).zfill(2)
    date_today = date(int(year), int(month), int(day))
    return date_today


def get_s3_location(glue_table_name: str, base_s3_url: str) -> str:
    """Generate S3 location for today based on the table name."""
    today = datetime.today()
    year, month, day = today.year, str(today.month).zfill(2), str(today.day).zfill(2)
    return f"{base_s3_url}{glue_table_name}/import_year={year}/import_month={month}/import_day={day}/import_date={year}{month}{day}/"


PARTITION_KEYS = ['import_year', 'import_month', 'import_day', 'import_date']
