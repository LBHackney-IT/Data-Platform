from jobs.planning.tascomi_create_daily_snapshot import prepare_increments, apply_increments
from pyspark.sql import Row
from datetime import datetime, date

class TestSnapshotCreation:

    def test_apply_changed_record(self, spark):
        input_snapshot = [{'id': 1, 'application_stage': 8}]
        input_increment = [{'id': 1, 'application_stage': 9}]
        expected = [{'id': 1, 'application_stage': 9}]
        response = self.apply_increments(spark, input_snapshot, input_increment)
        assert (response == expected)

    def test_apply_new_record(self, spark):
        input_snapshot = [{'id': 1, 'application_stage': 8}]
        input_increment = [{'id': 2, 'application_stage': 1}]
        expected = [{'id': 1, 'application_stage': 8},{'id': 2, 'application_stage': 1}]
        response = self.apply_increments(spark, input_snapshot, input_increment)
        assert (response == expected)

    def test_prepare_several_days_increments(self, spark):
        input_increment = [{'id': 1, 'application_stage': 5, 'last_updated': datetime(2021, 9, 24, 0, 0, 0)},{'id': 1, 'application_stage': 6, 'last_updated': datetime(2021, 9, 25, 0, 0, 0)}]
        expected = [{'id': 1, 'application_stage': 6, 'last_updated': datetime(2021, 9, 25, 0, 0, 0)}]
        response = self.prepare_increments(spark, input_increment)
        assert (response == expected)

    def test_prepare_several_records_increments(self, spark):
        input_increment = [{'id': 1, 'application_stage': 5, 'last_updated': datetime(2021, 9, 24, 0, 0, 0)},{'id': 2, 'application_stage': 5, 'last_updated': datetime(2021, 9, 25, 0, 0, 0)}]
        expected = [{'id': 1, 'application_stage': 5, 'last_updated': datetime(2021, 9, 24, 0, 0, 0), 'snapshot_year': '2021', 'snapshot_month': '9', 'snapshot_day': '24', 'snapshot_date': '2021'},{'id': 2, 'application_stage': 5, 'last_updated': datetime(2021, 9, 25, 0, 0, 0)}]
        response = self.prepare_increments(spark, input_increment)
        assert (response == expected)
  
    # def test_castColumns_integer(self, spark):
    #     input_data = [{'id_number': '12'}]
    #     expected = [{'id_number': 12}]
    #     response = self.castColumns(spark, self.column_type_dictionary_path, "MyTable", input_data, "integer", IntegerType())
    #     assert (response == expected)

    # def test_castColumns_boolean(self, spark):
    #     input_data = [{'flag': 'f'},{'flag': 't'}]
    #     expected = [{'flag': False},{'flag': True}]
    #     response = self.castColumns(spark,self.column_type_dictionary_path, "MyTable", input_data, "boolean", BooleanType())
    #     assert (response == expected)

    
    # def test_castColumns_when_all_datatypes_not_represented_in_dictionary(self, spark):
    #     input_data = [{'id_number': '12', 'flag': 'f', 'start_date': '2021-09-24'}]
    #     expected = [{'id_number': 12, 'flag': False,'start_date': '2021-09-24'}]
    #     response = self.castColumnsAllTypes(spark, self.column_type_dictionary_partial_path, "MyTable", input_data)
    #     assert (response == expected)


    def apply_increments(self, spark, input_snapshot, input_increment):
        query_data_snapshot = spark.createDataFrame(spark.sparkContext.parallelize([Row(**i) for i in input_snapshot]))
        query_data_increment = spark.createDataFrame(spark.sparkContext.parallelize([Row(**i) for i in input_increment]))
        return [row.asDict() for row in apply_increments(query_data_snapshot, query_data_increment).rdd.collect()]

    def prepare_increments(self, spark, data):
        query_data = spark.createDataFrame(spark.sparkContext.parallelize([Row(**i) for i in data]))
        return [row.asDict() for row in prepare_increments(query_data).rdd.collect()]


