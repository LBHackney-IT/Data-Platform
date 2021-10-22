from recast_tables import castColumns, castColumnsAllTypes
from pyspark.sql import Row
from pyspark.sql.types import TimestampType, IntegerType, BooleanType, FloatType, LongType, DoubleType, DateType
from datetime import datetime, date

class TestRecastTables:
  
    def test_castColumns_timestamp(self, spark):
        response = self.castColumns(spark, [{'submit_date': '2021-09-24 08:58:47'}], "timestamp", TimestampType())
        expected = [{'submit_date': datetime(2021, 9, 24, 8, 58, 47)}]
        assert (response == expected)
  
    def test_castColumns_integer(self, spark):
        response = self.castColumns(spark, [{'id_number': '12'}], "integer", IntegerType())
        expected = [{'id_number': 12}]
        assert (response == expected)

    def test_castColumns_boolean(self, spark):
        response = self.castColumns(spark, [{'flag': 'f'},{'flag': 't'}], "boolean", BooleanType())
        expected = [{'flag': False},{'flag': True}]
        assert (response == expected)

    # Comparison of floats not doable with assert, hence the small precision 91.0 in this test
    def test_castColumns_float(self, spark):
        response = self.castColumns(spark, [{'measurement': '91.0'}], "float", FloatType())
        expected = [{'measurement': 91.0}]
        assert (response == expected)

    def test_castColumns_double(self, spark):
        response = self.castColumns(spark, [{'large_measurement': '91.535554'}], "double", DoubleType())
        expected = [{'large_measurement': 91.535554}]
        assert (response == expected)


    def test_castColumns_long(self, spark):
        response = self.castColumns(spark, [{'long_id': '9157952949254835554'}], "long", LongType())
        expected = [{'long_id': 9157952949254835554}]
        assert (response == expected)

    def test_castColumns_date(self, spark):
        response = self.castColumns(spark, [{'start_date': '2021-09-24'}], "date", DateType())
        expected = [{'start_date': date(2021, 9, 24)}]
        assert (response == expected)

    def test_castColumns_allTypes(self, spark):
        response = self.castColumnsAllTypes(spark, [{'submit_date': '2021-09-24 08:58:47', 'id_number': '12', 'flag': 'f', 'measurement': '91.0', 'large_measurement': '91.535554', 'long_id': '9157952949254835554', 'start_date': '2021-09-24'}])
        expected = [{'submit_date': datetime(2021, 9, 24, 8, 58, 47), 'id_number': 12, 'flag': False, 'measurement': 91.0, 'large_measurement': 91.535554, 'long_id': 9157952949254835554,'start_date': date(2021, 9, 24)}]
        assert (response == expected)

    def castColumns(self, spark, data, typeName, dataType):
        # The column dictionary is saved in JSON format in a separate file in this directory.
        # Then we are using the same code that is used in the script to access this file just with a relative path
        # instead of an S3 path.

        columnsDictionary = spark.read.option("multiline", "true").json("./stub_column_type_dictionary.json")
        query_data = spark.createDataFrame(spark.sparkContext.parallelize([Row(**i) for i in data]))
        return [row.asDict() for row in castColumns(columnsDictionary, "MyTable", query_data, typeName, dataType).rdd.collect()]

    def castColumnsAllTypes(self, spark, data):
        # The column dictionary is saved in JSON format in a separate file in this directory.
        # Then we are using the same code that is used in the script to access this file just with a relative path
        # instead of an S3 path.
        columnsDictionary = spark.read.option("multiline", "true").json("./stub_column_type_dictionary.json")
        query_data = spark.createDataFrame(spark.sparkContext.parallelize([Row(**i) for i in data]))
        return [row.asDict() for row in castColumnsAllTypes(columnsDictionary, "MyTable", query_data).rdd.collect()]