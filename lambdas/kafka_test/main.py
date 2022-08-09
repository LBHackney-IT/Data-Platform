import sys

sys.path.append('./lib/')

from dotenv import load_dotenv
from os import getenv
from kafka import KafkaProducer
from kafka import KafkaConsumer


def lambda_handler(event, lambda_context):
    load_dotenv()
    kafka_brokers = getenv("TARGET_KAFKA_BROKERS")
    kafka_version = getenv("TARGET_KAFKA_VERSION")
    operation = event['operation']
    print(f'Operation: {operation}')
    print(f'Kafka Version: {kafka_version}')
    version_split = kafka_version.split('.')

    if operation == "list-all-topics":
        list_topics(kafka_brokers, version_split)

    if operation == "send-message-to-topic":
        message = event['message']
        kafka_topic = event['topic']
        send_msg_async(kafka_brokers, kafka_topic, message, version_split)


def list_topics(kafka_brokers, version_split):
    print('Listing all available topics in the cluster')
    consumer = KafkaConsumer(bootstrap_servers=kafka_brokers, api_version=(version_split[0], version_split[1], version_split[2]), security_protocol='SSL')
    print(consumer.topics())


def send_msg_async(kafka_brokers, kafka_topic, message, version_split):
    print(f'Sending message to the {kafka_topic}')

    producer = KafkaProducer(bootstrap_servers=kafka_brokers, api_version=(version_split[0], version_split[1], version_split[2]), security_protocol='SSL')

    producer.send(kafka_topic, bytes(message, 'utf-8'))
    producer.flush()
