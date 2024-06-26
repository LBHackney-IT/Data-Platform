import json
import logging
from os import getenv
from urllib.parse import quote

import boto3
import urllib3

logger = logging.getLogger()
logger.setLevel(logging.INFO)


def format_message(event) -> dict:
    timestamp = event["time"]
    job_name = event["detail"]["jobName"]
    job_name_parsed = quote(job_name)
    job_run_id = event["detail"]["jobRunId"]
    error_message = event["detail"]["message"]
    region = event["region"]
    return {
        "text": (
            f"{timestamp} \nGlue failure detected for job: *{job_name}* \nrun:"
            f" https://{region}.console.aws.amazon.com/gluestudio/home?region={region}#/job/{job_name_parsed}/run/{job_run_id} \nError"
            f" message: {error_message}"
        )
    }


def get_max_retries(job_name, glue_client=None) -> int:
    glue_client = glue_client or boto3.client("glue")
    response = glue_client.get_job(JobName=job_name)
    return response["Job"]["MaxRetries"]


def get_run_attempt(job_name, job_run_id, glue_client=None) -> int:
    glue_client = glue_client or boto3.client("glue")
    response = glue_client.get_job_run(JobName=job_name, RunId=job_run_id)
    return response["JobRun"]["Attempt"]


def lambda_handler(
    event=None, lambda_context=None, secretsManagerClient=None, glueClient=None
):
    secret_name = getenv("SECRET_NAME")
    secrets_manager_client = secretsManagerClient or boto3.client("secretsmanager")
    glue_client = glueClient or boto3.client("glue")

    max_retries = get_max_retries(event["detail"]["jobName"], glue_client)
    attempt = get_run_attempt(
        event["detail"]["jobName"], event["detail"]["jobRunId"], glue_client
    )

    if attempt < max_retries:
        logger.info("Glue job failed, but it is still within the max retries")
    else:
        secret = secrets_manager_client.get_secret_value(SecretId=secret_name)

        webhook_url = secret["SecretString"]
        message = format_message(event)
        message_headers = {"Content-Type": "application/json; charset=UTF-8"}
        http = urllib3.PoolManager()

        http.request(
            "POST", webhook_url, body=json.dumps(message), headers=message_headers
        )

        logger.info("Alert sent successfully")


if __name__ == "__main__":
    lambda_handler("event", "lambda_context")
