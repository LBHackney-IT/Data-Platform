"""
Functions and objects relating to housing disrepair analysis, specifically for damp and mould predictions.

TODO
* complete docstrings
* ml models and pipeline constructor
* write predictions to csv
"""
from pyspark.ml.classification import LogisticRegression
from pyspark.ml.evaluation import MulticlassClassificationEvaluator, BinaryClassificationEvaluator
from pyspark.ml.feature import StringIndexer, OneHotEncoder, VectorAssembler, Imputer, StandardScaler
from pyspark.ml.functions import vector_to_array
from pyspark.ml.tuning import ParamGridBuilder, CrossValidator
from pyspark.sql.functions import col, lit, udf, when, trim, length, greatest, expr
from pyspark.sql.types import DoubleType, ArrayType
from pyspark.sql import DataFrame


def convert_yn_to_bool(dataframe, columns):
    for column in columns:
        dataframe = dataframe.withColumn(column, when(col(column) == 'Y', 1).otherwise(col(column))) \
            .withColumn(column, when(col(column) == 'N', 0).otherwise(col(column)))
    return dataframe


def prepare_input_datasets(repairs_df, tenure_df, tenure_df_columns, deleted_estates, street_or_estate):
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

    # filter dataset to have either streets or estates
    repairs_df = repairs_df.filter(col('estate_street').isin(street_or_estate)) \
        .select('*')
    repairs_df = repairs_df.drop('estate_street')

    # join on uprn field (both string type)
    joined_df = repairs_df.join(tenure_df, 'uprn', 'left')

    # drop duplicate rows
    joined_df = joined_df.drop_duplicates(subset=['uprn'])
    return joined_df


def set_target(dataframe, target):
    dataframe = dataframe.withColumn('target', when(col(*target) == 1, 1).otherwise(0))
    dataframe = dataframe.drop(*target)
    return dataframe


def prepare_index_field(dataframe, column):
    """This feature will be used as a unique ID and needs to be numerical/string"""
    dataframe = dataframe.withColumn(column, col(column).cast('string'))
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
                                     when(col(bedroom_column) <= 1, '1 bedroom or less')
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


def assign_confidence_score(dataframe, high_confidence_flag):
    dataframe = dataframe.withColumn('confidence_score',
                                     when((col(high_confidence_flag) > 0) & (col('target') == 1), lit(1))
                                     .when((col(high_confidence_flag) > 0) & (col('target') == 0), lit(0.6))
                                     .when((col(high_confidence_flag) == 0) & (col('target') == 1), lit(0.8))
                                     .when((col(high_confidence_flag) == 0) & (col('target') == 0), lit(1))
                                     .otherwise(lit(0.8)))
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
    encoder = OneHotEncoder(inputCols=output_cols, outputCols=output_ohe, dropLast=True)
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


def scale_features(dataframe, vectorised_cols, output_col, mean, std, keep_columns):
    # set up scaler
    scaler = StandardScaler(inputCol=vectorised_cols, outputCol=output_col, withMean=mean, withStd=std)
    scaler_model = scaler.fit(dataframe)
    df_scaled = scaler_model.transform(dataframe)
    # extract scaled columns out
    if keep_columns:
        num_in_list = len(df_scaled.first()[vectorised_cols])
        df_scaled = df_scaled.select('*', array_to_list(col(vectorised_cols)).alias('scaled_col_list'))
        new_cols = [col('scaled_col_list')[i].alias(vectorised_cols) for i in range(num_in_list)]
        df_scaled = df_scaled.select('*', *new_cols)
        df_scaled = df_scaled.drop(*['scaled_col_list'])

    # drop columns no longer required
    df_scaled = df_scaled.drop(*vectorised_cols)
    return df_scaled


def assemble_vector_of_features(dataframe, cols_to_omit, cols_list, output_col):
    # vectorise features into a single column
    cols = [column for column in cols_list if column not in cols_to_omit]
    vector_assembler = VectorAssembler(inputCols=cols, outputCol=output_col)
    df_assembled = vector_assembler.transform(dataframe)
    return df_assembled


def evaluation_of_metrics(predictions: DataFrame, labelled_column: str, weights: str):
    metrics = MulticlassClassificationEvaluator(predictionCol="prediction",
                                                labelCol=labelled_column,
                                                weightCol=weights,
                                                probabilityCol="probability")
    accuracy = metrics.evaluate(predictions, {metrics.metricName: "accuracy"})
    precision_non_match = metrics.evaluate(predictions,
                                           {metrics.metricName: "precisionByLabel", metrics.metricLabel: 0.0})
    precision_match = metrics.evaluate(predictions,
                                       {metrics.metricName: "precisionByLabel", metrics.metricLabel: 1.0})
    recall_non_match = metrics.evaluate(predictions,
                                        {metrics.metricName: "recallByLabel", metrics.metricLabel: 0.0})
    recall_match = metrics.evaluate(predictions,
                                    {metrics.metricName: "recallByLabel", metrics.metricLabel: 1.0})
    return accuracy, precision_non_match, precision_match, recall_non_match, recall_match


