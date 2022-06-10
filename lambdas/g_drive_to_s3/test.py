from unittest import TestCase
import os
import json
import botocore.session
from botocore.stub import Stubber
from g_drive_to_s3.main import file_changed
from datetime import datetime
from googleapiclient.discovery import build
from googleapiclient.http import HttpMock


class GDriveToS3(TestCase):
  def setUp(self) -> None:
    self.boto_session = botocore.session.get_session()
    self.boto_session.set_credentials("", "")
    self.s3 = self.boto_session.create_client('s3')
    self.stubber = Stubber(self.s3)
    self.google_responses_dir = os.path.join(os.path.dirname(__file__), "google_api_mock_responses")
    return super().setUp()

  def tearDown(self) -> None:
    try:
      os.remove(os.path.join(self.google_responses_dir, "get_file.json"))
    except:
      pass
    return super().tearDown()

  def set_up_get_object_s3_stub(self, bucket_name, key, last_modified_date):
    response = {
      'ETag': 'string',
      'LastModified': datetime.fromisoformat(last_modified_date)
    }
    self.stubber.add_response('get_object', response, {
      'Bucket': bucket_name,
      'Key': key
    })
    self.stubber.activate()
  
  def setup_get_file_from_drive_stub(self, file_id, date_created, date_modifed = None):
    get_file_response = {
      'id': file_id,
      'createdTime': date_created
    }
    if date_modifed:
      get_file_response['modifiedTime'] = date_modifed

    response_file = open(f'{os.path.join(self.google_responses_dir, "get_file.json")}', "w")
    json.dump(get_file_response, response_file, indent="")
    response_file.close()

    http = HttpMock(f'{os.path.join(self.google_responses_dir, "drive.json")}', {'status': '200'})
    service = build('drive', 'v3',
                http=http,
                developerKey='your_api_key')
    http = HttpMock(f'{os.path.join(self.google_responses_dir, "get_file.json")}', {'status': '200'})
    return (service, http)

  def test_file_changed_returns_true_if_file_does_not_exist_in_s3(self):
    bucket_name = "my-fave-bucket"
    key = "groovy-spreadsheet.csv"

    self.stubber.add_client_error('get_object',
      service_error_code='NoSuchKey',
      service_message='The specified key does not exist.',
      expected_params={
        'Bucket': bucket_name,
        'Key': key,
      }
    )
    self.stubber.activate()

    response = file_changed(self.s3, None, bucket_name, key, None)

    self.assertTrue(response)

  def test_file_changed_returns_false_if_file_gdrive_modified_time_earlier_then_s3_timestamp(self):
    bucket_name = "my-fave-bucket"
    key = "groovy-spreadsheet.csv"
    file_id = "FHRUWHFUW387GFEWUI36"

    self.set_up_get_object_s3_stub(bucket_name, key, "2022-03-15 01:19:41+00:00")
    drive_service, http_mock = self.setup_get_file_from_drive_stub(file_id, "2022-02-14T15:19:41.433Z", "2022-03-14T15:19:41.433Z")

    response = file_changed(self.s3, drive_service, bucket_name, key, file_id, http_mock)

    self.assertFalse(response)

  def test_file_changed_returns_false_if_file_gdrive_created_time_earlier_then_s3_timestamp(self):
    bucket_name = "my-fave-bucket"
    key = "groovy-spreadsheet.csv"
    file_id = "FHRUWHFUW387GFEWUI36"

    self.set_up_get_object_s3_stub(bucket_name, key, "2022-03-15 01:19:41+00:00")
    drive_service, http_mock = self.setup_get_file_from_drive_stub(file_id, "2022-03-14T15:19:41.433Z")

    response = file_changed(self.s3, drive_service, bucket_name, key, file_id, http_mock)

    self.assertFalse(response)

  def test_file_changed_returns_true_if_gdrive_file_modifed_after_s3_last_modified(self):
    bucket_name = "my-fave-bucket"
    key = "groovy-spreadsheet.csv"
    file_id = "FHRUWHFUW387GFEWUI36"

    self.set_up_get_object_s3_stub(bucket_name, key, "2022-03-15 11:20:27+00:00")
    drive_service, http_mock = self.setup_get_file_from_drive_stub(file_id, "2022-03-14T15:19:41.433Z", "2022-03-16T15:19:41.433Z")

    response = file_changed(self.s3, drive_service, bucket_name, key, file_id, http_mock)

    self.assertTrue(response)
    