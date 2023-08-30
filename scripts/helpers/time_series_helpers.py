"""
Functions to support development of time series analytics work.
"""
import datetime
from typing import Tuple, Union

import numpy as np
from matplotlib import pyplot as plt
from pmdarima import auto_arima
from prophet import Prophet
from prophet.diagnostics import cross_validation, performance_metrics

import pyspark.pandas as ps
from sklearn.metrics import mean_squared_error
from statsmodels.tsa.seasonal import seasonal_decompose
from statsmodels.tsa.statespace.sarimax import SARIMAX

import pandas as pd

from statsmodels.tsa.exponential_smoothing.ets import ETSModel


def get_train_test_subsets(time_series: ps.DataFrame, periods: int) -> Tuple[ps.DataFrame, ps.DataFrame]:
    """ Splits dataset into train and test datasets. Test subset is determined by periods which is the number
    periods to test the model with. Returned dataframes contain unique rows, with no overlap.

    Args:
        time_series (Dataframe): Dataframe that contains the timeseries data, indexed by date
        periods (int): Number of periods to test model with e.g. for a weekly dataset, a value of 26
        would mean 26 weeks

    Returns:
        train (Dataframe): Dataframe with most recent n periods removed
        test (Dataframe): Dataframe with most recent n periods only.
    """
    train = time_series[: -periods]
    test = time_series[-periods:]
    return train, test


def get_best_arima_model(y: ps.DataFrame, start_q: int, start_p: int, max_iter: int, m: int,
                         d=None, D=None, **kwargs: dict) -> Tuple[tuple, tuple]:
    """
    Uses the Auto Arima algorithm from pmdarima to determine the best parameters for order and
    seasonal order in Auto Regression models. Function expects time series dataset with dates set as index, and target
    to be predicted as 'y'. See https://alkaline-ml.com/pmdarima/modules/generated/pmdarima.arima.auto_arima.html
    for variable descriptions.

    Args:
        y (Dataframe): Time series data
        start_q (int): The starting value of q, the order of the moving-average (“MA”) model.
        start_p (int): The starting value of p (number of time lags). Must be a positive integer.
        max_iter (int): Number of function evaluations
        m (int): Number of periods in each season e.g. 52 weeks in a year 'season'
        d (int): The order of first-differencing. None by default.
        D (int): The order of the seasonal differencing. None by default.
        kwargs (dict): additional keyword arguments used by auto_arima function

    Returns:
        best_order (tuple(int, int, int))
        best_seasonal (tuple(int, int, int, int))

    """
    model = auto_arima(y=y, start_q=start_q, start_p=start_p, d=d, D=D, trace=True,
                       m=m, error_action='ignore', maxiter=max_iter, kwargs=kwargs)

    print(model.aic())
    best_order = model.get_params().get('order')
    best_seasonal = model.get_params().get('seasonal_order')
    print(f'Best order p, d, q: {best_order}\nBest seasonal order: {best_seasonal}')
    return best_order, best_seasonal


def test_sarimax(train: ps.DataFrame, test: ps.DataFrame, order: tuple,
                 seasonal_order: tuple, exog=None) -> Tuple[dict, ps.DataFrame]:
    """
    Function that fits a SARIMAX model and calculates evaluation metrics RMSE, MAE, AIC and BIC.
    See https://www.statsmodels.org/dev/generated/statsmodels.tsa.statespace.sarimax.SARIMAX.html#statsmodels.tsa.statespace.sarimax.SARIMAX
    for full documentation.

    Args:
        train (Dataframe): Contains subset of data used to train model.
        test (Dataframe): Contains subset of data used to test model.
        order (int, int, int): Tuple containing p, d, q values.
        seasonal_order (int, int, int, int): Tuple containing (P,D,Q,s) order of seasonal components.
        exog (Series): None by default. Option for an exogenous variable to be included in model fitting.

    Returns:
        sarimax_metrics (dict of {str: float}): Evaluation metrics of fitted model.
        predictions (Dataframe): Contains model predictions for test data, indexed by date.

    """
    model_sarimax = SARIMAX(endog=train.y,
                            exog=exog,
                            order=order,
                            seasonal_order=seasonal_order).fit()

    test['predicted'] = model_sarimax.predict(start=test.index[0], end=test.index[-1])
    predictions = test['predicted']

    # performance metrics
    rmse_sarimax = round(np.sqrt(mean_squared_error(test.y, test.predicted)), 2)
    mae_sarimax = round(model_sarimax.mae, 2)
    aic_sarimax = round(model_sarimax.aic, 2)
    bic_sarimax = round(model_sarimax.bic, 2)

    sarimax_metrics = {'RMSE': rmse_sarimax, 'MAE': mae_sarimax,
                       'AIC': aic_sarimax, 'BIC': bic_sarimax
                       }

    return sarimax_metrics, predictions


