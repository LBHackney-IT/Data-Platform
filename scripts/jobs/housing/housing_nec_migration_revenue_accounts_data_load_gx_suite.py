# flake8: noqa: F821

import sys

from awsglue.utils import getResolvedOptions
import great_expectations as gx
import great_expectations.expectations as gxe


class RevenueExpectPayRefColumnValuesToNotBeNull(gxe.ExpectColumnValuesToNotBeNull):
    column: str = "LRAC_PAY_REF"
    description: str = (
        "Expect LLRAC_PAY_REF (pay ref) values to not be Null in contacts load"
    )


class RevenueExpectTenancyRefToNotBeNull(gxe.ExpectColumnValuesToNotBeNull):
    column: str = "LRAC_TCY_ALT_REF"
    description: str = "Expect LRAC_TCY_ALT_REF to not be Null"


arg_key = ["s3_target_location"]
args = getResolvedOptions(sys.argv, arg_key)
locals().update(args)

# add to GX context
context = gx.get_context(mode="file", project_root_dir=s3_target_location)

suite = gx.ExpectationSuite(name="revenue_accounts_data_load_suite")

suite.add_expectation(RevenueExpectPayRefColumnValuesToNotBeNull())
suite.add_expectation(RevenueExpectTenancyRefToNotBeNull())
suite = context.suites.add(suite)
