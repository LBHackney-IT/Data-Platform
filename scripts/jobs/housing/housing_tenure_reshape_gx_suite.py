# flake8: noqa: F821

import sys

from awsglue.utils import getResolvedOptions
import great_expectations as gx
import great_expectations.expectations as gxe

arg_key = ['s3_target_location']
args = getResolvedOptions(sys.argv, arg_key)
locals().update(args)


class ExpectMemberFullNameColumnValueLengthsBetween(gxe.ExpectColumnValueLengthsToBeBetween):
    column: str = "member_fullname"
    min_value: int = 1
    description: str = "Expect Member Fullname to be at least 1 character length"


class ExpectDescriptionValuesToBeInSet(gxe.ExpectColumnValuesToBeInSet):
    column: str = 'description'
    value_set: list = ['Asylum Seeker', 'Commercial Let', 'Temp Decant', 'Freehold', 'Freehold (Serv)', 'Introductory',
                       'Leasehold (RTB)', 'Lse 100% Stair', 'License Temp Ac', 'Mesne Profit Ac', 'Non-Secure',
                       'Private Garage', 'Registered Social Landlord', 'RenttoMortgage', 'Secure', 'Shared Owners',
                       'Short Life Lse', 'Private Sale LH', 'Shared Equity', 'Tenant Acc Flat', 'Temp B&B',
                       'Tenant Garage', 'Temp Hostel Lse', 'Temp Hostel', 'Temp Annex', 'Temp Private Lt',
                       'Temp Traveller']
    description: str = "Expect description values to contain one of the set"


class ExpectMemberIsResponsibleValuesToBeInSet(gxe.ExpectColumnValuesToBeInSet):
    column: str = 'member_is_responsible'
    value_set: list = [True, False]
    description: str = "Expect member_is_responsible field to be boolean value of true or false"


class ExpectIsMutualExchangeValuesToBeInSet(gxe.ExpectColumnValuesToBeInSet):
    column: str = 'ismutualexchange'
    value_set: list = [True, False]
    description: str = "Expect ismutualexchange field to be boolean value of true or false"


class ExpectTenancyIDAndPropertyReferenceColumnValuesToBeUniqueWithinRecord(
    gxe.ExpectSelectColumnValuesToBeUniqueWithinRecord):
    column_list: list = ['tenancy_id', 'property_reference']
    description: str = "Expect Tenancy ID and Property Reference field to be unique for a record"


class ExpectTenancyIDAndPaymentReferenceColumnValuesToBeUniqueWithinRecord(
    gxe.ExpectSelectColumnValuesToBeUniqueWithinRecord):
    column_list: list = ['tenancy_id', 'paymentreference']
    description: str = "Expect Tenancy ID and Payment Reference field to be unique for a record"


class ExpectTenancyIDColumnNotToBeNull(gxe.ExpectColumnValuesToNotBeNull):
    column: str = "tenancy_id"
    description: str = "Expect Tenancy ID column to be complete with no missing values"


class ExpectTagRefColumnNotToBeNull(gxe.ExpectColumnValuesToNotBeNull):
    column: str = "uh_ten_ref"
    description: str = "Expect Tag Ref column to be complete with no missing values"


class ExpectStartOfTenureDateColumnNotToBeNull(gxe.ExpectColumnValuesToNotBeNull):
    column: str = "startoftenuredate"
    description: str = "Expect Start of Tenure Date column to be complete with no missing values"


class ExpectEndOfTenureDateColumnToBeNull(gxe.ExpectColumnValuesToBeNull):
    column: str = "endoftenuredate"
    description: str = "Expect End of Tenure Date column to be null with no default values"
    condition_parser: str = 'pandas'
    row_condition: str = 'isterminated<>False'


class ExpectTenureCodeColumnNotToBeNull(gxe.ExpectColumnValuesToNotBeNull):
    column: str = "tenure_code"
    description: str = "Expect Tenure Code column to be complete with no missing values"


class ExpectTenureCodeValuesToBeInSet(gxe.ExpectColumnValuesToBeInSet):
    column: str = 'tenure_code'
    value_set: list = ['ASY', 'COM', 'DEC', 'FRE', 'FRS', 'INT', 'LEA', 'LHS', 'LTA', 'MPA', 'NON', 'PVG', 'SEC', 'SHO',
                       'SLL', 'SPS', 'SSE', 'TAF', 'TBB', 'TGA', 'THL', 'THO', 'TLA', 'TPL', 'TRA']
    description: str = "Expect tenure code field to contain one of the set"


# add to GX context
context = gx.get_context(mode="file", project_root_dir=s3_target_location)

suite = gx.ExpectationSuite(name='tenure_reshape_suite')
suite.add_expectation(ExpectTenancyIDAndPaymentReferenceColumnValuesToBeUniqueWithinRecord())
suite.add_expectation(ExpectMemberFullNameColumnValueLengthsBetween())
suite.add_expectation(ExpectDescriptionValuesToBeInSet())
suite.add_expectation(ExpectMemberIsResponsibleValuesToBeInSet())
suite.add_expectation(ExpectTenancyIDAndPropertyReferenceColumnValuesToBeUniqueWithinRecord())
suite.add_expectation(ExpectTenancyIDColumnNotToBeNull())
suite.add_expectation(ExpectStartOfTenureDateColumnNotToBeNull())
suite.add_expectation(ExpectEndOfTenureDateColumnToBeNull())
suite.add_expectation(ExpectTenureCodeColumnNotToBeNull())
suite.add_expectation(ExpectTagRefColumnNotToBeNull())
suite.add_expectation(ExpectTenureCodeValuesToBeInSet())

suite = context.suites.add(suite)
