"""
Functions and objects relating to housing disrepair analysis, specifically for damp and mould predictions.

TODO
* complete docstrings
"""
from pyspark.ml.evaluation import BinaryClassificationEvaluator
from pyspark.ml.feature import StringIndexer, OneHotEncoder, VectorAssembler, Imputer, StandardScaler, PCA
import pyspark.sql.functions as f
from pyspark.sql.types import DoubleType, ArrayType


def convert_yn_to_bool(dataframe, columns):
    """
    Converts string columns with 'Y' / 'N' to a boolean type column with 1 / 0

    Args:
        dataframe: PySpark dataframe
        columns: list of columns to be converted
    Returns:
        dataframe: PySpark dataframe containing the converted columns
    """
    for column in columns:
        dataframe = dataframe.withColumn(column, f.when(f.col(column).isin(['Y', 'Yes']), 1).otherwise(f.col(column))) \
            .withColumn(column, f.when(f.col(column).isin(['N', 'No']), 0).otherwise(f.col(column)))
    return dataframe


def prepare_input_datasets(repairs_df, tenure_df, repairs_df_columns, tenure_df_columns, deleted_estates,
                           street_or_estate, year_subset):
    """
    Performs initial preparation for input datasets (repairs and tenure dataframes) and returns single joined
    dataframe.

    Args:
        year_subset ():
        street_or_estate ():
        repairs_df:
        tenure_df:
        repairs_df_columns:
        tenure_df_columns:
        deleted_estates:
    Returns:
        joined_df: PySpark dataframe containing the prepared repairs and tenure dataframes, joined
        by uprn fields.
    """
    tenure_df = tenure_df.select(*tenure_df_columns)

    # drop rows without uprn
    repairs_df = repairs_df.withColumn('uprn_len', f.length(f.trim(f.col('uprn'))))
    repairs_df = repairs_df.filter((repairs_df.uprn_len > 0)) \
        .select('*')
    tenure_df = tenure_df.withColumn('uprn_len', f.length(f.trim(f.col('uprn'))))
    tenure_df = tenure_df.filter((tenure_df.uprn_len > 0)) \
        .select('*')

    # drop rows with deleted/demolished estates
    repairs_df = repairs_df.filter(~f.col('estate_name').isin(deleted_estates)) \
        .select('*')

    # filter dataset to have either streets or estates
    repairs_df = repairs_df.filter(f.col('estate_street').isin(street_or_estate)) \
        .select('*')
    repairs_df = repairs_df.drop('estate_street')

    cols_to_keep_repairs = [column for column in repairs_df.columns if
                            (column.endswith(year_subset))] + repairs_df_columns
    cols_to_keep_repairs_refined = [column for column in cols_to_keep_repairs if column in repairs_df.schema.names]
    repairs_df = repairs_df.select(*cols_to_keep_repairs_refined)

    # join on uprn field (both string type)
    joined_df = repairs_df.join(tenure_df, 'uprn', 'left')

    # drop duplicate rows
    joined_df = joined_df.drop_duplicates(subset=['uprn'])
    return joined_df


def set_target(dataframe, target_col):
    """Creates a new formatted target column based on the feature to be predicted"""
    dataframe = dataframe.withColumn('target', f.when(f.col(target_col) == '1', 1.0).otherwise(0.0))
    dataframe = dataframe.withColumn('target', f.col('target').cast('int'))
    return dataframe


def assign_confidence_score(dataframe, leak_flag, damp_mould_flag, leak_weighting):
    """Assigns a confidence score based on flags determining leak or damp/mould issues
    inputs:
        dataframe:
        leak_flag:
        damp_mould_flag:
    output:
        dataframe with new confidence_score column
    """

    # format flag column to boolean
    for flag in [leak_flag, damp_mould_flag]:
        dataframe = dataframe.withColumn(flag, f.when(f.col(flag) == '1', 1.0).otherwise(0.0))
        dataframe = dataframe.withColumn(flag, f.col(flag).cast('int'))
    dataframe = dataframe.withColumn('confidence_score',
                                     f.when((f.col(leak_flag) == 1) & (f.col(damp_mould_flag) == 1), f.lit(1))
                                     .when((f.col(leak_flag) == 0) & (f.col(damp_mould_flag) == 1), f.lit(1))
                                     .when((f.col(leak_flag) == 1) & (f.col(damp_mould_flag) == 0),
                                           f.lit(leak_weighting))
                                     .when((f.col(leak_flag) == 0) & (f.col(damp_mould_flag) == 0), f.lit(1))
                                     .otherwise(f.lit(0)))
    return dataframe


