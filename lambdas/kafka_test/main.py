import sys
import uuid
import json

sys.path.append('./lib/')
sys.path.append('./topic-messages/')

from dotenv import load_dotenv
from os import getenv
from confluent_kafka import avro
from confluent_kafka.admin import AdminClient
from confluent_kafka.avro import AvroProducer, AvroConsumer, SerializerError
from confluent_kafka.cimpl import NewTopic, KafkaException

BOOTSTRAP_SERVERS_KEY = "bootstrap.servers"
SECURITY_PROTOCOL_KEY = "security.protocol"
SECURITY_PROTOCOL_VALUE = "ssl"
SCHEMA_REGISTRY_URL_KEY = "schema.registry.url"
GROUP_ID_KEY = "group.id"
CLIENT_ID_KEY = "client.id"
CLIENT_ID_VALUE = "kafka-test"


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
        send_message_to_topic(kafka_brokers, schema_registry_url, kafka_topic)

    if operation == "read-message-from-topic":
        kafka_topic = event['topic']
        read_message_from_topic(kafka_brokers, schema_registry_url, kafka_topic)


def list_all_topics(kafka_brokers):
    print('Listing all available topics in the cluster:')
    admin = AdminClient({
        BOOTSTRAP_SERVERS_KEY: kafka_brokers,
        SECURITY_PROTOCOL_KEY: SECURITY_PROTOCOL_VALUE,
        CLIENT_ID_KEY: CLIENT_ID_VALUE
    })
    topics = admin.list_topics().topics
    for topic in topics:
        print(topic)
    return topics


def delivery_report(err, msg):
    """ Called once for each message produced to indicate delivery result.
        Triggered by poll() or flush(). """
    if err is not None:
        print('Message delivery failed: {}'.format(err))
    else:
        print('Message delivered to {} [{}]'.format(msg.topic(), msg.partition()))


def send_message_to_topic(kafka_brokers, schema_registry_url, kafka_topic):
    print(f'Sending message to the {kafka_topic}')

    key_schema, value_schema = load_schema_from_file(kafka_topic)

    topics = list_all_topics(kafka_brokers)
    if kafka_topic not in topics:
        create_topic(kafka_brokers, kafka_topic)

    producer_config = {
        BOOTSTRAP_SERVERS_KEY: kafka_brokers,
        SECURITY_PROTOCOL_KEY: SECURITY_PROTOCOL_VALUE,
        SCHEMA_REGISTRY_URL_KEY: schema_registry_url,
        CLIENT_ID_KEY: CLIENT_ID_VALUE,
        'on_delivery': delivery_report
    }

    producer = AvroProducer(producer_config, default_key_schema=key_schema, default_value_schema=value_schema)

    key = CLIENT_ID_VALUE + str(uuid.uuid4())
    with open("./topic-messages/" + kafka_topic + ".json") as json_file:
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


def load_schema_from_file(kafka_topic):
    key_schema_string = """
    {"type": "string"}
    """

    key_schema = avro.loads(key_schema_string)
    value_schema = avro.load("./lib/" + kafka_topic + ".json")

    return key_schema, value_schema


def create_topic(kafka_brokers, kafka_topic):
    print(f'{kafka_topic} topic does not exist. Creating..')
    admin = AdminClient({
        BOOTSTRAP_SERVERS_KEY: kafka_brokers,
        SECURITY_PROTOCOL_KEY: SECURITY_PROTOCOL_VALUE,
        CLIENT_ID_KEY: CLIENT_ID_VALUE
    })
    topic_list = [NewTopic(kafka_topic, 2, 1)]

    try:
        result = admin.create_topics(topic_list, operation_timeout=30)
        for _, f in result.items():
            try:
                f.result()
            except KafkaException as ex:
                print(f'  {ex.args[0]}')
    except Exception as e:
        print(f"Exception while creating topic - {kafka_topic}: {e}")
        raise e
    else:
        print(f"Successfully created topic - {kafka_topic}")


def read_message_from_topic(kafka_brokers, schema_registry_url, kafka_topic):
    print(f'Reading message from {kafka_topic} topic')

    consumer_config = {
        BOOTSTRAP_SERVERS_KEY: kafka_brokers,
        SECURITY_PROTOCOL_KEY: SECURITY_PROTOCOL_VALUE,
        SCHEMA_REGISTRY_URL_KEY: schema_registry_url,
        CLIENT_ID_KEY: CLIENT_ID_VALUE,
        GROUP_ID_KEY: CLIENT_ID_VALUE,
        'auto.offset.reset': 'earliest'
    }

    consumer = AvroConsumer(consumer_config)
    consumer.subscribe([kafka_topic])

    while True:
        try:
            message = consumer.poll(1.0)

        except SerializerError as e:
            print("Message deserialization failed for {}: {}".format(message, e))
            break

        if message is None:
            continue

        if message.error():
            print("AvroConsumer error: {}".format(message.error()))
            continue

        print('Received message: {}'.format(message.value().decode('utf-8')))

    consumer.close()
