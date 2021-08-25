from address_cleaning import clean_addresses
from pyspark.sql import Row
from unittest.case import TestCase

class TestCleanAddresses:
    def test_has_concatenated_string_to_match_column(self, spark):
        self.assertDictionaryContains(
            {'concatenated_string_to_match': 'CRANLEIGH COURT'},
            self.clean_addresses(spark, [
                {'address': 'CRANLEIGH COURT', 'import_year': "2021" , 'import_month': "08", 'import_day': "19"}
            ])[0]
        )

    def test_has_concatenated_string_to_match_column_when_source_address_header_is_different(self, spark):
        response = self.clean_addresses(spark, [
            {'flowers': 'FLOWERS COURT', 'import_year': "2021" , 'import_month': "08", 'import_day': "19"}
          ], 'flowers')

        self.assertDictionaryContains(
            {'concatenated_string_to_match': 'FLOWERS COURT'},
            response[0]
        )

    def assertDictionaryContains(self, expected, actual):
        TestCase().assertEqual(actual, { **actual,  **expected})

    def test_gets_latest_partitions(self, spark):
        assert (
            self.clean_addresses(spark, [
            {'address': 'CRANLEIGH COURT', 'import_year': "2021" , 'import_month': "08", 'import_day': "19"},
            {'address': 'CRANLEIGH COURT', 'import_year': "2021" , 'import_month': "08", 'import_day': "20"}
            ])
            ==
            [
                {'concatenated_string_to_match': 'CRANLEIGH COURT', 'import_year': "2021" , 'import_month': "08", 'import_day': "20"}
            ]
        )

    def clean_addresses(self, spark, addresses, address_column_header = "address", postcode_column_header = None):
        logger = DummyLogger()
        query_addresses = spark.createDataFrame(spark.sparkContext.parallelize([Row(**i) for i in addresses]))
        return [row.asDict() for row in clean_addresses(query_addresses, address_column_header, postcode_column_header, logger).rdd.collect()]

class DummyLogger:
    def info(self, message):
        return