def prepare_index_field(dataframe, column):
    """This feature will be used as a unique ID and needs to be numerical/string"""
    dataframe = dataframe.withColumn(column, f.col(column).cast('string'))
    return dataframe


def get_total_occupants_housing_benefit(dataframe, hb_num_children, hb_num_adults):
    """
    Creates new column with the sum of adults and children in households receiving housing benefit.
    Args:
        dataframe (PySpark Dataframe):
        hb_num_children (Column):
        hb_num_adults (Column):

    Returns:
        dataframe with new column 'no_of_people_hb'

    """
    dataframe = dataframe.withColumn('no_of_people_hb', f.col(hb_num_children) + f.col(hb_num_adults))
    dataframe = dataframe.na.fill(value=0, subset=['no_of_people_hb'])
    dataframe = dataframe.drop(hb_num_adults)
    return dataframe


def get_total_occupants(dataframe, new_column_name, occupancy_columns, child_count):
    if len(occupancy_columns) > 1:
        dataframe = dataframe.withColumn(new_column_name,
                                         f.greatest(*[f.col(c).cast('int').alias(c) for c in occupancy_columns]))
    elif len(occupancy_columns) == 1:
        dataframe = dataframe.withColumn(new_column_name,
                                         f.col(occupancy_columns[0]).cast('int'))
    dataframe = dataframe.withColumn(new_column_name,
                                     f.when(((f.col(new_column_name) == 1) & (f.col(child_count) > 0)),
                                            2).otherwise(f.col(new_column_name)))
    return dataframe


def group_number_of_bedrooms(dataframe, bedroom_column, new_column_name):
    dataframe = dataframe.withColumn(new_column_name,
                                     f.when(f.col(bedroom_column) <= 1, '1 bedroom or less')
                                     .otherwise('More than 1 bedrooms'))
    dataframe = dataframe.drop(bedroom_column)
    return dataframe


def rename_void_column(dataframe, void_column):
    dataframe = dataframe.withColumnRenamed(void_column, 'flag_void')
    return dataframe


def get_external_walls(dataframe, attachment_column, new_column_name):
    dataframe = dataframe.withColumn(new_column_name,
                                     f.when(f.col(attachment_column).isin(['EndTerrace', 'SemiDetached', 'Detached',
                                                                           'EnclosedEndTerrace']), 1).otherwise(0))
    dataframe = dataframe.drop(attachment_column)
    return dataframe


def get_communal_area(dataframe, communal_area_column, new_column_name):
    dataframe = dataframe.withColumn(new_column_name,
                                     f.when(f.col(communal_area_column) == 'No Communal Area', 1).otherwise(0))
    dataframe = dataframe.drop(communal_area_column)
    return dataframe


def get_roof_insulation(dataframe, roof_insulation_column, new_column_name):
    dataframe = dataframe.withColumn(new_column_name,
                                     f.when(f.col(roof_insulation_column).isin(['Another Dwelling Above',
                                                                                'mm200', 'mm100', 'mm300',
                                                                                'mm400', 'mm250', 'mm150',
                                                                                'mm50', 'mm75', 'mm270',
                                                                                'mm350', 'mm25',
                                                                                'mm12']), 1).otherwise(0))
    dataframe = dataframe.drop(roof_insulation_column)
    return dataframe


# main fuel
def get_main_fuel(dataframe, fuel_column, new_column_name):
    dataframe = dataframe.withColumn(new_column_name,
                                     f.when(f.col(fuel_column) == 'Gas (Individual)', 1).otherwise(0))
    dataframe = dataframe.drop(fuel_column)
    return dataframe


def get_boilers(dataframe, heating_column, new_column_name):
    dataframe = dataframe.withColumn(new_column_name,
                                     f.when(f.col(heating_column) == 'Boilers', 1).otherwise(0))
    dataframe = dataframe.drop(heating_column)
    return dataframe


