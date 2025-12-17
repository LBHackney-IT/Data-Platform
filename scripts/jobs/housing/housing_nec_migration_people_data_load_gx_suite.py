# flake8: noqa: F821

import sys

from awsglue.utils import getResolvedOptions
import great_expectations as gx
import great_expectations.expectations as gxe


class PeopleExpectPersonRefColumnValuesToBeUnique(gxe.ExpectColumnValuesToBeUnique):
    column: str = "lpar_per_alt_ref"
    description: str = "Expect lpar_per_alt_ref (person ref) values to be unique"


class PeopleExpectPersonRefColumnValuesToNotBeNull(gxe.ExpectColumnValuesToNotBeNull):
    column: str = "lpar_per_alt_ref"
    description: str = "Expect lpar_per_alt_ref (person ref) values to not be Null"


class PeopleExpectTitleToBeInSet(gxe.ExpectColumnValuesToBeInSet):
    column: str = "lpar_per_title"
    value_set: list = [
        "DAME",
        "DR",
        "LAD",
        "LORD",
        "MASTER",
        "MISS",
        "MR",
        "MRS",
        "MS",
        "MX",
        "PROFESSOR",
        "RABBI",
        "REVEREND",
        "SIR",
        "",
    ]
    description: str = "Expect title to be one of the set"


class PeopleExpectPeopleColumnsToMatchOrderedList(
    gxe.ExpectTableColumnsToMatchOrderedList
):
    column_list = [
        "lpar_per_surname",
        "lpar_per_forename",
        "lpar_hop_start_date",
        "lpar_tcy_alt_ref",
        "lpar_hop_hpsr_code",
        "lpar_per_title",
        "lpar_per_initials",
        "lpar_per_date_of_birth",
        "lpar_per_hou_disabled_ind",
        "lpar_per_hou_oap_ind",
        "lpar_per_frv_fge_code",
        "lpar_hop_hrv_rel_code",
        "lpar_per_hou_employer",
        "lpar_per_hou_hrv_hms_code",
        "lpar_phone",
        "lpar_hop_end_date",
        "lpar_hop_hper_code",
        "lpar_tcy_ind",
        "lpar_tin_main_tenant_ind",
        "lpar_tin_start_date",
        "lpar_tin_end_date",
        "lpar_tin_hrv_tir_code",
        "lpar_tin_stat_successor_ind",
        "lpar_per_alt_ref",
        "lpar_per_frv_feo_code",
        "lpar_per_ni_no",
        "lpar_per_frv_hgo_code",
        "lpar_per_frv_fnl_code",
        "lpar_per_other_name",
        "lpar_per_hou_surname_prefix",
        "lpar_hou_legacy_ref",
        "lpar_ipp_shortname",
        "lpar_ipp_placement_ind",
        "lpar_ipp_current_ind",
        "lpar_ipp_ipt_code",
        "lpar_ipp_usr_username",
        "lpar_ipp_spr_printer_name",
        "lpar_ipp_comments",
        "lpar_ipp_vca_code",
        "lpar_ipu_aun_code",
        "lpar_ipp_staff_id",
        "lpar_ipp_cos_code",
        "lpar_ipp_hrv_fit_code",
        "lpar_type",
        "lpar_org_sort_code",
        "lpar_org_name",
        "lpar_org_short_name",
        "lpar_org_frv_oty_code",
        "lpar_per_hou_at_risk_ind",
        "lpar_per_hou_hrv_ntly_code",
        "lpar_per_hou_hrv_sexo_code",
        "lpar_per_hou_hrv_rlgn_code",
        "lpar_per_hou_hrv_ecst_code",
        "lpar_org_current_ind",
        "lpar_hop_head_hhold_ind",
        "lpar_hhold_group_no",
        "lpar_created_date",
        "lpar_created_by",
        "lpar_modified_date",
        "lpar_modified_by",
        "lpar_per_hou_end_date",
        "lpar_per_hou_hrv_hpe_code",
        "lpar_org_dup",
        "tranche",
    ]
    description: str = "Expect people load columns to match ordered list exactly"


arg_key = ["s3_target_location"]
args = getResolvedOptions(sys.argv, arg_key)
locals().update(args)

# add to GX context
context = gx.get_context(mode="file", project_root_dir=s3_target_location)

suite = gx.ExpectationSuite(name="people_data_load_suite")

suite.add_expectation(PeopleExpectPersonRefColumnValuesToBeUnique())
suite.add_expectation(PeopleExpectTitleToBeInSet())
suite.add_expectation(PeopleExpectPeopleColumnsToMatchOrderedList())
suite.add_expectation(PeopleExpectPersonRefColumnValuesToNotBeNull())
suite = context.suites.add(suite)
