"""
This job tries to find and predict the same (or similar) person in a given dataset. Therefore, this job tries to help
remove duplicate information present in the dataset. The difference can be subtle that makes the problem difficult to
address. Few such examples are:

1. Slight difference in spelling of the name of the person in multiple records (e.g. John in some places while Jon at
   other places for the same person)
2. Using initials for e.g. Alexander Graham Bell in some places and A. G. Bell in other places
3. Some records missing vital information like title, date of birth etc. while other do not.

This situation is present in many of the dataset and this job is an attempt to address such problems at scale tries to
link all record of the same person
.
The job can be run in local mode (i.e. on your local environment) and also on AWS (see Usage below).

Usage:
To run in local mode:
set the mode to 'local' and provide the path od data set of your local machine
--execution_mode=local
--person_reshape_data_path="<path/to/local/data>"
--assets_reshape_data_path="<path/to/local/data>"
--tenure_reshape_data_path="<path/to/local/data>"
--council_tax_account_data_path="<path/to/local/data>"
--council_tax_liability_person_data_path="<path/to/local/data>"
--council_tax_non_liability_person_data_path="<path/to/local/data>"
--council_tax_occupation_data_path="<path/to/local/data>"
--council_tax_property_data_path="<path/to/local/data>"
--housing_benefit_member_data_path="<path/to/local/data>"
--housing_benefit_household_data_path="<path/to/local/data>"
--housing_benefit_rent_assessment_data_path="<path/to/local/data>"
--housing_benefit_tax_calc_stmt_data_path="<path/to/local/data>"
--parking_permit_data_path="<path/to/local/data>"
--output_path="<path/to/local/data>"

To run in AWS mode:
No need to provide mode (or optionally set it to 'aws')
--person_reshape_data_path=s3://<path/to/data>
--assets_reshape_data_path=s3://<path/to/data>
--tenure_reshape_data_path=s3://<path/to/data>
--council_tax_account_data_path=s3://<path/to/data>
--council_tax_liability_person_data_path=s3://<path/to/data>
--council_tax_non_liability_person_data_path=s3://<path/to/data>
--council_tax_occupation_data_path=s3://<path/to/data>
--council_tax_property_data_path=s3://<path/to/data>
--housing_benefit_member_data_path=s3://<path/to/data>
--housing_benefit_household_data_path=s3://<path/to/data>
--housing_benefit_rent_assessment_data_path=s3://<path/to/data>
--housing_benefit_tax_calc_stmt_data_path=s3://<path/to/data>
--parking_permit_data_path="s3://<path/to/data>
--output_path=s3://<path/to/output_location>
--additional-python-modules=abydos==0.5.0
--TempDir = s3://<<path/to/spark_tmp/>
"""


import re

import pandas as pd
from abydos.distance import Cosine
from abydos.phonetic import DoubleMetaphone

from graphframes import GraphFrame
from pyspark.ml import Pipeline
from pyspark.ml.classification import LogisticRegression, LogisticRegressionModel
from pyspark.ml.evaluation import BinaryClassificationEvaluator, MulticlassClassificationEvaluator
from pyspark.ml.feature import StringIndexer, OneHotEncoder, VectorAssembler
from pyspark.ml.functions import vector_to_array
from pyspark.ml.tuning import ParamGridBuilder, CrossValidator, CrossValidatorModel
from pyspark.sql import DataFrame, SparkSession, Column
from pyspark.sql.functions import to_date, col, lit, broadcast, udf, when, substring, lower, concat_ws, soundex, \
    regexp_replace, trim, sort_array, split, array_join, struct
from pyspark.sql.pandas.functions import pandas_udf
from pyspark.sql.types import StructType, StructField, StringType, DateType, BooleanType, DoubleType


extracted_name_schema = StructType([
    StructField("entity_type", StringType(), True),
    StructField("title", StringType(), True),
    StructField("first_name", StringType(), True),
    StructField("middle_name", StringType(), True),
    StructField("last_name", StringType(), True)
])

features_schema = StructType([
    StructField("first_name_similar", BooleanType(), True),
    StructField("middle_name_similar", BooleanType(), True),
    StructField("last_name_similar", BooleanType(), True),
    StructField("name_similarity", DoubleType(), True),
    StructField("address_line_1_similarity", DoubleType(), True),
    StructField("address_line_2_similarity", DoubleType(), True),
    StructField("full_address_similarity", DoubleType(), True),
])


@udf(returnType=extracted_name_schema)
def extract_name_udf(name: str):
    return extract_person_name(name)


def extract_person_name(name: str) -> (str, str, str, str, str):
    """Extracts parts of name from the combined name. Few examples are:
        1. "Turing, MR Alan Mathison" will return: "Person", "Mr", "Alan", "Mathison", "Turing"
        2. "King, Ada Augusta" will return: "Person", None, "Ada", "Augusta", "King"
        3. "Renting company LTD" will return: "Business", None, None, None, None
    There will be false positives i.e. when a belongs to business it is tagged as person or vice-versa.

    Args:
        name: combined name including first name, last name, title etc.
    Returns: A quadruple where each element represents title, first_name, middle_name, last_name
    """
    common_titles = ["mr", "mr.", "mrs", "mrs.", "ms", "ms.", "miss", "master", "exor", "exors", "executors", "of",
                     "rep", "per", "pers", "reps", "prep", "&prep", "pe", "personal", "repmr", "repmrs", "repsmr",
                     "repsmrs", "the", "reps.of",
                     "dr", "dr.", "prof", "profeessor", "rev", "lady", "dame", "sir", "lord"]
    common_titles_subset_with_space = ["mr ", "mr. ", "mrs ", "mrs. ", "ms ", "ms. ", "miss ", "exor ", "exors "]

    common_business_types_small = ["ltd", "llp", "plc", "pvt", "&", "lbh", " inc,", "llc", "bv"]
    common_business_types = ["limited",
                             "association", "housing", "trust", "home", "society", "estates", "properties", "property",
                             "group", "fund", "invest", "investment", "estate", "development", "board",
                             "letting", "agent", "accommodat", "occupier", "residential", "relocation",
                             "accomodation", "traveller", "living", "education", "residence", "resident",
                             "organisation", "management", "international", "national", "clinic", "solutions",
                             "service", "system", "security", "move", "store", "academy", "ventures", "rent",
                             "account", "building", "company", "congregation", "project", "residencial", "centre",
                             "sport", "assets", "developer", "asylum", "committee", "school", "apartment",
                             "chartered", "consultant", "enterprise", "corporate", "associates", "studios",
                             "consultancy", "borough",
                             "holdings", "agency", "propperties", "hotel", "lodge", "university", "proeprties",
                             "hackney", "empty", "void", "london", "council"]

    deceased_flags = ["decd", "dec'd", "d'cead", "desd", "d'ced", "de'd", "def'd", "dea's", "dece'd", "dec", "dec`d",
                      "deceased"]

    junk_data = ["test", "owner"]

    # Don't try to extract person's name if the supplied name belong to business or is empty.
    if not name or any(junk in name.casefold() for junk in junk_data):
        return "Unknown", None, None, None, None

    if any(business in name.casefold() for business in common_business_types) or (
            any(business in name.casefold() for business in common_business_types_small) and
            not any(t in name.casefold() for t in common_titles_subset_with_space)):
        return "Business", None, None, None, None

    person_title, first_name, middle_name, last_name = None, None, None, None
    deceased_title = "(Deceased)" if any(dec in name.casefold() for dec in deceased_flags) else None
    name_cleaned = re.sub(r"\([^()]*\)", " ", name)  # removes parentheses

    name_list = [n.strip() for n in name_cleaned.split(",") if n.strip()]
    if len(name_list) == 1:
        parts_of_name = [n for n in name_list[0].split() if n.casefold() not in deceased_flags]
        title_finder = [t for t in parts_of_name if t.casefold() in common_titles]
        person_title = " ".join(title_finder) if len(title_finder) else None
        name_without_title = [n for n in parts_of_name if n.casefold() not in common_titles]
        if len(name_without_title) == 1:
            last_name = name_without_title[0]
        elif len(name_without_title) == 2:
            first_name, last_name = name_without_title
        elif len(name_without_title) == 3:
            first_name, middle_name, last_name = name_without_title
        elif len(name_without_title) > 3:
            first_name = name_without_title[0]
            last_name = name_without_title[-1]
            middle_name = " ".join(name_without_title[1:-1])
    elif len(name_list) == 2:
        title_finder = [t for t in name_list[0].split() if t.casefold() in common_titles]
        person_title = " ".join(title_finder) if len(title_finder) else None
        last_name = " ".join(
            [n for n in name_list[0].split() if n and n.casefold() not in deceased_flags + common_titles])
        title_with_name = name_list[1].split()
        if not person_title:
            title_finder = [t for t in title_with_name if t.casefold() in common_titles]
            person_title = " ".join(title_finder) if len(title_finder) else None
        remaining_name = [n for n in title_with_name if
                          n.casefold() != (person_title or "").casefold() and n.casefold() not in common_titles and
                          n.casefold() not in [".", "&"]]

        if len(remaining_name) == 1:
            first_name = remaining_name[0]
        elif len(remaining_name) == 2:
            first_name, middle_name = remaining_name
        elif len(remaining_name) > 2:
            first_name = remaining_name[0]
            middle_name = ' '.join(remaining_name[1:])  # middle name includes anything not in first name or last name

    title = " ".join(filter(None, (person_title, deceased_title))).strip() if person_title or deceased_title else None
    last_name = last_name if last_name else None

    return "Person", title, first_name, middle_name, last_name


