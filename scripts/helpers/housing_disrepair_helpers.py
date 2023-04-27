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
from pyspark.ml.feature import StringIndexer, OneHotEncoder, VectorAssembler, Imputer, StandardScaler
from pyspark.ml.functions import vector_to_array
from pyspark.ml.tuning import ParamGridBuilder, CrossValidator, CrossValidatorModel
from pyspark.sql import DataFrame, SparkSession, Column
from pyspark.sql.functions import to_date, col, lit, broadcast, udf, when, substring, lower, concat_ws, soundex, \
    regexp_replace, trim, split, struct, arrays_zip, array, array_sort, length, greatest, expr
from pyspark.sql.pandas.functions import pandas_udf
from pyspark.sql.types import StructType, StructField, StringType, DateType, BooleanType, DoubleType, ArrayType


def convert_yn_to_bool(dataframe, columns):
    for column in columns:
        dataframe = dataframe.withColumn(column, when(col(column) == 'Y', 1).otherwise(col(column))) \
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


def prepare_index_field(dataframe, column):
    "This feature will be used as a unique ID and needs to be numerical"
    dataframe = dataframe.withColumn(column, col(column).cast('float'))
    return dataframe


def get_total_occupants_housing_benefit(dataframe, hb_num_children, hb_num_adults):
    dataframe = dataframe.withColumn('no_of_people_hb', col(hb_num_children) + col(hb_num_adults))
    dataframe = dataframe.na.fill(value=0, subset=['no_of_people_hb'])
    dataframe = dataframe.drop(hb_num_adults)
    return dataframe


def get_total_occupants(dataframe, new_column_name, occupancy_columns, child_count, inputs_list_to_update):
    dataframe = dataframe.withColumn(new_column_name,
                                     greatest(*[col(c).cast('int').alias(c) for c in occupancy_columns]))
    dataframe = dataframe.withColumn(new_column_name,
                                     when(((col(new_column_name) == 1) & (col(child_count) > 0)),
                                          2).otherwise(col(new_column_name)))
    inputs_list_to_update.append(new_column_name)
    return dataframe


def group_number_of_bedrooms(dataframe, bedroom_column, new_column_name, inputs_list_to_update):
    dataframe = dataframe.withColumn(new_column_name,
                                     when(col(bedroom_column) <= 1, '1 or more bedrooms')
                                     .otherwise('More than 1 bedrooms'))
    dataframe = dataframe.drop(bedroom_column)
    inputs_list_to_update.append(new_column_name)
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


def clean_boolean_features(dataframe, bool_list):
    df_cols = dataframe.schema.names
    # check that bool list is up-to-date
    bool_list = [c for c in bool_list if c in df_cols]
    for bool_col in bool_list:
        dataframe = dataframe.withColumn(bool_col, col(bool_col).cast('int'))
    dataframe = dataframe.fillna(value=0, subset=bool_list)
    return dataframe


def drop_rows_with_nulls(dataframe, features_list):
    # drop rows without key data, using character length
    for feat in features_list:
        dataframe = dataframe.filter(~(length(trim(col(feat))) == 0))
    return dataframe


def impute_missing_values(dataframe, features_to_impute, strategy, suffix):
    imputer = Imputer(
        inputCols=features_to_impute,
        outputCols=[f'{a}{suffix}' for a in features_to_impute]
    ).setStrategy(strategy)
    dataframe = imputer.fit(dataframe).transform(dataframe)
    return dataframe


def one_hot_encode_categorical_features(dataframe, string_columns):
    df_cols = dataframe.schema.names
    # check that bool list is up-to-date
    columns = [c for c in string_columns if c in df_cols]
    output_cols = [f'{a}_vec' for a in columns]

    # apply string indexer
    string_indexer = StringIndexer(inputCols=columns, outputCols=output_cols)
    indexer_fitted = string_indexer.fit(dataframe)
    df_indexed = indexer_fitted.transform(dataframe)
    df_indexed = df_indexed.drop(*columns)

    #  apply one hot encoder
    output_ohe = [f'{a}_ohe' for a in columns]
    encoder = OneHotEncoder(inputCols=output_cols, outputCols=output_ohe, dropLast=False)
    df_ohe = encoder.fit(df_indexed).transform(df_indexed)
    df_ohe = df_ohe.drop(*output_cols)

    # create set of binary columns so that features can be interpreted post model training
    for n, ohe in enumerate(output_ohe):
        df_ohe = df_ohe.select('*', vector_to_array(ohe).alias(f'col_{ohe}'))
        # prepare for expanding into individual binary columns
        num_categories = len(df_ohe.first()[f'col_{ohe}'])
        # get column labels
        labels = [i.strip().replace(".", "_").replace("-", "_").replace(" ", "_") for i in
                  indexer_fitted.labelsArray[n]]
        cols_expanded = [(col(f'col_{ohe}')[i].alias(f'{labels[i]}')) for i in range(num_categories)]
        df_ohe = df_ohe.select('*', *cols_expanded)
        df_ohe = df_ohe.drop(ohe)
        df_ohe = df_ohe.drop(f'col_{ohe}')

    return df_ohe


def array_to_list(vector_column):
    def to_list(vector):
        return vector.toArray().tolist()
    return udf(to_list, ArrayType(DoubleType()))(vector_column)


def scale_continuous_features(dataframe, cols_to_scale):
    scaler = StandardScaler(inputCol='selected_cols_assembled', outputCol='scaled_cols')
    vector_assembler = VectorAssembler().setInputCols(cols_to_scale).setOutputCol('selected_cols_assembled')
    df_vec = vector_assembler.transform(dataframe)
    df_scaled = scaler.fit(df_vec.select('selected_cols_assembled')).transform(df_vec)
    df_scaled = df_scaled.drop('selected_cols_assembled', *cols_to_scale)
    # extract scaled columns out
    df_scaled = df_scaled.select('*', array_to_list(col('scaled_cols')).alias('scaled_col_list')) \
        .select('*', *[col('scaled_col_list')[i].alias(cols_to_scale[i]) for i in range(2)])
    df_scaled = df_scaled.drop(*['scaled_cols', 'scaled_col_list'])
    return df_scaled


def assemble_vector_of_features(dataframe, cols_to_omit):
    # vectorise features into a single column
    cols = [col for col in dataframe.schema.names if col not in cols_to_omit]
    vector_assembler = VectorAssembler(inputCols=cols, outputCol='features')
    df_assembled = vector_assembler.transform(dataframe)
    return df_assembled

# def build_pipeline(dataframe, columns, suffix):
#     df_cols = dataframe.schema.names
#     # check that bool list is up-to-date
#     columns = [c for c in columns if c in df_cols]
#     output_cols = [f'{a}{suffix}' for a in columns]
#     string_indexer = StringIndexer(inputCols=columns, outputCols=output_cols)
#     #  apply one hot encoder
#     output_ohe = [f'{a}_ohe' for a in columns]
#     encoder = OneHotEncoder(inputCols=output_cols, outputCols=output_ohe, dropLast=False)
#     # vectorise features into a single column
#     vector_assembler = VectorAssembler(
#         inputCols=["uprn_vec", "title_vec", "date_of_birth_vec", "first_name_similar", "middle_name_similar",
#                    "last_name_similar", "name_similarity", "address_line_1_similarity", "address_line_2_similarity",
#                    "full_address_similarity"], outputCol='features')
#     classifier = LogisticRegression(featuresCol='features', labelCol='target',
#                                     standardization=False)
#
#     pipeline = Pipeline(stages=[string_indexer, one_hot_encoder, vector_assembler, classifier])
