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

    # List all available topics in the cluster
    list_topics(kafka_brokers, kafka_topic)

    # Send message to the configured topic
    send_msg_async(kafka_brokers, kafka_topic)


def list_topics(kafka_brokers, kafka_topic):
    print("Sending message")
    ca_root_location = 'CARoot.pem'
    cert_location = 'certificate.pem'
    key_location = 'key.pem'
    password = 'welcome123'

    consumer = KafkaConsumer(bootstrap_servers=kafka_brokers,
                             security_protocol='SSL',
                             ssl_check_hostname=True,
                             ssl_cafile=ca_root_location,
                             ssl_certfile=cert_location,
                             ssl_keyfile=key_location,
                             ssl_password=password)
    print(consumer.topics())


def send_msg_async(kafka_brokers, kafka_topic):
    print("Sending message")
    ca_root_location = 'CARoot.pem'
    cert_location = 'certificate.pem'
    key_location = 'key.pem'
    password = 'welcome123'

    producer = KafkaProducer(bootstrap_servers=kafka_brokers,
                             security_protocol='SSL',
                             ssl_check_hostname=True,
                             ssl_cafile=ca_root_location,
                             ssl_certfile=cert_location,
                             ssl_keyfile=key_location,
                             ssl_password=password)

    producer.send(kafka_topic, bytes('Hello Kafka!', 'utf-8'))
    producer.flush()
