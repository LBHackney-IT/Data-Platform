# flake8: noqa: F821

import sys

from awsglue.utils import getResolvedOptions
import great_expectations as gx
import great_expectations.expectations as gxe

arg_key = ['s3_target_location']
args = getResolvedOptions(sys.argv, arg_key)
locals().update(args)


class ExpectUPRNColumnValueLengthsBetween(gxe.ExpectColumnValueLengthsToBeBetween):
    column: str = "uprn"
    min_value: int = 11
    max_value: int = 12
    description: str = "Expect UPRN to be between 11 and 12 characters length inclusive"


class ExpectUPRNColumnValuesToMatchRegex(gxe.ExpectColumnValuesToMatchRegex):
    column: str = "uprn"
    regex: str = "[1-9]\d{10,11}"
    description: str = "Expect UPRN to match regex ^[1-9]\d{10,11} (starting with digit 1-9, followed by 10 or 11 digits"


class ExpectUPRNNotToBeNull(gxe.ExpectColumnValuesToNotBeNull):
    column: str = "uprn"
    description: str = "Expect UPRN column to be complete with no missing values"


class ExpectAssetIDNotToBeNull(gxe.ExpectColumnValuesToNotBeNull):
    column: str = "asset_id"
    description: str = "Expect Asset ID column to be complete with no missing values"


class ExpectAssetTypeNotToBeNull(gxe.ExpectColumnValuesToNotBeNull):
    column: str = "assettype"
    description: str = "Expect Asset Type column to be complete with no missing values"


# add to GX context
context = gx.get_context(mode="file", project_root_dir=s3_target_location)

suite = gx.ExpectationSuite(name='assets_reshape_suite')

suite.add_expectation(ExpectUPRNColumnValueLengthsBetween())
suite.add_expectation(ExpectUPRNColumnValuesToMatchRegex())
suite.add_expectation(ExpectUPRNNotToBeNull())
suite.add_expectation(ExpectAssetIDNotToBeNull())
suite.add_expectation(ExpectAssetTypeNotToBeNull())

suite = context.suites.add(suite)
