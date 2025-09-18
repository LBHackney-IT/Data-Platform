# flake8: noqa: F821

import sys

from awsglue.utils import getResolvedOptions
import great_expectations as gx
import great_expectations.expectations as gxe


class ExpectTagRefColumnValuesToBeUnique(gxe.ExpectColumnValuesToBeUnique):
    column: str = "LTCY_ALT_REF"
    description: str = "Expect LTCY_ALT_REF (tenancy ref) values to be unique"


class ExpectTenancyTypeCodeToBeInSet(gxe.ExpectColumnValuesToBeInSet):
    column: str = "LTCY_TTY_CODE"
    value_set: list = [
        "ASH",
        "ASY",
        "Demoted",
        "FRS",
        "HAL",
        "INT",
        "LEA",
        "LTA",
        "LHS",
        "MPA",
        "PVG",
        "SPS",
        "RTM",
        "SEC",
        "SSE",
        "SHO",
        "SLL",
        "TLA",
        "TBB",
        "TBBFam",
        "DEC",
        "THGF",
        "THO",
        "THL",
        "TPL",
        "TRA",
        "TACCFLAT",
        "TGA",
        "UNDER18",
        "NONSECTA",
        "NONSECHR",
        "OFFICESE",
        "LIVINGRT",
        "FRE",
    ]
    description: str = "Expect tenancy type code to contain one of the set"


class ExpectTenureTypeCodeToBeInSet(gxe.ExpectColumnValuesToBeInSet):
    column: str = "LTCY_HRV_TTYP_CODE"
    value_set: list = [
        "Secure",
        "NonSec",
        "NonRes",
        "Leasehold",
        "Temporary",
        "Freehold",
        "Commercial",
        "LivingRent"
    ]
    description: str = "Expect tenure type code to be one of the set"


class ExpectTenancyStatusCodeToBeInSet(gxe.ExpectColumnValuesToBeInSet):
    column: str = "LTCY_HRV_TST_CODE"
    value_set: list = ["Notice", "Decant", "UnautOcc"]
    description: str = "Expect tenancy status code to be one of the set"



arg_key = ["s3_target_location"]
args = getResolvedOptions(sys.argv, arg_key)
locals().update(args)

# add to GX context
context = gx.get_context(mode="file", project_root_dir=s3_target_location)

suite = gx.ExpectationSuite(name="tenancies_data_load_suite")

suite.add_expectation(ExpectTagRefColumnValuesToBeUnique())
suite.add_expectation(ExpectTenancyTypeCodeToBeInSet())
suite.add_expectation(ExpectTenureTypeCodeToBeInSet())
suite.add_expectation(ExpectTenancyStatusCodeToBeInSet())
suite = context.suites.add(suite)
