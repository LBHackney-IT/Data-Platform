# flake8: noqa: F821
import sys

from awsglue.utils import getResolvedOptions
import great_expectations as gx
import great_expectations.expectations as gxe

arg_key = ['s3_target_location']
args = getResolvedOptions(sys.argv, arg_key)
locals().update(args)


class ExpectPropRefColumnValuesToBeUnique(gxe.ExpectColumnValuesToBeUnique):
    column: str = 'prop_ref'
    description: str = "Expect Prop Ref field to be unique for a property type"


class ExpectArrPatchNotToBeNull(gxe.ExpectColumnValuesToNotBeNull):
    column: str = "arr_patch"
    description: str = "Expect Arrears Patch column to be complete with no missing values"


class ExpectPropRefNotToBeNull(gxe.ExpectColumnValuesToNotBeNull):
    column: str = "prop_ref"
    description: str = "Expect Prop Ref column to be complete with no missing values"


# add to GX context
context = gx.get_context(mode="file", project_root_dir=s3_target_location)

suite = gx.ExpectationSuite(name='maproperty_suite')

suite.add_expectation(ExpectPropRefColumnValuesToBeUnique())
suite.add_expectation(ExpectArrPatchNotToBeNull())
suite.add_expectation(ExpectPropRefNotToBeNull())

suite = context.suites.add(suite)