def categorise_title(title: Column) -> Column:
    """A helper function categorise title. To be used in DataFrame:
    If a name contain multiple titles for e.g. Mr. & Mrs. Simpson, then only one title will be selected, Below is the
    priority list (priority goes from highest to least):

    * master
    * ms
    * mrs
    * miss
    * mr
    * dame
    * lady
    * lord
    * prof
    * dr
    * rev
    * sir
    * rabbi

    Args:
        title: Column containing title

    Returns:
        Column have one of the above category

    """
    category_master = title.contains("master")  # Priority 1
    category_ms = title.contains("ms")  # Priority 2
    category_mrs = title.contains("mrs")  # Priority 3
    category_miss = title.contains("miss")  # Priority 4
    category_mr = title.contains("mr")  # Priority 5
    category_dame = title.contains("dame")  # Priority 6
    category_lady = title.contains("lady")  # Priority 7
    category_lord = title.contains("lord")  # Priority 8
    category_prof = title.contains("prof")  # Priority 9
    category_dr = title.contains("dr")  # Priority 10
    category_rev = title.contains("rev")  # Priority 11
    category_sir = title.contains("sir")  # Priority 12
    category_rabbi = title.contains("rabbi")  # Priority 13

    return when(category_master, lit("master")) \
        .when(category_ms, lit("ms")) \
        .when(category_mrs, lit("mrs")) \
        .when(category_miss, lit("miss")) \
        .when(category_mr, lit("mr")) \
        .when(category_dame, lit("dame")) \
        .when(category_lady, lit("lady")) \
        .when(category_lord, lit("lord")) \
        .when(category_prof, lit("prof")) \
        .when(category_dr, lit("dr")) \
        .when(category_rev, lit("rev")) \
        .when(category_sir, lit("sir")) \
        .when(category_rabbi, lit("rabbi")) \
        .otherwise("unknown")


def standardize_name(name: Column) -> Column:
    """Applies following rules to the names:
    If the string is null return empty string otherwise apply below rules:

    * Substitute all zeros (0) with O
    * Substitute all ones (1) with L
    * Remove following characters romt the start of the name: ampersand (&), asterisk(*), dot(.), any forward-slash or
    back-slash
    * Remove any leading or trailing whitespace
    * lower case the name

    Args:
        name: name of the columns and should be of type Column

    Returns:
        Column after applying the rules

    """
    return when(name.isNull(), lit("")) \
        .otherwise(
        lower(trim(regexp_replace(regexp_replace(regexp_replace(name, "0", "O"), "1", "L"), "^[\\&*./\\\]+", ""))))


def standardize_full_name(first_name: Column, middle_name: Column, last_name: Column) -> Column:
    """A Dataframe helper function to sort person's name. This will help to deal with out-of-order names. For example if
    the original name 'Alexander Graham Bell' is mistakenly recorded as 'Graham Alexander Bell' in one system and as
    'Bell Alexander Graham' in another system, this function will convert both the names as 'Alexander Bell Graham'.
    This will make our model more robust for out-of-order names.

    Args:
        first_name: Column name containing the first name.
        middle_name: Column name containing the middle name.
        last_name: Column name containing the last name.

    Returns:
        A single name with parts of the name alphabetically sorted.
    """
    return trim(array_join(sort_array(split(concat_ws(" ", first_name, middle_name, last_name), " ")), " ", ""))


def standardize_address_line(address_line: Column) -> Column:
    """A DataFrame helper function that converts null or none to empty string i.e. ""

    Args:
        address_line: Columns containing data
    Returns:
        Column after converting Null or None to empty string.

    """
    return when(address_line.isNull(), lit("")).otherwise(trim(lower(address_line)))


def full_address(address_line_1: Column, address_line_2: Column, address_line_3: Column,
                 address_line_4: Column) -> Column:
    """A DataFrame helper function that joins all the parts of the address to form a single address. For example if the
    address is:

    100 House Number        (Line 1)

    Nice Street             (Line 2)

    Some Council            (Line 3)

    London                  (Line 4)

    This will be turned into: 100 House Number Nice Street Some Council London

    Args:
        address_line_1: Line 1 of the address
        address_line_2: Line 2 of the address
        address_line_3: Line 3 of the address
        address_line_4: Line 4 of the address

    Returns:
        Full address after joining all the lines.

    """
    return trim(concat_ws(" ", address_line_1, address_line_2, address_line_3, address_line_4))


