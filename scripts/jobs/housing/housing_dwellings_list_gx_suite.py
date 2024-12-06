# flake8: noqa: F821

import sys

from awsglue.utils import getResolvedOptions
import great_expectations as gx
import great_expectations.expectations as gxe

class ExpectLLPGColumnValuesToBeUnique(gxe.ExpectColumnValuesToBeUnique):
    column: str = 'llpg'
    description: str = "Expect UPRN (LLPG) values to be unique"


class ExpectLLPGAndPropRefColumnValuesToBeUniqueWithinRecord(gxe.ExpectSelectColumnValuesToBeUniqueWithinRecord):
    column_list: list = ['llpg', 'property_dwelling_reference_number']
    description: str = "Expect LLPG and and Property Reference fields to be unique for a record"


class ExpectLLPGColumnValuesToNotBeNull(gxe.ExpectColumnValuesToNotBeNull):
    column: str = 'llpg'
    description: str = "Expect LLPG column to be complete with no nulls"


class ExpectLLPGColumnValueLengthsBetween(gxe.ExpectColumnValueLengthsToBeBetween):
    column: str = "llpg"
    min_value: int = 11
    max_value: int = 12
    description: str = "Expect UPRN (LLPG) to be between 11 and 12 characters length inclusive"


class ExpectBlockRefNoColumnValuesToMatchRegex(gxe.ExpectColumnValuesToMatchRegex):
    column: str = "block_reference_number"
    regex: str = r"^[0-9]\d+$"
    description: str = "Expect Block Reference Number to match regex ^[0-9]\d+$ (numerical)"


class ExpectLLPGColumnValuesToMatchRegex(gxe.ExpectColumnValuesToMatchRegex):
    column: str = "llpg"
    regex: str = r"^[1-9]\d{10,11}"
    description: str = "Expect UPRN (LLPG) to match regex ^[1-9]\d{10,11} (starting with digit 1-9, followed by 10 or 11 digits"


class ExpectEstateRefNoColumnValuesToMatchRegex(gxe.ExpectColumnValuesToMatchRegex):
    column: str = "estate_reference_number"
    regex: str = r"^[0-9]\d+$"
    description: str = "Expect Estate Reference Number to match regex ^[0-9]\d+$ (numerical)"



arg_key = ['s3_target_location']
args = getResolvedOptions(sys.argv, arg_key)
locals().update(args)

# add to GX context
context = gx.get_context(mode="file", project_root_dir=s3_target_location)

suite = gx.ExpectationSuite(name='housing_dwellings_list_suite')

suite.add_expectation(ExpectLLPGColumnValuesToBeUnique())
suite.add_expectation(ExpectLLPGAndPropRefColumnValuesToBeUniqueWithinRecord())
suite.add_expectation(ExpectLLPGColumnValuesToNotBeNull())
suite.add_expectation(ExpectLLPGColumnValueLengthsBetween())
suite.add_expectation(ExpectBlockRefNoColumnValuesToMatchRegex())
suite.add_expectation(ExpectLLPGColumnValuesToMatchRegex())
suite.add_expectation(ExpectEstateRefNoColumnValuesToMatchRegex())

suite = context.suites.add(suite)
