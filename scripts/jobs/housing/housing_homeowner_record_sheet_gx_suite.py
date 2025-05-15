# flake8: noqa: F821

import sys

from awsglue.utils import getResolvedOptions
import great_expectations as gx
import great_expectations.expectations as gxe


class ExpectPropNoColumnValuesToBeUnique(gxe.ExpectColumnValuesToBeUnique):
    column: str = 'property_no'
    description: str = "Expect Property Number values to be unique"


class ExpectPropNoAndPaymentRefColumnValuesToBeUniqueWithinRecord(gxe.ExpectSelectColumnValuesToBeUniqueWithinRecord):
    column_list: list = ['property_no', 'payment_ref']
    description: str = "Expect Property Number and Payment Reference fields to be unique for a record"


class ExpectPropNoColumnValuesToNotBeNull(gxe.ExpectColumnValuesToNotBeNull):
    column: str = 'property_no'
    description: str = "Expect Property Number column to be complete with no nulls"


class ExpectPropNoNoColumnValuesToMatchRegex(gxe.ExpectColumnValuesToMatchRegex):
    column: str = "property_no"
    regex: str = r"^\d+$"
    description: str = "Expect Property Number Number to match regex ^\d+$ (numerical)"


class ExpectPaymentRefNoColumnValuesToMatchRegex(gxe.ExpectColumnValuesToMatchRegex):
    column: str = "payment_ref"
    regex: str = r"^\d+$"
    description: str = "Expect Payment Reference Number to match regex ^\d+$ (numerical)"


class ExpectTenureTypeColumnValuesToBeInSet(gxe.ExpectColumnValuesToBeInSet):
    column: str = 'tenancy'
    value_set: list = ['Leasehold (RTB)', 'Private Sale LH', 'Freehold (Serv)', 'Lse 100% Stair', 'Shared Equity',
                       'Shared Owners']
    description: str = "Expect Tenure Type values to be one of Leasehold (RTB), Private Sale LH, Freehold (Serv), Lse 100% Stair, Shared Equity, Shared Owners"


arg_key = ['s3_target_location']
args = getResolvedOptions(sys.argv, arg_key)
locals().update(args)

# add to GX context
context = gx.get_context(mode="file", project_root_dir=s3_target_location)

suite = gx.ExpectationSuite(name='housing_homeowner_record_sheet_suite')

suite.add_expectation(ExpectPropNoColumnValuesToBeUnique())
suite.add_expectation(ExpectPropNoAndPaymentRefColumnValuesToBeUniqueWithinRecord())
suite.add_expectation(ExpectPropNoColumnValuesToNotBeNull())
suite.add_expectation(ExpectPropNoNoColumnValuesToMatchRegex())
suite.add_expectation(ExpectPaymentRefNoColumnValuesToMatchRegex())
suite.add_expectation(ExpectTenureTypeColumnValuesToBeInSet())
suite = context.suites.add(suite)
