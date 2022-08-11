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
    kafka_version = getenv("TARGET_KAFKA_VERSION")
    operation = event['operation']
    print(f'Operation: {operation}')
    print(f'Kafka Version: {kafka_version}')
    kafka_version_split = kafka_version.split('.')

    if operation == "list-all-topics":
        # list_topics(kafka_brokers, kafka_version_split)
        list_topics_confluent(kafka_brokers)

    if operation == "send-message-to-topic":
        message = event['message']
        kafka_topic = event['topic']
        send_msg_async(kafka_brokers, kafka_topic, message, kafka_version_split)


def list_topics(kafka_brokers, kafka_version_split):
    print('Listing all available topics in the cluster')
    consumer = KafkaConsumer(bootstrap_servers=kafka_brokers,
                             security_protocol='SSL',
                             group_id='kafka-test',
                             client_id='kafka-test',
                             api_version=(int(kafka_version_split[0]),
                                          int(kafka_version_split[1]),
                                          int(kafka_version_split[2])))
    print(consumer.topics())


def list_topics_confluent(kafka_brokers):
    print('Listing all available topics in the cluster')
    admin = AdminClient({
        'bootstrap.servers': kafka_brokers,
        'security.protocol': 'ssl'
    })
    print(admin.list_topics())


def send_msg_async(kafka_brokers, kafka_topic, message, kafka_version_split):
    print(f'Sending message to the {kafka_topic}')

    producer = KafkaProducer(bootstrap_servers=kafka_brokers,
                             security_protocol='SSL',
                             group_id='kafka-test',
                             client_id='kafka-test',
                             api_version=(int(kafka_version_split[0]),
                                          int(kafka_version_split[1]),
                                          int(kafka_version_split[2])))

    producer.send(kafka_topic, bytes(message, 'utf-8'))
    producer.flush()
