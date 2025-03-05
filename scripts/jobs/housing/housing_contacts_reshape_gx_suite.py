# flake8: noqa: F821

import sys

from awsglue.utils import getResolvedOptions
import great_expectations as gx
import great_expectations.expectations as gxe


class ExpectContactTypeColumnValuesToBeInSet(gxe.ExpectColumnValuesToBeInSet):
    column: str = 'contacttype'
    value_set: list = ['email', 'address', 'phone']
    description: str = "Expect Contact Type to be one of email, address or phone"


class ExpectSubTypeColumnValuesToBeInSet(gxe.ExpectColumnValuesToBeInSet):
    column: str = 'subtype'
    value_set: list = ['mainNumber', 'emergencyContact', 'carer', 'wife', 'husband', 'spouse', 'child', 'sibling',
                       'relative', 'neighbour', 'doctor', 'socialWorker', 'other']
    description: str = "Expect Subtype values to be within set"


class ExpectTargetTypeColumnValuesToBeInSet(gxe.ExpectColumnValuesToBeInSet):
    column: str = 'targettype'
    value_set: list = ['person', 'organisation']
    description: str = "Expect Target Type values to be one of person or organisation"


class ExpectContactValueColumnValuesToBeUnique(gxe.ExpectColumnValuesToBeUnique):
    column: str = 'value'
    description: str = "Expect Value field to be unique for a contact type"


class ExpectTargetIDAndValueColumnValuesToBeUniqueWithinRecord(gxe.ExpectSelectColumnValuesToBeUniqueWithinRecord):
    column_list: list = ['target_id', 'value']
    description: str = "Expect Target ID and Value field to be unique for a record"


class ExpectTargetIDColumnValuesToNotBeNull(gxe.ExpectColumnValuesToNotBeNull):
    column: str = 'target_id'
    description: str = "Expect Target ID column to be complete with no nulls"


class ExpectContactValueColumnValuesToNotBeNull(gxe.ExpectColumnValuesToNotBeNull):
    column: str = 'value'
    description: str = "Expect Value column to be complete with no nulls"


class ExpectContactTypeColumnValuesToNotBeNull(gxe.ExpectColumnValuesToNotBeNull):
    column: str = 'contacttype'
    description: str = "Expect Contact Type column to be complete with no nulls"


class ExpectSubTypeColumnValuesToNotBeNull(gxe.ExpectColumnValuesToNotBeNull):
    column: str = 'subtype'
    description: str = "Expect Subtype column to be complete with no nulls"


arg_key = ['s3_target_location']
args = getResolvedOptions(sys.argv, arg_key)
locals().update(args)

# add to GX context
context = gx.get_context(mode="file", project_root_dir=s3_target_location)

suite = gx.ExpectationSuite(name='contacts_reshape_suite')

suite.add_expectation(ExpectContactTypeColumnValuesToBeInSet())
suite.add_expectation(ExpectSubTypeColumnValuesToBeInSet())
suite.add_expectation(ExpectTargetTypeColumnValuesToBeInSet())
suite.add_expectation(ExpectContactValueColumnValuesToBeUnique())
suite.add_expectation(ExpectTargetIDAndValueColumnValuesToBeUniqueWithinRecord())
suite.add_expectation(ExpectTargetIDColumnValuesToNotBeNull())
suite.add_expectation(ExpectContactValueColumnValuesToNotBeNull())
suite.add_expectation(ExpectContactTypeColumnValuesToNotBeNull())
suite.add_expectation(ExpectSubTypeColumnValuesToNotBeNull())

suite = context.suites.add(suite)
