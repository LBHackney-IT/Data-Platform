# flake8: noqa: F821

import sys

from awsglue.utils import getResolvedOptions
import great_expectations as gx
import great_expectations.expectations as gxe


class ExpectPersonRefColumnValuesToNotBeNull(gxe.ExpectColumnValuesToNotBeNull):
    column: str = "LCDE_LEGACY_REF"
    description: str = (
        "Expect LCDE_LEGACY_REF (person ref) values to not be Null in contacts load"
    )


class ExpectValueColumnValuesToNotBeNull(gxe.ExpectColumnValuesToNotBeNull):
    column: str = "LCDE_CONTACT_VALUE"
    description: str = "Expect LCDE_CONTACT_VALUE (contact value) to not be Null"


class ExpectContactTypeCodeToBeInSet(gxe.ExpectColumnValuesToBeInSet):
    column: str = "LCDE_FRV_CME_CODE,"
    value_set: list = ["WORKTEL", "MOBILETEL", "HOMETEL", "EMAIL", "OTHER"]
    description: str = "Expect contact type code to be one of the set"


class ExpectContactsColumnsToMatchOrderedList(gxe.ExpectTableColumnsToMatchOrderedList):
    column_list = [
        "LCDE_LEGACY_REF",
        "LCDE_LEGACY_TYPE",
        "LCDE_START_DATE",
        "LCDE_CREATED_DATE",
        "LCDE_CREATED_BY",
        "LCDE_CONTACT_VALUE",
        "LCDE_FRV_CME_CODE",
        "LCDE_CONTACT_NAME",
        "LCDE_END_DATE",
        "LCDE_PRECEDENCE",
        "LCDE_FRV_COMM_PREF_CODE",
        "LCDE_ALLOW_TEXTS",
        "LCDE_SECONDARY_REF",
        "LCDE_COMMENTS",
    ]
    description: str = "Expect columns to match ordered list exactly"


arg_key = ["s3_target_location"]
args = getResolvedOptions(sys.argv, arg_key)
locals().update(args)

# add to GX context
context = gx.get_context(mode="file", project_root_dir=s3_target_location)

suite = gx.ExpectationSuite(name="contacts_data_load_suite")

suite.add_expectation(ExpectContactsColumnsToMatchOrderedList())
suite.add_expectation(ExpectContactTypeCodeToBeInSet())
suite.add_expectation(ExpectPersonRefColumnValuesToNotBeNull())
suite.add_expectation(ExpectValueColumnValuesToNotBeNull())
suite = context.suites.add(suite)
