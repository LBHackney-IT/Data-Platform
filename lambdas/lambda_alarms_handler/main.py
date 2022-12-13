import logging
import boto3
from json import dumps
from os import getenv

import urllib3

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def format_message(event) -> dict:
    return {
         'text': f"{event['Records'][0]['Sns']['Timestamp']} Lambda failure detected: {event['Records'][0]['Sns']['Subject']}"
    }

def lambda_handler(event=None, lambda_context=None, secretsManagerClient=None):
    secret_name = getenv("SECRET_NAME")
    secrets_manager_client = secretsManagerClient or boto3.client('secretsmanager')
    
    secret = secrets_manager_client.get_secret_value(
        SecretId=secret_name,
    )
    
    webhook_url = secret['SecretString']

    message = format_message(event)

    message_headers = {'Content-Type': 'application/json; charset=UTF-8'}
    
    http = urllib3.PoolManager()

    http.request(
        'POST',
        webhook_url,
        body=dumps(message),
        headers=message_headers
    )

    logger.info("Alert sent successfully")

if __name__ == '__main__':
    lambda_handler('event', 'lambda_context')
