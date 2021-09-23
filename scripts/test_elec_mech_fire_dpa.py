from elec_mech_fire_dpa import clean_mech_fire_data 
import datetime
from pyspark.sql import Row
from unittest.case import TestCase
import pytest
from unit_testing_helpers import assertDictionaryContains

class TestMechFireDpaCleaning:
    def test_date_conversion(self, spark):
        response = self.clean_mech_fire_data(spark, [{'date': datetime.datetime(2002, 1, 10, 0, 0)}])

        assertDictionaryContains({'date': datetime.datetime(2002, 1, 10, 0, 0)}, response[0])

    def test_status_standard(self, spark):
        response = self.clean_mech_fire_data(spark, [{'order_status': 'Y'}])

        assertDictionaryContains({'order_status': 'Completed'}, response[0])


    def clean_mech_fire_data(self, spark, repairs):
        repairs_with_imports = [{'import_year': '2021', 'import_month': '08', 'import_day': '19','date':datetime.datetime(2002, 1, 10, 0, 0),'order_status':'Y', **i} for i in repairs]
        logger = DummyLogger()
        query_repairs = spark.createDataFrame(
            spark.sparkContext.parallelize(
                [Row(**i) for i in repairs_with_imports]
            )
        )
        return [row.asDict() for row in clean_mech_fire_data(query_repairs).rdd.collect()]

class DummyLogger:
    def info(self, message):
        return
