
from pyspark.sql import DataFrame

from scripts.helpers.helpers import get_glue_env_var


def get_metrics_target_location():
    metrics_target_location = get_glue_env_var('deequ_metrics_location')
    if (metrics_target_location == None):
        raise ValueError("deequ_metrics_location not set. Please define in the glue job arguments.")
    return metrics_target_location


def cancel_job_if_failing_quality_checks(check_results: DataFrame):
    """
    This method will check if there are any failing constraints
    on the provided PyDeequ Verification Result.
    If there are any, it will cause the Glue job to fail by
    throwing an exception with the constraint message.

    Example of usage:
    cancel_job_if_failing_quality_checks(VerificationResult.checkResultsAsDataFrame(spark_session, checkResult))
    """
    has_error = check_results.where(check_results.constraint_status == "Failure")
    if (has_error.count() > 0):
        messages = [
            f"{message['check']}. {message['constraint_message']}"
            for message in has_error.collect()
        ]
        raise Exception(' | '.join(messages))


def get_data_quality_check_results(check_results):
    """
    This will return the contraint messages for the data quality checks.
    """
    messages = [
        f'{message.constraint} finished with status {message.constraint_status}. {message.constraint_message}'
        for message in check_results.collect()
    ]
    return messages


def get_success_metrics(success_metrics):
    """
    This will return the success metrics for the passed data quality checks.
    """
    messages = [
        f'{message.entity} {message.instance}, {message.name}, {message.value}'
        for message in success_metrics.collect()
    ]
    return messages


