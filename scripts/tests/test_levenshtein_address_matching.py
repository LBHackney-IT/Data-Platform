import logging
import os
import unittest
from logging import Logger

from pyspark.sql import SparkSession

from scripts.jobs.levenshtein_address_matching import prep_source_data, prep_addresses_api_data, match_addresses


class AddressMatchingTests(unittest.TestCase):
    spark: SparkSession = None
    logger: Logger = None
    root_path = os.path.realpath(os.path.join(os.path.dirname(__file__), '..'))
    base_path_data = os.path.join(root_path, "tests", "test_data", "levenshtein_address_matching")
    source_data_path = os.path.join(base_path_data, "source")
    addresses_data_path = os.path.join(base_path_data, "addresses")

    @classmethod
    def setUpClass(cls) -> None:
        cls.spark = SparkSession \
            .builder \
            .config("spark.sql.debug.maxToStringFields", "10000") \
            .config("spark.sql.parquet.int96RebaseModeInRead", "LEGACY") \
            .config("spark.sql.parquet.int96RebaseModeInWrite", "LEGACY") \
            .master("local[*]") \
            .appName("AddressMatchingTests") \
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
        source_raw = self.spark.read.option("header", "true").csv(self.source_data_path)
        source = prep_source_data(source_raw)
        expected_columns = ["prinx", "query_address", "query_postcode"]
        actual_columns = source.columns
        self.assertCountEqual(actual_columns, expected_columns)

    def test_prep_addresses_api_data(self):
        addresses_raw = self.spark.read.option("header", "true").csv(self.addresses_data_path)
        addresses = prep_addresses_api_data(addresses_raw, match_to_property_shell="")
        expected_columns = ["target_address", "target_address_short", "target_address_medium", "uprn", "blpu_class",
                            "target_postcode"]
        actual_columns = addresses.columns
        self.assertCountEqual(actual_columns, expected_columns)
        self.assertEqual(addresses.count(), addresses_raw.count())

    def test_match_addresses(self):
        source_raw = self.spark.read.option("header", "true").csv(self.source_data_path)
        source = prep_source_data(source_raw)
        addresses_raw = self.spark \
            .read.option("header", "true").csv(self.addresses_data_path)
        addresses = prep_addresses_api_data(addresses_raw, match_to_property_shell="")
        actual = match_addresses(source, addresses, self.logger)
        self.assertEqual(actual.count(), 2)

    def test_small_data_perfect_matches(self):
        source_address = self.spark.createDataFrame([
            (14, "4 LEASIDE HOUSE E5 9HJ", "E5 9HJ"),
            (15, "53 GRANVILLE COURT N1 5SP", "N1 5SP")], schema=["prinx", "query_address", "query_postcode"])

        target_address = self.spark.createDataFrame([
            ("4 LEASIDE HOUSE E5 9HJ", "4 LEASIDE HOUSE E5 9HJ", "4 LEASIDE HOUSE E5 9HJ", "E5 9HJ", "RD",
             "100023006986"),
            ("45 LEASIDE HOUSE E5 9HJ", "45 LEASIDE HOUSE E5 9HJ", "45 LEASIDE HOUSE E5 9HJ", "E5 9HJ", "RD",
             "2222222222"),
            ("4 LEASIDE HOUSE E5 9HZ", "4 LEASIDE HOUSE E5 9HZ", "4 LEASIDE HOUSE E5 9HZ", "E5 9HZ", "RD",
             "3333333333"),
            ("53 GRANVILLE COURT DE BEAUVOIR ESTATE N1 5SP", "53 GRANVILLE COURT N1 5SP",
             "53 GRANVILLE COURT DE BEAUVOIR ESTATE N1 5SP", "N1 5SP", "RD", "10008223722"),
            ("FLAT 53 GRANVILLE COURT DE BEAUVOIR ESTATE N1 5SP", "FLAT 53 N1 5SP", "FLAT 53 GRANVILLE COURT N1 5SP",
             "N1 5SP", "RD", "10008223722"),
            ("5 GRANVILLE COURT DE BEAUVOIR ESTATE N1 5SP", "5 GRANVILLE COURT N1 5SP",
             "5 GRANVILLE COURT DE BEAUVOIR ESTATE N1 5SP", "N1 5SP", "RD", "3333333333")
        ], schema=["target_address", "target_address_short", "target_address_medium", "target_postcode", "blpu_class",
                   "uprn"])

        actual_df = match_addresses(source_address, target_address, self.logger)
        actual = [row.asDict() for row in actual_df.collect()]  # Converts dataframe into list of dict
        expected = [
            {"prinx": 14, "query_address": "4 LEASIDE HOUSE E5 9HJ", "matched_uprn": "100023006986",
             "matched_address": "4 LEASIDE HOUSE E5 9HJ", "matched_blpu_class": "RD", "match_type": "perfect",
             "round": "round 0"},
            {"prinx": 15, "query_address": "53 GRANVILLE COURT N1 5SP", "matched_uprn": "10008223722",
             "matched_address": "53 GRANVILLE COURT DE BEAUVOIR ESTATE N1 5SP", "matched_blpu_class": "RD",
             "match_type": "perfect on first line and postcode", "round": "round 0"},
        ]
        self.assertListEqual(actual, expected)
