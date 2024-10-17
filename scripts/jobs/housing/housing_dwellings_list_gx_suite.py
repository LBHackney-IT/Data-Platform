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

suite = gx.ExpectationSuite(name='housing_dwellings_list_suite')
suite.add_expectation(
    gxe.ExpectColumnValuesToBeUnique(
        column='llpg')
)
suite.add_expectation(
    gxe.ExpectSelectColumnValuesToBeUniqueWithinRecord(
        column_list=['llpg', 'property_dwelling_reference_number'])
)
suite.add_expectation(
    gxe.ExpectColumnValuesToNotBeNull(
        column='llpg')
)
suite.add_expectation(
    gxe.ExpectColumnValueLengthsToBeBetween(
        column="llpg",
        min_value=11,
        max_value=12)
)
suite.add_expectation(
    gxe.ExpectColumnValuesToMatchRegex(
        column="llpg",
        regex=r"^[1-9]\d{10,11}")
)
suite.add_expectation(
    gxe.ExpectColumnValuesToMatchRegex(
        column="block_reference_number",
        regex=r"^[0-9]\d+$")
)
suite.add_expectation(
    gxe.ExpectColumnValuesToMatchRegex(
        column="estate_reference_number",
        regex=r"^[0-9]\d+$")
)

suite = context.suites.add(suite)
