"""
This script imports a prepared dataset for running ml models to predict properties most at risk from
damp and mould.

Input datasets:
* Prepared dataset containing household level data on building type/characteristics and repairs history

Output:
* Trained predictive model of type specified
"""

import argparse

from great_expectations.dataset import SparkDFDataset
from pyspark.ml import Pipeline
from pyspark.ml.classification import LogisticRegression, RandomForestClassifier, GBTClassifier, \
    LinearSVC, MultilayerPerceptronClassifier, DecisionTreeClassifier
from pyspark.ml.evaluation import BinaryClassificationEvaluator
from pyspark.ml.tuning import ParamGridBuilder, CrossValidator

from scripts.jobs.env_context import DEFAULT_MODE_AWS, LOCAL_MODE, ExecutionContextProvider
from scripts.helpers.helpers import add_import_time_columns, PARTITION_KEYS, \
    create_pushdown_predicate_for_latest_written_partition, \
    create_pushdown_predicate_for_max_date_partition_value
from scripts.helpers.housing_disrepair_helpers import balance_classes, \
    get_evaluation_metrics, split_dataset, set_up_base_model_pipeline_stages, set_up_meta_model_pipeline_stages
import scripts.helpers.damp_and_mould_inputs as inputs


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--execution_mode", default=DEFAULT_MODE_AWS, choices=[DEFAULT_MODE_AWS, LOCAL_MODE], type=str,
                        required=False, metavar="set --execution_mode=aws to run on AWS")
    parser.add_argument("--source_catalog_database_data_and_insight", type=str, required=True,
                        metavar="set --source_catalog_database_data_and_insight=path to catalog database")
    parser.add_argument("--source_catalog_table_damp_and_mould_prepped", type=str, required=True,
                        metavar="set --source_catalog_table_damp_and_mould_prepped=path to disrepair dataset")
    parser.add_argument("--model_output_path", type=str, required=False,
                        metavar=f"set --model_output_path=path to model output folder")

    # set argument for each arg
    source_catalog_database_data_and_insight_glue_arg = "source_catalog_database_data_and_insight"
    source_catalog_table_damp_and_mould_prepped_glue_arg = "source_catalog_table_damp_and_mould_prepped"
    model_output_path_glue_arg = "model_output_path"

    glue_args = [source_catalog_database_data_and_insight_glue_arg,
                 source_catalog_table_damp_and_mould_prepped_glue_arg,
                 model_output_path_glue_arg
                 ]

    local_args, _ = parser.parse_known_args()
    mode = local_args.execution_mode

    with ExecutionContextProvider(mode, glue_args, local_args) as execution_context:
        logger = execution_context.logger
        spark = execution_context.spark_session
        spark.conf.set("spark.sql.broadcastTimeout", 7200)

        # set additional variables
        save_model = True
        stacking = True
        testing = False

        # set input and output
        source_catalog_database_data_and_insight = execution_context.get_input_args(
            source_catalog_database_data_and_insight_glue_arg)
        source_catalog_table_damp_and_mould_prepped = execution_context.get_input_args(
            source_catalog_table_damp_and_mould_prepped_glue_arg)
        model_output_path = execution_context.get_input_args(model_output_path_glue_arg)

        # load prepared data into a dataframe
        dm_df = execution_context.get_dataframe(source_catalog_table_damp_and_mould_prepped)

        if testing:

            # set up column lists for the base model pipeline
            df_cols = dm_df.schema.names
            str_cols = [c for c in inputs.ohe_cols if c in df_cols]
            initial_feat_cols = [column for column in df_cols if
                                 column not in str_cols + ['uprn', 'target', 'confidence_score_std', 'import_datetime',
                                                           'confidence_score', 'import_timestamp', 'import_year',
                                                           'import_month', 'import_day', 'import_date']]

            base_model_stages = set_up_base_model_pipeline_stages(string_cols=str_cols,
                                                                  feature_cols=initial_feat_cols,
                                                                  output_feature_col='std_features',
                                                                  input_target_col='target',
                                                                  output_target_col='target_idx'
                                                                  )

            # set up classifiers
            log_reg = LogisticRegression(featuresCol='std_features', labelCol='target_idx',
                                         weightCol='confidence_score')

            rf = RandomForestClassifier(featuresCol='std_features', labelCol='target_idx',
                                        weightCol='confidence_score', seed=42)

            gbt = GBTClassifier(featuresCol='std_features', labelCol='target_idx',
                                weightCol='confidence_score', seed=42)

            lsvm = LinearSVC(featuresCol='std_features', labelCol='target_idx',
                             weightCol='confidence_score')

            dtc = DecisionTreeClassifier(featuresCol='std_features', labelCol='target_idx',
                                         weightCol='confidence_score', seed=42)

            # create empty dataframe for metrics
            metrics_df = spark.createDataFrame([(1, 'TP'),
                                                (2, 'FP'),
                                                (3, 'TN'),
                                                (4, 'FN'),
                                                (5, 'Accuracy'),
                                                (6, 'Precision'),
                                                (7, 'Recall'),
                                                (8, 'Area under ROC Curve'),
                                                (9, 'Area under PR Curve'),
                                                (10, 'F1 score')],
                                               ['#', 'metric'])

            classifier_list = [

                ['Linear SVM Classifier', lsvm],
                ['Decision Tree Classifier', dtc],
                ['Logistic Regression', log_reg],
                ['Random Forests', rf],
                ['Gradient Boosted Trees', gbt]]

            for title, classifier in classifier_list:
                logger.info(f'Training {classifier}...')

                # add classifier to pipeline
                specific_base_model_stages = base_model_stages + [classifier]
                pipeline = Pipeline(stages=specific_base_model_stages)

                train_test = dm_df.randomSplit([0.7, 0.3], seed=42)
                train = train_test[0]
                test = train_test[1]
                train.cache()

                # create grid of parameters to test for each classifier
                params = ParamGridBuilder() \
                    .addGrid(log_reg.threshold, [0.4]) \
                    .addGrid(log_reg.regParam, [0.00]) \
                    .addGrid(log_reg.maxIter, [10]) \
                    .addGrid(rf.numTrees, [350]) \
                    .addGrid(rf.maxDepth, [10]) \
                    .addGrid(rf.impurity, ['entropy']) \
                    .addGrid(gbt.maxIter, [200]) \
                    .addGrid(gbt.minInfoGain, [0.01]) \
                    .addGrid(gbt.maxDepth, [10]) \
                    .addGrid(gbt.maxBins, [40]) \
                    .addGrid(lsvm.maxIter, [200]) \
                    .addGrid(lsvm.regParam, [0.02]) \
                    .addGrid(lsvm.threshold, [0.5]) \
                    .addGrid(dtc.thresholds, [[0.4, 0.4]]) \
                    .addGrid(dtc.maxDepth, [10]) \
                    .addGrid(dtc.minInfoGain, [0.01]) \
                    .build()

                cv = CrossValidator(estimator=pipeline,
                                    estimatorParamMaps=params,
                                    evaluator=BinaryClassificationEvaluator(labelCol='target_idx',
                                                                            weightCol='confidence_score',
                                                                            metricName='areaUnderPR'),
                                    numFolds=5,
                                    parallelism=5)

                # Run cross-validation, and choose the best set of parameters.
                cv_model = cv.fit(train)

                # get best model parameters
                best_mod = cv_model.bestModel

                param_dict = best_mod.stages[-1].extractParamMap()
                best_vals_dict = {}
                for k, v in param_dict.items():
                    best_vals_dict[k.name] = v

                av_metrics = zip(cv_model.avgMetrics, params)

                logger.info(f'\nAverage metrics for {classifier}: {av_metrics}\n')

                # apply best model to test data and generate metrics
                prediction_test = best_mod.transform(test)

                # check cols available
                output_cols = [output_col for output_col in ['uprn', 'target_idx', 'probability', 'rawPrediction',
                                                             'prediction'] if
                               output_col in prediction_test.schema.names]

                predictions = prediction_test.select(*output_cols)
                metrics = get_evaluation_metrics(classifier_name=f'{title}: {best_vals_dict}',
                                                 spark=spark,
                                                 predictions=predictions,
                                                 target='target_idx',
                                                 prediction_col='prediction')
                metrics_df = metrics_df.join(metrics, on='metric')

            logger.info(f'Writing results to {model_output_path}/metrics/...')
            metrics_df.write.csv(header=True, mode='overwrite', path=f'{model_output_path}/metrics/')

        if stacking:
            logger.info(f'Starting the stacking process...')
            logger.info(f'Splitting dataset into train, validation and test sets...')

            train_stack, val_stack, test_stack = split_dataset(dataframe=dm_df, target='target',
                                                               ratio_list=[0.4, 0.4, 0.2])

            # set up base model stages
            df_cols = dm_df.schema.names
            str_cols = [c for c in inputs.ohe_cols if c in df_cols]
            initial_feat_cols = [column for column in df_cols if
                                 column not in str_cols + ['uprn', 'target', 'confidence_score_std', 'import_datetime',
                                                           'confidence_score', 'import_timestamp', 'import_year',
                                                           'import_month', 'import_day', 'import_date']]
            base_model_stages = set_up_base_model_pipeline_stages(string_cols=str_cols,
                                                                  feature_cols=initial_feat_cols,
                                                                  output_feature_col='std_features',
                                                                  input_target_col='target',
                                                                  output_target_col='target_idx'
                                                                  )

            # set up best classifiers from testing phase
            log_reg = LogisticRegression(featuresCol='std_features', labelCol='target_idx',
                                         weightCol='confidence_score', predictionCol='pred_log_reg',
                                         probabilityCol='prob_log_reg', rawPredictionCol='rawPred_log_reg',
                                         maxIter=10, regParam=0.01, threshold=0.4)

            rf = RandomForestClassifier(featuresCol='std_features', labelCol='target_idx', weightCol='confidence_score',
                                        seed=42, predictionCol='pred_rf', probabilityCol='prob_rf',
                                        rawPredictionCol='rawPred_rf', numTrees=350, maxDepth=10, impurity='entropy')

            gbt = GBTClassifier(featuresCol='std_features', labelCol='target_idx', weightCol='confidence_score',
                                seed=42, predictionCol='pred_gbt', maxIter=50, maxBins=40, maxDepth=5)

            lsvm = LinearSVC(featuresCol='std_features', labelCol='target_idx',
                             weightCol='confidence_score', predictionCol='pred_lsvm',
                             rawPredictionCol='rawPred_lsvm', aggregationDepth=2, maxIter=100, regParam=0.01)

            dtc = DecisionTreeClassifier(featuresCol='std_features', labelCol='target_idx',
                                         weightCol='confidence_score', seed=42, maxDepth=15,
                                         predictionCol='pred_dtc',
                                         probabilityCol='prob_dtc', rawPredictionCol='rawPred_dtc')

            # add base models to pipeline
            base_models = [log_reg, rf, gbt, lsvm, dtc]
            stacked_base_model_stages = base_model_stages + base_models
            pipeline_stack = Pipeline(stages=stacked_base_model_stages)

            # create pipeline for base model and fit on the training set
            pipeline_base_model = pipeline_stack.fit(train_stack)

            # make predictions on the validation set
            base_model_preds = pipeline_base_model.transform(val_stack)

            logger.info(f'Setting up meta model...')
            # create the meta features dataset
            meta_model_cols = ['pred_log_reg', 'pred_rf', 'pred_gbt', 'pred_lsvm', 'pred_dtc']
            meta_model_cont_cols = ['prob_log_reg', 'prob_rf', 'prob_dtc']
            meta_feats_df = base_model_preds.select(*meta_model_cols, *meta_model_cont_cols, 'target_idx')
            meta_model_stages = set_up_meta_model_pipeline_stages(meta_feature_cols=meta_model_cols,
                                                                  meta_cont_cols=meta_model_cont_cols,
                                                                  output_meta_features_col='all_meta_features',
                                                                  meta_target_col='target_idx',
                                                                  output_meta_target_col='meta_target')

            # build the mata model pipeline
            meta_classifier = LogisticRegression(featuresCol='all_meta_features',
                                                 labelCol='meta_target', predictionCol='meta_predictions')
            meta_model_stages += [meta_classifier]
            meta_pipeline = Pipeline(stages=meta_model_stages)

            meta_params = ParamGridBuilder() \
                .addGrid(meta_classifier.regParam, [0.01]) \
                .addGrid(meta_classifier.maxIter, [10]) \
                .addGrid(meta_classifier.threshold, [0.4]) \
                .build()

            cv_meta = CrossValidator(estimator=meta_pipeline,
                                     estimatorParamMaps=meta_params,
                                     evaluator=BinaryClassificationEvaluator(labelCol='meta_target'),
                                     numFolds=5,
                                     parallelism=5)

            # Run cross-validation and get the best meta model
            pipeline_meta_model = cv_meta.fit(meta_feats_df)

            # make predictions using meta model on test dataset
            logger.info(f'Making predictions on test dataset...')
            base_model_preds_test = pipeline_base_model.transform(test_stack)
            meta_test_df = base_model_preds_test.select(*meta_model_cols, *meta_model_cont_cols, 'target')
            meta_model_test_preds = pipeline_meta_model.transform(meta_test_df)

            meta_model_test_preds.show(5)
            stacked_metrics_df = get_evaluation_metrics(classifier_name=f'Stacked',
                                                        spark=spark,
                                                        predictions=meta_model_test_preds,
                                                        target='target',
                                                        prediction_col='meta_predictions'
                                                        )
            stacked_metrics_df.show()

        if save_model:
            logger.info(f'Saving meta model to {model_output_path}/meta_model_output/...')
            pipeline_meta_model.write().overwrite().save(f'{model_output_path}/meta_model_output/')
            meta_model_test_preds.write.parquet(mode='overwrite', path=f'{model_output_path}/meta_preds/parquet/')
            meta_model_test_preds.select(*meta_model_cols, 'target', 'meta_predictions') \
                .coalesce(1).write.csv(header=True,
                                       path=f'{model_output_path}/meta_preds/',
                                       mode='overwrite')


if __name__ == '__main__':
    main()
