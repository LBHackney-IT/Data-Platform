# flake8: noqa: F821

import sys

from awsglue.utils import getResolvedOptions
import great_expectations as gx
import great_expectations.expectations as gxe


class DebitBreakdownsExpectPayRefColumnValuesToNotBeNull(
    gxe.ExpectColumnValuesToNotBeNull
):
    column: str = "ldbr_pay_ref"
    description: str = "Expect ldbr_pay_ref values to not be Null"


class DebitBreakdownsExpectElementCodeToBeInSet(gxe.ExpectColumnValuesToBeInSet):
    column: str = "ldbr_ele_code"
    value_set: list = [
        "DBR",
        "DCA",
        "DCC",
        "DCE",
        "DCO",
        "DCP",
        "DGA",
        "DGM",
        "DHA",
        "DHE",
        "DHM",
        "DLL",
        "DR2",
        "DSC",
        "DTA",
        "DTC",
        "DTL",
        "DVA",
        "DWR",
        "DWS",
    ]
    description: str = "Expect element code (ldbr_ele_code) to be one of the set"


class DebitBreakdownsExpectDBRColumnsToMatchOrderedList(
    gxe.ExpectTableColumnsToMatchOrderedList
):
    column_list = [
        "ldbr_pay_ref",
        "ldbr_pro_refno",
        "ldbr_ele_code",
        "ldbr_start_date",
        "ldbr_end_date",
        "ldbr_att_code",
        "ldbr_ele_value",
        "tranche",
    ]
    description: str = "Expect columns to match ordered list exactly; tranche at end"


arg_key = ["s3_target_location"]
args = getResolvedOptions(sys.argv, arg_key)
locals().update(args)

# add to GX context
context = gx.get_context(mode="file", project_root_dir=s3_target_location)

suite = gx.ExpectationSuite(name="debit_breakdowns_data_load_suite")

suite.add_expectation(DebitBreakdownsExpectPayRefColumnValuesToNotBeNull())
suite.add_expectation(DebitBreakdownsExpectElementCodeToBeInSet())
suite.add_expectation(DebitBreakdownsExpectDBRColumnsToMatchOrderedList())

suite = context.suites.add(suite)
