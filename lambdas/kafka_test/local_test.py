import helpers
import sys

sys.path.append('./lib/')

from confluent_kafka import Consumer
from confluent_kafka.avro import AvroProducer, AvroConsumer, SerializerError
from confluent_kafka.admin import AdminClient
from confluent_kafka.cimpl import NewTopic
from confluent_kafka.cimpl import NewTopic, KafkaException

BOOTSTRAP_SERVERS_KEY = "bootstrap.servers"
SECURITY_PROTOCOL_KEY = "security.protocol"
SECURITY_PROTOCOL_VALUE = "plaintext" #must be set to plaintext locally, otherwise ssl
GROUP_ID_KEY = "group.id"
CLIENT_ID_VALUE = "kafka-local-test"
CLIENT_ID_KEY = "client.id"
AUTO_OFFSET_RESET_KEY = "auto.offset.reset"
AUTO_OFFSET_RESET_VALUE = "earliest"
SCHEMA_REGISTRY_URL_KEY = "schema.registry.url"

#broker config if using the provided Docker setup
kafka_brokers = "localhost:19093, localhost:19092"

#schema registry URL if using the provided Docker setup
schema_registry_url = "http://localhost:8081"

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

    topic_list = [NewTopic(kafka_topic, num_partitions=1, replication_factor=1)] #set replication_factor to 2 on dev/test

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

def list_consumer_groups(kafka_brokers):
    
    admin = AdminClient({
        BOOTSTRAP_SERVERS_KEY: kafka_brokers,
        SECURITY_PROTOCOL_KEY: SECURITY_PROTOCOL_VALUE
    })

    groups = admin.list_groups()

    for group in groups:
        print(group)

def get_consumer_group_details(kafka_brokers, group_name):
    
    admin = AdminClient({
        BOOTSTRAP_SERVERS_KEY: kafka_brokers,
        SECURITY_PROTOCOL_KEY: SECURITY_PROTOCOL_VALUE
    })

    groups = admin.list_groups(group=group_name,timeout=10)

    for group in groups:
        print(group)

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

def read_message_from_topic_using_schema(kafka_brokers, kafka_topic):
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
  
#####################
# for local testing #
#####################
#Send message to contact details topic
#send_message_to_topic_using_schema(kafka_brokers, "contact_details_api", schema_registry_url)

#Read message from contact details api topic
#read_message_from_topic_using_schema(kafka_brokers, "contact_details_api")

#Send message to tenure topic
#send_message_to_topic_using_schema(kafka_brokers, "tenure_api", schema_registry_url)

#Read message from tenure topic
#read_message_from_topic_using_schema(kafka_brokers, "tenure_api")
