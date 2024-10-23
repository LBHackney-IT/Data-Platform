# flake8: noqa: F821
from datetime import datetime
import sys

from awsglue.utils import getResolvedOptions
import great_expectations as gx
import great_expectations.expectations as gxe

arg_key = ['s3_target_location']
args = getResolvedOptions(sys.argv, arg_key)
locals().update(args)

# add to GX context
context = gx.get_context(mode="file", project_root_dir=s3_target_location)

suite = gx.ExpectationSuite(name='person_reshape_suite')
suite.add_expectation(
    gxe.ExpectColumnValueLengthsToBeBetween(
        column="firstname",
        min_value=1)
)
suite.add_expectation(
    gxe.ExpectColumnValueLengthsToBeBetween(
        column="surname",
        min_value=1)
)
suite.add_expectation(
    gxe.ExpectColumnValueLengthsToBeBetween(
        column="uprn",
        min_value=11,
        max_value=12)
)
suite.add_expectation(
    gxe.ExpectColumnValuesToMatchRegex(
        column="uprn",
        regex=r"^[1-9]\d{10,11}")
)
suite.add_expectation(
    gxe.ExpectColumnValuesToNotBeNull(
        column='uprn')
)
suite.add_expectation(
    gxe.ExpectColumnValuesToBeInSet(
        column='type',
        value_set=['Asylum Seeker', 'Commercial Let', 'Temp Decant', 'Freehold', 'Freehold (Serv)', 'Introductory',
                   'Leasehold (RTB)', 'Lse 100% Stair', 'License Temp Ac', 'Mesne Profit Ac', 'Non-Secure',
                   'Private Garage', 'Registered Social Landlord', 'RenttoMortgage', 'Secure', 'Shared Owners',
                   'Short Life Lse', 'Private Sale LH', 'Shared Equity', 'Tenant Acc Flat', 'Temp B&B', 'Tenant Garage',
                   'Temp Hostel Lse', 'Temp Hostel', 'Temp Annex', 'Temp Private Lt', 'Temp Traveller'])
)
suite.add_expectation(
    gxe.ExpectColumnValuesToBeInSet(
        column='person_type',
        value_set=['Tenant', 'HouseholdMember', 'Leaseholder', 'Freeholder', 'Occupant', 'HousingOfficer',
                   'HousingAreaManager'])
)
suite.add_expectation(
    gxe.ExpectColumnValuesToBeInSet(
        column='preferredtitle',
        value_set=['Dr', 'Master', 'Miss', 'Mr', 'Mrs', 'Ms', 'Other', 'Rabbi', 'Reverend'])
)
suite.add_expectation(
    gxe.ExpectColumnValuesToBeUnique(
        column='person_id')
)
suite.add_expectation(
    gxe.ExpectColumnValuesToNotBeNull(
        column='person_id')
)
suite.add_expectation(
    gxe.ExpectSelectColumnValuesToBeUniqueWithinRecord(
        column_list=['person_id', 'propertyreference'])
)
suite.add_expectation(
    gxe.ExpectColumnValuesToNotBeNull(
        column='propertyreference')
)
suite.add_expectation(
    gxe.ExpectSelectColumnValuesToBeUniqueWithinRecord(
        column_list=['person_id', 'paymentreference'])
)
suite.add_expectation(
    gxe.ExpectColumnValuesToNotBeNull(
        column='uprn')
)
suite.add_expectation(
    gxe.ExpectColumnValuesToNotBeNull(
        column='dateofbirth_parsed')
)
suite.add_expectation(
    gxe.ExpectColumnValuesToBeBetween(
        column='dateofbirth_parsed',
        min_value=datetime(1900, 1, 1, 0, 0, 0).isoformat(),
        max_value=datetime.today().isoformat()
    )
)

suite = context.suites.add(suite)
