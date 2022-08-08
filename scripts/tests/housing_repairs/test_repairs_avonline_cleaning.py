from scripts.jobs.housing_repairs.repairs_avonline_cleaning import clean_avonline_repairs
from pyspark.sql import Row
from scripts.tests.helpers import assertions

class TestAvonlineCleaning:
    def test_title_case_conversion(self, spark):
        response = self.clean_avonline_repairs(spark, [{'contact_information': 'joe bloggs'}])

        assertions.dictionaryContains({'contact_information': 'Joe Bloggs'}, response[0])

    def clean_avonline_repairs(self, spark, repairs):
        repairs_with_imports = [{'import_year': '2021', 'import_month': '08', 'import_day': '19', **i} for i in repairs]
        query_repairs = spark.createDataFrame(
            spark.sparkContext.parallelize(
                [Row(**i) for i in repairs_with_imports]
            )
        )
        return [row.asDict() for row in clean_avonline_repairs(query_repairs).rdd.collect()]


    # def test_has_concatenated_string_to_match_column_when_source_address_header_is_different(self, spark):
    #     response = self.clean_addresses(spark, [{'flowers': 'FLOWERS COURT'}], 'flowers')
    #
    #     self.assertDictionaryContains({'concatenated_string_to_match': 'FLOWERS COURT'}, response[0])
    #
    # postcode_examples = [
    #     ["SW1P 3EA", "SW1P 3EA"],
    #     ["SE17DB", "SE1 7DB"],
    #     ["GIR 0AA", "GIR 0AA"],
    #     ["GIR0AA", "GIR 0AA"]
    # ]
    # @pytest.mark.parametrize("input_postcode, expected_postcode", postcode_examples)
    # def test_extracts_postcode_like_string_from_address_column(self, spark, input_postcode, expected_postcode):
    #     response = self.clean_addresses(spark, [{'address': input_postcode}], 'address')
    #
    #     self.assertDictionaryContains({'postcode': expected_postcode}, response[0])
