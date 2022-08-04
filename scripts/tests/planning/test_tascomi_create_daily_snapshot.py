from scripts.jobs.planning.tascomi_create_daily_snapshot import prepare_increments, apply_increments
from pyspark.sql import Row
from datetime import datetime, date


class TestSnapshotCreation:

    snapshotYear = str(datetime.now().year)
    snapshotMonth = str(datetime.now().month).zfill(2)
    snapshotDay = str(datetime.now().day).zfill(2)
    snapshotDate = snapshotYear + snapshotMonth + snapshotDay

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
        '''when applying several days increments containing several changes of the sane application, we should prepare the increment only keeping the latest version'''
        input_increment = [{'id': 1, 'application_stage': 5, 'last_updated': datetime(2021, 9, 24, 1, 0, 0)},{'id': 1, 'application_stage': 6, 'last_updated': datetime(2021, 9, 25, 0, 0, 0)}]
        expected = [{'id': 1, 'application_stage': 6, 'last_updated': datetime(2021, 9, 25, 0, 0, 0)}]
        response = self.prepare_increments(spark, input_increment)
        assert (response == expected)

    def test_prepare_several_records_increments(self, spark):
        '''when applying several days increments containing several applications, we should prepare the increment keeping one record per application'''
        input_increment = [{'id': 1, 'application_stage': 5, 'last_updated': datetime(2021, 9, 24, 0, 0, 0)},{'id': 2, 'application_stage': 5, 'last_updated': datetime(2021, 9, 25, 0, 0, 0)}]
        expected = [{'id': 1, 'application_stage': 5, 'last_updated': datetime(2021, 9, 24, 0, 0, 0)},{'id': 2, 'application_stage': 5, 'last_updated': datetime(2021, 9, 25, 0, 0, 0)}]
        response = self.prepare_increments(spark, input_increment)
        assert (response == expected)
  
  
    def apply_increments(self, spark, input_snapshot, input_increment):
        query_data_snapshot = spark.createDataFrame(spark.sparkContext.parallelize([Row(**i) for i in input_snapshot]))
        query_data_increment = spark.createDataFrame(spark.sparkContext.parallelize([Row(**i) for i in input_increment]))
        return [row.asDict() for row in apply_increments(query_data_snapshot, query_data_increment).rdd.collect()]

    def prepare_increments(self, spark, data):
        query_data = spark.createDataFrame(spark.sparkContext.parallelize([Row(**i) for i in data]))
        return [row.asDict() for row in prepare_increments(query_data).rdd.collect()]


