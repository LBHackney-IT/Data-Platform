# flake8: noqa: F821
from datetime import datetime
import sys

from awsglue.utils import getResolvedOptions
import great_expectations as gx
import great_expectations.expectations as gxe

arg_key = ['s3_target_location']
args = getResolvedOptions(sys.argv, arg_key)
locals().update(args)


class ExpectTagRefColumnValuesToBeUnique(gxe.ExpectColumnValuesToBeUnique):
    column: str = 'tag_ref'
    description: str = "Expect Tag Ref field to be unique for a tenancy"


class ExpectTagRefNotToBeNull(gxe.ExpectColumnValuesToNotBeNull):
    column: str = "tag_ref"
    description: str = "Expect Tag Ref column to be complete with no missing values"


class ExpectPropRefNotToBeNull(gxe.ExpectColumnValuesToNotBeNull):
    column: str = "prop_ref"
    description: str = "Expect Prop Ref column to be complete with no missing values"


class ExpectCoTNotToBeNull(gxe.ExpectColumnValuesToNotBeNull):
    column: str = "cot"
    description: str = "Expect Tenancy start date column (cot) to be complete with no missing values"


class ExpectTenureNotToBeNull(gxe.ExpectColumnValuesToNotBeNull):
    column: str = "tenure"
    description: str = "Expect tenure to be complete with no missing values"


class ExpectSaffRentAccNotToBeNull(gxe.ExpectColumnValuesToNotBeNull):
    column: str = "u_saff_rentacc"
    description: str = "Expect Saff rent account (payment ref) to be complete with no missing values"


class ExpectRentGroupRefNotToBeNull(gxe.ExpectColumnValuesToNotBeNull):
    column: str = "rentgrp_ref"
    description: str = "Expect Rent Group ref column to be complete with no missing values"


class ExpectEoTToBeBetween(gxe.ExpectColumnValuesToBeBetween):
    column: str = 'eot_parsed'
    min_value: str = datetime(1920, 1, 1, 0, 0, 0).isoformat()
    max_value: str = datetime.today().isoformat()
    description: str = "Expect eot_parsed be between 1920-01-01 and today's date"
    condition_parser: str = 'great_expectations'
    row_condition: str = 'col("eot_parsed").notNull()'


class ExpectCoTToBeBetween(gxe.ExpectColumnValuesToBeBetween):
    column: str = 'cot_parsed'
    min_value: str = datetime(1920, 1, 1, 0, 0, 0).isoformat()
    max_value: str = datetime.today().isoformat()
    description: str = "Expect cot_parsed be between 1920-01-01 and today's date"
    condition_parser: str = 'great_expectations'
    row_condition: str = 'col("cot").notNull()'


# add to GX context
context = gx.get_context(mode="file", project_root_dir=s3_target_location)

suite = gx.ExpectationSuite(name='matenancyagreement_suite')

suite.add_expectation(ExpectTagRefColumnValuesToBeUnique())
suite.add_expectation(ExpectTagRefNotToBeNull())
suite.add_expectation(ExpectPropRefNotToBeNull())
suite.add_expectation(ExpectCoTNotToBeNull())
suite.add_expectation(ExpectTenureNotToBeNull())
suite.add_expectation(ExpectSaffRentAccNotToBeNull())
suite.add_expectation(ExpectRentGroupRefNotToBeNull())
suite.add_expectation(ExpectEoTToBeBetween())
suite.add_expectation(ExpectCoTToBeBetween())

suite = context.suites.add(suite)
