# flake8: noqa: F821

import sys

from awsglue.utils import getResolvedOptions
import great_expectations as gx
import great_expectations.expectations as gxe


class PropertiesExpectPropRefColumnValuesToBeUnique(gxe.ExpectColumnValuesToBeUnique):
    column: str = "lpro_propref"
    description: str = "Expect UPRN (lpro_propref) values to be unique"


class PropertiesExpectPropRefColumnValuesToNotBeNull(gxe.ExpectColumnValuesToNotBeNull):
    column: str = "lpro_propref"
    description: str = "Expect lpro_propref (prop ref) values to not be Null"


class PropertiesExpectPropTypeCodeToBeInSet(gxe.ExpectColumnValuesToBeInSet):
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


class PropertiesExpectOccStatusCodeToBeInSet(gxe.ExpectColumnValuesToBeInSet):
    column: str = "lpro_sco_code"
    value_set: list = ["OCC", "VOI", "CLO"]
    description: str = "Expect status codes (lpro_sco_code) to be one of the set"


class PropertiesExpectOrgIndicatorToBeInSet(gxe.ExpectColumnValuesToBeInSet):
    column: str = "lpro_organisation_ind"
    value_set: list = ["Y", "N"]
    description: str = (
        "Expect organisation indicator (lpro_organisation_ind) to be one of the set"
    )


class PropertiesExpectOwnTypeToBeInSet(gxe.ExpectColumnValuesToBeInSet):
    column: str = "lpro_hou_hrv_hot_code"
    value_set: list = [
        "ASSOC",
        "COUN",
        "LEASH",
        "LEASL",
        "LEASHOUT",
        "LEASLOUT",
        "PRIVATE",
    ]
    description: str = (
        "Expect ownership type code (lpro_hou_hrv_hot_code) to be one of the set"
    )


class PropertiesExpectPropSourceToBeInSet(gxe.ExpectColumnValuesToBeInSet):
    column: str = "lpro_hou_hrv_hrs_code"
    value_set: list = [
        "LEASED",
        "NEWBUILD",
        "PURCHASE",
        "STOCKTRANS",
        "BUYBACK",
        "ACQUIRED",
        "ENFRAN",
    ]
    description: str = (
        "Expect property source code (lpro_hou_hrv_hrs_code) to be one of the set"
    )


class PropertiesExpectResIndicatorToBeInSet(gxe.ExpectColumnValuesToBeInSet):
    column: str = "lpro_hou_residential_ind"
    value_set: list = ["Y", "N"]
    description: str = (
        "Expect residential indicator (lpro_hou_residential_ind) to be one of the set"
    )


class PropertiesExpectPropTypeValuesToBeInSet(gxe.ExpectColumnValuesToBeInSet):
    column: str = "lpro_hou_ptv_code"
    value_set: list = [
        "BOI",
        "BUN",
        "CMC",
        "CMF",
        "COM",
        "CON",
        "CYC",
        "DUP",
        "FLT",
        "GAR",
        "HOU",
        "LFT",
        "MAI",
        "PLY",
        "PRA",
        "PSP",
        "ROM",
        "STD",
        "TRV",
    ]
    description: str = (
        "Expect property type values (lpro_hou_ptv_code) to be one of the set"
    )


class PropertiesExpectPropColumnsToMatchOrderedList(
    gxe.ExpectTableColumnsToMatchOrderedList
):
    column_list = [
        "lpro_propref",
        "lpro_hou_frb",
        "lpro_sco_code",
        "lpro_organisation_ind",
        "lpro_hou_hrv_hot_code",
        "lpro_hou_hrv_hrs_code",
        "lpro_hou_hrv_hbu_code",
        "lpro_hou_hrv_hlt_code",
        "lpro_parent_propref",
        "lpro_hou_sale_date",
        "lpro_service_prop_ind",
        "lpro_hou_acquired_date",
        "lpro_hou_defects_ind",
        "lpro_hou_residential_ind",
        "lpro_hou_alt_ref",
        "lpro_hou_lease_start_date",
        "lpro_hou_lease_review_date",
        "lpro_hou_construction_date",
        "lpro_hou_ptv_code",
        "lpro_hou_hrv_pst_code",
        "lpro_hou_hrv_hmt_code",
        "lpro_hou_management_end_date",
        "lpro_free_refno",
        "lpro_free_name",
        "lpro_prop_status",
        "lpro_status_start",
        "lpro_hou_allow_placement_ind",
        "lpro_hou_debit_to_date",
        "lpro_on_debit_start_date",
        "lpro_phone",
        "lpro_agent_par_refno",
        "lpro_pld_comments",
        "lpro_refno",
        "tranche",
    ]
    description: str = "Expect columns to match ordered list exactly; tranche at end"


arg_key = ["s3_target_location"]
args = getResolvedOptions(sys.argv, arg_key)
locals().update(args)

# add to GX context
context = gx.get_context(mode="file", project_root_dir=s3_target_location)

suite = gx.ExpectationSuite(name="properties_data_load_suite")

suite.add_expectation(PropertiesExpectPropRefColumnValuesToBeUnique())
suite.add_expectation(PropertiesExpectPropTypeCodeToBeInSet())
suite.add_expectation(PropertiesExpectOccStatusCodeToBeInSet())
suite.add_expectation(PropertiesExpectOrgIndicatorToBeInSet())
suite.add_expectation(PropertiesExpectOwnTypeToBeInSet())
suite.add_expectation(PropertiesExpectPropSourceToBeInSet())
suite.add_expectation(PropertiesExpectResIndicatorToBeInSet())
suite.add_expectation(PropertiesExpectPropTypeValuesToBeInSet())
suite.add_expectation(PropertiesExpectPropColumnsToMatchOrderedList())
suite.add_expectation(PropertiesExpectPropRefColumnValuesToNotBeNull())
suite = context.suites.add(suite)