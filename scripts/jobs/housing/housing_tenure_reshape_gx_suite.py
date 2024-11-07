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
    max_value: int = 1
    description: str = "Expect Member Fullname to be at least 1 character length"


class ExpectUPRNColumnValueLengthsBetween(gxe.ExpectColumnValueLengthsToBeBetween):
    column: str = "uprn"
    min_value: int = 11
    max_value: int = 12
    description: str = "Expect UPRN to be between 11 and 12 characters length inclusive"


class ExpectUPRNColumnValuesToMatchRegex(gxe.ExpectColumnValuesToMatchRegex):
    column: str = "uprn"
    regex: str = r"^[1-9]\d{10,11}"
    description: str = "Expect UPRN to match regex ^[1-9]\d{10,11} (starting with digit 1-9, followed by 10 or 11 digits"


class ExpectDescriptionValuesToBeInSet(gxe.ExpectColumnValuesToBeInSet):
    column: str = 'description'
    value_set: list = ['Asylum Seeker', 'Commercial Let', 'Temp Decant', 'Freehold', 'Freehold (Serv)', 'Introductory',
                       'Leasehold (RTB)', 'Lse 100% Stair', 'License Temp Ac', 'Mesne Profit Ac', 'Non-Secure',
                       'Private Garage', 'Registered Social Landlord', 'RenttoMortgage', 'Secure', 'Shared Owners',
                       'Short Life Lse', 'Private Sale LH', 'Shared Equity', 'Tenant Acc Flat', 'Temp B&B',
                       'Tenant Garage',
                       'Temp Hostel Lse', 'Temp Hostel', 'Temp Annex', 'Temp Private Lt', 'Temp Traveller']
    description: str = "Expect description values to contain one of the set"


class ExpectAssetTypeValuesToBeInSet(gxe.ExpectColumnValuesToBeInSet):
    column: str = 'asset_type'
    value_set: list = ['Block', 'Concierge', 'Dwelling', 'LettableNonDwelling', 'MediumRiseBlock', 'NA',
                       'TravellerSite']
    description: str = "Expect Asset Type values to contain one of the set"


class ExpectPersonTenureTypeValuesToBeInSet(gxe.ExpectColumnValuesToBeInSet):
    column: str = 'persontenuretype'
    value_set: list = ['Tenant', 'Leaseholder', 'Freeholder', 'HouseholdMember', 'Occupant']
    description: str = "Expect Asset Type values to contain one of the set"


class ExpectTenancyIDAndPropertyReferenceColumnValuesToBeUniqueWithinRecord(
    gxe.ExpectSelectColumnValuesToBeUniqueWithinRecord):
    column_list: list = ['tenancy_id', 'property_reference']
    description: str = "Expect Tenancy ID and Property Reference field to be unique for a record"


class ExpectTenancyIDAndPaymentReferenceColumnValuesToBeUniqueWithinRecord(
    gxe.ExpectSelectColumnValuesToBeUniqueWithinRecord):
    column_list: list = ['tenancy_id', 'paymentreference']
    description: str = "Expect Tenancy ID and Payment Reference field to be unique for a record"


class ExpectPaymentReferenceColumnNotToBeNull(gxe.ExpectColumnValuesToNotBeNull):
    column: str = "paymentreference"
    description: str = "Expect Payment Reference column to be complete with no missing values"


class ExpectTenancyIDColumnNotToBeNull(gxe.ExpectColumnValuesToNotBeNull):
    column: str = "tenancy_id"
    description: str = "Expect Tenancy ID column to be complete with no missing values"


class ExpectUPRNNotToBeNull(gxe.ExpectColumnValuesToNotBeNull):
    column: str = "uprn"
    description: str = "Expect UPRN column to be complete with no missing values"


class ExpectStartOfTenureDateColumnNotToBeNull(gxe.ExpectColumnValuesToNotBeNull):
    column: str = "startoftenuredate"
    description: str = "Expect Start of Tenure Date column to be complete with no missing values"


class ExpectTenureCodeColumnNotToBeNull(gxe.ExpectColumnValuesToNotBeNull):
    column: str = "tenure_code"
    description: str = "Expect Tenure Code column to be complete with no missing values"


# add to GX context
context = gx.get_context(mode="file", project_root_dir=s3_target_location)

suite = gx.ExpectationSuite(name='tenure_reshape_suite')
suite.add_expectation(ExpectTenancyIDAndPaymentReferenceColumnValuesToBeUniqueWithinRecord())
suite.add_expectation(ExpectMemberFullNameColumnValueLengthsBetween())
suite.add_expectation(ExpectUPRNColumnValueLengthsBetween())
suite.add_expectation(ExpectUPRNColumnValuesToMatchRegex())
suite.add_expectation(ExpectDescriptionValuesToBeInSet())
suite.add_expectation(ExpectAssetTypeValuesToBeInSet())
suite.add_expectation(ExpectTenancyIDAndPropertyReferenceColumnValuesToBeUniqueWithinRecord())
suite.add_expectation(ExpectPaymentReferenceColumnNotToBeNull())
suite.add_expectation(ExpectTenancyIDColumnNotToBeNull())
suite.add_expectation(ExpectUPRNNotToBeNull())
suite.add_expectation(ExpectStartOfTenureDateColumnNotToBeNull())
suite.add_expectation(ExpectTenureCodeColumnNotToBeNull())

suite = context.suites.add(suite)