def prepare_clean_housing_data(spark: SparkSession, person_reshape_data_path: str, assets_reshape_data_path: str,
                               tenure_reshape_data_path: str) -> DataFrame:
    """A function to prepare and clean housing data. Data comes from multiple sources. This function is specific to this
    particular data source. For a new data source please add a new function.

    Args:
        spark: SparkSession
        person_reshape_data_path: Path of the S3 (or local) folder containing person reshape data
        assets_reshape_data_path: Path of the S3 (or local) folder containing assets reshape data
        tenure_reshape_data_path: Path of the S3 (or local) folder containing tenure reshape data

    Returns:
        A DataFrame after preparing data from multiple sources and cleaning it.

    """
    person_reshape = spark.read.parquet(person_reshape_data_path)
    assets_reshape = spark.read.parquet(assets_reshape_data_path)
    tenure_reshape = spark.read.parquet(tenure_reshape_data_path)

    housing = person_reshape \
        .join(assets_reshape, person_reshape["assetid"] == assets_reshape["asset_id"], how="left") \
        .join(tenure_reshape, person_reshape["person_id"] == tenure_reshape["person_id"], how="left") \
        .filter(person_reshape["type"].isin(["Secure", "Introductory", "Mense Profit Ac", "Leasehold (RTB)"])) \
        .withColumn("source", lit("housing")) \
        .withColumn("extracted_name", extract_name_udf(col("member_fullname"))) \
        .withColumn("entity_type",
                    when(lower(col("member_type")) == "person", lit("Person"))
                    .when(lower(col("member_type")) == "organisation", lit("Business"))
                    .otherwise(lit("Unknown"))) \
        .withColumn("title",
                    when((col("extracted_name.title").isNull()) |
                         (lower(col("extracted_name.title")) == lower(col("preferredTitle"))), col("preferredTitle"))
                    .otherwise(concat_ws(" ", col("preferredTitle"), col("extracted_name.title")))) \
        .withColumn("first_name", col("extracted_name.first_name")) \
        .withColumn("middle_name", col("extracted_name.middle_name")) \
        .withColumn("last_name", col("extracted_name.last_name")) \
        .withColumn("dob", to_date(substring(person_reshape["dateofbirth"], 1, 10), format="yyyy-MM-dd")) \
        .withColumn("date_of_birth",  # null value represented by 1900-01-01, so converting 1900-01-01 to null
                    when(col("dob") == to_date(lit("1900-01-01"), "yyyy-MM-dd"), lit(None).cast(DateType()))
                    .otherwise(col("dob"))) \
        .withColumnRenamed("postcode", "post_code") \
        .withColumnRenamed("addressline1", "address_line_1") \
        .withColumnRenamed("addressline2", "address_line_2") \
        .withColumnRenamed("addressline3", "address_line_3") \
        .withColumnRenamed("addressline4", "address_line_4") \
        .withColumnRenamed("placeOfBirth", "place_of_birth") \
        .select(col("source"), person_reshape["person_id"], person_reshape["uprn"], col("entity_type"), col("title"),
                col("first_name"), col("middle_name"), col("last_name"), col("date_of_birth"),
                col("post_code"), col("address_line_1"), col("address_line_2"), col("address_line_3"),
                col("address_line_4"))

    return housing


def standardize_housing_data(housing_cleaned: DataFrame) -> DataFrame:
    """Standardize housing data. This function convert all the custom names (coming from their respective sources to
    standard names that will be used by various other functions like feature engineering etc.)
    The DataFrame returned will have the following columns:

    * source: Source of the data like parking, tax etc. Should be of type string and cannot be blank.
    * source_id: Unique ID for reach record. It's ok to have same person with different source_id.
    Should be of type string and cannot be blank.
    * uprn: UPRN of the address. Should be of type string and can be blank.
    * title: Title of the person. Should be of type string and can be blank.
    * first_name: First name of the person. Should be of type string and can be blank.
    * middle_name: Middle name of the person. Should be of type string and can be blank.
    * last_name: Last name of the person. Should be of type string and can be blank.
    * name: Concatenation of first, middle and last name after sorting alphabetically of the person.
    Should be of type string and can be blank.
    * date_of_birth: Date of birth of the person. Should be of type Date and can be blank.
    * post_code: Postal code of the address. Should be of type string and can be blank.
    * address_line_1: First line of the address. Should be of type string and can be blank.
    * address_line_2: Second line of the address. Should be of type string and can be blank.
    * address_line_3: Third line of the address. Should be of type string and can be blank.
    * address_line_4: Fourth line of the address. Should be of type string and can be blank.
    * full_address: Concatenation of address line 1, address line 2, address line 3, address line 4 in that order.
    Should be of type string and can be blank.

    Args:
        housing_cleaned: housing DataFrame after preparing and cleaning it.

    Returns:
        A housing DataFrame with all the standard columns listed above.

    """
    housing = housing_cleaned \
        .filter(col("entity_type") == "Person") \
        .drop(col("entity_type")) \
        .withColumnRenamed("person_id", "source_id") \
        .withColumn("title", categorise_title(lower(col("title")))) \
        .withColumn("first_name", standardize_name(col("first_name"))) \
        .withColumn("middle_name", standardize_name(col("middle_name"))) \
        .withColumn("last_name", standardize_name(col("last_name"))) \
        .withColumn("name", standardize_full_name(col("first_name"), col("middle_name"), col("last_name"))) \
        .withColumn("post_code", lower(col("post_code"))) \
        .withColumn("address_line_1", standardize_address_line(col("address_line_1"))) \
        .withColumn("address_line_2", standardize_address_line(col("address_line_2"))) \
        .withColumn("address_line_3", standardize_address_line(col("address_line_3"))) \
        .withColumn("address_line_4", standardize_address_line(col("address_line_4"))) \
        .withColumn("full_address", full_address(col("address_line_1"), col("address_line_2"), col("address_line_3"),
                                                 col("address_line_4"))) \
        .select(col("source"), col("source_id"), col("uprn"), col("title"), col("first_name"), col("middle_name"),
                col("last_name"), col("name"), col("date_of_birth"), col("post_code"), col("address_line_1"),
                col("address_line_2"), col("address_line_3"), col("address_line_4"), col("full_address")) \
        .dropDuplicates(["source_id", "uprn", "date_of_birth"])

    return housing


def prepare_clean_council_tax_data(spark: SparkSession, council_tax_account_data_path: str,
                                   council_tax_liability_person_data_path: str,
                                   council_tax_non_liability_person_data_path: str,
                                   council_tax_occupation_data_path: str,
                                   council_tax_property_data_path: str) -> DataFrame:
    """A function to prepare and clean council tax data. Data comes from multiple sources. This function is specific to
    this particular data source. For a new data source please add a new function.

    Args:
        spark: SparkSession
        council_tax_account_data_path: Path of the S3 (or local) folder containing council tax account data
        council_tax_liability_person_data_path: Path of the S3 (or local) folder containing council tax liability data
        council_tax_non_liability_person_data_path: Path of the S3 (or local) folder containing council tax
        non-liability data
        council_tax_occupation_data_path: Path of the S3 (or local) folder containing council tax occupation data
        council_tax_property_data_path: Path of the S3 (or local) folder containing council tax property data

    Returns:
        A DataFrame after preparing data from multiple sources and cleaning it.

    """
    council_tax_account = spark.read.parquet(council_tax_account_data_path)
    council_tax_liability_person = spark.read.parquet(council_tax_liability_person_data_path)
    council_tax_non_liability_person = spark.read.parquet(council_tax_non_liability_person_data_path)
    council_tax_occupation = spark.read.parquet(council_tax_occupation_data_path) \
        .filter((col("live_ind") == 1) & (col("vacation_date") > col("import_datetime")))
    council_tax_property = spark.read.parquet(council_tax_property_data_path)

    council_tax_property_occupancy = council_tax_occupation \
        .join(council_tax_property, "property_ref") \
        .withColumnRenamed("postcode", "post_code") \
        .withColumnRenamed("addr1", "address_line_1") \
        .withColumnRenamed("addr2", "address_line_2") \
        .withColumnRenamed("addr3", "address_line_3") \
        .withColumnRenamed("addr4", "address_line_4") \
        .select(col("uprn"), col("account_ref"), col("occupation_date"), col("vacation_date"), col("post_code"),
                col("address_line_1"), col("address_line_2"), col("address_line_3"), col("address_line_4"))

    liable_types = broadcast(
        spark.createDataFrame([
            (0, 'Non-liable'),
            (1, 'Joint & Several'),
            (2, 'Freeholder'),
            (3, 'Leaseholder'),
            (4, 'Tenant'),
            (5, 'Licencee'),
            (6, 'Resident'),
            (7, 'Owner'),
            (8, 'Assumed'),
            (9, 'VOID'),
            (10, 'Other'),
            (11, 'Suspense'),
            (12, 'CTax Payer'),
            (-1, '(DATA ERROR)')]).toDF("liability_id", "liability_type"))

    council_tax_lead_person = council_tax_account \
        .join(liable_types, col("lead_liab_pos") == col("liability_id")) \
        .withColumn("source", lit("council_tax")) \
        .withColumn("sub_source", lit("lead")) \
        .withColumn("position", lit(0)) \
        .withColumnRenamed("lead_liab_name", "name") \
        .withColumn("extracted_name", extract_name_udf(col("name"))) \
        .select(col("source"), col("account_ref"), col("party_ref"), col("liability_type"), col("sub_source"),
                col("position"), col("extracted_name.*"), col("name"))

    council_tax_liable_person = council_tax_liability_person \
        .join(liable_types, col("liab_pos") == col("liability_id")) \
        .withColumn("source", lit("council_tax")) \
        .withColumn("sub_source", lit("liable")) \
        .withColumn("position", col("liab_pers_occ")) \
        .withColumnRenamed("liab_name", "name") \
        .withColumn("extracted_name", extract_name_udf(col("name"))) \
        .select(col("source"), col("account_ref"), col("party_ref"), col("liability_type"), col("sub_source"),
                col("position"), col("extracted_name.*"), col("name"))

    council_tax_non_liable_person = council_tax_non_liability_person \
        .withColumn("source", lit("council_tax")) \
        .withColumn("sub_source", lit("non liable")) \
        .withColumn("liability_type", lit(None).cast(StringType())) \
        .withColumn("position", col("nonliab_occ")) \
        .withColumnRenamed("nonliab_name", "name") \
        .withColumn("extracted_name", extract_name_udf(col("name"))) \
        .select(col("source"), col("account_ref"), col("party_ref"), col("liability_type"), col("sub_source"),
                col("position"), col("extracted_name.*"), col("name"))

    council_tax_person = council_tax_lead_person.union(council_tax_liable_person).union(council_tax_non_liable_person) \
        .join(council_tax_property_occupancy, "account_ref")

    return council_tax_person


