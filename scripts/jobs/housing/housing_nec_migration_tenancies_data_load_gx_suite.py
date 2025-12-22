# flake8: noqa: F821

import sys

from awsglue.utils import getResolvedOptions
import great_expectations as gx
import great_expectations.expectations as gxe


class TenanciesExpectTagRefColumnValuesToBeUnique(gxe.ExpectColumnValuesToBeUnique):
    column: str = "ltcy_alt_ref"
    description: str = "Expect ltcy_alt_ref (tenancy ref) values to be unique"


class TenanciesExpectTenancyRefColumnValuesToNotBeNull(gxe.ExpectColumnValuesToNotBeNull):
    column: str = "ltcy_alt_ref"
    description: str = "Expect ltcy_alt_ref (tenancy ref) values to not be Null"


class TenanciesExpectTenancyTypeCodeToBeInSet(gxe.ExpectColumnValuesToBeInSet):
    column: str = "ltcy_tty_code"
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
        "NONSECHR",
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
    column: str = "ltcy_hrv_ttyp_code"
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
    column: str = "ltcy_hrv_tst_code"
    value_set: list = ["DECANT", "NOTICE", "UNAUTHOCC"]
    description: str = "Expect tenancy status code (ltcy_hrv_tst_code) to be one of the set"


class TenanciesExpectTenancyColumnsToMatchOrderedList(gxe.ExpectTableColumnsToMatchOrderedList):
    column_list = [
        'ltcy_act_end_date',
        'ltcy_act_start_date',
        'ltcy_alt_ref',
        'ltcy_correspond_name',
        'ltcy_expected_end_date',
        'ltcy_hrv_rhr_code',
        'ltcy_hrv_rwr_code',
        'ltcy_hrv_tnr_code',
        'ltcy_hrv_tso_code',
        'ltcy_hrv_tst_code',
        'ltcy_hrv_ttr_code',
        'ltcy_hrv_ttyp_code',
        'ltcy_notice_given_date',
        'ltcy_notice_rec_date',
        'ltcy_phone',
        'ltcy_review_date',
        'ltcy_rtb_admitted_date',
        'ltcy_rtb_app_expected_end_date',
        'ltcy_rtb_app_reference',
        'ltcy_rtb_held_date',
        'ltcy_rtb_received_date',
        'ltcy_rtb_withdrawn_date',
        'ltcy_tho_end_date1',
        'ltcy_tho_end_date2',
        'ltcy_tho_end_date3',
        'ltcy_tho_end_date4',
        'ltcy_tho_end_date5',
        'ltcy_tho_end_date6',
        'ltcy_tho_hrv_ttr_code2',
        'ltcy_tho_hrv_ttr_code3',
        'ltcy_tho_hrv_ttr_code4',
        'ltcy_tho_hrv_ttr_code5',
        'ltcy_tho_hrv_ttr_code6',
        'ltcy_tho_propref1',
        'ltcy_tho_propref2',
        'ltcy_tho_propref3',
        'ltcy_tho_propref4',
        'ltcy_tho_propref5',
        'ltcy_tho_propref6',
        'ltcy_tho_start_date1',
        'ltcy_tho_start_date2',
        'ltcy_tho_start_date3',
        'ltcy_tho_start_date4',
        'ltcy_tho_start_date5',
        'ltcy_tho_start_date6',
        'ltcy_tho_ttr_code1',
        'ltcy_tty_code',
        'tranche'
    ]
    description: str = "Expect tenancy load columns to match ordered list exactly; tranche at end"


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