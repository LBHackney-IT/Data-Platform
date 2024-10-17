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

suite = gx.ExpectationSuite(name='assets_reshape_suite')
suite.add_expectation(
    gxe.ExpectColumnValueLengthsToBeBetween(
        column="uprn",
        min_value=11,
        max_value=12)
)
suite.add_expectation(
    gxe.ExpectColumnValuesToMatchRegex(
        column="uprn",
        regex=r"^[1-9]\d{10,11}")
)
suite.add_expectation(
    gxe.ExpectColumnValuesToBeInSet(
        column='type',
        value_set=['Dwelling'])
)
suite.add_expectation(
    gxe.ExpectColumnValuesToBeUnique(
        column='asset_id')
)
suite.add_expectation(
    gxe.ExpectColumnValuesToNotBeNull(
        column='asset_id')
)
suite.add_expectation(
    gxe.ExpectColumnValuesToNotBeNull(
        column='uprn')
)
suite.add_expectation(
    gxe.ExpectColumnValuesToNotBeNull(
        column='estate_name')
)
suite.add_expectation(
    gxe.ExpectColumnValuesToNotBeNull(
        column='type')
)

suite = context.suites.add(suite)
