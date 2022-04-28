from unittest import TestCase

from botocore import stub
from botocore.stub import Stubber

import install_kafka_connectors

configurationInput = {
    "cluster_config": {
        "value": {
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
        }
    },
    "default_s3_plugin_configuration": {
        "value": {
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
        }
    },
    "tenure_connector_name": {"value": "tenure-api"}
}

example_plugin = install_kafka_connectors.PluginDetails(
    name="joates-confluentinc-kafka-connect-s3-10-0-5-merged",
    state="ACTIVE",
    arn="arn:aws:kafkaconnect:eu-west-2:484466746276:custom-plugin/joates-confluentinc-kafka-connect-s3-10-0-5-merged/440682f3-a01b-4992-ba50-9a2868a40cc5-4",
    revision=1
)

expected_create_connector_request = {
    "capacity": {
        "autoScaling": {
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
    "connectorConfiguration": configurationInput["default_s3_plugin_configuration"]["value"]["connector_configuration"],
    "connectorName": "tenure-api",
    "connectorDescription": "Kafka connector to write tenure-api changes to S3",
    "kafkaCluster": {
        'apacheKafkaCluster': {
            'bootstrapServers': "b-1.joates-event-streaming.j2065l.c4.kafka.eu-west-2.amazonaws.com:9094,b-2.joates-event-streaming.j2065l.c4.kafka.eu-west-2.amazonaws.com:9094,b-3.joates-event-streaming.j2065l.c4.kafka.eu-west-2.amazonaws.com:9094",
            'vpc': {
                'securityGroups': [
                    "sg-00dbd0a9b77dc5aa6"
                ],
                'subnets': [
                    "subnet-03982d71297d968ca",
                    "subnet-09de42c945f5507df",
                    "subnet-0c1bd8eaff9d7fd96",
                ]
            }
        }
    },
    "kafkaClusterClientAuthentication": {
        "authenticationType": "NONE"
    },
    "kafkaClusterEncryptionInTransit": {
        "encryptionType": "TLS"
    },
    "kafkaConnectVersion": "2.7.1",
    "logDelivery": {
        "workerLogDelivery": {
            "cloudWatchLogs": {
                "enabled": True,
                "logGroup": "joates-kafka-connector"
            }
        }
    },
    "plugins": [
        {
            "customPlugin": {
                "customPluginArn": "arn:aws:kafkaconnect:eu-west-2:484466746276:custom-plugin/joates-confluentinc-kafka-connect-s3-10-0-5-merged/440682f3-a01b-4992-ba50-9a2868a40cc5-4",
                "revision": 1
            }
        },
    ],
    "serviceExecutionRoleArn": "arn:aws:iam::484466746276:role/joates-kafka-connector"
}

class InstallKafkaConnectorTest(TestCase):
    def setUp(self) -> None:
        self.kafka = install_kafka_connectors.get_kafka_client()
        self.kafkaStub = Stubber(self.kafka)
        return super().setUp()
    
    def stub_list_plugins(self, plugins_list = None):
        if plugins_list == None:
            plugins_list = [
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
        self.kafkaStub.add_response('list_custom_plugins', { "customPlugins": plugins_list }, { "maxResults": 100 })

    def test_get_plugin_if_exists(self):
        self.stub_list_plugins()
        result = self.get_plugin_if_exists("joates-confluentinc-kafka-connect-s3-10-0-5-merged")
        self.assertEqual(result.name, example_plugin.name)
        self.assertEqual(result.state, example_plugin.state)
        self.assertEqual(result.arn, example_plugin.arn)
        self.assertEqual(result.revision, example_plugin.revision)

    def get_plugin_if_exists(self, *args):
        self.kafkaStub.activate()
        return install_kafka_connectors.get_plugin_if_exists(self.kafka, *args)

    def test_connector_config_from_input_config(self):
        result = install_kafka_connectors.connector_config_from_input_config(configurationInput, example_plugin)
        self.assertEqual(result.name, "tenure-api")
        self.assertEqual(result.description, "Kafka connector to write tenure-api changes to S3")
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
        self.kafkaStub.add_response('list_connectors',
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
            connector_description="Kafka connector to write tenure-api changes to S3",
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
        self.kafkaStub.add_response('list_connectors',
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
        describe_response = {
            "connectorName": connector_name,
            "connectorArn": connector_arn,
            "currentVersion": "4",
            "kafkaConnectVersion": kafka_connect_version,
            "connectorConfiguration": connector_configuration,
            "capacity": {
                "autoScaling": capacity_auto_scaling,
            }
        }
        if connector_description:
            describe_response["connectorDescription"] = connector_description
        self.kafkaStub.add_response('describe_connector', describe_response,
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
        self.kafkaStub.activate()
        return install_kafka_connectors.get_connector(self.kafka, *args)

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
            connector_description=None
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
        self.kafkaStub.activate()
        return install_kafka_connectors.check_connector_exists_with_config(self.kafka, *args)

    def stub_create_connector(self, expected_request_object=None):
        if not expected_request_object:
            expected_request_object = {
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
            }
        self.kafkaStub.add_response('create_connector',
            {
                "connectorArn": "arn:aws:kafkaconnect:eu-west-2:484466746276:connector/tenure-api/dcec484e-8cf2-4118-9432-df85ebe0e165-4",
                "connectorName": "tenure-api",
                "connectorState": "CREATING"
            },
            expected_request_object
        )

    def test_create_connector(self):
        config = install_kafka_connectors.connector_config_from_input_config(configurationInput, example_plugin)
        self.stub_create_connector()
        result = self.create_connector(config)

        self.assertEqual(result.name, "tenure-api")
        self.assertEqual(result.arn,
                         "arn:aws:kafkaconnect:eu-west-2:484466746276:connector/tenure-api/dcec484e-8cf2-4118-9432-df85ebe0e165-4")
        self.assertEqual(result.state, "CREATING")

    def create_connector(self, *args):
        self.kafkaStub.activate()
        return install_kafka_connectors.create_connector(self.kafka, *args)

    def test_get_capacity_request(self):
        config = install_kafka_connectors.connector_config_from_input_config(configurationInput, example_plugin)
        capacity = self.get_capacity_request(config.capacity)
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
        updated_capacity_config = {
            'autoScaling': {
                'maxWorkerCount': 5,
                'mcuCount': 1,
                'minWorkerCount': 1,
                'scaleInPolicy': {'cpuUtilizationPercentage': 20},
                'scaleOutPolicy': {'cpuUtilizationPercentage': 80}
            }
        }
        connector_arn = "arn:aws:kafkaconnect:eu-west-2:484466746276:connector/tenure-api/6004d2e0-ff6d-4d0a-8c88-a94b86435167-4"
        connector_version = "C3JWKAKR8XB7XF"
        self.kafkaStub.add_response('update_connector',
                                 {
                                     'connectorArn': 'arn:aws:kafkaconnect:eu-west-2:484466746276:connector/tenure-api/6004d2e0-ff6d-4d0a-8c88-a94b86435167-4',
                                     'connectorState': 'UPDATING'
                                 },
                                 {
                                     "capacity": updated_capacity_config,
                                     "connectorArn": connector_arn,
                                     "currentVersion": connector_version
                                 })
        result = self.update_connector(
            connector_arn,
            connector_version,
            install_kafka_connectors.ConnectorCapacity(
                auto_scaling=updated_capacity_config["autoScaling"]
            )
        )
        self.assertEqual(result.arn, connector_arn)
        self.assertEqual(result.state, 'UPDATING')

    def update_connector(self, *args):
        self.kafkaStub.activate()
        return install_kafka_connectors.update_connector_capacity(self.kafka, *args)

    def stub_deleting_connector(self, connector_arn, connector_version):
        self.kafkaStub.add_response('delete_connector',
            {
                'connectorArn': connector_arn,
                'connectorState': 'DELETING'
            },
            {
                "connectorArn": connector_arn,
                "currentVersion": connector_version
            })
        self.kafkaStub.add_response('describe_connector',
            {
                "connectorState": "DELETING",
            },
            {
                "connectorArn": connector_arn,
            })
        self.kafkaStub.add_response('describe_connector',
            {
                "connectorState": "DELETED",
            },
            {
                "connectorArn": connector_arn,
            })

    def test_delete_connector(self):
        connector_arn = "arn:aws:kafkaconnect:eu-west-2:484466746276:connector/tenure-api/6004d2e0-ff6d-4d0a-8c88-a94b86435167-4"
        connector_version = "C3DWYIK6Y9EEQB"
        self.stub_deleting_connector(connector_arn, connector_version)
        self.delete_connector(connector_arn, connector_version)
        self.kafkaStub.assert_no_pending_responses()

    def delete_connector(self, *args):
        self.kafkaStub.activate()
        return install_kafka_connectors.delete_connector(self.kafka, *args)

# End to End tests

    def entry_point(self, *args):
        self.kafkaStub.activate()
        return install_kafka_connectors.entry_point(*args)

    def test_if_plugin_doesnt_exist_returns(self):
        self.stub_list_plugins([])
        response = self.entry_point(configurationInput, self.kafka)
        self.assertEqual(response.success, False)
        self.assertEqual(response.failure_reason, f"Cannot find plugin with name {example_plugin.name}")

    def test_if_connector_doesnt_exist_it_creates_connector(self):
        self.stub_list_plugins()
        self.setup_unsuccessful_get_connector()

        self.stub_create_connector(expected_create_connector_request)

        response = self.entry_point(configurationInput, self.kafka)
    
        self.assertEqual(response.success, True)
        self.assertEqual(response.connector_response.name, "tenure-api")
        self.assertEqual(response.connector_response.arn, "arn:aws:kafkaconnect:eu-west-2:484466746276:connector/tenure-api/dcec484e-8cf2-4118-9432-df85ebe0e165-4")
        self.assertEqual(response.connector_response.state, "CREATING")

    def test_when_connector_needs_updating(self):
        self.stub_list_plugins()
        self.setup_successful_get_connector(capacity_auto_scaling={
            "maxWorkerCount": 6,
            "mcuCount": 3,
            "minWorkerCount": 2,
            "scaleInPolicy": {
                "cpuUtilizationPercentage": 40
            },
            "scaleOutPolicy": {
                "cpuUtilizationPercentage": 70
            }
        })

        self.kafkaStub.add_response("update_connector",
            {
                "connectorArn": "arn:aws:kafkaconnect:eu-west-2:484466746276:connector/tenure-api/6004d2e0-ff6d-4d0a-8c88-a94b86435167-4",
                "connectorState": "UPDATING"
            },
            {
                "capacity": expected_create_connector_request["capacity"],
                "connectorArn": "arn:aws:kafkaconnect:eu-west-2:484466746276:connector/tenure-api/0d5b9cd7-6e4a-4195-8558-de9e0ff98e7f-4",
                "currentVersion": "4"
            })

        response = self.entry_point(configurationInput, self.kafka)

        self.assertEqual(response.success, True)
        self.assertEqual(response.connector_response.arn, "arn:aws:kafkaconnect:eu-west-2:484466746276:connector/tenure-api/6004d2e0-ff6d-4d0a-8c88-a94b86435167-4")
        self.assertEqual(response.connector_response.state, "UPDATING")

    def test_when_connector_needs_recreating(self):
        self.stub_list_plugins()
        self.setup_successful_get_connector(connector_configuration={
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
                "value.converter.schema.registry.url": "http://my-old-schema-reg.eu-west-2.elb.amazonaws.com:8081",
                "value.converter.schemas.enable": "True",
            })
        self.stub_deleting_connector("arn:aws:kafkaconnect:eu-west-2:484466746276:connector/tenure-api/0d5b9cd7-6e4a-4195-8558-de9e0ff98e7f-4", "4")
        self.stub_create_connector(expected_create_connector_request)

        response = self.entry_point(configurationInput, self.kafka)

        self.assertEqual(response.success, True)
        self.assertEqual(response.connector_response.name, "tenure-api")
        self.assertEqual(response.connector_response.arn, "arn:aws:kafkaconnect:eu-west-2:484466746276:connector/tenure-api/dcec484e-8cf2-4118-9432-df85ebe0e165-4")
        self.assertEqual(response.connector_response.state, "CREATING")