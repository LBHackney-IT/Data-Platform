from unittest import TestCase

from botocore import stub
from botocore.stub import Stubber

import install_kafka_connectors

configurationInput = {
    "cluster_config": {"value": {
        "bootstrap_brokers": "",
        "bootstrap_brokers_tls": "b-1.joates-event-streaming.j2065l.c4.kafka.eu-west-2.amazonaws.com:9094,b-2.joates-event-streaming.j2065l.c4.kafka.eu-west-2.amazonaws.com:9094,b-3.joates-event-streaming.j2065l.c4.kafka.eu-west-2.amazonaws.com:9094",
        "vpc_security_groups": [
            "sg-00dbd0a9b77dc5aa6"
        ],
        "vpc_subnets": [
            "subnet-03982d71297d968ca",
            "subnet-09de42c945f5507df",
            "subnet-0c1bd8eaff9d7fd96",
        ],
        "zookeeper_connect_string": "z-1.joates-event-streaming.j2065l.c4.kafka.eu-west-2.amazonaws.com:2181,z-2.joates-event-streaming.j2065l.c4.kafka.eu-west-2.amazonaws.com:2181,z-3.joates-event-streaming.j2065l.c4.kafka.eu-west-2.amazonaws.com:2181"
    }},
    "default_s3_plugin_configuration": {"value": {
        "capacity": {
            "auto_scaling": {
                "maxWorkerCount": 3,
                "mcuCount": 1,
                "minWorkerCount": 1,
                "scaleInPolicy": {
                    "cpuUtilizationPercentage": 20
                },
                "scaleOutPolicy": {
                    "cpuUtilizationPercentage": 80
                }
            }
        },
        "connect_version": "2.7.1",
        "connector_configuration": {
            "connector.class": "io.confluent.connect.s3.S3SinkConnector",
            "errors.log.enable": "True",
            "flush.size": "1",
            "format.class": "io.confluent.connect.s3.format.parquet.ParquetFormat",
            "key.converter": "org.apache.kafka.connect.storage.StringConverter",
            "key.converter.schemas.enable": "False",
            "partitioner.class": "io.confluent.connect.storage.partitioner.DefaultPartitioner",
            "s3.bucket.name": "dataplatform-joates-raw-zone",
            "s3.region": "eu-west-2",
            "s3.sse.kms.key.id": "8c5aa61d-8dab-4127-9190-5dfabc20d84c",
            "schema.compatibility": "BACKWARD",
            "storage.class": "io.confluent.connect.s3.storage.S3Storage",
            "tasks.max": "2",
            "topics": "tenure_api",
            "value.converter": "io.confluent.connect.avro.AvroConverter",
            "value.converter.schema.registry.url": "http://internal-joates-schema-registry-alb-1831198015.eu-west-2.elb.amazonaws.com:8081",
            "value.converter.schemas.enable": "True",
        },
        "connector_log_delivery_config": {
            "log_group": "joates-kafka-connector",
            "log_group_enabled": True,
        },
        "connector_s3_plugin": {
            "bucket_arn": "arn:aws:s3:::dataplatform-joates-kafka-dependency-storage",
            "file_key": "plugins/confluentinc-kafka-connect-s3-10.0.5-merged.zip",
            "name": "joates-confluentinc-kafka-connect-s3-10-0-5-merged"
        },
        "service_execution_role_arn": "arn:aws:iam::484466746276:role/joates-kafka-connector"
    }},
    "tenure_connector_name": {"value": "tenure-api"}
}

example_plugin = install_kafka_connectors.PluginDetails(
    name="joates-confluentinc-kafka-connect-s3-10-0-5-merged",
    state="ACTIVE",
    arn="arn:aws:kafkaconnect:eu-west-2:484466746276:custom-plugin/joates-confluentinc-kafka-connect-s3-10-0-5-merged/440682f3-a01b-4992-ba50-9a2868a40cc5-4",
    revision=1
)


