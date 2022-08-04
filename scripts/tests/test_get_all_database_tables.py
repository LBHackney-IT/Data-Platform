from unittest import TestCase
import botocore.session
from botocore.stub import Stubber
from unittest.mock import Mock

from scripts.helpers.database_ingestion_helpers import get_all_database_tables, get_filtered_tables


generic_get_tables_response_keys = {
    "TableList": [],
}

class GetDatabaseTablesTest(TestCase):
  def setUp(self) -> None:
    self.boto_session = botocore.session.get_session()
    self.boto_session.set_credentials("", "")
    self.glue = self.boto_session.create_client('glue', region_name='eu-west-2')
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

    self.assertEqual(self.get_all_database_tables('test-db'), ['my-test-table'])


  def test_glue_gets_all_tables_from_catalog_database_when_response_is_paginated(self):
      self.set_up_get_database_tables_stub(
        {
          'DatabaseName': 'test-db',
        },
        {
          'NextToken': 'token',
          'TableList': [
            {
              'Name': 'my-test-table'
            }
          ]
        }
      )

      self.set_up_get_database_tables_stub(
        {
          'DatabaseName': 'test-db',
          'NextToken': 'token'
        },
        {
          'TableList': [
            {
              'Name': 'my-test-table-2'
            }
          ]
        }
      )

      self.assertEqual(self.get_all_database_tables('test-db'), ['my-test-table', 'my-test-table-2'])


  def test_get_all_database_tables_calls_get_filtered_tables_with_filtered_tables_expression(self):
      table_filter_expression = 'my-test-table-1'

      self.set_up_test_database_tables_stub_response()

      filtered_tables_mock = Mock()
      self.get_all_database_tables('test-db', table_filter_expression)
      filtered_tables_mock(['my-test-table-1', 'my-test-table-2', 'my-test-table-3'], table_filter_expression)

      filtered_tables_mock.assert_called_once_with(['my-test-table-1', 'my-test-table-2', 'my-test-table-3'], 'my-test-table-1')

  def test_get_all_database_tables_gets_filtered_tables_given_filtered_tables_expression(self):
      table_filter_expression = 'my-test-table-1'

      self.set_up_test_database_tables_stub_response()

      self.assertEqual(self.get_all_database_tables('test-db', table_filter_expression), ['my-test-table-1'])

  def test_get_all_database_tables_gets_different_filtered_tables_given_filtered_tables_expression(self):
      table_filter_expression = 'my-test-table-2'

      self.set_up_test_database_tables_stub_response()

      self.assertEqual(self.get_all_database_tables('test-db', table_filter_expression), ['my-test-table-2'])

  def test_get_filtered_tables_returns_list_of_one_filtered_table(self):
      table_filter_expression = 'my-test-table-2'

      tables_to_filter = ['my-test-table-1', 'my-test-table-2', 'my-test-table-3']
      filtered_tables = get_filtered_tables(tables_to_filter, table_filter_expression)

      self.assertEqual(filtered_tables, ['my-test-table-2'])

  def test_get_filtered_tables_returns_list_of_multiple_filtered_tables(self):
      table_filter_expression = '^my-test-table.*'

      tables_to_filter = ['my-test-table-1', 'my-test-table-2', 'my-test-table-3', 'another-test-table', 'random-table']
      filtered_tables = get_filtered_tables(tables_to_filter, table_filter_expression)

      self.assertEqual(filtered_tables, ['my-test-table-1', 'my-test-table-2', 'my-test-table-3'])


  def get_all_database_tables(self, *args):
    self.stubber.activate()
    return get_all_database_tables(self.glue, *args)

  def set_up_test_database_tables_stub_response(self):
    return self.set_up_get_database_tables_stub(
      {
        'DatabaseName': 'test-db',
      },
      {
        'TableList': [
        {
          'Name': 'my-test-table-1'
        },
        {
          'Name': 'my-test-table-2'
        },
        {
          'Name': 'my-test-table-3'
        }
      ]
    }
  )

