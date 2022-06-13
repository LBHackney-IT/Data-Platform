import logging
import unittest
from logging import Logger

from pyspark.sql import SparkSession

from scripts.jobs.gb_levenshtein_address_matching import prep_source_data, prep_addresses_api_data, match_addresses_gb


class AddressMatchingTests(unittest.TestCase):
    spark: SparkSession = None
    logger: Logger = None

    @classmethod
    def setUpClass(cls) -> None:
        cls.spark = SparkSession \
            .builder \
            .config("spark.sql.debug.maxToStringFields", "10000") \
            .config("spark.sql.parquet.int96RebaseModeInRead", "LEGACY") \
            .config("spark.sql.parquet.int96RebaseModeInWrite", "LEGACY") \
            .master("local[*]") \
            .appName("SparkLocal") \
            .getOrCreate()

        logging.basicConfig(
            format="%(asctime)s %(levelname)7s %(module)20s.%(lineno)3d: %(message)s",
            datefmt="%y/%m/%d %H:%M:%S",
            level=logging.INFO,
            handlers=[
                logging.StreamHandler()
            ])
        cls.logger = logging.getLogger(__name__)
        cls.logger.setLevel(logging.DEBUG)

    @classmethod
    def tearDownClass(cls) -> None:
        cls.spark.stop()

    def test_prep_source_data(self):
        source_raw = self.spark.read.option("header", "true").csv("test_data/levenshtein_address_matching/source/")
        source = prep_source_data(source_raw)
        expected_columns = ["prinx", "query_address", "query_postcode"]
        actual_columns = source.columns
        self.assertCountEqual(actual_columns, expected_columns)

    def test_prep_addresses_api_data(self):
        addresses_raw = self.spark \
            .read.option("header", "true").csv("test_data/levenshtein_address_matching/addresses/")
        addresses = prep_addresses_api_data(addresses_raw, match_to_property_shell="")
        expected_columns = ["target_address", "target_address_short", "target_address_medium", "uprn", "blpu_class",
                            "target_postcode"]
        actual_columns = addresses.columns
        self.assertCountEqual(actual_columns, expected_columns)
        self.assertEqual(addresses.count(), addresses_raw.count())

    def test_match_addresses(self):
        source_raw = self.spark.read.option("header", "true").csv("test_data/levenshtein_address_matching/source/")
        source = prep_source_data(source_raw)
        addresses_raw = self.spark \
            .read.option("header", "true").csv("test_data/levenshtein_address_matching/addresses/")
        addresses = prep_addresses_api_data(addresses_raw, match_to_property_shell="")
        actual = match_addresses_gb(source, addresses, self.logger)
        actual.show(truncate=False)
        self.assertEqual(actual.count(), 2)