class InstallKafkaConnectorTest(TestCase):
    def setUp(self) -> None:
        self.s3 = install_kafka_connectors.get_s3_client()
        self.s3Stub = Stubber(self.s3)
        return super().setUp()

    def test_get_plugin_if_exists(self):
        self.s3Stub.add_response('list_custom_plugins',
                                 {
                                     "customPlugins": [
                                         {
                                             "name": "breycarr-confluentinc-kafka-connect-s3-10-0-5-merged",
                                             "customPluginState": "ACTIVE",
                                             "customPluginArn": 'arn:aws:kafkaconnect:eu-west-2:484466746276:custom-plugin/breycarr-confluentinc-kafka-connect-s3-10-0-5-merged/2d6ef7fc-0add-4bfe-a604-241287eaca9b-4',
                                             "latestRevision": {
                                                 "revision": 1
                                             }
                                         },
                                         {
                                             "name": 'joates-confluentinc-kafka-connect-s3-10-0-5-merged',
                                             "customPluginState": 'ACTIVE',
                                             "customPluginArn": 'arn:aws:kafkaconnect:eu-west-2:484466746276:custom-plugin/joates-confluentinc-kafka-connect-s3-10-0-5-merged/440682f3-a01b-4992-ba50-9a2868a40cc5-4',
                                             "latestRevision": {
                                                 "revision": 1
                                             }
                                         },
                                     ]
                                 },
                                 {
                                     "maxResults": 100
                                 })
        result = self.get_plugin_if_exists("joates-confluentinc-kafka-connect-s3-10-0-5-merged")
        self.assertEqual(result.name, example_plugin.name)
        self.assertEqual(result.state, example_plugin.state)
        self.assertEqual(result.arn, example_plugin.arn)
        self.assertEqual(result.revision, example_plugin.revision)

    def get_plugin_if_exists(self, *args):
        self.s3Stub.activate()
        return install_kafka_connectors.get_plugin_if_exists(self.s3, *args)

    def test_connector_config_from_input_config(self):
        result = install_kafka_connectors.connector_config_from_input_config(configurationInput, example_plugin)
        self.assertEqual(result.name, "tenure-api")
        self.assertEqual(result.description, "Kafka connector to write tenure API changes to S3")
        # self.assertEqual(result.configuration, "")
        self.assertEqual(result.cluster_config.bootstrap_servers,
                         "b-1.joates-event-streaming.j2065l.c4.kafka.eu-west-2.amazonaws.com:9094,b-2.joates-event-streaming.j2065l.c4.kafka.eu-west-2.amazonaws.com:9094,b-3.joates-event-streaming.j2065l.c4.kafka.eu-west-2.amazonaws.com:9094")
        self.assertEqual(result.cluster_config.vpc_security_groups, ["sg-00dbd0a9b77dc5aa6"])
        self.assertEqual(result.cluster_config.vpc_subnets,
                         ["subnet-03982d71297d968ca", "subnet-09de42c945f5507df", "subnet-0c1bd8eaff9d7fd96"])
        self.assertEqual(result.kafka_connect_version, "2.7.1")
        self.assertEqual(result.log_delivery.log_group, "joates-kafka-connector")
        self.assertEqual(result.log_delivery.log_group_enabled, True)
        self.assertEqual(result.service_execution_role_arn, "arn:aws:iam::484466746276:role/joates-kafka-connector")
        self.assertEqual(result.plugin, example_plugin)
        self.assertEqual(result.capacity.auto_scaling, {'maxWorkerCount': 3,
                                                        'mcuCount': 1,
                                                        'minWorkerCount': 1,
                                                        'scaleInPolicy': {'cpuUtilizationPercentage': 20},
                                                        'scaleOutPolicy': {'cpuUtilizationPercentage': 80}})
        self.assertEqual(result.capacity.provisioned_capacity, None)
        self.assertEqual(result.worker_configuration, None)

    def setup_unsuccessful_get_connector(self):
        self.s3Stub.add_response('list_connectors',
                                 {
                                     "connectors": []
                                 },
                                 {
                                     "connectorNamePrefix": "tenure-api",
                                     "maxResults": 100,
                                 })

    def setup_successful_get_connector(
            self,
            connector_name="tenure-api",
            connector_arn="arn:aws:kafkaconnect:eu-west-2:484466746276:connector/tenure-api/0d5b9cd7-6e4a-4195-8558-de9e0ff98e7f-4",
            connector_description="Kafka connector to write tenure API changes to S3",
            kafka_connect_version="2.7.1",
            connector_configuration=None,
            capacity_auto_scaling=None,
            capacity_provisioned_capacity=None,
    ):
        if connector_configuration is None:
            connector_configuration = configurationInput['default_s3_plugin_configuration']['value'][
                'connector_configuration']
        if capacity_auto_scaling is None:
            capacity_auto_scaling = configurationInput['default_s3_plugin_configuration']['value']['capacity'][
                'auto_scaling']
        self.s3Stub.add_response('list_connectors',
                                 {
                                     "connectors": [
                                         {
                                             "connectorName": connector_name,
                                             "connectorArn": connector_arn
                                         }
                                     ]
                                 },
                                 {
                                     "connectorNamePrefix": connector_name,
                                     "maxResults": 100,
                                 })

        self.s3Stub.add_response('describe_connector',
                                 {
                                     "connectorName": connector_name,
                                     "connectorArn": connector_arn,
                                     "connectorDescription": connector_description,
                                     "currentVersion": "4",
                                     "kafkaConnectVersion": kafka_connect_version,
                                     "connectorConfiguration": connector_configuration,
                                     "capacity": {
                                         "autoScaling": capacity_auto_scaling,
                                     }
                                 },
                                 {
                                     "connectorArn": connector_arn,
                                 })

    def test_get_connector(self):
        self.setup_unsuccessful_get_connector()
        result = self.get_connector("tenure-api")
        self.assertEqual(result, False)

        self.setup_successful_get_connector()
        result = self.get_connector("tenure-api")
        self.assertEqual(result["connectorName"], "tenure-api")
        self.assertEqual(result["connectorArn"],
                         "arn:aws:kafkaconnect:eu-west-2:484466746276:connector/tenure-api/0d5b9cd7-6e4a-4195-8558-de9e0ff98e7f-4")

    def get_connector(self, *args):
        self.s3Stub.activate()
        return install_kafka_connectors.get_connector(self.s3, *args)

    def test_check_connector_exists_with_config(self):
        config = install_kafka_connectors.connector_config_from_input_config(configurationInput, example_plugin)

        self.setup_unsuccessful_get_connector()
        result = self.check_connector_exists_with_config(config)
        self.assertEqual(result["action"], "CREATE")

        self.setup_successful_get_connector()
        result = self.check_connector_exists_with_config(config)
        self.assertEqual(result["action"], "NONE")

        self.setup_successful_get_connector(
            connector_description="Something Else"
        )
        result = self.check_connector_exists_with_config(config)
        self.assertEqual(result["action"], "RECREATE")
        self.assertEqual(result["arn"],
                         "arn:aws:kafkaconnect:eu-west-2:484466746276:connector/tenure-api/0d5b9cd7-6e4a-4195-8558-de9e0ff98e7f-4")
        self.assertEqual(result["version"], "4")

        self.setup_successful_get_connector(
            kafka_connect_version="2.7.3"
        )
        result = self.check_connector_exists_with_config(config)
        self.assertEqual(result["action"], "RECREATE")
        self.assertEqual(result["arn"],
                         "arn:aws:kafkaconnect:eu-west-2:484466746276:connector/tenure-api/0d5b9cd7-6e4a-4195-8558-de9e0ff98e7f-4")
        self.assertEqual(result["version"], "4")

        self.setup_successful_get_connector(
            connector_configuration={
            }
        )
        result = self.check_connector_exists_with_config(config)
        self.assertEqual(result["action"], "RECREATE")
        self.assertEqual(result["arn"],
                         "arn:aws:kafkaconnect:eu-west-2:484466746276:connector/tenure-api/0d5b9cd7-6e4a-4195-8558-de9e0ff98e7f-4")
        self.assertEqual(result["version"], "4")

        self.setup_successful_get_connector(
            capacity_auto_scaling={}
        )
        result = self.check_connector_exists_with_config(config)
        self.assertEqual(result["action"], "UPDATE")
        self.assertEqual(result["arn"],
                         "arn:aws:kafkaconnect:eu-west-2:484466746276:connector/tenure-api/0d5b9cd7-6e4a-4195-8558-de9e0ff98e7f-4")
        self.assertEqual(result["version"], "4")

    def check_connector_exists_with_config(self, *args):
        self.s3Stub.activate()
        return install_kafka_connectors.check_connector_exists_with_config(self.s3, *args)

    def test_create_connector(self):
        config = install_kafka_connectors.connector_config_from_input_config(configurationInput, example_plugin)
        self.s3Stub.add_response('create_connector',
                                 {
                                     "connectorArn": "arn:aws:kafkaconnect:eu-west-2:484466746276:connector/tenure-api/dcec484e-8cf2-4118-9432-df85ebe0e165-4",
                                     "connectorName": "tenure-api",
                                     "connectorState": "CREATING"
                                 },
                                 {
                                     "capacity": stub.ANY,
                                     "connectorConfiguration": stub.ANY,
                                     "connectorName": stub.ANY,
                                     "connectorDescription": stub.ANY,
                                     "kafkaCluster": stub.ANY,
                                     "kafkaClusterClientAuthentication": stub.ANY,
                                     "kafkaClusterEncryptionInTransit": stub.ANY,
                                     "kafkaConnectVersion": stub.ANY,
                                     "logDelivery": stub.ANY,
                                     "plugins": stub.ANY,
                                     "serviceExecutionRoleArn": stub.ANY
                                 })
        result = self.create_connector(config)

        self.assertEqual(result.name, "tenure-api")
        self.assertEqual(result.arn,
                         "arn:aws:kafkaconnect:eu-west-2:484466746276:connector/tenure-api/dcec484e-8cf2-4118-9432-df85ebe0e165-4")
        self.assertEqual(result.state, "CREATING")

    def create_connector(self, *args):
        self.s3Stub.activate()
        return install_kafka_connectors.create_connector(self.s3, *args)

    def test_get_capacity_request(self):
        config = install_kafka_connectors.connector_config_from_input_config(configurationInput, example_plugin)
        capacity = self.get_capacity_request(config)
        self.assertEqual(capacity['autoScaling'], {
            'maxWorkerCount': 3,
            'mcuCount': 1,
            'minWorkerCount': 1,
            'scaleInPolicy': {'cpuUtilizationPercentage': 20},
            'scaleOutPolicy': {'cpuUtilizationPercentage': 80}
        })
        self.assertNotIn('provisionedCapacity', capacity)

    def get_capacity_request(self, *args):
        return install_kafka_connectors.get_capacity_request(*args)

    def test_update_connector(self):
        config = install_kafka_connectors.connector_config_from_input_config(configurationInput, example_plugin)
        config.capacity.auto_scaling['maxWorkerCount'] = 5
        connector_arn = "arn:aws:kafkaconnect:eu-west-2:484466746276:connector/tenure-api/6004d2e0-ff6d-4d0a-8c88-a94b86435167-4"
        connector_version = "C3JWKAKR8XB7XF"
        self.s3Stub.add_response('update_connector',
                                 {
                                     'connectorArn': 'arn:aws:kafkaconnect:eu-west-2:484466746276:connector/tenure-api/6004d2e0-ff6d-4d0a-8c88-a94b86435167-4',
                                     'connectorState': 'UPDATING'
                                 },
                                 {
                                     "capacity": self.get_capacity_request(config),
                                     "connectorArn": connector_arn,
                                     "currentVersion": connector_version
                                 })
        result = self.update_connector(
            connector_arn,
            connector_version,
            config
        )
        self.assertIn('connectorArn', result)
        self.assertEqual(result['connectorArn'], connector_arn)
        self.assertIn('connectorState', result)
        self.assertEqual(result['connectorState'], 'UPDATING')

    def update_connector(self, *args):
        self.s3Stub.activate()
        return install_kafka_connectors.update_connector(self.s3, *args)

    def test_delete_connector(self):
        connector_arn = "arn:aws:kafkaconnect:eu-west-2:484466746276:connector/tenure-api/6004d2e0-ff6d-4d0a-8c88-a94b86435167-4"
        connector_version = "C3DWYIK6Y9EEQB"
        self.s3Stub.add_response('delete_connector',
                                 {
                                     'connectorArn': connector_arn,
                                     'connectorState': 'DELETING'
                                 },
                                 {
                                     "connectorArn": connector_arn,
                                     "currentVersion": connector_version
                                 })
        self.s3Stub.add_response('describe_connector',
                                 {
                                     "connectorState": "DELETING",
                                 },
                                 {
                                     "connectorArn": connector_arn,
                                 })
        self.s3Stub.add_response('describe_connector',
                                 {
                                     "connectorState": "DELETED",
                                 },
                                 {
                                     "connectorArn": connector_arn,
                                 })
        self.delete_connector(connector_arn, connector_version)

    def delete_connector(self, *args):
        self.s3Stub.activate()
        return install_kafka_connectors.delete_connector(self.s3, *args)

    # def test_end_to_end(self):
    #     install_kafka_connectors.entry_point(configurationInput)
