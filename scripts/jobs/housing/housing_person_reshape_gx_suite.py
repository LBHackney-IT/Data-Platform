# flake8: noqa: F821
from datetime import datetime
import sys

from awsglue.utils import getResolvedOptions
import great_expectations as gx
import great_expectations.expectations as gxe

arg_key = ['s3_target_location']
args = getResolvedOptions(sys.argv, arg_key)
locals().update(args)


# class ExpectFirstNameColumnValueLength(gxe.ExpectColumnValueLengthsToBeBetween):
#     column: str = "firstname"
#     min_value: int = 1
#     description: str = "Expect first name to be at least 1 character length"


class ExpectSurnameColumnValueLength(gxe.ExpectColumnValueLengthsToBeBetween):
    column: str = "surname"
    min_value: int = 1
    description: str = "Expect surname to be at least 1 character length"


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


class ExpectIsOrganisationColumnValuesToNotBeNull(gxe.ExpectColumnValuesToNotBeNull):
    column: str = 'isorganisation'
    description: str = "Expect isorganisation column (boolean) be complete with no missing values"


class ExpectIsOrganisationValuesToBeInSet(gxe.ExpectColumnValuesToBeInSet):
    column: str = 'isorganisation'
    value_set: list = [True, False]
    description: str = "Expect IsOrganisation field to be boolean value of true or false"


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


class ExpectDateOfBirthColumnValuesToNotBeNull(gxe.ExpectColumnValuesToNotBeNull):
    column: str = 'dateofbirth_parsed'
    description: str = "Expect dateofbirth_parsed be complete with no missing values"
    condition_parser: str = 'pandas'
    row_condition: str = 'isorganisation<>true'


class ExpectDateOfBirthToBeBetween(gxe.ExpectColumnValuesToBeBetween):
    column: str = 'dateofbirth_parsed'
    min_value: str = datetime(1900, 1, 1, 0, 0, 0).isoformat()
    max_value: str = datetime.today().isoformat()
    description: str = "Expect dateofbirth_parsed be complete with no missing values"


# add to GX context
context = gx.get_context(mode="file", project_root_dir=s3_target_location)

suite = gx.ExpectationSuite(name='person_reshape_suite')
# suite.add_expectation(ExpectFirstNameColumnValueLength())
suite.add_expectation(ExpectSurnameColumnValueLength())
suite.add_expectation(ExpectPersonTypeValuesToBeInSet())
suite.add_expectation(ExpectPreferredTitleValuesToBeInSet())
suite.add_expectation(ExpectPersonIDColumnValuesToBeUnique())
suite.add_expectation(ExpectPersonIDColumnValuesToNotBeNull())
suite.add_expectation(ExpectPersonIDAndPropertyReferenceColumnValuesToBeUniqueWithinRecord())
suite.add_expectation(ExpectPropertyRefColumnValuesToNotBeNull())
suite.add_expectation(ExpectPersonIDAndPaymentReferenceColumnValuesToBeUniqueWithinRecord())
suite.add_expectation(ExpectDateOfBirthColumnValuesToNotBeNull())
suite.add_expectation(ExpectDateOfBirthToBeBetween())
suite.add_expectation(ExpectIsOrganisationColumnValuesToNotBeNull())
suite.add_expectation(ExpectIsOrganisationValuesToBeInSet())

suite = context.suites.add(suite)
