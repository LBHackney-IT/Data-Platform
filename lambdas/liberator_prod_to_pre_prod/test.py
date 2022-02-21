from unittest import TestCase
import botocore.session
from botocore.stub import Stubber

from liberator_prod_to_pre_prod.main import lambda_handler
from datetime import datetime
import os


class GetS3SubfoldersTest(TestCase):
  def setUp(self) -> None:
    self.boto_session = botocore.session.get_session()
    self.boto_session.set_credentials("", "")
    self.s3 = self.boto_session.create_client('s3')
    self.stubber = Stubber(self.s3)
    return super().setUp()

  def set_up_copy_object_stub(self, expected_params):
    response = {
        'CopyObjectResult': {
            'ETag': 'string',
            'LastModified': datetime(2015, 1, 1)
        }
    }
    self.stubber.add_response('copy_object', response, expected_params)
    self.stubber.activate()

  def test_copies_correct_object(self):
    self.set_up_copy_object_stub(
      {
        'Bucket': 'test-bucket',
        'Key': 'my-things/some-folder/maybe-another/the-best-file.txt',
        'CopySource': {
            'Bucket': 'source-bucket',
            'Key': 'some-folder/maybe-another/the-best-file.txt'
        }
      }
    )

    os.environ["TARGET_BUCKET_ID"] = "test-bucket"
    os.environ["TARGET_PREFIX"] = "my-things"

    event = {
      "detail": {
        "resources": [
            {
                "type": "AWS::S3::Object",
                "ARN": "arn:aws:s3:::source-bucket/some-folder/maybe-another/the-best-file.txt"
            },
            {
                "accountId": "494163742216",
                "type": "AWS::S3::Bucket",
                "ARN": "arn:aws:s3:::source-bucket"
            }
        ]
      }
    }

    self.assertEqual(lambda_handler(event, {}, self.s3), None)