def standardize_council_tax_data(council_tax_cleaned: DataFrame) -> DataFrame:
    """Standardize council tax data. This function convert all the custom names (coming from their respective sources to
    standard names that will be used by various other functions like feature engineering etc.)
    The DataFrame returned will have the following columns:

    * source: Source of the data like parking, tax etc. Should be of type string and cannot be blank.
    * source_id: Unique ID for reach record. It's ok to have same person with different source_id.
    Should be of type string and cannot be blank.
    * uprn: UPRN of the address. Should be of type string and can be blank.
    * title: Title of the person. Should be of type string and can be blank.
    * first_name: First name of the person. Should be of type string and can be blank.
    * middle_name: Middle name of the person. Should be of type string and can be blank.
    * last_name: Last name of the person. Should be of type string and can be blank.
    * name: Concatenation of first, middle and last name after sorting alphabetically of the person.
    Should be of type string and can be blank.
    * date_of_birth: Date of birth of the person. Should be of type Date and can be blank.
    * post_code: Postal code of the address. Should be of type string and can be blank.
    * address_line_1: First line of the address. Should be of type string and can be blank.
    * address_line_2: Second line of the address. Should be of type string and can be blank.
    * address_line_3: Third line of the address. Should be of type string and can be blank.
    * address_line_4: Fourth line of the address. Should be of type string and can be blank.
    * full_address: Concatenation of address line 1, address line 2, address line 3, address line 4 in that order.
    Should be of type string and can be blank.

    Args:
        council_tax_cleaned: council tax DataFrame after preparing and cleaning it.

    Returns:
        A council tax DataFrame with all the standard columns listed above.

    """
    council_tax = council_tax_cleaned \
        .filter(col("entity_type") == "Person") \
        .drop(col("entity_type")) \
        .withColumn("source_id", concat_ws("-", col("account_ref"), col("party_ref"), col("position"))) \
        .withColumn("date_of_birth", lit(None).cast(DateType())) \
        .withColumn("title", categorise_title(lower(col("title")))) \
        .withColumn("first_name", standardize_name(col("first_name"))) \
        .withColumn("middle_name", standardize_name(col("middle_name"))) \
        .withColumn("last_name", standardize_name(col("last_name"))) \
        .withColumn("name", standardize_full_name(col("first_name"), col("middle_name"), col("last_name"))) \
        .withColumn("post_code", lower(col("post_code"))) \
        .withColumn("address_line_1", standardize_address_line(col("address_line_1"))) \
        .withColumn("address_line_2", standardize_address_line(col("address_line_2"))) \
        .withColumn("address_line_3", standardize_address_line(col("address_line_3"))) \
        .withColumn("address_line_4", standardize_address_line(col("address_line_4"))) \
        .withColumn("full_address", full_address(col("address_line_1"), col("address_line_2"), col("address_line_3"),
                                                 col("address_line_4"))) \
        .select(col("source"), col("source_id"), col("uprn"), col("title"), col("first_name"), col("middle_name"),
                col("last_name"), col("name"), col("date_of_birth"), col("post_code"), col("address_line_1"),
                col("address_line_2"), col("address_line_3"), col("address_line_4"), col("full_address")) \
        .dropDuplicates(["source_id", "uprn"])

    return council_tax


def prepare_clean_housing_benefit_data(spark: SparkSession, housing_benefit_member_data_path: str,
                                       housing_benefit_household_data_path: str,
                                       housing_benefit_rent_assessment_data_path: str,
                                       housing_benefit_tax_calc_stmt_data_path: str) -> DataFrame:
    """A function to prepare and clean housing benefit data. Data comes from multiple sources. This function is specific
    to this particular data source. For a new data source please add a new function.

    Args:
        spark: SparkSession
        housing_benefit_member_data_path: Path of the S3 (or local) folder containing housing benefit member data
        housing_benefit_household_data_path: Path of the S3 (or local) folder containing housing benefit household data
        housing_benefit_rent_assessment_data_path: Path of the S3 (or local) folder containing housing benefit rent
        assessment data
        housing_benefit_tax_calc_stmt_data_path: Path of the S3 (or local) folder containing housing benefit tax
        calculation statement data

    Returns:
        A DataFrame after preparing data from multiple sources and cleaning it.

    """
    housing_benefit_member = spark.read.parquet(housing_benefit_member_data_path) \
        .withColumn("claim_house_id", concat_ws("-", col("claim_id"), col("house_id"))) \
        .withColumn("claim_person_ref", concat_ws("-", col("claim_id"), col("house_id"), col("member_id"))) \
        .withColumn("gender", when(col("gender") == 2, "F").when(col("gender") == 1, "M").otherwise("O")) \
        .withColumn("extracted_name", extract_name_udf(col("name"))) \
        .withColumn("source", lit("housing_benefit")) \
        .withColumn("date_of_birth", to_date(col("birth_date"))) \
        .select(col("source"), col("claim_person_ref"), col("claim_house_id"), col("extracted_name.*"),
                col("date_of_birth"), col("gender"))

    housing_benefit_household = spark.read.parquet(housing_benefit_household_data_path) \
        .withColumn("claim_house_id", concat_ws("-", col("claim_id"), col("house_id"))) \
        .withColumnRenamed("addr1", "address_line_1") \
        .withColumnRenamed("addr2", "address_line_2") \
        .withColumnRenamed("addr3", "address_line_3") \
        .withColumnRenamed("addr4", "address_line_4") \
        .filter((col("from_date") < col("import_datetime")) & (col("to_date") > col("import_datetime"))) \
        .select(col("claim_id"), col("claim_house_id"), col("address_line_1"), col("address_line_2"),
                col("address_line_3"), col("address_line_4"), col("post_code"), col("uprn"))

    housing_benefit_rent_assessment = spark \
        .read.parquet(housing_benefit_rent_assessment_data_path) \
        .filter((col("from_date") < col("import_datetime")) & (col("to_date") > col("import_datetime"))) \
        .select(col("claim_id"))
    housing_benefit_tax_calc_stmt = spark.read.parquet(housing_benefit_tax_calc_stmt_data_path) \
        .filter((col("from_date") < col("import_datetime")) & (col("to_date") > col("import_datetime"))) \
        .select(col("claim_id"))
    housing_benefit_rent_tax = housing_benefit_rent_assessment.union(housing_benefit_tax_calc_stmt)

    housing_benefit_household_claims = housing_benefit_household \
        .join(housing_benefit_rent_tax, ["claim_id"])

    housing_benefit_cleaned = housing_benefit_member.join(housing_benefit_household_claims, ["claim_house_id"]) \
        .withColumn("source", lit("housing_benefit")) \
        .select(col("source"), col("claim_person_ref"), col("uprn"), col("entity_type"), col("title"),
                col("first_name"), col("middle_name"), col("last_name"), col("date_of_birth"), col("gender"),
                col("post_code"), col("address_line_1"), col("address_line_2"), col("address_line_3"),
                col("address_line_4"))

    return housing_benefit_cleaned


