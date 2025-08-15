# flake8: noqa: F821

import sys

from awsglue.utils import getResolvedOptions
import great_expectations as gx
import great_expectations.expectations as gxe


class ExpectPropRefColumnValuesToBeUnique(gxe.ExpectColumnValuesToBeUnique):
    column: str = "LPRO_PROPREF"
    description: str = "Expect UPRN (LPRO_PROPREF) values to be unique"


class ExpectPropTypeCodeToBeInSet(gxe.ExpectColumnValuesToBeInSet):
    column: str = "LPRO_HOU_PTV_CODE"
    value_set: list = [
        "BUN",
        "CMC",
        "CMF",
        "COM",
        "CYC",
        "DUP",
        "FLT",
        "GAR",
        "HOU",
        "MAI",
        "PRA",
        "PSP",
        "ROM",
        "STD",
        "TRV",
    ]
    description: str = "Expect property type codes to contain one of the set"


arg_key = ["s3_target_location"]
args = getResolvedOptions(sys.argv, arg_key)
locals().update(args)

# add to GX context
context = gx.get_context(mode="file", project_root_dir=s3_target_location)

suite = gx.ExpectationSuite(name="properties_data_load_suite")

suite.add_expectation(ExpectPropRefColumnValuesToBeUnique())
suite.add_expectation(ExpectPropTypeCodeToBeInSet())
suite = context.suites.add(suite)
