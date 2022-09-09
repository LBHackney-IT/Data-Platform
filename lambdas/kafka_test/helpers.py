import urllib.request
import json

def load_latest_value_schema_for_topic_from_schema_registry(kafka_topic, schema_registry_url):
    uri_for_latest_schema = f"{schema_registry_url}/subjects/{kafka_topic}-value/versions/latest"

    print(f"loading schema from: {uri_for_latest_schema}")

    try:
        response = urllib.request.urlopen(urllib.request.Request(
                url=uri_for_latest_schema,
                headers={'Accept': 'application/json'},
                method='GET'),
                timeout=5)

        value_schema_details = json.load(response)

        value_schema = value_schema_details["schema"]
        
        return value_schema
    except Exception as e:
        print(f"Unable to load latest schema for {kafka_topic}")
        raise e

def check_schema_registry_connection(schema_registry_url):
    
    try:
        response = urllib.request.urlopen(urllib.request.Request(
                url=schema_registry_url,
                headers={'Accept': 'application/json'},
                method='GET'),
                timeout=5)

        print(f'Response: {response.status}')

    except Exception as e:
        print(f"Unable to connect to schema registry {e}")
        raise e

def delivery_report(err, msg):
    """ Called once for each message produced to indicate delivery result.
        Triggered by poll() or flush(). """
    if err is not None:
        print('Message delivery failed: {}'.format(err))
    else:
        print('Message delivered to {} [{}]'.format(msg.topic(), msg.partition()))

def get_json_test_message_for_topic_from_a_file(kafka_topic):
    print(f"Loading test message for {kafka_topic}")
    
    try:
        with open("./topic-messages/" + kafka_topic + ".json") as json_file: 
            return json.loads(json_file.read())
    except Exception as e:
        print(f"Unable to load test message for {kafka_topic}")
        raise e