import sys
import helpers

sys.path.append('./lib/')

from dotenv import load_dotenv
from os import getenv
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
AUTO_OFFSET_RESET_KEY = "auto.offset.reset"
AUTO_OFFSET_RESET_VALUE = "earliest"

def lambda_handler(event, lambda_context):
    load_dotenv()
    kafka_brokers = getenv("TARGET_KAFKA_BROKERS")
    schema_registry_url = getenv("SCHEMA_REGISTRY_URL")
    operation = event['operation']
    print(f'Operation: {operation}')

    if operation == "list-all-topics":
        list_all_topics(kafka_brokers)
    
    if operation == "create-topic":
        kafka_topic = event['topic']
        create_topic(kafka_brokers, kafka_topic)

    if operation == "send-message-to-topic-using-schema":
        kafka_topic = event['topic']
        send_message_to_topic_using_schema(kafka_brokers, kafka_topic, schema_registry_url)
    
    if operation == "read-message-from-topic-using-schema":
        kafka_topic = event['topic']
        read_message_from_topic_using_schema(kafka_brokers, kafka_topic, schema_registry_url)

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

def create_topic(kafka_brokers, kafka_topic):
    print(f"Creating topic: {kafka_topic}")

    admin = AdminClient({
        BOOTSTRAP_SERVERS_KEY: kafka_brokers,
        SECURITY_PROTOCOL_KEY: SECURITY_PROTOCOL_VALUE,
        CLIENT_ID_KEY: CLIENT_ID_VALUE
    })

    topic_list = [NewTopic(kafka_topic, num_partitions=1, replication_factor=2)] #set replication_factor to 2 on dev/test

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

def send_message_to_topic_using_schema(kafka_brokers, kafka_topic, schema_registry_url):

    value_schema = helpers.load_latest_value_schema_for_topic_from_schema_registry(kafka_topic, schema_registry_url)

    message = helpers.get_json_test_message_for_topic_from_a_file(kafka_topic)

    avro_producer = AvroProducer({
        BOOTSTRAP_SERVERS_KEY: kafka_brokers,
        'on_delivery': helpers.delivery_report,
        SCHEMA_REGISTRY_URL_KEY: schema_registry_url,
        SECURITY_PROTOCOL_KEY: SECURITY_PROTOCOL_VALUE,
        }, default_key_schema=None, default_value_schema=value_schema) 

    avro_producer.produce(topic=kafka_topic, value=message) 
    avro_producer.flush()

def read_message_from_topic_using_schema(kafka_brokers, kafka_topic, schema_registry_url):
    print(f'Reading message from {kafka_topic} topic')

    consumer_config = {
        BOOTSTRAP_SERVERS_KEY: kafka_brokers,
        SECURITY_PROTOCOL_KEY: SECURITY_PROTOCOL_VALUE,
        SCHEMA_REGISTRY_URL_KEY: schema_registry_url,
        CLIENT_ID_KEY: CLIENT_ID_VALUE,
        GROUP_ID_KEY: CLIENT_ID_VALUE,
        AUTO_OFFSET_RESET_KEY: AUTO_OFFSET_RESET_VALUE
    }
  
    value_schema = helpers.load_latest_value_schema_for_topic_from_schema_registry(kafka_topic, schema_registry_url)
    
    consumer = AvroConsumer(consumer_config, reader_value_schema=value_schema)
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

        print('Received message: {}'.format(message.value()))
    consumer.close()    
