import sys
from dotenv import load_dotenv
from os import getenv
from kafka import KafkaProducer
from kafka import KafkaConsumer

sys.path.append('./lib/')


def lambda_handler(event, lambda_context):
    load_dotenv()
    kafka_brokers = getenv("TARGET_KAFKA_BROKERS")
    kafka_topic = getenv("TARGET_KAFKA_TOPIC")
    operation = event['operation']

    if operation == "list-all-topics":
        # List all available topics in the cluster
        list_topics(kafka_brokers)

    if operation == "send-message-to-topic":
        # Send message to the configured topic
        message = event['message']
        send_msg_async(kafka_brokers, kafka_topic, message)


def list_topics(kafka_brokers):
    print("Listing Topics")
    consumer = KafkaConsumer(bootstrap_servers=kafka_brokers, security_protocol='SSL')
    print(consumer.topics())


def send_msg_async(kafka_brokers, kafka_topic, message):
    print("Sending message")

    producer = KafkaProducer(bootstrap_servers=kafka_brokers, security_protocol='SSL')

    producer.send(kafka_topic, bytes(message, 'utf-8'))
    producer.flush()