def forecast_with_sarimax(train: ps.DataFrame, order: tuple, seasonal_order: tuple, steps: tuple[int, str, datetime],
                          exog=None) -> ps.Series:
    """
    Trains SARIMAX model with full dataset and produces a forcast for number periods (steps) specified.
    For full documentation see:
     https://www.statsmodels.org/stable/generated/statsmodels.tsa.statespace.sarimax.SARIMAXResults.html
    Args:
        train (Dataframe): Time series data, indexed by datetime.
        order (int, int, int): Tuple containing p, d, q values.
        seasonal_order (int, int, int, int): Tuple containing (P,D,Q,s) order of seasonal components.
        steps (int, str, datetime): Number of steps (periods) to forecast.
        exog (None): Default None. Optional.

    Returns:
        model_forecast (Dataframe) of forecast values of length
    """
    # train Sarimax model with all data
    model_sarimax = SARIMAX(endog=train.y,
                            exog=exog,
                            order=order,
                            seasonal_order=seasonal_order).fit()

    # make a forecast with Sarimax model trained on all data
    model_forecast = model_sarimax.forecast(steps=steps)
    return model_forecast


def reshape_time_series_data(pdf: ps.DataFrame, date_col: str, var_cols: list, dateformat: str) -> ps.DataFrame:
    """
    Prepares and cleans time series dataframe for time series models. Datetime column cast as datetime data type,
    datetime set as dataframe index, and features renamed to 'y_{n}'.
    Args:
        pdf (Dataframe): Dataframe containing date columns and features
        date_col (str): Name of the column containing datetime
        var_cols (list): List of features to keep within the reshaped dataframe

    Returns:
        Reshaped dataframe

    """

    pdf = pdf[[date_col] + var_cols]
    pdf = pdf.rename(columns={date_col: 'ds'})
    pdf.ds = ps.to_datetime(pdf.ds, format=dateformat)
    pdf = pdf.set_index('ds').sort_index()
    if len(var_cols) == 1:
        pdf = pdf.rename(columns={var_cols[0]: 'y'})
        pdf = pdf.astype({'y': float})
    elif len(var_cols) > 1:
        for v_col in var_cols:
            counter = 0
            pdf = pdf.rename(columns={v_col: f'y_{counter}'})
            pdf = pdf.astype({f'y_{counter}': float})
            counter += 1
        pdf = pdf.rename(columns={'y_0': 'y'})
    return pdf


def get_seasonal_decomposition(x: ps.DataFrame, model: str, period: int) -> Tuple[ps.DataFrame, ps.Series,
                                                                                  ps.Series, ps.Series]:
    """
    Drops any NAs from input dataframe. Extracts the trend, seasonality and residuals from dataset.
    Args:
        x (Dataframe): Dataframe indexed by date.
        model (str): Either of “additive” or “multiplicative”. Type of seasonal component.
        period (int): Number of periods within the season e.g. 52 weeks in a year (the season).

    Returns:
        x_reshaped (Dataframe): reshaped dataframe with NAs dropped.
        trend (Series): The upward and/or downward change in the values in the dataset.
        seasonal (Series) Short term cyclical repeating pattern in data.
        residual (Series) Random variation in the data once trend and seasonality removed.
    """
    x_reshaped = x.dropna
    decompose = seasonal_decompose(x=x_reshaped, model=model, period=period)
    trend = decompose.trend
    seasonal = decompose.seasonal
    residual = decompose.resid
    return x_reshaped, trend, seasonal, residual


def plot_seasonal_decomposition(x: ps.DataFrame, trend: ps.Series, seasonal: ps.Series, residual: ps.Series,
                                fname=None, show=False) -> None:
    """Options to plot seasonal decomposition data as well as save a PNG to file.
    If fname=None, PNG will not be saved. Returns None.
    """
    label_loc = 'upper left'
    fig, axes = plt.subplots(4, sharex=True)
    fig.set_figheight(10)
    fig.set_figwidth(15)
    fig.suptitle('Decomposition of time series data')
    axes[0].plot(x, label='Original')
    axes[0].legend(loc=label_loc)
    axes[1].plot(trend, label='Trend')
    axes[1].legend(loc=label_loc)
    axes[2].plot(seasonal, label='Cyclic')
    axes[2].legend(loc=label_loc)
    axes[3].plot(residual, label='Residuals')
    axes[3].legend(loc=label_loc)
    if fname:
        plt.tight_layout()
        plt.savefig(fname=fname)
    if show:
        plt.show()


