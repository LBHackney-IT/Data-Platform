"""
This script uses helpers from time_series_helpers.py to forecast future staff sickness levels using the SARIMAX model.

"""

import argparse
from pyspark.sql.types import FloatType

from scripts.helpers.time_series_helpers import get_best_arima_model, test_sarimax, forecast_with_sarimax, \
    get_train_test_subsets, get_seasonal_decomposition, plot_pred_forecast, \
    reshape_time_series_data, plot_seasonal_decomposition
from scripts.jobs.env_context import DEFAULT_MODE_AWS, LOCAL_MODE, ExecutionContextProvider
from scripts.helpers.helpers import add_import_time_columns, PARTITION_KEYS, \
    create_pushdown_predicate_for_max_date_partition_value


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--execution_mode", default=DEFAULT_MODE_AWS,
                        choices=[DEFAULT_MODE_AWS, LOCAL_MODE], type=str,
                        required=False, metavar="set --execution_mode=aws to run on AWS")
    parser.add_argument("--source_catalog_database", default=DEFAULT_MODE_AWS, type=str,
                        required=False)
    parser.add_argument("--source_catalog_table_sickness", default=DEFAULT_MODE_AWS, type=str,
                        required=False)
    parser.add_argument("--output_path", default=DEFAULT_MODE_AWS, type=str,
                        required=False)
    parser.add_argument("--target_bucket", default=DEFAULT_MODE_AWS, type=str,
                        required=False)
    parser.add_argument("--periods", default=DEFAULT_MODE_AWS, type=int,
                        required=False)
    parser.add_argument("--season", default=DEFAULT_MODE_AWS, type=int,
                        required=False)

    # set argument for each arg
    source_catalog_database_glue_arg = "source_catalog_database"
    source_catalog_table_sickness_glue_arg = "source_catalog_table_sickness"
    output_path_glue_arg = "output_path"
    target_bucket_glue_arg = "target_bucket"
    periods_glue_arg = "periods"
    season_glue_arg = "season"

    glue_args = [
        source_catalog_database_glue_arg,
        source_catalog_table_sickness_glue_arg,
        output_path_glue_arg,
        target_bucket_glue_arg,
        periods_glue_arg,
        season_glue_arg
    ]

    local_args, _ = parser.parse_known_args()
    mode = local_args.execution_mode

    with ExecutionContextProvider(mode, glue_args, local_args) as execution_context:
        logger = execution_context.logger
        spark = execution_context.spark_session
        spark.conf.set("spark.sql.broadcastTimeout", "7200")

        source_catalog_database = execution_context.get_input_args(source_catalog_database_glue_arg)
        source_catalog_table_sickness = execution_context.get_input_args(source_catalog_table_sickness_glue_arg)
        output_data_path = execution_context.get_input_args(output_path_glue_arg)
        target_bucket = execution_context.get_input_args(target_bucket_glue_arg)
        periods = execution_context.get_input_args(periods_glue_arg)
        season = execution_context.get_input_args(season_glue_arg)

        # read in data
        absence_df = execution_context.get_dataframe(name_space=source_catalog_database,
                                                     table_name=source_catalog_table_sickness,
                                                     push_down_predicate=create_pushdown_predicate_for_max_date_partition_value(
                                                         source_catalog_database,
                                                         source_catalog_table_sickness, 'import_date'))
        absence_pdf = absence_df.toPandas()
        absence_pdf = reshape_time_series_data(pdf=absence_pdf,
                                               date_col='calculation_date:absence',
                                               var_cols=['days_lost:absence'],
                                               dateformat='%d/%m/%Y')

        # set min and max cutoff dates
        #  TODO a function that trims data to nearest Monday two weeks either end
        min_date = '2017-05-16'
        max_date = '2023-08-07'

        absence_pdf = absence_pdf.loc[min_date: max_date]
        # resample data to week level
        week_absence = absence_pdf.resample('W-MON').sum()

        # look at the absence data in more detail
        absence_reshape, trend, seasonality, residuals = get_seasonal_decomposition(x=absence_pdf,
                                                                                    model='additive',
                                                                                    period=int(season))
        # plot decomposition
        plot_seasonal_decomposition(x=absence_pdf, trend=trend, seasonal=seasonality, residual=residuals,
                                    bucket=target_bucket, fname='images/decomposition_staff_sickness.png')

        # split into train and test subsets. Test based on number weeks/periods to predict e.g 6 months
        train, test = get_train_test_subsets(time_series=week_absence, periods=int(periods))

        # use Auto ARIMA to derive best values for p, d and q and seasonal order
        best_order, best_seasonal_order = get_best_arima_model(y=week_absence,
                                                               start_q=0,
                                                               start_p=0,
                                                               d=1,
                                                               D=1,
                                                               max_iter=20,
                                                               m=int(season))

        # test SARIMAX with new values
        sarimax_metrics, predictions = test_sarimax(train=train,
                                                    test=test,
                                                    order=best_order,
                                                    seasonal_order=best_seasonal_order)
        logger.info(f'SARIMAX model evaluation metrics: {sarimax_metrics}')

        # make forecast with SARIMAX using all data for one year (52 weeks)
        model_forecast = forecast_with_sarimax(train=week_absence,
                                               order=best_order,
                                               seasonal_order=best_seasonal_order,
                                               steps=int(periods))
        logger.info(f'SARIMAX model forecast: {model_forecast.head()}')

        plot_pred_forecast(train=train, test=test, predictions=predictions, forecast=model_forecast,
                           train_label='Train', test_label='Test', title='Absence forecasting (Sickness)',
                           suptitle='SARIMAX', metrics=sarimax_metrics,
                           ylabel='Number absences', xlabel='Year', bucket=target_bucket,
                           fname='images/sarimax_pred_forecast_staff_sickness.png')

        # Convert pandas df to spark df and then write forecast to parquet
        model_forecast_df = spark.createDataFrame(model_forecast, FloatType())
        model_forecast_df = add_import_time_columns(model_forecast_df)
        execution_context.save_dataframe(model_forecast_df,
                                         f'{output_data_path}',
                                         *PARTITION_KEYS,
                                         save_mode='overwrite')
        logger.info(f'Prepared dataframe for model forecast written successfully to {output_data_path}')


if __name__ == '__main__':
    main()
