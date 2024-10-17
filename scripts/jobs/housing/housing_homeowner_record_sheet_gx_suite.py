# flake8: noqa: F821

import sys

from awsglue.utils import getResolvedOptions
import great_expectations as gx
import great_expectations.expectations as gxe

arg_key = ['s3_target_location']
args = getResolvedOptions(sys.argv, arg_key)
locals().update(args)

# add to GX context
context = gx.get_context(mode="file", project_root_dir=s3_target_location)

suite = gx.ExpectationSuite(name='housing_homeowner_record_sheet_suite')
suite.add_expectation(
    gxe.ExpectColumnValuesToBeUnique(
        column='property_no')
)
suite.add_expectation(
    gxe.ExpectSelectColumnValuesToBeUniqueWithinRecord(
        column_list=['property_no', 'payment_ref'])
)
suite.add_expectation(
    gxe.ExpectColumnValuesToNotBeNull(
        column='property_no')
)
suite.add_expectation(
    gxe.ExpectColumnValuesToMatchRegex(
        column="property_no",
        regex=r"^[0-9]\d+$")
)
suite.add_expectation(
    gxe.ExpectColumnValuesToMatchRegex(
        column="payment_ref",
        regex=r"^[0-9]\d+$")
)
suite.add_expectation(
    gxe.ExpectColumnValuesToBeInSet(
        column='tenancy',
        value_set=['Leasehold (RTB)', 'Private Sale LH', 'Freehold (Serv)', 'Lse 100% Stair', 'Shared Equity',
                   'Shared Owners'])
)

suite = context.suites.add(suite)
