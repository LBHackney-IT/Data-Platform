# flake8: noqa: F821

import sys

from awsglue.utils import getResolvedOptions
import great_expectations as gx
import great_expectations.expectations as gxe


class ExpectPayRefColumnValuesToNotBeNull(gxe.ExpectColumnValuesToNotBeNull):
    column: str = "LACA_PAY_REF"
    description: str = (
        "Expect LACA_PAY_REF (pay ref) values to not be Null in contacts load"
    )


class ExpectValueColumnValuesToNotBeNull(gxe.ExpectColumnValuesToNotBeNull):
    column: str = "LACA_CREATED_DATE"
    description: str = "Expect LCDE_CONTACT_VALUE (contact value) to not be Null"


class ExpectArrearCodeToBeInSet(gxe.ExpectColumnValuesToBeInSet):
    column: str = "LACA_ARA_CODE"
    value_set: list = [
        "BAGF",
        "BAG1",
        "RTRN",
        "FRA2",
        "ADVR",
        "RDCN",
        "DWPR",
        "DWPN",
        "EDCL",
        "NOTE",
        "RHCN",
        "CORT",
        "IUPO",
        "IRA1",
        "NTQ",
        "CON3",
        "RREQ",
        "RRFN",
        "STAT",
        "SHB",
        "SNW",
        "ARRN",
        "POP",
        "FRA1",
        "BCOL",
        "DWPC",
        "DWPT",
        "COUT",
        "NFA",
        "NRA2",
        "FRET",
        "SCH",
        "SNP",
        "VISN",
        "WOA",
        "WOC",
        "WOH",
        "WON",
        "CDAT",
        "CNOK",
        "ADVC",
        "EVIC",
        "FINC",
        "HBN",
        "SRA1",
        "TRA1",
        "NRA1",
        "IRA1",
        "MRA1",
        "TELO",
        "RPAN",
        "RRHB",
        "RRF",
        "SAR",
        "SBA",
        "SCM",
        "SSA",
        "VISI",
        "WOF",
        "RCHN",
        "RDDN",
        "CDL",
        "FINI",
        "GRA1",
        "AGRL",
        "SRA2",
        "TRA2",
        "NRA2",
        "IRA2",
        "MRA2",
        "CWAL",
        "TELI",
        "RELI",
        "LREF",
        "NOSP",
        "INTV",
        "SUP",
        "UCC"
    ]
    description: str = "Expect arrear code to be one of the set"


class ExpectArrearsActionsColumnsToMatchOrderedList(gxe.ExpectTableColumnsToMatchOrderedList):
    column_list = [
        "LACA_BALANCE",
        "LACA_PAY_REF",
        "LACA_TYPE",
        "LACA_CREATED_BY",
        "LACA_CREATED_DATE",
        "LACA_ARREARS_DISPUTE_IND",
        "LACA_ARA_CODE",
        "LACA_STATUS",
        "LACA_HRV_ADL_CODE",
        "LACA_EAC_EPO_CODE",
        "LACA_EFFECTIVE_DATE",
        "LACA_EXPIRY_DATE",
        "LACA_NEXT_ACTION_DATE",
        "LACA_AUTH_DATE",
        "LACA_AUTH_USERNAME",
        "LACA_PRINT_DATE",
        "LACA_DEL_"
    ]
    description: str = "Expect columns to match ordered list exactly"


arg_key = ["s3_target_location"]
args = getResolvedOptions(sys.argv, arg_key)
locals().update(args)

# add to GX context
context = gx.get_context(mode="file", project_root_dir=s3_target_location)

suite = gx.ExpectationSuite(name="arrears_actions_data_load_suite")

suite.add_expectation(ExpectArrearsActionsColumnsToMatchOrderedList())
suite.add_expectation(ExpectArrearCodeToBeInSet())
suite.add_expectation(ExpectPayRefColumnValuesToNotBeNull())
suite.add_expectation(ExpectValueColumnValuesToNotBeNull())
suite = context.suites.add(suite)