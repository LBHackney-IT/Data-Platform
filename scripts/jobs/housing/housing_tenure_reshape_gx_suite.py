import great_expectations as gx
import great_expectations.expectations as gxe

context = gx.get_context(mode="file")

suite = gx.ExpectationSuite(name='tenure_reshape')
suite.add_expectation(
    gxe.ExpectColumnValueLengthsToBeBetween(
        column="member_fullname",
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
    gxe.ExpectColumnValuesToBeInSet(
        column='description',
        value_set=['Asylum Seeker', 'Commercial Let', 'Temp Decant', 'Freehold', 'Freehold (Serv)', 'Introductory',
                   'Leasehold (RTB)', 'Lse 100% Stair', 'License Temp Ac', 'Mesne Profit Ac', 'Non-Secure',
                   'Private Garage', 'Registered Social Landlord', 'RenttoMortgage', 'Secure', 'Shared Owners',
                   'Short Life Lse', 'Private Sale LH', 'Shared Equity', 'Tenant Acc Flat', 'Temp B&B', 'Tenant Garage',
                   'Temp Hostel Lse', 'Temp Hostel', 'Temp Annex', 'Temp Private Lt', 'Temp Traveller'])
)
suite.add_expectation(
    gxe.ExpectColumnValuesToBeInSet(
        column='asset_type',
        value_set=['Block', 'Concierge', 'Dwelling', 'LettableNonDwelling', 'MediumRiseBlock', 'NA', 'TravellerSite'])
)
suite.add_expectation(
    gxe.ExpectColumnValuesToBeInSet(
        column='persontenuretype',
        value_set=['Tenant', 'Leaseholder', 'Freeholder', 'HouseholdMember', 'Occupant'])
)
suite.add_expectation(
    gxe.ExpectColumnValuesToBeInSet(
        column='member_type',
        value_set=['person', 'organisation'])
)
suite.add_expectation(
    gxe.ExpectColumnValuesToBeUnique(
        column='person_id')
)
suite.add_expectation(
    gxe.ExpectSelectColumnValuesToBeUniqueWithinRecord(
        column_list=['tenancy_id', 'property_reference'])
)
suite.add_expectation(
    gxe.ExpectSelectColumnValuesToBeUniqueWithinRecord(
        column_list=['tenancy_id', 'paymentreference'])
)
suite.add_expectation(
    gxe.ExpectColumnValuesToNotBeNull(
        column='paymentreference')
)
suite.add_expectation(
    gxe.ExpectColumnValuesToNotBeNull(
        column='tenancy_id')
)
suite.add_expectation(
    gxe.ExpectColumnValuesToNotBeNull(
        column='uprn')
)
suite.add_expectation(
    gxe.ExpectColumnValuesToNotBeNull(
        column='startoftenuredate')
)
suite.add_expectation(
    gxe.ExpectColumnValuesToNotBeNull(
        column='tenure_code')
)
suite.add_expectation(
    gxe.ExpectColumnValuesToNotBeNull(
        column='dateofbirth')
)
suite.add_expectation(
    gxe.ExpectColumnValuesToNotBeNull(
        column='balance')
)
suite.add_expectation(
    gxe.ExpectColumnValuesToBeBetween(
        column='service_charge',
        min_value=0
    )
)
suite.add_expectation(
    gxe.ExpectColumnValuesToNotBeNull(
        column='billingfrequency')
)