def plot_time_series_data(x: ps.DataFrame, var_dict: dict, title: str, xlabel: str, ylabel: str,
                          fname=None, show=False) -> None:
    """Options to plot time series data as well as save a PNG to file.

    Args:
        x (Dataframe): Dataframe containing time series data, indexed by datetime.
        var_dict (dict): dict containing label and variable names e.g. {'Number people': 'y'}
        title (str): Title of plot.
        xlabel (str): Label of x axis.
        ylabel (str): label of y axis.
        fname (str): Filename of PNG. If None, PNG will not be saved.
        show (bool): Option to show plot in console.

    Returns:
        None

    """
    fig = plt.subplots(figsize=(10, 8))
    for k, v in var_dict.items():
        plt.plot(x.index, x[v], label=k)
    plt.title(title)
    plt.xlabel(xlabel)
    plt.ylabel(ylabel)
    plt.legend()
    if fname:
        plt.tight_layout()
        plt.savefig(fname=fname)
    if show:
        plt.show()


def plot_pred_forecast(train: ps.DataFrame, test: ps.DataFrame, predictions: ps.DataFrame, forecast: ps.Series,
                       train_label: str, test_label: str, title: str, suptitle: str, ylabel: str, xlabel: str,
                       metrics: dict, fname=None, show=False) -> None:
    """

    Args:
        train (Dataframe): Dataframe containing training timeseries dataset.
        test (Dataframe): Dataframe containing testing timeseries dataset.
        predictions (Dataframe): Dataframe containing predictions made on training data.
        forecast (Series): Series containing Out-of-sample predictions.
        train_label (str): Legend label for train dataset.
        test_label (str): Legend label for test dataset.
        title (str): Main title of plot.
        suptitle (str): Subtitle of plot.
        ylabel (str): y axis label.
        xlabel (str): x axis label.
        metrics (dict): Dictionary containing model performance metrics. Any length.
        fname (str): Default is None. If not empty, then will be the name of the file.
        show (bool): Boolean option to show chart in console.

    Returns:
        None

    """
    _, ax = plt.subplots(figsize=(20, 8))
    train.y.plot(ax=ax, label=train_label)
    test.y.plot(ax=ax, label=test_label)
    predictions.plot(ax=ax, label='Test forecast')
    forecast.plot(ax=ax, label='Model forecast')
    plt.legend()
    plt.title(title)
    plt.suptitle(f'{suptitle}: {metrics}', fontsize=18)
    plt.ylabel(ylabel)
    plt.xlabel(xlabel)
    if fname:
        plt.tight_layout()
        plt.savefig(fname=fname)
    if show:
        plt.show()


def apply_prophet(df, periods, horizon):
    """Function to test functionality tof the Prophet time series forecasting algorithm.
    """
    m = Prophet()
    m.fit(df)
    future = m.make_future_dataframe(periods=periods)
    future.tail()
    forecast = m.predict(future)
    cross_val = cross_validation(m, horizon=horizon)
    metrics = performance_metrics(cross_val)
    return forecast, cross_val, metrics


def get_start_end_date(dataframe, period, forecast_count):
    """

        Args:
            Dataframe (Dataframe): Dataframe containing training timeseries dataset.
            period (string): Description of the Period. "M" for example,
            forecast_count (Int): Amount of data points you want to forecast for

        Returns:
            Start Date (Datetime),
            End Date (Datetime)

        """

    max_index = dataframe.index.max()

    date_maker = {
        "M": [max_index + pd.DateOffset(months=1), max_index + pd.DateOffset(months=forecast_count)],
        "D": [max_index + pd.DateOffset(months=1), max_index + pd.DateOffset(months=forecast_count)],
        "W": [max_index + pd.DateOffset(weeks=1), max_index + pd.DateOffset(weeks=forecast_count)],
        "Y": [max_index + pd.DateOffset(years=1), max_index + pd.DateOffset(years=forecast_count)],
        "Q": [max_index + pd.DateOffset(months=3), max_index + pd.DateOffset(months=forecast_count * 3)]
    }

    start_date = date_maker.get(period)[0]
    end_date = date_maker.get(period)[1]

    return start_date, end_date


def forecast_ets(dataframe, start_date, end_date, seasonal=None, damped_trend=False, seasonal_periods=None):
    """

        Args:
            Dataframe (Dataframe): Dataframe containing training timeseries dataset.
            start_date (string): Start date of the Forecast,
            end_date (string): End date of the Forecast
            seasonal (String): Trend Component model. Optional. "Add", "mul" or None (default)
            damped_trend (Bool): Whether or not an included trend component is damped. Default is False
            seasonal_periods (int): The number of periods in a complete seasonal cycle for seasonal (Holt-Winters) models. For example, 4 for quarterly data with an annual cycle or 7 for daily data with a weekly cycle. Required if seasonal is not None.

        Returns:
            Forecast Results (Dataframe),

        """

    print(f'Get Prediction with: {start_date} to {end_date}')
    model = ETSModel(
        dataframe,
        error="add",
        trend="add",
        seasonal=seasonal,
        damped_trend=damped_trend,
        seasonal_periods=4,
    )
    fit = model.fit()

    pred = fit.get_prediction(start=start_date, end=end_date)

    df = pred.summary_frame(alpha=0.05)

    return df