def get_open_air_walkways(dataframe, open_walkways_column, new_column_name):
    dataframe = dataframe.withColumn(new_column_name,
                                     f.when(f.col(open_walkways_column) == 'Yes', 1).otherwise(0))
    dataframe = dataframe.drop(open_walkways_column)
    return dataframe


def get_vulnerability_score(dataframe, vulnerability_dict, new_column_name):
    dataframe = dataframe.withColumn(new_column_name, f.lit(0))
    for vulnerability in vulnerability_dict:
        # print(vulnerability)
        cols = vulnerability_dict.get(vulnerability)
        dataframe = convert_yn_to_bool(dataframe=dataframe, columns=cols)
        # print(cols)
        if len(cols) > 1:
            # for multiple columns
            calc = '+'.join(cols)
            dataframe = dataframe.withColumn(new_column_name,
                                             f.when((f.expr(calc) > 0),
                                                    1 + f.col(new_column_name)).otherwise(f.col(new_column_name)))
            dataframe = dataframe.drop(*cols)
        else:
            # for single columns
            cols = list(cols)[0]
            dataframe = dataframe.withColumn(new_column_name,
                                             f.when((f.col(cols).cast('int')) > 0,
                                                    1 + f.col(new_column_name)).otherwise(f.col(new_column_name)))
            dataframe = dataframe.drop(cols)
    return dataframe


def clean_boolean_features(dataframe, bool_list):
    df_cols = dataframe.schema.names
    # check that bool list is up-to-date
    bool_list = [c for c in bool_list if c in df_cols]
    for bool_col in bool_list:
        dataframe = dataframe.withColumn(bool_col, f.col(bool_col).cast('int'))
    dataframe = dataframe.fillna(value=0, subset=bool_list)
    return dataframe


def drop_rows_with_nulls(dataframe, features_list):
    # drop rows without key data, using character length
    for feat in features_list:
        dataframe = dataframe.filter(~(f.length(f.trim(f.col(feat))) == 0))
    return dataframe


def impute_missing_values(dataframe, features_to_impute, strategy, suffix):
    imputer = Imputer(
        inputCols=features_to_impute,
        outputCols=[f'{a}{suffix}' for a in features_to_impute]
    ).setStrategy(strategy)
    dataframe = imputer.fit(dataframe).transform(dataframe)
    return dataframe


def array_to_list(vector_column):
    def to_list(vector):
        return vector.toArray().tolist()

    return f.udf(to_list, ArrayType(DoubleType()))(vector_column)


def get_evaluation_metrics(classifier_name, spark, predictions, prediction_col, target):
    tp = float(predictions.filter(f"{prediction_col} == 1.0 AND {target} == 1").count())
    fp = float(predictions.filter(f"{prediction_col} == 1.0 AND {target} == 0").count())
    tn = float(predictions.filter(f"{prediction_col} == 0.0 AND {target} == 0").count())
    fn = float((predictions.filter(f"{prediction_col} == 0.0 AND {target} == 1").count()))
    print(f'tp: {tp}\ntn: {tn}\nfp: {fp}\nfn: {fn}\n')
    accuracy = round(float((tp + tn)) / float((tp + fp + fn + tn)), 3)
    precision = round(float(tp / float((tp + fp))), 3)
    recall = round(float(tp / float((tp + fn))), 3)
    evaluator = BinaryClassificationEvaluator(labelCol=target)
    auc_roc = float(evaluator.evaluate(predictions, {evaluator.metricName: "areaUnderROC"}))
    auc_pr = float(evaluator.evaluate(predictions, {evaluator.metricName: "areaUnderPR"}))
    f1 = round(float(2 * ((precision * recall) / (precision + recall))), 3)

    metrics = spark.createDataFrame([
        ('TP', tp),
        ('FP', fp),
        ('TN', tn),
        ('FN', fn),
        ('Accuracy', accuracy),
        ('Precision', precision),
        ('Recall', recall),
        ('Area under ROC Curve', round(float(auc_roc), 3)),
        ('Area under PR Curve', round(float(auc_pr), 3)),
        ('F1 score', f1)],
        ['metric', classifier_name])
    return metrics


