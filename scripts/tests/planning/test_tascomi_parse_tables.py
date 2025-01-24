from scripts.helpers.helpers import parse_json_into_dataframe
from pyspark.sql import Row
from datetime import datetime
from unittest import TestCase

from scripts.tests.helpers import assertions


class TestTascomiParsingRefinement:

    def test_column_expansion(self, spark):
        response = self.parse_json_into_dataframe(spark, 'contacts', [{'contacts': '{"id": "34607",'
                                                                                   ' "creation_user_id": null,'
                                                                                   ' "title_id": "4"}'}])
        expected = ['id', 'creation_user_id', 'title_id',
                    'page_number', 'import_api_url_requested', 'import_api_status_code',
                    'import_exception_thrown', 'import_datetime', 'import_timestamp',
                    'import_year', 'import_month', 'import_day', 'import_date']
        TestCase().assertCountEqual(list(response[0]), expected)

    def test_parsed_row_data(self, spark):
        response = self.parse_json_into_dataframe(spark, 'contacts', [{'contacts': '{"id": "34607",'
                                                                                   ' "creation_user_id": null,'
                                                                                   ' "title_id": "4"}'}])
        expected = {'id': '34607', 'creation_user_id': None, 'title_id': '4', 'page_number': 691,
                     'import_api_url_requested': 'https://hackney-planning.idoxcloud.com/rest/v1/contacts?page=691',
                     'import_api_status_code': 200, 'import_exception_thrown': '',
                     'import_datetime': datetime(2021, 9, 16, 13, 10), 'import_timestamp': '1631797859.247579',
                     'import_year': '2021', 'import_month': '09', 'import_day': '16',
                     'import_date': '20210916'}
        assertions.dictionaryContains(response[0], expected)

    def parse_json_into_dataframe(self, spark, column, data):
        data_with_imports = [{'page_number': 691,
                              'import_api_url_requested': 'https://hackney-planning.idoxcloud.com/rest/v1/contacts?page=691',
                              'import_api_status_code': 200, 'import_exception_thrown': '',
                              'import_datetime': datetime(2021, 9, 16, 13, 10), 'import_timestamp': '1631797859.247579',
                              'import_year': '2021', 'import_month': '09', 'import_day': '16',
                              'import_date': '20210916', **i} for i in data]
        query_data = spark.createDataFrame(
            spark.sparkContext.parallelize(
                [Row(**i) for i in data_with_imports]
            )
        )
        return [row.asDict() for row in parse_json_into_dataframe(spark, column, query_data).rdd.collect()]
