from scripts.jobs.recast_tables import castColumns, castColumnsAllTypes
from pyspark.sql import Row
from pyspark.sql.types import TimestampType, IntegerType, BooleanType, FloatType, LongType, DoubleType, DateType
from datetime import datetime, date
import os

class TestRecastTables:

    column_type_dictionary_path =  os.path.dirname(__file__) + "/stubs/column_type_dictionary.json"
    column_type_dictionary_partial_path =  os.path.dirname(__file__) + "/stubs/column_type_dictionary_partial.json"
    def test_castColumns_timestamp(self, spark):
        input_data = [{'submit_date': '2021-09-24 08:58:47'}]
        expected = [{'submit_date': datetime(2021, 9, 24, 8, 58, 47)}]
        response = self.castColumns(spark, self.column_type_dictionary_path , "MyTable", input_data, "timestamp", TimestampType())
        assert (response == expected)
  
    def test_castColumns_integer(self, spark):
        input_data = [{'id_number': '12'}]
        expected = [{'id_number': 12}]
        response = self.castColumns(spark, self.column_type_dictionary_path, "MyTable", input_data, "integer", IntegerType())
        assert (response == expected)

    def test_castColumns_boolean(self, spark):
        input_data = [{'flag': 'f'},{'flag': 't'}]
        expected = [{'flag': False},{'flag': True}]
        response = self.castColumns(spark,self.column_type_dictionary_path, "MyTable", input_data, "boolean", BooleanType())
        assert (response == expected)

    # Comparison of floats not doable with assert, hence the small precision 91.0 in this test
    def test_castColumns_float(self, spark):
        input_data = [{'measurement': '91.0'}]
        expected = [{'measurement': 91.0}]
        response = self.castColumns(spark, self.column_type_dictionary_path, "MyTable", input_data, "float", FloatType())
        assert (response == expected)

    def test_castColumns_double(self, spark):
        input_data = [{'large_measurement': '91.535554'}]
        expected = [{'large_measurement': 91.535554}]
        response = self.castColumns(spark,self.column_type_dictionary_path, "MyTable", input_data, "double", DoubleType())
        assert (response == expected)

    def test_castColumns_long(self, spark):
        input_data = [{'long_id': '9157952949254835554'}]
        expected = [{'long_id': 9157952949254835554}]
        response = self.castColumns(spark, self.column_type_dictionary_path, "MyTable", input_data, "long", LongType())
        assert (response == expected)

    def test_castColumns_date(self, spark):
        input_data = [{'start_date': '2021-09-24'}]
        response = self.castColumns(spark,self.column_type_dictionary_path, "MyTable", input_data, "date", DateType())
        expected = [{'start_date': date(2021, 9, 24)}]
        assert (response == expected)

    def test_castColumns_allTypes(self, spark):
        input_data = [{'submit_date': '2021-09-24 08:58:47', 'id_number': '12', 'flag': 'f', 'measurement': '91.0', 'large_measurement': '91.535554', 'long_id': '9157952949254835554', 'start_date': '2021-09-24'}]
        expected = [{'submit_date': datetime(2021, 9, 24, 8, 58, 47), 'id_number': 12, 'flag': False, 'measurement': 91.0, 'large_measurement': 91.535554, 'long_id': 9157952949254835554,'start_date': date(2021, 9, 24)}]
        response = self.castColumnsAllTypes(spark, self.column_type_dictionary_path, "MyTable", input_data)
        assert (response == expected)

    def test_castColumns_when_table_not_represented_in_dictionary(self, spark):
        input_data = [{'submit_date': '2021-09-24 08:58:47'}]
        expected = [{'submit_date': '2021-09-24 08:58:47'}]
        response = self.castColumnsAllTypes(spark, self.column_type_dictionary_path, "some_table_not_in_the_dictionary", input_data)
        assert (response == expected)

    def test_castColumns_when_all_datatypes_not_represented_in_dictionary(self, spark):
        input_data = [{'id_number': '12', 'flag': 'f', 'start_date': '2021-09-24'}]
        expected = [{'id_number': 12, 'flag': False,'start_date': '2021-09-24'}]
        response = self.castColumnsAllTypes(spark, self.column_type_dictionary_partial_path, "MyTable", input_data)
        assert (response == expected)


    def castColumns(self, spark, dictionaryPath, tableName, data, typeName, dataType):
        # The column dictionary is saved in JSON format in a separate file in this directory.
        # Then we are using the same code that is used in the script to access this file just with a relative path
        # instead of an S3 path.

        columnsDictionary = spark.read.option("multiline", "true").json(dictionaryPath).rdd.collect()[0]
        query_data = spark.createDataFrame(spark.sparkContext.parallelize([Row(**i) for i in data]))
        return [row.asDict() for row in castColumns(columnsDictionary, tableName, query_data, typeName, dataType).rdd.collect()]

    def castColumnsAllTypes(self, spark, dictionaryPath, tableName, data):
        # The column dictionary is saved in JSON format in a separate file in this directory.
        # Then we are using the same code that is used in the script to access this file just with a relative path
        # instead of an S3 path.
        columnsDictionary = spark.read.option("multiline", "true").json(dictionaryPath).rdd.collect()[0]
        query_data = spark.createDataFrame(spark.sparkContext.parallelize([Row(**i) for i in data]))
        return [row.asDict() for row in castColumnsAllTypes(columnsDictionary, tableName, query_data).rdd.collect()]