def standardize_housing_benefit_data(housing_benefit_cleaned: DataFrame) -> DataFrame:
    """Standardize housing benefit data. This function convert all the custom names (coming from their respective
    sources to standard names that will be used by various other functions like feature engineering etc.)
    The DataFrame returned will have the following columns:

    * source: Source of the data like parking, tax etc. Should be of type string and cannot be blank.
    * source_id: Unique ID for reach record. It's ok to have same person with different source_id. Should be of type
    string and cannot be blank.
    * uprn: UPRN of the address. Should be of type string and can be blank.
    * title: Title of the person. Should be of type string and can be blank.
    * first_name: First name of the person. Should be of type string and can be blank.
    * middle_name: Middle name of the person. Should be of type string and can be blank.
    * last_name: Last name of the person. Should be of type string and can be blank.
    * name: Concatenation of first, middle and last name after sorting alphabetically of the person. Should be of type
    string and can be blank.
    * date_of_birth: Date of birth of the person. Should be of type Date and can be blank.
    * post_code: Postal code of the address. Should be of type string and can be blank.
    * address_line_1: First line of the address. Should be of type string and can be blank.
    * address_line_2: Second line of the address. Should be of type string and can be blank.
    * address_line_3: Third line of the address. Should be of type string and can be blank.
    * address_line_4: Fourth line of the address. Should be of type string and can be blank.
    * full_address: Concatenation of address line 1, address line 2, address line 3, address line 4 in that order.
    Should be of type string and can be blank.

    Args:
        housing_benefit_cleaned: housing benefit DataFrame after preparing and cleaning it.

    Returns:
        A housing benefit DataFrame with all the standard column listed above.

    """
    housing_benefit = housing_benefit_cleaned \
        .filter(col("entity_type") == "Person") \
        .drop(col("entity_type")) \
        .withColumn("source_id", col("claim_person_ref")) \
        .withColumn("title", categorise_title(lower(col("title")))) \
        .withColumn("first_name", standardize_name(col("first_name"))) \
        .withColumn("middle_name", standardize_name(col("middle_name"))) \
        .withColumn("last_name", standardize_name(col("last_name"))) \
        .withColumn("name", standardize_full_name(col("first_name"), col("middle_name"), col("last_name"))) \
        .withColumn("post_code", lower(col("post_code"))) \
        .withColumn("address_line_1", standardize_address_line(col("address_line_1"))) \
        .withColumn("address_line_2", standardize_address_line(col("address_line_2"))) \
        .withColumn("address_line_3", standardize_address_line(col("address_line_3"))) \
        .withColumn("address_line_4", standardize_address_line(col("address_line_4"))) \
        .withColumn("full_address", full_address(col("address_line_1"), col("address_line_2"), col("address_line_3"),
                                                 col("address_line_4"))) \
        .select(col("source"), col("source_id"), col("uprn"), col("title"), col("first_name"), col("middle_name"),
                col("last_name"), col("name"), col("date_of_birth"), col("post_code"), col("address_line_1"),
                col("address_line_2"), col("address_line_3"), col("address_line_4"), col("full_address")) \
        .dropDuplicates(["source_id", "first_name", "last_name", "date_of_birth", "post_code"])

    return housing_benefit


def prepare_clean_parking_permit_data(spark: SparkSession, parking_permit_data_path: str) -> DataFrame:
    """A function to prepare and clean parking permit data. This function is specific to this particular data source.
    For a new data source please add a new function.

    Args:
        spark: SparkSession
        parking_permit_data_path: Path of the S3 (or local) folder containing parking permit data.

    Returns:
        A DataFrame after preparing data from multiple sources and cleaning it.

    """

    parking_permit_cleaned = spark.read.parquet(parking_permit_data_path) \
        .withColumn("source", lit("parking_permit")) \
        .withColumn("extracted_name",
                    extract_name_udf(concat_ws(" ", col("forename_of_applicant"), col("surname_of_applicant")))) \
        .withColumn("date_of_birth", to_date(col("date_of_birth_of_applicant"), format="yyyy-MM-dd")) \
        .withColumnRenamed("postcode", "post_code") \
        .withColumnRenamed("email_address_of_applicant", "email") \
        .filter(col("permit_type").isin(["Residents", "Estate Resident"])) \
        .select(col("source"), col("permit_reference"),
                col("extracted_name.*"),
                col("date_of_birth"), col("email"), col("post_code"), col("uprn"),
                col("address_line_1"), col("address_line_2"), col("address_line_3"))

    return parking_permit_cleaned


def standardize_parking_permit_data(parking_permit_cleaned: DataFrame) -> DataFrame:
    """Standardize parking permit data. This function convert all the custom names (coming from their respective sources
    to standard names that will be used by various other functions like feature engineering etc.)
    The DataFrame returned will have the following columns:

    * source: Source of the data like parking, tax etc. Should be of type string and cannot be blank.
    * source_id: Unique ID for reach record. It's ok to have same person with different source_id. Should be of type
    string and cannot be blank.
    * uprn: UPRN of the address. Should be of type string and can be blank.
    * title: Title of the person. Should be of type string and can be blank.
    * first_name: First name of the person. Should be of type string and can be blank.
    * middle_name: Middle name of the person. Should be of type string and can be blank.
    * last_name: Last name of the person. Should be of type string and can be blank.
    * name: Concatenation of first, middle and last name after sorting alphabetically of the person. Should be of type
    string and can be blank.
    * date_of_birth: Date of birth of the person. Should be of type Date and can be blank.
    * post_code: Postal code of the address. Should be of type string and can be blank.
    * address_line_1: First line of the address. Should be of type string and can be blank.
    * address_line_2: Second line of the address. Should be of type string and can be blank.
    * address_line_3: Third line of the address. Should be of type string and can be blank.
    * address_line_4: Fourth line of the address. Should be of type string and can be blank.
    * full_address: Concatenation of address line 1, address line 2, address line 3, address line 4 in that order.
    Should be of type string and can be blank.

    Args:
        parking_permit_cleaned: parking permit DataFrame after preparing and cleaning it.

    Returns:
        A parking permit DataFrame with all the standard column listed above.

    """
    parking_permit = parking_permit_cleaned \
        .filter(col("entity_type") == "Person") \
        .drop(col("entity_type")) \
        .withColumn("source_id", col("permit_reference")) \
        .withColumn("title", categorise_title(lower(col("title")))) \
        .withColumn("first_name", standardize_name(col("first_name"))) \
        .withColumn("middle_name", standardize_name(col("middle_name"))) \
        .withColumn("last_name", standardize_name(col("last_name"))) \
        .withColumn("name", standardize_full_name(col("first_name"), col("middle_name"), col("last_name"))) \
        .withColumn("post_code", lower(col("post_code"))) \
        .withColumn("address_line_1", standardize_address_line(col("address_line_1"))) \
        .withColumn("address_line_2", standardize_address_line(col("address_line_2"))) \
        .withColumn("address_line_3", standardize_address_line(col("address_line_3"))) \
        .withColumn("address_line_4", lit("").cast(StringType())) \
        .withColumn("full_address", full_address(col("address_line_1"), col("address_line_2"), col("address_line_3"),
                                                 col("address_line_4"))) \
        .select(col("source"), col("source_id"), col("uprn"), col("title"), col("first_name"), col("middle_name"),
                col("last_name"), col("name"), col("date_of_birth"), col("post_code"), col("address_line_1"),
                col("address_line_2"), col("address_line_3"), col("address_line_4"), col("full_address"))

    return parking_permit


