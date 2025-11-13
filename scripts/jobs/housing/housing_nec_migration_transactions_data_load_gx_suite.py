# flake8: noqa: F821

import sys

from awsglue.utils import getResolvedOptions
import great_expectations as gx
import great_expectations.expectations as gxe


class ExpectPayRefColumnValuesToNotBeNull(gxe.ExpectColumnValuesToNotBeNull):
    column: str = "LTRN_ALT_REF"
    description: str = "Expect LTRN_ALT_REF values to not be Null in contacts load"


arg_key = ["s3_target_location"]
args = getResolvedOptions(sys.argv, arg_key)
locals().update(args)

# add to GX context
context = gx.get_context(mode="file", project_root_dir=s3_target_location)

suite = gx.ExpectationSuite(name="transactions_data_load_suite")

suite.add_expectation(ExpectPayRefColumnValuesToNotBeNull())
suite = context.suites.add(suite)
