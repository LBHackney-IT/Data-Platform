"""
Functions to support development of time series analytics work.
"""

import numpy as np
from matplotlib import pyplot as plt
from pmdarima import auto_arima
from prophet import Prophet
from prophet.diagnostics import cross_validation, performance_metrics

import pyspark.pandas as ps
from sklearn.metrics import mean_squared_error, mean_absolute_error
from statsmodels.tsa.seasonal import seasonal_decompose
from statsmodels.tsa.statespace.sarimax import SARIMAX


def get_train_test_subsets(time_series, periods):
    """ Splits dataset into train and test datasets. Test subset is determined by periods which is the number
    periods to test the model with.

    Args:
        time_series (Dataframe):
        periods (int):

    Returns:
        train (Dataframe)
        test (Dataframe)
    """
    train = time_series[: -periods]
    test = time_series[-periods:]
    return train, test


def get_best_arima_model(y, start_q, start_p, d, D, max_iter, m, **kwargs):
    """
    Uses the Auto Arima algorithm from pmdarima to determine the best parameters for order and
    seasonal order in Auto Regression models. Function expects time series dataset with dates set as index, and target
    to be predicted as 'y'.

    Args:
        y (Dataframe): Time series data
        start_q (int):
        start_p (int):
        d (int):
        D (int):
        max_iter (int): Number of function evaluations
        m (int): Number of periods in each season e.g. 52 weeks in a year 'season'
        kwargs (dict):

    Returns:
        best_order (int, int, int)
        best_seasonal (int, int, int, int)

    """
    model = auto_arima(y=y, start_q=start_q, start_p=start_p, d=d, D=D, trace=True,
                       m=m, error_action='ignore', maxiter=max_iter, kwargs=kwargs)

    print(model.aic())
    best_order = model.get_params().get('order')
    best_seasonal = model.get_params().get('seasonal_order')
    print(f'Best order p, d, q: {best_order}\nBest seasonal order: {best_seasonal}')
    return best_order, best_seasonal


def test_sarimax(train, test, order, seasonal_order, exog=None):
    """

    Args:
        train (Dataframe):
        test (Dataframe):
        exog (Series):
        order (int, int, int):
        seasonal_order (int, int, int, int):

    Returns:
        sarimax_metrics (dict of {str: float})
        predictions (Series)

    """
    model_sarimax = SARIMAX(endog=train.y,
                            exog=exog,
                            order=order,
                            seasonal_order=seasonal_order).fit()

    test['predicted'] = model_sarimax.predict(start=test.index[0], end=test.index[-1])
    predictions = test['predicted']

    # performance metrics
    rmse_sarimax = round(np.sqrt(mean_squared_error(test.y, test.predicted)), 2)
    mae_sarimax = round(mean_absolute_error(test.y, test.predicted), 2)
    aic_sarimax = round(model_sarimax.aic, 2)
    bic_sarimax = round(model_sarimax.bic, 2)

    sarimax_metrics = {'RMSE': rmse_sarimax, 'MAE': mae_sarimax, 'AIC': aic_sarimax,
                       'BIC': bic_sarimax
                       }

    return sarimax_metrics, predictions


def forecast_with_sarimax(train, order, seasonal_order, steps, exog=None):
    """

    Args:
        train (Dataframe): Time series data
        exog (): Default None
        order (int, int, int)
        seasonal_order (int, int, int, int)
        steps (int, str, datetime): Number of steps to forecast

    Returns:
        model_forecast (Series) of forecast values of length
    """
    # train Sarimax model with all data
    model_sarimax = SARIMAX(endog=train.y,
                            exog=exog,
                            order=order,
                            seasonal_order=seasonal_order).fit()

    # make a forecast with Sarimax model trained on all data
    model_forecast = model_sarimax.forecast(steps=steps)
    return model_forecast


def reshape_time_series_data(pdf, date_col, var_cols):
    # cast date column and add as index
    pdf = pdf[[date_col] + var_cols]
    pdf = pdf.rename(columns={date_col: 'ds'})
    pdf.ds = ps.to_datetime(pdf.ds, format='%d/%m/%Y')
    pdf = pdf.set_index('ds').sort_index()
    if len(var_cols) == 1:
        pdf = pdf.rename(columns={var_cols[0]: 'y'})
    elif len(var_cols) > 1:
        for v_col in var_cols:
            counter = 0
            pdf = pdf.rename(columns={v_col: f'y_{counter}'})
            pdf = pdf.astype({f'y_{counter}': float})
            counter += 1
        pdf = pdf.rename(columns={'y_0': 'y'})
    return pdf


def get_seasonal_decompose_plot(x, model, period, plot=False, fname=None):
    """

    Args:
        fname ():
        plot ():
        df ():
        model ():
        period ():

    Returns:

    """
    decompose = seasonal_decompose(x=x.dropna(), model=model, period=period)
    trend = decompose.trend
    seasonal = decompose.seasonal
    residual = decompose.resid
    if plot:
        label_loc = 'upper left'
        fig, axes = plt.subplots(4, 1, sharex=True, sharey=False)
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
        plt.show()
    return trend, seasonal, residual


def plot_time_series_data(x, var_dict, title, xlabel, ylabel, fname=None):
    """

    Args:
        x ():
        var_dict (): dict containing label and variable names e.g. {'Number people': 'y'}
        title ():
        xlabel ():
        ylabel ():

    Returns:

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
    plt.show()


# plot predictions and forecast
def plot_pred_forecast(train, test, predictions, forecast,
                       train_label, test_label, title,
                       suptitle, ylabel, xlabel, metrics, fname):
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
    plt.show()


def apply_prophet(df, periods, horizon):
    m = Prophet()
    m.fit(df)
    future = m.make_future_dataframe(periods=periods)
    future.tail()
    forecast = m.predict(future)
    cross_val = cross_validation(m, horizon=horizon)
    metrics = performance_metrics(cross_val)
    return forecast, cross_val, metrics
