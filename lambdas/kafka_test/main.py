import sys
from dotenv import load_dotenv
from os import getenv
from kafka import KafkaProducer
from kafka import KafkaConsumer

sys.path.append('./lib/')


def lambda_handler(event, lambda_context):
    load_dotenv()
    kafka_brokers = getenv("TARGET_KAFKA_BROKERS")
    operation = event['operation']
    print(f'Operation: {operation}')

    if operation == "list-all-topics":
        list_topics(kafka_brokers)

    if operation == "send-message-to-topic":
        message = event['message']
        kafka_topic = event['topic']
        send_msg_async(kafka_brokers, kafka_topic, message)


def list_topics(kafka_brokers):
    print('Listing all available topics in the cluster')
    consumer = KafkaConsumer(bootstrap_servers=kafka_brokers, security_protocol='SSL')
    print(consumer.topics())


def send_msg_async(kafka_brokers, kafka_topic, message):
    print(f'Sending message to the {kafka_topic}')

    producer = KafkaProducer(bootstrap_servers=kafka_brokers, security_protocol='SSL')

    producer.send(kafka_topic, bytes(message, 'utf-8'))
    producer.flush()