def remove_deceased(df: DataFrame) -> DataFrame:
    """Remove deceased person from the DataFrame. For the data sources we have cleansed this information that was present
    along with other details of the person for e.g. if the person name is given Executors of Mr. Abc Pqr Xyz then
    title is Executors of Mr. while first name is Abc, middle name Pqr and Xyz as last name. Deceased information
    is available in title column. If you have used different method or strategy for cleaning or extracting the name,
    please create your own method for this functionality.

    Args:
        df: A DataFrame containing title column

    Returns:
        A DataFrame after removing all the deceased persons.

    """
    deceased_filter_cond = lower(col("title")).contains("(deceased)") | \
                           lower(col("title")).contains("executor") | \
                           lower(col("title")).contains("exor") | \
                           lower(col("title")).contains("rep") | \
                           lower(col("title")).contains(" of") | \
                           lower(col("title")).contains("of ") | \
                           lower(col("title")).contains("the") | \
                           lower(col("title")).contains("pe") | \
                           lower(col("title")).contains("other")

    return df.filter(~deceased_filter_cond)


def generate_possible_matches(df: DataFrame) -> DataFrame:
    """From a given DataFrame that have been standardized this method generate possible matches. To do generate all the
    possible matches (including False Positives) this method generates soundex phonetic code on first and the last name
    and then joining the DataFrame with itself when phonetic code are same. To avoid confusion between columns names it
    renames all the columns with a prefix of 'a' and 'b' and to represent two persons that we are matching.

    Args:
        df: DataFrame that have been standardized

    Returns:
        A DataFrame that contains all the possible match with columns starting with 'a_' and 'b_' to represent the two
         persons a and b that we are comparing.

    """
    partitions = 5
    df_a = df.select(*[col(c).alias(f"a_{c}") for c in df.columns]) \
        .withColumn("first_name_soundex", soundex(col("a_first_name"))) \
        .withColumn("last_name_soundex", soundex(col("a_last_name"))) \
        .repartition(partitions, col("first_name_soundex"), col("last_name_soundex"))

    df_b = df.select(*[col(c).alias(f"b_{c}") for c in df.columns]) \
        .withColumn("first_name_soundex", soundex(col("b_first_name"))) \
        .withColumn("last_name_soundex", soundex(col("b_last_name"))) \
        .repartition(partitions, col("first_name_soundex"), col("last_name_soundex"))

    return df_a.join(df_b,
                     (df_a["a_source_id"] != df_b["b_source_id"]) &
                     (df_a["first_name_soundex"] == df_b["first_name_soundex"]) &
                     (df_a["last_name_soundex"] == df_b["last_name_soundex"])) \
        .drop(*["first_name_soundex", "last_name_soundex"])


def automatically_label_data(df: DataFrame) -> DataFrame:
    """Automatically labels data if two records have same id or their attributes are exactly same.
    Auto label will be 1.0 whenever there is a perfect match otherwise null.

    Args:
        df: A DataFrame after generating all the possible matches

    Returns:
        A DataFrame with column auto_labels.

    """
    return df.withColumn("auto_labels",
                         when((col("a_source_id") == col("b_source_id")) | (
                                 (col("a_first_name") == col("b_first_name")) &
                                 (col("a_last_name") == col("b_last_name")) &
                                 (col("a_date_of_birth") == col("b_date_of_birth")) &
                                 (col("a_uprn") == col("b_uprn")) &
                                 (col("a_post_code") == col("b_post_code"))), lit(True))
                         .otherwise(lit(None).cast(BooleanType())))


@pandas_udf(features_schema)
def generate_features(input_df: pd.DataFrame) -> pd.DataFrame:
    """This is a Spark UDF and is to be used with DataFrames only. This method generate features that is to be used by
    the machine learning model to learn from the data. If you are just replacing phonetic or similarity algorithms with
    different ones, then only modifying this method is fine. But if some you want to increase or decrease the features
    then changes are required in following places: features_schema, feature_engineering(), train_model() and ofcourse
    retrain the model.
    For performance reasons multiple columns are passed to this function and multiple columns are returned by this
    function. From usage point in Spark DataFrame pass all the columns in struct and also expect struct to be returned.
    From this function's point, treat both input and output as Pandas DataFrame (and not Spark DataFrame).
    It expects following columns to be present. Note 'a' and 'b' here refers to the two datasets that we are comparing
    to find same person.

    * a_first_name: First name from the 'a' dataset
    * b_first_name: First name from the 'b' dataset
    * a_middle_name: Middle name from the 'a' dataset
    * b_middle_name: Middle name from the 'b' dataset
    * a_last_name: Last name from the 'a' dataset
    * b_last_name: Last name from the 'b' dataset
    * a_address_line_1: Address Line 1 from the 'a' dataset
    * b_address_line_1: Address Line 1 from the 'b' dataset
    * a_address_line_2: Address Line 2 from the 'a' dataset
    * b_address_line_2: Address Line 2 from the 'b' dataset
    * a_full_address: Full address from the 'a' dataset
    * b_full_address: Full address from the 'b' dataset

    Args:
        input_df: A struct/pandas dataframe containing all the above listed columns.

    Returns:
        A Spark struct/pandas dataframe containing following columns first_name_similar, middle_name_similar, last_name_
        similar, name_similarity, address_line_1_similarity, address_line_2_similarity, full_address_similarity

    """
    phonetic_algo = DoubleMetaphone()
    similarity_algo = Cosine()

    input_df["first_name_similar"] = input_df.apply(
        lambda x: phonetic_algo.encode(x["a_first_name"]) == phonetic_algo.encode(x["b_first_name"]), axis=1)
    input_df["middle_name_similar"] = input_df.apply(
        lambda x: phonetic_algo.encode(x["a_middle_name"]) == phonetic_algo.encode(x["b_middle_name"]), axis=1)
    input_df["last_name_similar"] = input_df.apply(
        lambda x: phonetic_algo.encode(x["a_last_name"]) == phonetic_algo.encode(x["b_last_name"]), axis=1)
    input_df["name_similarity"] = input_df.apply(lambda x: similarity_algo.sim(x["a_name"], x["b_name"]), axis=1)
    input_df["address_line_1_similarity"] = input_df.apply(
        lambda x: similarity_algo.sim(x["a_address_line_1"], x["b_address_line_1"]), axis=1)
    input_df["address_line_2_similarity"] = input_df.apply(
        lambda x: similarity_algo.sim(x["a_address_line_2"], x["b_address_line_2"]), axis=1)
    input_df["full_address_similarity"] = input_df.apply(
        lambda x: similarity_algo.sim(x["a_full_address"], x["b_full_address"]), axis=1)

    return input_df.drop([
        "a_first_name", "b_first_name", "a_middle_name", "b_middle_name", "a_last_name", "b_last_name",
        "a_name", "b_name",
        "a_address_line_1", "b_address_line_1", "a_address_line_2", "b_address_line_2",
        "a_full_address", "b_full_address"], axis=1)


