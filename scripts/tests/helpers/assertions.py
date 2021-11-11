from unittest.case import TestCase

def dictionaryContains(expected, actual):
    TestCase().assertEqual(actual, { **actual,  **expected})