from helpers.helpers import get_glue_env_var

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
