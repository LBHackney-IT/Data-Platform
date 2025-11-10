# flake8: noqa: F821

import sys

from awsglue.utils import getResolvedOptions
import great_expectations as gx
import great_expectations.expectations as gxe


class ExpectPersonRefColumnValuesToBeUnique(gxe.ExpectColumnValuesToBeUnique):
    column: str = "LPAR_PER_ALT_REF"
    description: str = "Expect LPAR_PER_ALT_REF (person ref) values to be unique"


class ExpectPersonRefColumnValuesToNotBeNull(gxe.ExpectColumnValuesToNotBeNull):
    column: str = "LPAR_PER_ALT_REF"
    description: str = "Expect LPAR_PER_ALT_REF (person ref) values to not be Null"


class ExpectTitleToBeInSet(gxe.ExpectColumnValuesToBeInSet):
    column: str = "LPAR_PER_TITLE"
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
        None,
    ]
    description: str = "Expect title to be one of the set"


class ExpectPeopleColumnsToMatchOrderedList(gxe.ExpectTableColumnsToMatchOrderedList):
    column_list = [
        "LPAR_TIN_HRV_TIR_CODE",
        "LPAR_TIN_STAT_SUCCESSOR_IND",
        "LPAR_TIN_START_DATE",
        "LPAR_TIN_MAIN_TENANT_IND",
        "LPAR_TIN_END_DATE",
        "LPAR_TCY_IND",
        "LPAR_TCY_ALT_REF",
        "LPAR_PHONE",
        "LPAR_PER_TITLE",
        "LPAR_PER_SURNAME",
        "LPAR_PER_OTHER_NAME",
        "LPAR_PER_NI_NO",
        "LPAR_PER_INITIALS",
        "LPAR_PER_HOU_OAP_IND",
        "LPAR_PER_HOU_HRV_HMS_CODE",
        "LPAR_PER_HOU_EMPLOYER",
        "LPAR_PER_HOU_DISABLED_IND",
        "LPAR_PER_FRV_HGO_CODE",
        "LPAR_PER_FRV_FNL_CODE",
        "LPAR_PER_FRV_FGE_CODE",
        "LPAR_PER_FRV_FEO_CODE",
        "LPAR_PER_FORENAME",
        "LPAR_PER_DATE_OF_BIRTH",
        "LPAR_PER_ALT_REF",
        "LPAR_HOP_START_DATE",
        "LPAR_HOP_HRV_REL_CODE",
        "LPAR_HOP_HPSR_CODE",
        "LPAR_HOP_HPER_CODE",
        "LPAR_HOP_END_DATE",
    ]
    description: str = "Expect people load columns to match ordered list exactly"


arg_key = ["s3_target_location"]
args = getResolvedOptions(sys.argv, arg_key)
locals().update(args)

# add to GX context
context = gx.get_context(mode="file", project_root_dir=s3_target_location)

suite = gx.ExpectationSuite(name="people_data_load_suite")

suite.add_expectation(ExpectPersonRefColumnValuesToBeUnique())
suite.add_expectation(ExpectTitleToBeInSet())
suite.add_expectation(ExpectPeopleColumnsToMatchOrderedList())
suite.add_expectation(ExpectPersonRefColumnValuesToNotBeNull())
suite = context.suites.add(suite)
