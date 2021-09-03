from unittest.case import TestCase
import pytest

def assertDictionaryContains(expected, actual):
    TestCase().assertEqual(actual, { **actual,  **expected})

class DummyLogger:
    def info(self, message):
        return