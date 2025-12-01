# flake8: noqa: F821

import sys

from awsglue.utils import getResolvedOptions
import great_expectations as gx
import great_expectations.expectations as gxe


class TenanciesExpectTagRefColumnValuesToBeUnique(gxe.ExpectColumnValuesToBeUnique):
    column: str = "LTCY_ALT_REF"
    description: str = "Expect LTCY_ALT_REF (tenancy ref) values to be unique"


class TenanciesExpectTenancyRefColumnValuesToNotBeNull(gxe.ExpectColumnValuesToNotBeNull):
    column: str = "LTCY_ALT_REF"
    description: str = "Expect LTCY_ALT_REF (tenancy ref) values to not be Null"


class TenanciesExpectTenancyTypeCodeToBeInSet(gxe.ExpectColumnValuesToBeInSet):
    column: str = "LTCY_TTY_CODE"
    value_set: list = [
        "ASH",
        "ASY",
        "DEC",
        "Demoted",
        "FRE",
        "FRS",
        "HAL",
        "LIVINGRT",
        "INT",
        "LEA",
        "LHS",
        "LTA",
        "MPA",
        "NONSEC",
        "PVG",
        "RTM",
        "SEC",
        "SHO",
        "SLL",
        "SPS",
        "SSE",
        "TACCFLAT",
        "TBB",
        "TBBFam",
        "THO",
        "TGA",
        "THL",
        "THGF",
        "TLA",
        "TPL",
        "TRA",
        "UNDER18",
        "OFFICESE",
    ]
    description: str = "Expect tenancy type code to contain one of the set"


class TenanciesExpectTenureTypeCodeToBeInSet(gxe.ExpectColumnValuesToBeInSet):
    column: str = "LTCY_HRV_TTYP_CODE"
    value_set: list = [
        "SECURE",
        "NONSEC",
        "NONRES",
        "LEASEHOLD",
        "TEMPORARY",
        "FREEHOLD",
        "COMMERCIAL",
        "LIVINGRENT",
    ]
    description: str = "Expect tenure type code to be one of the set"


class TenanciesExpectTenancyStatusCodeToBeInSet(gxe.ExpectColumnValuesToBeInSet):
    column: str = "LTCY_HRV_TST_CODE"
    value_set: list = ["DECANT", "NOTICE", "UNAUTHOCC"]
    description: str = "Expect tenancy status code to be one of the set"


class TenanciesExpectTenancyColumnsToMatchOrderedList(gxe.ExpectTableColumnsToMatchOrderedList):
    column_list = [
        "LTCY_ALT_REF",
        "LTCY_TTY_CODE",
        "LTCY_ACT_START_DATE",
        "LTCY_CORRESPOND_NAME",
        "LTCY_HRV_TTYP_CODE",
        "LTCY_HRV_TSO_CODE",
        "LTCY_ACT_END_DATE",
        "LTCY_NOTICE_GIVEN_DATE",
        "LTCY_NOTICE_REC_DATE",
        "LTCY_EXPECTED_END_DATE",
        "LTCY_RTB_RECEIVED_DATE",
        "LTCY_RTB_ADMITTED_DATE",
        "LTCY_RTB_HELD_DATE",
        "LTCY_RTB_WITHDRAWN_DATE",
        "LTCY_RTB_APP_EXPECTED_END_DATE",
        "LTCY_HRV_TST_CODE",
        "LTCY_HRV_TTR_CODE",
        "LTCY_HRV_TNR_CODE",
        "LTCY_HRV_RHR_CODE",
        "LTCY_HRV_RWR_CODE",
        "LTCY_RTB_APP_REFERENCE",
        "LTCY_THO_PROPREF1",
        "LTCY_THO_START_DATE1",
        "LTCY_THO_END_DATE1",
        "LTCY_THO_TTR_CODE1",
        "LTCY_THO_PROPREF2",
        "LTCY_THO_START_DATE2",
        "LTCY_THO_END_DATE2",
        "LTCY_THO_HRV_TTR_CODE2",
        "LTCY_THO_PROPREF3",
        "LTCY_THO_START_DATE3",
        "LTCY_THO_END_DATE3",
        "LTCY_THO_HRV_TTR_CODE3",
        "LTCY_THO_PROPREF4",
        "LTCY_THO_START_DATE4",
        "LTCY_THO_END_DATE4",
        "LTCY_THO_HRV_TTR_CODE4",
        "LTCY_THO_PROPREF5",
        "LTCY_THO_START_DATE5",
        "LTCY_THO_END_DATE5",
        "LTCY_THO_HRV_TTR_CODE5",
        "LTCY_THO_PROPREF6",
        "LTCY_THO_START_DATE6",
        "LTCY_THO_END_DATE6",
        "LTCY_THO_HRV_TTR_CODE6",
        "LTCY_PHONE",
        "LTCY_REVIEW_DATE",
    ]
    description: str = "Expect tenancy load columns to match ordered list exactly"


arg_key = ["s3_target_location"]
args = getResolvedOptions(sys.argv, arg_key)
locals().update(args)

# add to GX context
context = gx.get_context(mode="file", project_root_dir=s3_target_location)

suite = gx.ExpectationSuite(name="tenancies_data_load_suite")

suite.add_expectation(TenanciesExpectTagRefColumnValuesToBeUnique())
suite.add_expectation(TenanciesExpectTenancyTypeCodeToBeInSet())
suite.add_expectation(TenanciesExpectTenureTypeCodeToBeInSet())
suite.add_expectation(TenanciesExpectTenancyStatusCodeToBeInSet())
suite.add_expectation(TenanciesExpectTenancyColumnsToMatchOrderedList())
suite.add_expectation(TenanciesExpectTenancyRefColumnValuesToNotBeNull())

context.suites.add(suite)
