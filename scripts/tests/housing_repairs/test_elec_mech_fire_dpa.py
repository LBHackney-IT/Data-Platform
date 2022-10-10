from scripts.jobs.housing_repairs.elec_mech_fire_dpa import clean_mech_fire_data
import datetime
from pyspark.sql import Row
from scripts.tests.helpers import assertions

class TestMechFireDpaCleaning:
    def test_date_conversion(self, spark):
        response = self.clean_mech_fire_data(spark, [{'date': datetime.datetime(2002, 1, 10, 0, 0)}])

        assertions.dictionaryContains({'datetime_raised': datetime.datetime(2002, 1, 10, 0, 0)}, response[0])

    def test_status_standard(self, spark):
        response = self.clean_mech_fire_data(spark, [{'order_status': 'Y'}])

        assertions.dictionaryContains({'order_status': 'Completed'}, response[0])


    def clean_mech_fire_data(self, spark, repairs):
        repairs_with_imports = [{'import_year': '2021', 'import_month': '08', 'import_day': '19','date':datetime.datetime(2002, 1, 10, 0, 0),'order_status':'Y', **i} for i in repairs]
        query_repairs = spark.createDataFrame(
            spark.sparkContext.parallelize(
                [Row(**i) for i in repairs_with_imports]
            )
        )
        return [row.asDict() for row in clean_mech_fire_data(query_repairs).rdd.collect()]

