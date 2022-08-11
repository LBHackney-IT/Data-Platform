import sys

sys.path.append('./lib/')

from dotenv import load_dotenv
from os import getenv
from kafka import KafkaProducer
from kafka import KafkaConsumer
from confluent_kafka.admin import AdminClient


def lambda_handler(event, lambda_context):
    load_dotenv()
    kafka_brokers = getenv("TARGET_KAFKA_BROKERS")
    operation = event['operation']
    print(f'Operation: {operation}')

    if operation == "list-all-topics":
        list_topics_confluent(kafka_brokers)

    if operation == "send-message-to-topic":
        message = event['message']
        kafka_topic = event['topic']
        send_msg_async(kafka_brokers, kafka_topic, message)


def list_topics_confluent(kafka_brokers):
    print('Listing all available topics in the cluster:')
    admin = AdminClient({
        'bootstrap.servers': kafka_brokers,
        'security.protocol': 'ssl'
    })
    for topic in admin.list_topics().topics:
        print(topic)


def send_msg_async(kafka_brokers, kafka_topic, message,):
    print(f'Sending message to the {kafka_topic}')