def feature_engineering(df: DataFrame) -> DataFrame:
    """Generate features to be used for machine learning. Generated features are:

    * uprn_same: Matches UPRN. Possible values: match (for perfect match), non-match (for mismatch), unknown
    (if either value is missing)
    * title_same: Matches title. Possible values: match (for perfect match), non-match (for mismatch), unknown
    (if either value is missing)
    * date_of_birth_same: Matches date of birth. Possible values: match (for perfect match), non-match (for mismatch),
    unknown (if either value is missing)
    * date_of_birth_same: Matches date of birth. Possible values: match (for perfect match), non-match (for mismatch),
    unknown (if either value is missing)
    * first_name_similar: True if name matches else false
    * middle_name_similar: True if name matches else false
    * last_name_similar: True if name matches else false
    * name_similarity: A double representing similarity between names
    * address_line_1_similarity: A double representing similarity between address
    * address_line_2_similarity: A double representing similarity between address
    * full_address_similarity: A double representing similarity between address

    Args:
        df: Input DataFrame after generating possible matches and/or optionally after automatic labelling

    Returns:
        A DataFrame with all the features (listed above).

    """
    match = lit("match")
    non_match = lit("non-match")
    unknown = lit("unknown")
    features_df = df \
        .withColumn("uprn_same",
                    when(col("a_uprn") == col("b_uprn"), match)
                    .when(col("a_uprn") != col("b_uprn"), non_match)
                    .otherwise(unknown)) \
        .withColumn("title_same",
                    when(col("a_title") == col("b_title"), match)
                    .when(col("a_title") != col("b_title"), non_match)
                    .otherwise(unknown)) \
        .withColumn("date_of_birth_same",
                    when(col("a_date_of_birth") == col("b_date_of_birth"), match)
                    .when(col("a_date_of_birth") != col("b_date_of_birth"), non_match)
                    .otherwise(unknown)) \
        .withColumn("similarity_features",
                    generate_features(struct(
                        col("a_first_name"), col("b_first_name"),
                        col("a_middle_name"), col("b_middle_name"),
                        col("a_last_name"), col("b_last_name"),
                        col("a_name"), col("b_name"),
                        col("a_address_line_1"), col("b_address_line_1"),
                        col("a_address_line_2"), col("b_address_line_2"),
                        col("a_full_address"), col("b_full_address")))) \
        .select(col("*"), col("similarity_features.*")).drop("similarity_features")

    return features_df


def evaluation_for_various_metrics(predictions: DataFrame):
    metrics = MulticlassClassificationEvaluator(predictionCol="prediction",
                                                labelCol="label",
                                                weightCol="label_confidence_score",
                                                probabilityCol="probability")
    accuracy = metrics.evaluate(predictions, {metrics.metricName: "accuracy"})
    precision_non_match = metrics.evaluate(predictions,
                                           {metrics.metricName: "precisionByLabel", metrics.metricLabel: 0.0})
    precision_match = metrics.evaluate(predictions, {metrics.metricName: "precisionByLabel", metrics.metricLabel: 1.0})
    recall_non_match = metrics.evaluate(predictions, {metrics.metricName: "recallByLabel", metrics.metricLabel: 0.0})
    recall_match = metrics.evaluate(predictions, {metrics.metricName: "recallByLabel", metrics.metricLabel: 1.0})
    return accuracy, precision_non_match, precision_match, recall_non_match, recall_match


def train_model(df: DataFrame, model_path: str) -> None:
    """Trains the model

    Args:
        df: DataFrame containing data. This includes both test and train
        model_path: Path where trained model is saved.

    Returns:
        Nothing. This function doesn't return anything

    """
    # Python unpacking (e.g. a,b = ["a", "b"]) removes the type information, therefore extracting from list
    train_test = df.randomSplit([0.8, 0.2], seed=42)
    train = train_test[0]
    test = train_test[1]
    train.cache()
    print(f"Training data size: {train.count()}")
    print(f"Test data size....: {test.count()}")

    string_indexer = StringIndexer(inputCols=["uprn_same", "title_same", "date_of_birth_same"],
                                   outputCols=["uprn_indexed", "title_indexed", "date_of_birth_indexed"],
                                   stringOrderType="alphabetAsc")
    one_hot_encoder = OneHotEncoder(inputCols=["uprn_indexed", "title_indexed", "date_of_birth_indexed"],
                                    outputCols=["uprn_vec", "title_vec", "date_of_birth_vec"])
    vector_assembler = VectorAssembler(
        inputCols=["uprn_vec", "title_vec", "date_of_birth_vec", "first_name_similar", "middle_name_similar",
                   "last_name_similar", "name_similarity", "address_line_1_similarity", "address_line_2_similarity",
                   "full_address_similarity"], outputCol="features")
    classifier = LogisticRegression(featuresCol="features", labelCol="label", weightCol="label_confidence_score",
                                    standardization=False)

    pipeline = Pipeline(stages=[string_indexer, one_hot_encoder, vector_assembler, classifier])
    # Due to limited time I haven't searched on a larger space
    # param_grid = ParamGridBuilder() \
    #     .addGrid(classifier.regParam, [0.0001, 0.00005, 8e-05, 7e-05, 5e-05]) \
    #     .addGrid(classifier.elasticNetParam, [0.0, 0.25, 0.5, 0.75, 1.0]) \
    #     .build()
    param_grid = ParamGridBuilder() \
        .addGrid(classifier.regParam, [7e-05]) \
        .addGrid(classifier.elasticNetParam, [1.0]) \
        .build()
    evaluator = BinaryClassificationEvaluator(labelCol="label",
                                              rawPredictionCol="rawPrediction",
                                              weightCol="label_confidence_score")

    cv = CrossValidator(estimator=pipeline, estimatorParamMaps=param_grid, evaluator=evaluator, numFolds=5, seed=42,
                        parallelism=5)
    cv_model = cv.fit(train)

    train_prediction = cv_model.transform(train)

    print(f"Training ROC AUC train score before fine-tuning..: {evaluator.evaluate(train_prediction):.5f}")
    accuracy, precision_non_match, precision_match, recall_non_match, recall_match = evaluation_for_various_metrics(
        train_prediction)
    print(f"Training Accuracy  before fine-tuning............: {accuracy:.5f}")
    print(f"Training Precision before fine-tuning (non-match): {precision_non_match:.5f}")
    print(f"Training Precision before fine-tuning.....(match): {precision_match:.5f}")
    print(f"Training Recall    before fine-tuning.(non-match): {recall_non_match:.5f}")
    print(f"Training Recall    before fine-tuning.....(match): {recall_match:.5f}")

    model: LogisticRegressionModel = cv_model.bestModel.stages[-1]
    training_summary = model.summary

    # Fine-tuning the model to maximize performance
    f_measure = training_summary.fMeasureByThreshold
    max_f_measure = f_measure.groupBy().max("F-Measure").select("max(F-Measure)").head()
    best_threshold = f_measure \
        .filter(f_measure["F-Measure"] == max_f_measure["max(F-Measure)"]) \
        .select("threshold") \
        .head()["threshold"]
    print(f"Best threshold: {best_threshold}")
    cv_model.bestModel.stages[-1].setThreshold(best_threshold)
    cv_model.write().overwrite().save(model_path)

    train_prediction = cv_model.transform(train)
    print(f"Training ROC AUC train score after fine-tuning...: {evaluator.evaluate(train_prediction):.5f}")
    accuracy, precision_non_match, precision_match, recall_non_match, recall_match = evaluation_for_various_metrics(
        train_prediction)
    print(f"Training Accuracy  after fine-tuning.............: {accuracy:.5f}")
    print(f"Training Precision after fine-tuning .(non-match): {precision_non_match:.5f}")
    print(f"Training Precision after fine-tuning......(match): {precision_match:.5f}")
    print(f"Training Recall    after fine-tuning..(non-match): {recall_non_match:.5f}")
    print(f"Training Recall    after fine-tuning......(match): {recall_match:.5f}")

    print("Only evaluate once in the end, so keep it commented for most of the time.")
    test_prediction = cv_model.transform(test)
    test_prediction.show()
    print(f'Write predictions to csv...')
    test_prediction.printSchema()
    test_prediction_for_export = test_prediction.withColumn('probability', vector_to_array(col('probability')))\
        .withColumn('probability_str', concat_ws('probability'))\
        .drop('uprn_vec', 'title_vec', 'date_of_birth_vec', 'features', 'rawPrediction', 'uprn_indexed',
              'title_indexed', 'date_of_birth_indexed', 'probability')
    test_prediction_for_export.write.csv(header=True, path=f"{model_path}/test_predictions")

    accuracy, precision_non_match, precision_match, recall_non_match, recall_match = evaluation_for_various_metrics(
        test_prediction)
    print(f"Test ROC AUC..............: {evaluator.evaluate(test_prediction):.5f}")
    print(f"Test Accuracy.............: {accuracy:.5f}")
    print(f"Test Precision (non-match): {precision_non_match:.5f}")
    print(f"Test Precision.....(match): {precision_match:.5f}")
    print(f"Test Recall....(non-match): {recall_non_match:.5f}")
    print(f"Test Recall........(match): {recall_match:.5f}")