def balance_classes(dataframe, target_col, new_weight_col):
    balance_ratio = dataframe.filter(col(target_col) == 1).count() / dataframe.count()
    calculate_weights = udf(lambda x: 1 * balance_ratio if x == 0 else (1 * (1.0 - balance_ratio)), DoubleType())
    dataframe_with_weights = dataframe.withColumn(new_weight_col, calculate_weights(target_col))
    return dataframe_with_weights


def train_model(df: DataFrame, model_path: str, test_model: bool, save_model: bool, target_col: str,
                weight_col: str, features_col: str) -> None:
    """Trains the model

    Args:
        df: DataFrame containing data. This includes both test and train
        model_path: Path where trained model is saved.
        test_model: Boolean to specify whether model should be tested with test data.
        save_model: Boolean to specify whether model should be saved to S3.
        target_col: Feature containing target to predict
        weight_col: Vector containing standardised confidence score
        features_col: Vector containing standardised input features

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

    classifier = LogisticRegression(featuresCol=features_col, labelCol=target_col, weightCol=weight_col,
                                    standardization=False)

    param_grid = ParamGridBuilder() \
        .addGrid(classifier.regParam, [7e-05]) \
        .addGrid(classifier.elasticNetParam, [1.0]) \
        .build()
    evaluator = BinaryClassificationEvaluator(labelCol=target_col,
                                              rawPredictionCol="rawPrediction",
                                              weightCol=weight_col)

    cv = CrossValidator(estimator=classifier, estimatorParamMaps=param_grid, evaluator=evaluator, numFolds=5,
                        seed=42,
                        parallelism=5)
    cv_model = cv.fit(train)

    train_prediction = cv_model.transform(train)

    print(f"Training ROC AUC train score before fine-tuning..: {evaluator.evaluate(train_prediction):.5f}")
    accuracy, precision_non_match, precision_match, recall_non_match, recall_match = \
        evaluation_of_metrics(train_prediction, labelled_column=target_col, weights=weight_col)
    print(f"Training Accuracy  before fine-tuning............: {accuracy:.5f}")
    print(f"Training Precision before fine-tuning (non-match): {precision_non_match:.5f}")
    print(f"Training Precision before fine-tuning.....(match): {precision_match:.5f}")
    print(f"Training Recall    before fine-tuning.(non-match): {recall_non_match:.5f}")
    print(f"Training Recall    before fine-tuning.....(match): {recall_match:.5f}")

    model = cv_model.bestModel
    training_summary = model.summary

    # Fine-tuning the model to maximize performance
    f_measure = training_summary.fMeasureByThreshold
    max_f_measure = f_measure.groupBy().max("F-Measure").select("max(F-Measure)").head()
    best_threshold = f_measure \
        .filter(f_measure["F-Measure"] == max_f_measure["max(F-Measure)"]) \
        .select("threshold") \
        .head()["threshold"]
    print(f"Best threshold: {best_threshold}")
    cv_model.bestModel.setThreshold(best_threshold)
    print(model.extractParamMap())

    if save_model:
        cv_model.write().overwrite().save(model_path)

    train_prediction = cv_model.transform(train)
    print(f"Training ROC AUC train score after fine-tuning...: {evaluator.evaluate(train_prediction):.5f}")
    accuracy, precision_non_match, precision_match, recall_non_match, recall_match = \
        evaluation_of_metrics(train_prediction,
                              labelled_column=target_col,
                              weights=weight_col)

    print(f"Training Accuracy  after fine-tuning.............: {accuracy:.5f}")
    print(f"Training Precision after fine-tuning .(non-match): {precision_non_match:.5f}")
    print(f"Training Precision after fine-tuning......(match): {precision_match:.5f}")
    print(f"Training Recall    after fine-tuning..(non-match): {recall_non_match:.5f}")
    print(f"Training Recall    after fine-tuning......(match): {recall_match:.5f}")

    if test_model:
        print("Only evaluate once in the end, so keep it commented for most of the time.")
        test_prediction = cv_model.transform(test)
        test_prediction.show()
        print(f'Write predictions to csv...')
        test_prediction.printSchema()
        # test_prediction_for_export = test_prediction.withColumn('probability',
        #                                                         vector_to_array(col('probability'))) \
        #     .withColumn('probability_str', concat_ws('probability'))
        # test_prediction_for_export.write.csv(header=True, path=f"{model_path}/test_predictions")

        accuracy, precision_non_match, precision_match, recall_non_match, recall_match = evaluation_of_metrics(
            test_prediction,
            labelled_column=target_col,
            weights=weight_col)
        print(f"Test ROC AUC..............: {evaluator.evaluate(test_prediction):.5f}")
        print(f"Test Accuracy.............: {accuracy:.5f}")
        print(f"Test Precision (non-match): {precision_non_match:.5f}")
        print(f"Test Precision.....(match): {precision_match:.5f}")
        print(f"Test Recall....(non-match): {recall_non_match:.5f}")
        print(f"Test Recall........(match): {recall_match:.5f}")
