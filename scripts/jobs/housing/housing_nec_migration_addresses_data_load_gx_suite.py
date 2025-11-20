# flake8: noqa: F821

import sys

from awsglue.utils import getResolvedOptions
import great_expectations as gx
import great_expectations.expectations as gxe


class AddressesExpectPropRefColumnValuesToBeUnique(gxe.ExpectColumnValuesToBeUnique):
    column: str = "LAUS_LEGACY_REF"
    description: str = "Expect LAUS_LEGACY_REF values to be unique"

class AddressesExpectPropRefColumnValuesToNotBeNull(gxe.ExpectColumnValuesToNotBeNull):
    column: str = "LAUS_LEGACY_REF"
    description: str = "Expect LAUS_LEGACY_REF values to not be Null"

class AddressesExpectUPRNColumnValuesToBeUnique(gxe.ExpectColumnValuesToBeUnique):
    column: str = "LADR_UPRN"
    description: str = "Expect UPRN values to be unique"

class AddressesExpectUPRNColumnValuesToNotBeNull(gxe.ExpectColumnValuesToNotBeNull):
    column: str = "LADR_UPRN"
    description: str = "Expect UPRN values to not be Null"

class AddressesExpectAddressColumnsToMatchOrderedList(gxe.ExpectTableColumnsToMatchOrderedList):
    column_list = [
        "LAUS_LEGACY_REF",
        "LAUS_AUT_FAO_CODE",
        "LAUS_AUT_FAR_CODE",
        "LAUS_START_DATE",
        "LAUS_END_DATE",
        "LADR_FLAT",
        "LADR_BUILDING",
        "LADR_STREET_NUMBER",
        "LAEL_STREET",
        "LAEL_SUB_STREET1",
        "LAEL_SUB_STREET2",
        "LAEL_SUB_STREET3",
        "LAEL_AREA",
        "LAEL_TOWN",
        "LAEL_COUNTY",
        "LAEL_COUNTRY",
        "LAEL_POSTCODE",
        "LAEL_LOCAL_IND",
        "LAEL_ABROAD_IND",
        "LADD_ADDL1",
        "LADD_ADDL2",
        "LADD_ADDL3",
        "LAEL_STREET_INDEX_CODE",
        "LAUS_CONTACT_NAME",
        "LADR_EASTINGS",
        "LADR_NORTHINGS",
        "LADR_UPRN"
    ]
    description: str = "Expect columns to match ordered list exactly"


arg_key = ["s3_target_location"]
args = getResolvedOptions(sys.argv, arg_key)
locals().update(args)

# add to GX context
context = gx.get_context(mode="file", project_root_dir=s3_target_location)

suite = gx.ExpectationSuite(name="addresses_data_load_suite")

suite.add_expectation(AddressesExpectPropRefColumnValuesToBeUnique())
suite.add_expectation(AddressesExpectUPRNColumnValuesToBeUnique())
suite.add_expectation(AddressesExpectAddressColumnsToMatchOrderedList())
suite.add_expectation(AddressesExpectPropRefColumnValuesToNotBeNull())
suite.add_expectation(AddressesExpectUPRNColumnValuesToNotBeNull())
suite = context.suites.add(suite)
