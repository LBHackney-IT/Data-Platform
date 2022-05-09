import unittest
from datetime import datetime
from jobs.env_services.alloy_api_ingestion import format_time

class TestAlloyApiIngestion(unittest.TestCase):

    def test_format_time(self):
        date_time = datetime.datetime(2021,7,14)
        response = format_time(date_time)
        print(response)
        self.assertEqual(response, "2021-07-14T00:00:00.000Z")

if __name__ == '__main__':
    unittest.main()