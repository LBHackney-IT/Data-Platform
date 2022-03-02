from unittest import TestCase
import botocore.session
from botocore.stub import Stubber

from helpers.database_ingestion_helpers import get_all_database_tables


generic_get_tables_response_keys = {
    "TableList": [],
    "NextToken": "string"
}

class GetDatabaseTablesTest(TestCase):
  def setUp(self) -> None:
    self.boto_session = botocore.session.get_session()
    self.boto_session.set_credentials("", "")
    self.glue = self.boto_session.create_client('glue')
    self.stubber = Stubber(self.glue)
    return super().setUp()

  def set_up_get_database_tables_stub(self, expected_params, specific_response):
    response = {
      **generic_get_tables_response_keys,
      **specific_response
    }

    self.stubber.add_response('get_tables', response, { **expected_params })

  def test_glue_gets_one_table_from_catalog_database(self):
    self.set_up_get_database_tables_stub(
      {
        'DatabaseName': 'test-db',
      },
      {
        'TableList': [
          {
            'Name': 'my-test-table'
          }
        ]
      }
    )

    self.assertEqual(self.get_all_database_tables('test-db'), set(['my-test-table']))


  def get_all_database_tables(self, *args):
    self.stubber.activate()
    return get_all_database_tables(self.s3, *args)

#     assert table == expected_response

