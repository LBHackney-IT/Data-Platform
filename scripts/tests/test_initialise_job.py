import unittest
from unittest.mock import patch, MagicMock
from scripts.helpers.helpers import initialise_job


class TestInitialiseJob(unittest.TestCase):
    def setUp(self):
        self.mock_job = MagicMock()
        self.mock_logger = MagicMock()
        self.args_with_bookmark = {
            "JOB_NAME": "test_job",
            "BOOKMARK_CONTEXT": "test_context",
        }
        self.args_without_bookmark = {"JOB_NAME": "test_job"}

    def test_initialise_job_with_bookmark_context_and_logger(self):
        initialise_job(self.args_with_bookmark, self.mock_job, self.mock_logger)
        self.mock_job.init.assert_called_once_with(
            "test_job_test_context", self.args_with_bookmark
        )
        self.mock_logger.error.assert_not_called()

    def test_initialise_job_without_bookmark_context_and_logger(self):
        initialise_job(self.args_without_bookmark, self.mock_job, self.mock_logger)
        self.mock_job.init.assert_called_once_with(
            "test_job", self.args_without_bookmark
        )
        self.mock_logger.error.assert_not_called()

    def test_initialise_job_without_job_name_and_logger(self):
        with self.assertRaises(ValueError):
            initialise_job({}, self.mock_job, self.mock_logger)
        self.mock_logger.error.assert_called_once()

    @patch("scripts.helpers.helpers.logging")
    def test_initialise_job_with_initialisation_exception_and_default_logger(
        self, mock_logging
    ):
        self.mock_job.init.side_effect = Exception("Test Exception")
        with self.assertRaises(Exception):
            initialise_job(self.args_with_bookmark, self.mock_job)
        mock_logging.getLogger.assert_called_with("scripts.helpers.helpers")
        self.mock_job.init.assert_called_once()

    def test_initialise_job_with_initialisation_exception_and_custom_logger(self):
        self.mock_job.init.side_effect = Exception("Test Exception")
        with self.assertRaises(Exception):
            initialise_job(self.args_with_bookmark, self.mock_job, self.mock_logger)
        self.mock_logger.error.assert_called_with(
            "Failed to initialise job: Test Exception"
        )


if __name__ == "__main__":
    unittest.main()
