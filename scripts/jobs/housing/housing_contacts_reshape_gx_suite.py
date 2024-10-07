import sys

from awsglue.utils import getResolvedOptions
import great_expectations as gx
import great_expectations.expectations as gxe

arg_key = ['s3_target_location']
args = getResolvedOptions(sys.argv, arg_key)
locals().update(args)

# add to GX context
context = gx.get_context(mode="file", project_root_dir=s3_target_location)

suite = gx.ExpectationSuite(name='contacts_reshape')
suite.add_expectation(
    gxe.ExpectColumnValuesToBeInSet(
        column='contacttype',
        value_set=['email', 'address', 'phone'])
)
suite.add_expectation(
    gxe.ExpectColumnValuesToBeInSet(
        column='subtype',
        value_set=['correspondenceAddress', 'mobile', 'home', 'work', 'other', 'landline'])
)
suite.add_expectation(
    gxe.ExpectColumnValuesToBeInSet(
        column='targettype',
        value_set=['person', 'organisation'])
)
suite.add_expectation(
    gxe.ExpectColumnValuesToBeUnique(
        column='value')
)
suite.add_expectation(
    gxe.ExpectSelectColumnValuesToBeUniqueWithinRecord(
        column_list=['target_id', 'value'])
)
suite.add_expectation(
    gxe.ExpectColumnValuesToNotBeNull(
        column='target_id')
)
suite.add_expectation(
    gxe.ExpectColumnValuesToNotBeNull(
        column='value')
)
suite.add_expectation(
    gxe.ExpectColumnValuesToNotBeNull(
        column='contacttype')
)
suite.add_expectation(
    gxe.ExpectColumnValuesToNotBeNull(
        column='subtype')
)

suite = context.suites.add(suite)
