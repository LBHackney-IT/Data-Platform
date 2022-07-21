import logging
import os

import pytest

from scripts.jobs.levenshtein_address_matching import prep_source_data, prep_addresses_api_data, match_addresses


@pytest.fixture
def logger():
    logging.basicConfig(
        format="%(asctime)s %(levelname)7s %(module)20s.%(lineno)3d: %(message)s",
        datefmt="%y/%m/%d %H:%M:%S",
        level=logging.INFO,
        handlers=[
            logging.StreamHandler()
        ])
    logger = logging.getLogger(__name__)
    logger.setLevel(logging.DEBUG)
    return logger


class TestsAddressMatching:
    root_path = os.path.realpath(os.path.join(os.path.dirname(__file__), '..'))
    base_path_data = os.path.join(root_path, "tests", "test_data", "levenshtein_address_matching")
    source_data_path = os.path.join(base_path_data, "source")
    addresses_data_path = os.path.join(base_path_data, "addresses")

    def test_prep_source_data(self, spark, logger):
        """Test case needs to be enhanced based on good test data set"""
        logger.info("starting test_prep_source_data")
        source_raw = spark.read.option("header", "true").csv(self.source_data_path)
        source = prep_source_data(source_raw)
        expected_columns = ["prinx", "query_address", "query_postcode"]
        actual_columns = source.columns
        assert actual_columns == expected_columns

    def test_prep_addresses_api_data(self, spark, logger):
        """Test case needs to be enhanced based on good test data set"""
        addresses_raw = spark.read.option("header", "true").csv(self.addresses_data_path)
        addresses = prep_addresses_api_data(addresses_raw, match_to_property_shell="")
        expected_columns = ["target_address", "target_address_short", "target_address_medium", "uprn", "blpu_class",
                            "target_postcode"]
        actual_columns = addresses.columns
        assert actual_columns == expected_columns
        assert addresses.count() == addresses_raw.count()

    def test_match_addresses(self, spark, logger):
        source_raw = spark.read.option("header", "true").csv(self.source_data_path)
        source = prep_source_data(source_raw)
        addresses_raw = spark.read.option("header", "true").csv(self.addresses_data_path)
        addresses = prep_addresses_api_data(addresses_raw, match_to_property_shell="")
        actual = match_addresses(source, addresses, logger)
        assert actual.count() == 2

    def test_small_data_perfect_matches(self, spark, logger):
        source_address = spark.createDataFrame([
            (14, "4 LEASIDE HOUSE E5 9HJ", "E5 9HJ"),
            (15, "53 GRANVILLE COURT N1 5SP", "N1 5SP")], schema=["prinx", "query_address", "query_postcode"])

        target_address = spark.createDataFrame([
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

        actual_df = match_addresses(source_address, target_address, logger)
        actual = [row.asDict() for row in actual_df.collect()]  # Converts dataframe into list of dict
        expected = [
            {"prinx": 14, "query_address": "4 LEASIDE HOUSE E5 9HJ", "matched_uprn": "100023006986",
             "matched_address": "4 LEASIDE HOUSE E5 9HJ", "matched_blpu_class": "RD", "match_type": "perfect",
             "round": "round 0"},
            {"prinx": 15, "query_address": "53 GRANVILLE COURT N1 5SP", "matched_uprn": "10008223722",
             "matched_address": "53 GRANVILLE COURT DE BEAUVOIR ESTATE N1 5SP", "matched_blpu_class": "RD",
             "match_type": "perfect on first line and postcode", "round": "round 0"},
        ]
        assert actual == expected
