import sys
import uuid
import json

sys.path.append('./lib/')
sys.path.append('./topic-messages/')

from dotenv import load_dotenv
from os import getenv
from confluent_kafka import avro
from confluent_kafka.admin import AdminClient
from confluent_kafka.avro import AvroProducer


def lambda_handler(event, lambda_context):
    load_dotenv()
    kafka_brokers = getenv("TARGET_KAFKA_BROKERS")
    schema_registry_url = getenv("SCHEMA_REGISTRY_URL")
    operation = event['operation']
    print(f'Operation: {operation}')

    if operation == "list-all-topics":
        list_all_topics(kafka_brokers)

    if operation == "send-message-to-topic":
        kafka_topic = event['topic']
        kafka_schema_file_name = event['kafka_schema_file_name']
        send_message_to_topic(kafka_brokers, schema_registry_url, kafka_topic, kafka_schema_file_name)


def list_all_topics(kafka_brokers):
    print('Listing all available topics in the cluster:')
    admin = AdminClient({
        'bootstrap.servers': kafka_brokers,
        'security.protocol': 'ssl',
        'group.id': 'kafka-test',
        'client.id': 'kafka-test'
    })
    for topic in admin.list_topics().topics:
        print(topic)


def send_message_to_topic(kafka_brokers, schema_registry_url, kafka_topic, kafka_schema_file_name):
    print(f'Sending message to the {kafka_topic}')

    key_schema, value_schema = load_schema_from_file(kafka_schema_file_name)

    producer_config = {
        'bootstrap.servers': kafka_brokers,
        'security.protocol': 'ssl',
        'schema.registry.url': schema_registry_url,
        'client.id': 'kafka-test'

    }

    producer = AvroProducer(producer_config, default_key_schema=key_schema, default_value_schema=value_schema)

    key = "kakfa-test" + str(uuid.uuid4())
    with open("./topic-messages/" + kafka_schema_file_name) as json_file:
        value = json.loads(json_file.read())

    try:
        producer.produce(topic=kafka_topic, key=key, value=value)
    except Exception as e:
        print(f"Exception while producing record value - {value} to topic - {kafka_topic}: {e}")
        producer.flush()
        raise e
    else:
        print(f"Successfully producing record value - {value} to topic - {kafka_topic}")
        producer.flush()


def load_schema_from_file(kafka_schema_file_name):
    key_schema_string = """
    {"type": "string"}
    """

    key_schema = avro.loads(key_schema_string)
    value_schema = avro.load("./lib/" + kafka_schema_file_name)

    return key_schema, value_schema