def predict(features_df: DataFrame, model_path: str) -> DataFrame:
    """Make prediction on the featured data. Please note that this method generates possible matches itself all it needs
    is standardised DataFrame. Note column "predicted_label" contains prediction human-readable form while the column
    prediction contains numeric prediction.

    Args:
        features_df: DataFrame that contains all the features.
        model_path: Path where trained model is saved.

    Returns:
        Returns DataFrame with prediction.

    """
    cv_model: CrossValidatorModel = CrossValidatorModel.load(model_path)
    predictions = cv_model.transform(features_df).withColumn("predicted_label",
                                                             when(col("prediction") == 1.0, "match")
                                                             .when(col("prediction") == 0.0, "non-match")
                                                             .otherwise("unknown")) \
        .drop(*["uprn_indexed", "title_indexed", "date_of_birth_indexed", "uprn_vec", "title_vec",
                "date_of_birth_vec", "features", "rawPrediction", "probability"])

    return predictions


def link_all_matched_persons(standard_df: DataFrame, predicted_df: DataFrame) -> DataFrame:
    """Finds all the matching person in the standard DataFrame. All the records having same matching_id are considered
    as same person.

    Args:
        standard_df: DataFrame that have been standardized.
        predicted_df: DataFrame that contains predictions.

    Returns:
        A DataFrame similar to standard DataFrame but containing a column "matching_id" to indicate similar persons

    """
    vertices = standard_df.withColumn("id", col("source_id"))
    edges = predicted_df \
        .filter(col("prediction") == 1.0) \
        .withColumn("src", col("a_source_id")) \
        .withColumn("dst", col("b_source_id"))

    person_graph = GraphFrame(vertices, edges).dropIsolatedVertices()
    connected = person_graph.connectedComponents()
    unique_connections = connected \
        .select(col("source"), col("source_id"), col("component").alias("matching_id")) \
        .distinct()
    return standard_df \
        .join(unique_connections, ["source", "source_id"]) \
        .orderBy(col("matching_id"))

    # Extra analysis (for analyst only): if you need to do.

    # To find how many connection are there
    # person_graph.inDegrees.filter(col("inDegree") > 1).orderBy(col("inDegree").desc()).show(truncate=False)

    # Graph query using motif to find where person 'a' is connected to person 'b', and person 'b' is also connected to
    # person 'a'
    # motif = person_graph.find("(a)-[]->(b); (b)-[]->(a)")
    # motif.show(truncate=False)

    # To count number of triangles i.e. a connected to b, b connected to c and c is connected back to a
    # triangle_count = person_graph.triangleCount()
    # triangle_count.orderBy(col("count").desc()).show(n=10, truncate=False)


def match_persons(model_path: str, standard_df: DataFrame) -> DataFrame:
    """ A convenient method that facilitate the user of the module to perform person match. This method accepts a
    standard DataFrame that represents the dataset containing the record records referring to the same person.
    Standard DataFrame should have the following columns though data it can be missing.

    * source: Source of the data like parking, tax etc. Should be of type string and cannot be blank.
    * source_id: Unique ID for reach record. It's ok to have same person with different source_id. Should be of type
    string and cannot be blank.
    * uprn: UPRN of the address. Should be of type string and can be blank.
    * title: Title of the person. Should be of type string and can be blank.
    * first_name: First name of the person. Should be of type string and can be blank.
    * middle_name: Middle name of the person. Should be of type string and can be blank.
    * last_name: Last name of the person. Should be of type string and can be blank.
    * name: Concatenation of first, middle and last name after sorting alphabetically of the person. Should be of type
    string and can be blank.
    * date_of_birth: Date of birth of the person. Should be of type Date and can be blank.
    * post_code: Postal code of the address. Should be of type string and can be blank.
    * address_line_1: First line of the address. Should be of type string and can be blank.
    * address_line_2: Second line of the address. Should be of type string and can be blank.
    * address_line_3: Third line of the address. Should be of type string and can be blank.
    * address_line_4: Fourth line of the address. Should be of type string and can be blank.
    * full_address: Concatenation of address line 1, address line 2, address line 3, address line 4 in that order.
    Should be of type string and can be blank.

    Args:
        model_path: Path where trained model is saved.
        standard_df: A standardised DataFrame containing all the above columns

    Returns:
        A DataFrame similar to standardised DataFrame containing peron matched determined by the column "matching_id"

    Raises: AssertionError is mandatory columns are missing.

    """
    mandatory_columns = ["source", "source_id", "uprn", "title", "first_name", "middle_name", "last_name", "name",
                         "date_of_birth", "post_code", "address_line_1", "address_line_2", "address_line_3",
                         "address_line_4", "full_address"]
    try:
        assert set(mandatory_columns).issubset(standard_df.columns)
    except AssertionError as e:
        raise AssertionError(f"Standard DataFrame doesn't contain all the mandatory columns and error is {e}")

    possible_matches = generate_possible_matches(standard_df)
    features_df = feature_engineering(possible_matches)
    predictions = predict(features_df, model_path)
    result = link_all_matched_persons(standard_df, predictions)
    return result
