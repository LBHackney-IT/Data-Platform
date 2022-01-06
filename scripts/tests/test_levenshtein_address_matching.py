from jobs.levenshtein_address_matching import match_addresses, round_0
from tests.helpers import assertions, dummy_logger
from pyspark.sql import Row

class TestAddressMatching:

  
    def test_exact_match_gets_matched(self, spark):
        response = self.addresses_get_matched(spark, [
                {'prinx': 14, 'query_address': '4 LEASIDE HOUSE E5 9HJ', 'query_postcode': 'E5 9HJ'}
            ],
            [
                {'target_address': '4 LEASIDE HOUSE E5 9HJ', 'target_address_short': '4 LEASIDE HOUSE E5 9HJ', 'target_address_medium': '4 LEASIDE HOUSE E5 9HJ', 'target_postcode': 'E5 9HJ', 'blpu_class': 'RD', 'uprn': '100023006986'},
                {'target_address': '45 LEASIDE HOUSE E5 9HJ', 'target_address_short': '45 LEASIDE HOUSE E5 9HJ', 'target_address_medium': '45 LEASIDE HOUSE E5 9HJ', 'target_postcode': 'E5 9HJ', 'blpu_class': 'RD', 'uprn': '2222222222'},
                {'target_address': '4 LEASIDE HOUSE E5 9HZ', 'target_address_short': '4 LEASIDE HOUSE E5 9HZ', 'target_address_medium': '4 LEASIDE HOUSE E5 9HZ', 'target_postcode': 'E5 9HZ', 'blpu_class': 'RD', 'uprn': '3333333333'}
            ])
        assertions.dictionaryContains({'matched_uprn': '100023006986'}, response[0])

        # If I wanted to describe the full output, not just one field, I would do:
        # assert (
        #     [
        #         {'matched_uprn': '100023006986'}
        #     ]
        #     ==
        #     self.addresses_get_matched(spark, [
        #         {'prinx': 14, 'query_address': '4 LEASIDE HOUSE E5 9HJ', 'query_postcode': 'E5 9HJ'}
        #     ],
        #     [
        #         {'target_address': '4 LEASIDE HOUSE E5 9HJ', 'target_address_short': '4 LEASIDE HOUSE E5 9HJ', 'target_address_medium': '4 LEASIDE HOUSE E5 9HJ', 'target_postcode': 'E5 9HJ', 'blpu_class': 'RD', 'uprn': '100023006986'},
        #         {'target_address': '45 LEASIDE HOUSE E5 9HJ', 'target_address_short': '45 LEASIDE HOUSE E5 9HJ', 'target_address_medium': '45 LEASIDE HOUSE E5 9HJ', 'target_postcode': 'E5 9HJ', 'blpu_class': 'RD', 'uprn': '2222222222'},
        #         {'target_address': '4 LEASIDE HOUSE E5 9HZ', 'target_address_short': '4 LEASIDE HOUSE E5 9HZ', 'target_address_medium': '4 LEASIDE HOUSE E5 9HZ', 'target_postcode': 'E5 9HZ', 'blpu_class': 'RD', 'uprn': '3333333333'}
        #     ])
        # )

    def test_address_with_missing_estate_name_gets_matched(self, spark):
        response = self.addresses_get_matched(spark, [
                {'prinx': 15, 'query_address': '53 GRANVILLE COURT N1 5SP', 'query_postcode': 'N1 5SP'}
            ],
            [
                {'target_address': '4 LEASIDE HOUSE E5 9HJ', 'target_address_short': '4 LEASIDE HOUSE E5 9HJ', 'target_address_medium': '4 LEASIDE HOUSE E5 9HJ', 'target_postcode': 'E5 9HJ', 'blpu_class': 'RD', 'uprn': '100023006986'},
                {'target_address': '53 GRANVILLE COURT DE BEAUVOIR ESTATE N1 5SP', 'target_address_short': '53 GRANVILLE COURT N1 5SP', 'target_address_medium': '53 GRANVILLE COURT DE BEAUVOIR ESTATE N1 5SP', 'target_postcode': 'N1 5SP', 'blpu_class': 'RD', 'uprn': '10008223722'},
                {'target_address': 'FLAT 53 GRANVILLE COURT DE BEAUVOIR ESTATE N1 5SP', 'target_address_short': 'FLAT 53 N1 5SP', 'target_address_medium': 'FLAT 53 GRANVILLE COURT N1 5SP', 'target_postcode': 'N1 5SP', 'blpu_class': 'RD', 'uprn': '10008223722'},
                {'target_address': '5 GRANVILLE COURT DE BEAUVOIR ESTATE N1 5SP', 'target_address_short': '5 GRANVILLE COURT N1 5SP', 'target_address_medium': '5 GRANVILLE COURT DE BEAUVOIR ESTATE N1 5SP', 'target_postcode': 'N1 5SP', 'blpu_class': 'RD', 'uprn': '3333333333'},

            ])
        assertions.dictionaryContains({'matched_uprn': '10008223722'}, response[0])

    # def addresses_get_matched(self, spark, query_address, target_address):
    #     logger = dummy_logger.Logger()
    #     query_add = spark.createDataFrame(spark.sparkContext.parallelize([Row(**i) for i in query_address]))
    #     target_add = spark.createDataFrame(spark.sparkContext.parallelize([Row(**i) for i in target_address]))
    #     return [row.asDict() for row in match_addresses(query_add, target_add, logger).rdd.collect()]

    def addresses_get_matched(self, spark, query_address, target_address):
        logger = dummy_logger.Logger()
        query_add = spark.createDataFrame(spark.sparkContext.parallelize([Row(**i) for i in query_address]))
        target_add = spark.createDataFrame(spark.sparkContext.parallelize([Row(**i) for i in target_address]))
        return [row.asDict() for row in round_0(query_add, target_add, logger).rdd.collect()]
        