def balance_classes(dataframe, target_col, new_weight_col):
    balance_ratio = dataframe.filter(col(target_col) == 1).count() / dataframe.count()
    calculate_weights = f.udf(lambda x: 1 * balance_ratio if x == 0 else (1 * (1.0 - balance_ratio)), DoubleType())
    dataframe_with_weights = dataframe.withColumn(new_weight_col, calculate_weights(target_col))
    return dataframe_with_weights


def split_dataset(dataframe, target, ratio_list):
    # split dataframes according to target value (1 or 0)
    ones = dataframe.filter(dataframe[target] == 1)
    zeros = dataframe.filter(dataframe[target] == 0)
    if len(ratio_list) == 3:
        # split dataframes into training and testing
        train_ones, val_ones, test_ones = ones.randomSplit(ratio_list, seed=42)
        train_zeros, val_zeros, test_zeros = zeros.randomSplit(ratio_list, seed=42)

        # append each split back into a single dataset containing 0s and 1s
        train = train_zeros.union(train_ones)
        validation = val_zeros.union(val_ones)
        test = test_zeros.union(test_ones)
        return train, validation, test

    else:
        print('Not enough variables within ratio_list, expecting three.')


def set_up_base_model_pipeline_stages(string_cols,
                                      feature_cols,
                                      output_feature_col,
                                      input_target_col,
                                      output_target_col
                                      ):
    """

    Args:
        string_cols (list[str]):
        feature_cols (list[str]):
        output_feature_col (vector):
        input_target_col ():
        output_target_col ():

    Returns:

    """

    string_cols_indexed = [f'{a}_num' for a in string_cols]
    ohe_input_cols = [a for a in string_cols_indexed]
    ohe_output_cols = [f'{a}_ohe' for a in string_cols_indexed]
    vector_feat_cols = feature_cols + ohe_output_cols

    # set up the pipeline for base model prep
    stage1 = StringIndexer(inputCols=string_cols, outputCols=string_cols_indexed, handleInvalid='keep')
    stage2 = OneHotEncoder(inputCols=ohe_input_cols,
                           outputCols=ohe_output_cols, dropLast=True)
    stage3 = VectorAssembler(inputCols=vector_feat_cols, outputCol='features')
    stage4 = StandardScaler(inputCol='features', outputCol=output_feature_col, withMean=True)
    stage5 = StringIndexer(inputCol=input_target_col, outputCol=output_target_col)
    stages = [stage1, stage2, stage3, stage4, stage5]
    return stages


def set_up_meta_model_pipeline_stages(meta_feature_cols, output_meta_features_col, meta_cont_cols, meta_target_col,
                                      output_meta_target_col):
    """

    Args:
        meta_feature_cols ():
        output_meta_features_col ():
        meta_cont_cols ():
        meta_target_col ():
        output_meta_target_col ():

    Returns:
        meta_model_stages(list)

    """

    # set up the pipeline for base model prep
    stage1 = StringIndexer(inputCol=meta_target_col, outputCol=output_meta_target_col)
    stage2 = VectorAssembler(inputCols=meta_feature_cols, outputCol="meta_features")
    stage3 = VectorAssembler(inputCols=meta_cont_cols, outputCol="cont_features")
    stage4 = StandardScaler(inputCol="cont_features", outputCol='std_meta_cont_cols', withMean=True)
    stage5 = VectorAssembler(inputCols=['meta_features', 'std_meta_cont_cols'], outputCol=output_meta_features_col)
    meta_model_stages = [stage1, stage2, stage3, stage4, stage5]
    return meta_model_stages


def apply_pca(dataframe, feature_column, output_col, num_pca):
    pca = PCA(k=num_pca, inputCol=feature_column)
    pca.setOutputCol(output_col)
    model = pca.fit(dataframe)
    result = model.transform(dataframe)
    print(f'PCA explained variance: {model.explainedVariance}\n')
    return result


def get_child_count(dataframe, child_columns, new_column_name):
    """

    Args:
        dataframe ():
        child_columns ():
        new_column_name ():

    Returns:

    """
    dataframe = dataframe.withColumn(new_column_name,
                                     f.greatest(*[f.col(c).cast('int').alias(c) for c in child_columns]))
    return dataframe
