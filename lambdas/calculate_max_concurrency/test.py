from unittest import TestCase

from main import calculate_max_concurrency


class TestCalculateMaxConcurrency(TestCase):
    def test_calculate_max_concurrency(self):
        available_ips = 10
        ips_per_job = 2
        max_concurrency = calculate_max_concurrency(available_ips, ips_per_job)
        assert max_concurrency == 8
