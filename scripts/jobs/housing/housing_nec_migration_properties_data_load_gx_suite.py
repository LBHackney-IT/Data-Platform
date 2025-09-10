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


class ExpectOccStatusCodeToBeInSet(gxe.ExpectColumnValuesToBeInSet):
    column: str = "LPRO_SCO_CODE"
    value_set: list = ["OCC", "VOI", "CLO"]
    description: str = "Expect status codes to be one of the set"


class ExpectOrgIndicatorToBeInSet(gxe.ExpectColumnValuesToBeInSet):
    column: str = "LPRO_ORGANISATION_IND"
    value_set: list = ["Y", "N"]
    description: str = "Expect organisation indicator to be one of the set"


class ExpectOwnTypeToBeInSet(gxe.ExpectColumnValuesToBeInSet):
    column: str = "LPRO_HOU_HRV_HOT_CODE"
    value_set: list = [
        "ASSOC",
        "COUN",
        "LEASH",
        "LEASL",
        "LEASHOUT",
        "LEASLOUT",
        "PRIVATE",
    ]
    description: str = "Expect ownership type code to be one of the set"


class ExpectPropSourceToBeInSet(gxe.ExpectColumnValuesToBeInSet):
    column: str = "LPRO_HOU_HRV_HRS_CODE"
    value_set: list = [
        "LEASED",
        "NEWBUILD",
        "PURCHASE",
        "STOCKTRANS",
        "BUYBACK",
        "ACQUIRED",
    ]
    description: str = "Expect property source code to be one of the set"


class ExpectResIndicatorToBeInSet(gxe.ExpectColumnValuesToBeInSet):
    column: str = "LPRO_HOU_RESIDENTIAL_IND"
    value_set: list = ["Y", "N"]
    description: str = "Expect resdidential indicator to be one of the set"


class ExpectPropTypeValuesToBeInSet(gxe.ExpectColumnValuesToBeInSet):
    column: str = "LPRO_HOU_PTV_CODE"
    value_set: list = [
        "CMC",
        "CMC",
        "GAR",
        "FLT",
        "HOU",
        "MAI",
        "BUN",
        "TRV",
        "STD",
        "ROM",
        "COM",
        "PSP",
        "PRA",
        "CYC",
        "DUP",
    ]
    description: str = "Expect property type values to be one of the set"


class ExpectPropColumnsToMatchOrderedList(gxe.ExpectTableColumnsToMatchOrderedList):
    column_list = [
        "LPRO_PROPREF",
        "LPRO_HOU_FRB",
        "LPRO_SCO_CODE",
        "LPRO_ORGANISATION_IND",
        "LPRO_HOU_HRV_HOT_CODE",
        "LPRO_HOU_HRV_HRS_CODE",
        "LPRO_HOU_HRV_HBU_CODE",
        "LPRO_HOU_HRV_HLT_CODE",
        "LPRO_PARENT_PROPREF",
        "LPRO_HOU_SALE_DATE",
        "LPRO_SERVICE_PROP_IND",
        "LPRO_HOU_ACQUIRED_DATE",
        "LPRO_HOU_DEFECTS_IND",
        "LPRO_HOU_RESIDENTIAL_IND",
        "LPRO_HOU_ALT_REF",
        "LPRO_HOU_LEASE_START_DATE",
        "LPRO_HOU_LEASE_REVIEW_DATE",
        "LPRO_HOU_CONSTRUCTION_DATE",
        "LPRO_HOU_PTV_CODE",
        "LPRO_HOU_HRV_PST_CODE",
        "LPRO_HOU_HRV_HMT_CODE",
        "LPRO_HOU_MANAGEMENT_END_DATE",
        "LPRO_FREE_REFNO",
        "LPRO_FREE_NAME",
        "LPRO_PROP_STATUS",
        "LPRO_STATUS_START",
        "LPRO_HOU_ALLOW_PLACEMENT_IND",
        "LPRO_HOU_DEBIT_TO_DATE",
        "LPRO_ON_DEBIT_START_DATE",
        "LPRO_PHONE",
        "LPRO_AGENT_PAR_REFNO",
        "LPRO_PLD_COMMENTS",
        "LPRO_REFNO",
    ]
    description: str = "Expect columns to match ordered list exactly"


arg_key = ["s3_target_location"]
args = getResolvedOptions(sys.argv, arg_key)
locals().update(args)

# add to GX context
context = gx.get_context(mode="file", project_root_dir=s3_target_location)

suite = gx.ExpectationSuite(name="properties_data_load_suite")

suite.add_expectation(ExpectPropRefColumnValuesToBeUnique())
suite.add_expectation(ExpectPropTypeCodeToBeInSet())
suite.add_expectation(ExpectOccStatusCodeToBeInSet())
suite.add_expectation(ExpectOrgIndicatorToBeInSet())
suite.add_expectation(ExpectOwnTypeToBeInSet())
suite.add_expectation(ExpectPropSourceToBeInSet())
suite.add_expectation(ExpectResIndicatorToBeInSet())
suite.add_expectation(ExpectPropTypeValuesToBeInSet())
suite.add_expectation(ExpectPropColumnsToMatchOrderedList())
suite = context.suites.add(suite)
