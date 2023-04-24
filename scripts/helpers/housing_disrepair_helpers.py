"""
Functions and objects relating to housing disrepair analysis.
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
    regexp_replace, trim, split, struct, arrays_zip, array, array_sort, length, greatest, expr
from pyspark.sql.pandas.functions import pandas_udf
from pyspark.sql.types import StructType, StructField, StringType, DateType, BooleanType, DoubleType


def convert_yn_to_bool(dataframe, columns):
    for column in columns:
        dataframe = dataframe.withColumn(column, when(col(column) == 'Y', 1).otherwise(col(column)))\
            .withColumn(column, when(col(column) == 'N', 0).otherwise(col(column)))
    return dataframe


def prepare_input_datasets(repairs_df, tenure_df, repairs_cols, tenure_df_columns, deleted_estates):
    # drop columns not needed in MVP model
    cols_to_drop = [column for column in repairs_df.columns if
                    (column.endswith('_before_ld') | column.endswith('_last_2000'))]
    repairs_df = repairs_df.drop(*cols_to_drop)
    tenure_df = tenure_df.select(*tenure_df_columns)

    # drop rows without uprn
    repairs_df = repairs_df.withColumn('uprn_len', length(trim(col('uprn'))))
    repairs_df = repairs_df.filter((repairs_df.uprn_len > 0)) \
        .select('*')

    # drop rows with deleted/demolished estates
    repairs_df = repairs_df.filter(~col('estate_name').isin(deleted_estates)) \
        .select('*')

    # join on uprn field (both string type)
    joined_df = repairs_df.join(tenure_df, 'uprn', 'left')

    # drop rows that don't have estate_street value
    joined_df = joined_df.withColumn('es_len', length(trim(col('estate_street'))))
    joined_df = joined_df.filter((joined_df.es_len > 0)).select('*')
    joined_df = joined_df.drop('es_len')

    # drop duplicate rows
    joined_df = joined_df.drop_duplicates(subset=['uprn'])

    return joined_df


def set_target(dataframe, target):
    dataframe = dataframe.withColumn('target', when(col(*target) == 1, 1).otherwise(0))
    dataframe = dataframe.drop(*target)
    return dataframe


def get_total_occupants_housing_benefit(dataframe, hb_num_children, hb_num_adults):
    dataframe = dataframe.withColumn('no_of_people_hb', col(hb_num_children) + col(hb_num_adults))
    dataframe = dataframe.na.fill(value=0, subset=['no_of_people_hb'])
    dataframe = dataframe.drop(hb_num_adults)
    return dataframe


def get_total_occupants(dataframe, new_column_name, occupancy_columns, child_count):
    dataframe = dataframe.withColumn(new_column_name,
                                     greatest(*[col(c).cast('int').alias(c) for c in occupancy_columns]))
    dataframe = dataframe.withColumn(new_column_name,
                                     when(((col(new_column_name) == 1) & (col(child_count) > 0)),
                                          2).otherwise(col(new_column_name)))
    return dataframe


def group_number_of_bedrooms(dataframe, bedroom_column, new_column_name):
    dataframe = dataframe.withColumn(new_column_name,
                                     when(col(bedroom_column) <= 1, '1 or more bedrooms')
                                     .otherwise('More than 1 bedrooms'))
    dataframe = dataframe.drop(bedroom_column)
    return dataframe


def get_external_walls(dataframe, attachment_column, new_column_name):
    dataframe = dataframe.withColumn(new_column_name,
                                     when(col(attachment_column).isin(['EndTerrace', 'SemiDetached', 'Detached',
                                                                       'EnclosedEndTerrace']), 1).otherwise(0))
    dataframe = dataframe.drop(attachment_column)
    return dataframe


def get_communal_area(dataframe, communal_area_column, new_column_name):
    dataframe = dataframe.withColumn(new_column_name,
                                     when(col(communal_area_column) == 'No Communal Area', 1).otherwise(0))
    dataframe = dataframe.drop(communal_area_column)
    return dataframe


def get_roof_insulation(dataframe, roof_insulation_column, new_column_name):
    dataframe = dataframe.withColumn(new_column_name,
                                     when(col(roof_insulation_column).isin(['Another Dwelling Above',
                                                                            'mm200', 'mm100', 'mm300', 'mm400',
                                                                            'mm250', 'mm150', 'mm50', 'mm75', 'mm270',
                                                                            'mm350', 'mm25', 'mm12']), 1).otherwise(0))
    dataframe = dataframe.drop(roof_insulation_column)
    return dataframe


# main fuel
def get_main_fuel(dataframe, fuel_column, new_column_name):
    dataframe = dataframe.withColumn(new_column_name,
                                     when(col(fuel_column) == 'Gas (Individual)', 1).otherwise(0))
    dataframe = dataframe.drop(fuel_column)
    return dataframe


def get_boilers(dataframe, heating_column, new_column_name):
    dataframe = dataframe.withColumn(new_column_name,
                                     when(col(heating_column) == 'Boilers', 1).otherwise(0))
    dataframe = dataframe.drop(heating_column)
    return dataframe


def get_open_air_walkways(dataframe, open_walkways_column, new_column_name):
    dataframe = dataframe.withColumn(new_column_name,
                                     when(col(open_walkways_column) == 'Yes', 1).otherwise(0))
    dataframe = dataframe.drop(open_walkways_column)
    return dataframe


def get_vulnerability_score(dataframe, vulnerability_dict, new_column_name):
    dataframe = dataframe.withColumn(new_column_name, lit(0))
    for vulnerability in vulnerability_dict:
        # print(vulnerability)
        cols = vulnerability_dict.get(vulnerability)
        dataframe = convert_yn_to_bool(dataframe=dataframe, columns=cols)
        # print(cols)
        if len(cols) > 1:
            # for multiple columns
            calc = '+'.join(cols)
            dataframe = dataframe.withColumn(new_column_name,
                                             when(((expr(calc) > 0)),
                                                  1 + col(new_column_name)).otherwise(col(new_column_name)))
            dataframe = dataframe.drop(*cols)
        else:
            # for single columns
            cols = list(cols)[0]
            dataframe = dataframe.withColumn(new_column_name,
                                             when((col(cols).cast('int')) > 0,
                                                  1 + col(new_column_name)).otherwise(col(new_column_name)))
            dataframe = dataframe.drop(cols)
    return dataframe

