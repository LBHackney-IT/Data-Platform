# flake8: noqa: F821
from datetime import datetime
import sys

from awsglue.utils import getResolvedOptions
import great_expectations as gx
import great_expectations.expectations as gxe

arg_key = ['s3_target_location']
args = getResolvedOptions(sys.argv, arg_key)
locals().update(args)


class ExpectFirstNameColumnValueLength(gxe.ExpectColumnValueLengthsToBeBetween):
    column: str = "firstname"
    min_value: int = 1
    description: str = "Expect first name to be at least 1 character length"


class ExpectSurnameColumnValueLength(gxe.ExpectColumnValueLengthsToBeBetween):
    column: str = "surname"
    min_value: int = 1
    description: str = "Expect surname to be at least 1 character length"


class ExpectUPRNColumnValueLengthsBetween(gxe.ExpectColumnValueLengthsToBeBetween):
    column: str = "uprn"
    min_value: int = 11
    max_value: int = 12
    description: str = "Expect UPRN to be between 11 and 12 characters length inclusive"


class ExpectUPRNColumnValuesToMatchRegex(gxe.ExpectColumnValuesToMatchRegex):
    column: str = "uprn"
    regex: str = r"^[1-9]\d{10,11}"
    description: str = "Expect UPRN to match regex ^[1-9]\d{10,11} (starting with digit 1-9, followed by 10 or 11 digits"


class ExpectUPRNNotToBeNull(gxe.ExpectColumnValuesToNotBeNull):
    column: str = "uprn"
    description: str = "Expect UPRN column to be complete with no missing values"


class ExpectPersonTypeValuesToBeInSet(gxe.ExpectColumnValuesToBeInSet):
    column: str = 'person_type'
    value_set: list = ['Tenant', 'HouseholdMember', 'Leaseholder', 'Freeholder', 'Occupant', 'HousingOfficer',
                       'HousingAreaManager']
    description: str = "Expect person types values to contain one of Tenant, HouseholdMember, Leaseholder, Freeholder, Occupant HousingOfficer, HousingAreaManager"


class ExpectPreferredTitleValuesToBeInSet(gxe.ExpectColumnValuesToBeInSet):
    column: str = 'preferredtitle'
    value_set: list = ['Dr', 'Master', 'Miss', 'Mr', 'Mrs', 'Ms', 'Rabbi', 'Reverend', 'Mx']
    description: str = "Expect preferred titles to be one of Dr, Master, Miss, Mr, Mrs, Ms, Mx, Rabbi, Reverend"


class ExpectPersonIDColumnValuesToBeUnique(gxe.ExpectColumnValuesToBeUnique):
    column: str = 'person_id'
    description: str = "Expect Person ID to be unique within dataset"


class ExpectPersonIDColumnValuesToNotBeNull(gxe.ExpectColumnValuesToNotBeNull):
    column: str = 'person_id'
    description: str = "Expect Person ID be complete with no missing values"


class ExpectPersonIDAndPropertyReferenceColumnValuesToBeUniqueWithinRecord(
    gxe.ExpectSelectColumnValuesToBeUniqueWithinRecord):
    column_list: list = ['person_id', 'propertyreference']
    description: str = "Expect Person ID and Property Reference to be unique within dataset"


class ExpectPropertyRefColumnValuesToNotBeNull(gxe.ExpectColumnValuesToNotBeNull):
    column: str = 'propertyreference'
    description: str = "Expect Property Reference be complete with no missing values"


class ExpectPersonIDAndPaymentReferenceColumnValuesToBeUniqueWithinRecord(
    gxe.ExpectSelectColumnValuesToBeUniqueWithinRecord):
    column_list: list = ['person_id', 'paymentreference']
    description: str = "Expect Person ID and Payment Reference to be unique within dataset"


class ExpectUPRNColumnValuesToNotBeNull(gxe.ExpectColumnValuesToNotBeNull):
    column: str = 'uprn'
    description: str = "Expect UPRN be complete with no missing values"


class ExpectDateOfBirthColumnValuesToNotBeNull(gxe.ExpectColumnValuesToNotBeNull):
    column: str = 'dateofbirth_parsed'
    description: str = "Expect dateofbirth_parsed be complete with no missing values"


class ExpectDateOfBirthToBeBetween(gxe.ExpectColumnValuesToBeBetween):
    column: str = 'dateofbirth_parsed'
    min_value: str = datetime(1900, 1, 1, 0, 0, 0).isoformat()
    max_value: str = datetime.today().isoformat()
    condition_parser: str = "pandas"
    row_condition: str = 'df["dateofbirth_parsed"].str[:10]  >= "1850-01-01" and df["dateofbirth_parsed"].str[:10] < "2025-01-01" and df["startdate_parsed"].str[:10] > "1900-01-01" and df["startdate_parsed"].str[:10] < "2100-01-01"'
    description: str = "Expect dateofbirth_parsed be complete with no missing values"


# add to GX context
context = gx.get_context(mode="file", project_root_dir=s3_target_location)

suite = gx.ExpectationSuite(name='person_reshape_suite')
suite.add_expectation(ExpectFirstNameColumnValueLength())
suite.add_expectation(ExpectSurnameColumnValueLength())
suite.add_expectation(ExpectUPRNColumnValueLengthsBetween())
suite.add_expectation(ExpectUPRNColumnValuesToMatchRegex())
suite.add_expectation(ExpectUPRNNotToBeNull())
suite.add_expectation(ExpectPersonTypeValuesToBeInSet())
suite.add_expectation(ExpectPreferredTitleValuesToBeInSet())
suite.add_expectation(ExpectPersonIDColumnValuesToBeUnique())
suite.add_expectation(ExpectPersonIDColumnValuesToNotBeNull())
suite.add_expectation(ExpectPersonIDAndPropertyReferenceColumnValuesToBeUniqueWithinRecord())
suite.add_expectation(ExpectPropertyRefColumnValuesToNotBeNull())
suite.add_expectation(ExpectPersonIDAndPaymentReferenceColumnValuesToBeUniqueWithinRecord())
suite.add_expectation(ExpectUPRNColumnValuesToNotBeNull())
suite.add_expectation(ExpectDateOfBirthColumnValuesToNotBeNull())
suite.add_expectation(ExpectDateOfBirthToBeBetween())

suite = context.suites.add(suite)
