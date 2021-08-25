from address_cleaning import clean_addresses
from pyspark.sql import Row
from unittest.case import TestCase
import pytest

class TestCleanAddresses:
    def test_has_concatenated_string_to_match_column(self, spark):
        response = self.clean_addresses(spark, [
            {'address': 'CRANLEIGH COURT', 'import_year': "2021" , 'import_month': "08", 'import_day': "19"}
        ])

        self.assertDictionaryContains(
            {'concatenated_string_to_match': 'CRANLEIGH COURT'},
            response[0]
        )

    def test_has_concatenated_string_to_match_column_when_source_address_header_is_different(self, spark):
        response = self.clean_addresses(spark, [
            {'flowers': 'FLOWERS COURT', 'import_year': "2021" , 'import_month': "08", 'import_day': "19"}
        ], 'flowers')

        self.assertDictionaryContains(
            {'concatenated_string_to_match': 'FLOWERS COURT'},
            response[0]
        )

    @pytest.mark.parametrize("postcode", ["SW1P 3EA", "sw1p 3ea"])
    def test_extracts_postcode_like_string_from_address_column(self, spark, postcode):
        response = self.clean_addresses(spark, [
            {'address': postcode, 'import_year': "2021" , 'import_month': "08", 'import_day': "19"}
        ], 'address')

        self.assertDictionaryContains(
            {'postcode': postcode},
            response[0]
        )

    def test_removes_postcode_from_concatenated_string_to_match(self, spark):
        response = self.clean_addresses(spark, [
            {'address': 'CAT LANE SW1P 5DB', 'import_year': "2021" , 'import_month': "08", 'import_day': "19"}
        ], 'address')

        self.assertDictionaryContains(
            {'concatenated_string_to_match': 'CAT LANE '},
            response[0]
        )

    def test_has_empty_postcode_when_address_column_does_not_have_a_postcode(self, spark):
        response = self.clean_addresses(spark, [
            {'address': 'Not a postcode', 'import_year': "2021" , 'import_month': "08", 'import_day': "19"}
        ], 'address')

        self.assertDictionaryContains(
            {'postcode': ''},
            response[0]
        )

    def test_gets_latest_partitions(self, spark):
        assert (
            self.clean_addresses(spark, [
            {'address': 'CRANLEIGH COURT', 'import_year': "2021" , 'import_month': "08", 'import_day': "19"},
            {'address': 'CRANLEIGH COURT', 'import_year': "2021" , 'import_month': "08", 'import_day': "20"}
            ])
            ==
            [
                {'concatenated_string_to_match': 'CRANLEIGH COURT', 'import_year': "2021" , 'import_month': "08", 'import_day': "20", 'postcode': ''}
            ]
        )
    
    def test_address_line_formatting_converts_address_to_uppercase(self, spark):
        response = self.clean_addresses(spark, [
            {'address': '4 on tHe RoAd', 'import_year': "2021" , 'import_month': "08", 'import_day': "19"}
        ], 'address')

        self.assertDictionaryContains(
            {'concatenated_string_to_match': '4 ON THE ROAD'}, response[0]
        )

    def assertDictionaryContains(self, expected, actual):
        TestCase().assertEqual(actual, { **actual,  **expected})

    def clean_addresses(self, spark, addresses, address_column_header = "address", postcode_column_header = None):
        logger = DummyLogger()
        query_addresses = spark.createDataFrame(spark.sparkContext.parallelize([Row(**i) for i in addresses]))
        return [row.asDict() for row in clean_addresses(query_addresses, address_column_header, postcode_column_header, logger).rdd.collect()]

class DummyLogger:
    def info(self, message):
        return
