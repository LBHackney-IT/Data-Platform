from unittest import TestCase
import botocore.session
from botocore.stub import Stubber

from scripts.helpers.helpers import get_s3_subfolders


generic_list_objects_response_keys = {
  'Contents': [],
  'Name': 'string',
  'Prefix': 'string',
  'Delimiter': 'string',
  'MaxKeys': 2,
  'EncodingType': 'url',
  'KeyCount': 2,
  'ContinuationToken': 'string',
  'StartAfter': 'string'
}

class GetS3SubfoldersTest(TestCase):

  def setUp(self) -> None:
    self.boto_session = botocore.session.get_session()
    self.boto_session.set_credentials("", "")
    self.s3 = self.boto_session.create_client('s3')
    self.stubber = Stubber(self.s3)
    return super().setUp()

  def set_up_list_objects_stub(self, expected_params, specific_response):
    response = {
      **generic_list_objects_response_keys,
      **specific_response
    }
    self.stubber.add_response('list_objects_v2', response, { **expected_params, 'Delimiter': '/'})

  def test_empty_directory(self):
    self.set_up_list_objects_stub(
      {
        'Bucket': 'test-bucket',
        'Prefix': 'DNONOSOANDONAODN'
      },
      {
        'IsTruncated': False,
      }
    )

    self.assertEqual(self.get_s3_subfolders('test-bucket', 'DNONOSOANDONAODN'), set([]))

  def test_one_subfolder(self):
    self.set_up_list_objects_stub(
      {
        'Bucket': 'test-bucket',
        'Prefix': 'DNONOSOANDONAODN'
      },
      {
        'IsTruncated': False,
        'CommonPrefixes': [{
            'Prefix': 'mysubfolder-luna'
        }]
      }
    )
    self.assertEqual(self.get_s3_subfolders('test-bucket', 'DNONOSOANDONAODN'), set(['mysubfolder-luna']))

  def test_lots_of_keys(self):
    self.set_up_list_objects_stub(
      {
        'Bucket': 'test-bucket',
        'Prefix': 'DNONOSOANDONAODN'
      },
      {
        'IsTruncated': True,
        'CommonPrefixes': [{
            'Prefix': 'mysubfolder-luna'
        }],
        'NextContinuationToken': 'asd'
      }
    )
    self.set_up_list_objects_stub(
      {
        'Bucket': 'test-bucket',
        'Prefix': 'DNONOSOANDONAODN',
        'ContinuationToken': 'asd'
      },
      {
        'IsTruncated': False,
        'CommonPrefixes': [{
            'Prefix': 'mysubfolder-barry'
        }]
      }
    )
    self.assertEqual(self.get_s3_subfolders('test-bucket', 'DNONOSOANDONAODN'), set(['mysubfolder-luna', 'mysubfolder-barry']))


  def test_multiple_objects_with_the_same_common_prefix(self):
    self.set_up_list_objects_stub(
      {
        'Bucket': 'raw-zone-bucket',
        'Prefix': 'parking'
      },
      {
        'IsTruncated': True,
        'CommonPrefixes': [{
            'Prefix': 'mysubfolder-luna'
        }],
        'NextContinuationToken': 'asd'
      }
    )
    self.set_up_list_objects_stub(
      {
        'Bucket': 'raw-zone-bucket',
        'Prefix': 'parking',
        'ContinuationToken': 'asd'
      },
      {
        'IsTruncated': False,
        'CommonPrefixes': [{
            'Prefix': 'mysubfolder-luna'
        }]
      }
    )
    self.assertEqual(self.get_s3_subfolders('raw-zone-bucket', 'parking'), set(['mysubfolder-luna']))

  def get_s3_subfolders(self, *args):
    self.stubber.activate()
    return get_s3_subfolders(self.s3, *args)
