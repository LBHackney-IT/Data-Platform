import argparse
from dataclasses import dataclass
from typing import Dict, List, Union
from botocore.client import BaseClient
import logging
import time

import boto3
import json

logging.basicConfig()
logger = logging.getLogger(__name__)


def generate_arg_parser():
    parser = argparse.ArgumentParser()
    parser.add_argument("--input", help="expected input from terraform")
    return parser


@dataclass
class PluginDetails:
    name: str
    state: str
    arn: str
    revision: int


@dataclass
class PluginConfig:
    bucket_arn: str
    file_key: str
    name: str


@dataclass
class ConnectorConfiguration:
    service_execution_role_arn: str
    plugin_arn: str
    revision: str


@dataclass
class WorkerConfiguration:
    revision: str
    arn: str


@dataclass
class LogDeliveryConfiguration:
    log_group: str or None = None
    log_group_enabled: bool or None = None
    firehose_delivery_stream: str or None = None
    firehose_delivery_stream_enabled: bool or None = None
    s3_bucket: str or None = None
    s3_bucket_enabled: bool or None = None
    s3_prefix: str or None = None


@dataclass
class ClusterConfig:
    bootstrap_servers: str
    vpc_security_groups: List[str]
    vpc_subnets: List[str]


@dataclass
class ConnectorCapacity:
    auto_scaling: Dict[str, Union[int, str]]=None
    provisioned_capacity: Dict[str, Union[int, str]]=None


@dataclass
class CreateConnectorResponse:
    arn: str
    state: str
    name: str

@dataclass
class UpdateConnectorResponse:
    arn: str
    state: str

@dataclass
class ConnectorConfiguration:
    name: str
    description: str
    configuration: Dict[str, str]
    cluster_config: ClusterConfig
    kafka_connect_version: str
    log_delivery: LogDeliveryConfiguration
    service_execution_role_arn: str
    plugin: PluginDetails
    capacity: ConnectorCapacity
    worker_configuration: WorkerConfiguration or None

@dataclass
class Response:
    success: bool
    failure_reason: str=None
    connector_response: CreateConnectorResponse or UpdateConnectorResponse=None

def get_kafka_client() -> BaseClient:
    return boto3.client("kafkaconnect", region_name='eu-west-2')


# TODO: Add pagination encase there are more than 100 connectors
def get_plugin_if_exists(client: BaseClient, name: str):
    response = client.list_custom_plugins(
        maxResults=100,
    )
    plugins = response['customPlugins']
    return next((PluginDetails(
        name=plugin["name"],
        state=plugin["customPluginState"],
        arn=plugin["customPluginArn"],
        revision=plugin["latestRevision"]["revision"]
    ) for plugin in plugins if plugin["name"] == name), None)


def connector_config_from_input_config(input_config, plugin: PluginDetails) -> ConnectorConfiguration:
    default_s3_plugin_config = input_config["default_s3_plugin_configuration"]["value"]

    cluster_config_tf = input_config["cluster_config"]["value"]
    cluster_config = ClusterConfig(
        bootstrap_servers=cluster_config_tf["bootstrap_brokers_tls"],
        vpc_security_groups=cluster_config_tf["vpc_security_groups"],
        vpc_subnets=cluster_config_tf["vpc_subnets"]
    )

    log_delivery_tf = default_s3_plugin_config["connector_log_delivery_config"]
    log_delivery = LogDeliveryConfiguration(
        log_group=log_delivery_tf.get("log_group"),
        log_group_enabled=log_delivery_tf.get("log_group_enabled")
    )

    connector_capacity_tf = default_s3_plugin_config["capacity"]
    connector_capacity = ConnectorCapacity(
        auto_scaling=connector_capacity_tf.get("auto_scaling"),
        provisioned_capacity=connector_capacity_tf.get("provisioned_capacity")
    )
    name = input_config["tenure_connector_name"]["value"]

    return ConnectorConfiguration(
        name=name,
        description=f"Kafka connector to write {name} changes to S3",
        configuration=default_s3_plugin_config["connector_configuration"],
        cluster_config=cluster_config,
        kafka_connect_version=default_s3_plugin_config["connect_version"],
        log_delivery=log_delivery,
        service_execution_role_arn=default_s3_plugin_config["service_execution_role_arn"],
        plugin=plugin,
        capacity=connector_capacity,
        worker_configuration=input_config.get("worker_configuration", {}).get("value", None)
    )


def get_connector(client: BaseClient, connector_name: str):
    response = client.list_connectors(
        connectorNamePrefix=connector_name,
        maxResults=100,
    )
    connectors = response['connectors']
    if len(connectors) == 0:
        print(f"Connector Not Found for name {connector_name}")
        return False

    connector_arn = connectors[0]['connectorArn']

    connector = client.describe_connector(
        connectorArn=connector_arn
    )
    return connector


def check_connector_exists_with_config(client: BaseClient, connector_configuration: ConnectorConfiguration):
    description = get_connector(client, connector_configuration.name)

    if False == description:
        print("Connection Needs Creating")
        return {"action": "CREATE"}

    if description["connectorDescription"] != connector_configuration.description \
            or description["kafkaConnectVersion"] != connector_configuration.kafka_connect_version \
            or description["connectorConfiguration"] != connector_configuration.configuration:
        print("Connection Needs Recreating")
        return {"action": "RECREATE", "arn": description["connectorArn"], "version": description["currentVersion"]}
    if description["capacity"]["autoScaling"] != connector_configuration.capacity.auto_scaling:
        print("Needs Updating")
        return {"action": "UPDATE", "arn": description["connectorArn"], "version": description["currentVersion"]}

    print("No action needed, connector config hasn't changed")
    return {"action": "NONE"}


def create_connector(client: BaseClient, connector_configuration: ConnectorConfiguration):
    response = client.create_connector(
        capacity=get_capacity_request(connector_configuration.capacity),
        connectorConfiguration=connector_configuration.configuration,
        connectorName=connector_configuration.name,
        connectorDescription=connector_configuration.description,
        kafkaCluster={
            'apacheKafkaCluster': {
                'bootstrapServers': connector_configuration.cluster_config.bootstrap_servers,
                'vpc': {
                    'securityGroups': connector_configuration.cluster_config.vpc_security_groups,
                    'subnets': connector_configuration.cluster_config.vpc_subnets
                }
            }
        },
        kafkaClusterClientAuthentication={
            'authenticationType': 'NONE'
        },
        kafkaClusterEncryptionInTransit={
            'encryptionType': 'TLS'
        },
        kafkaConnectVersion=connector_configuration.kafka_connect_version,
        logDelivery={
            'workerLogDelivery': {
                'cloudWatchLogs': {
                    'enabled': connector_configuration.log_delivery.log_group_enabled,
                    'logGroup': connector_configuration.log_delivery.log_group
                }
            }
        },
        plugins=[
            {
                'customPlugin': {
                    'customPluginArn': connector_configuration.plugin.arn,
                    'revision': connector_configuration.plugin.revision
                }
            },
        ],
        serviceExecutionRoleArn=connector_configuration.service_execution_role_arn
    )
    return CreateConnectorResponse(
        name=response["connectorName"],
        arn=response["connectorArn"],
        state=response["connectorState"]
    )


def update_connector_capacity(client: BaseClient, connector_arn: str, current_version: str,
                     capacity_config: ConnectorCapacity):
    response = client.update_connector(
        capacity=get_capacity_request(capacity_config),
        connectorArn=connector_arn,
        currentVersion=current_version
    )
    logger.info(f"update_connector response {response}")
    return UpdateConnectorResponse(arn=response["connectorArn"], state=response["connectorState"])


def delete_connector(client: BaseClient, connector_arn: str, current_version: str):
    response = client.delete_connector(
        connectorArn=connector_arn,
        currentVersion=current_version
    )
    state = "DELETING"
    logger.info(f"delete_connector response {response}")
    while state == "DELETING":
        time.sleep(5)
        state_details = client.describe_connector(
            connectorArn=connector_arn
        )
        state = state_details["connectorState"]


def get_capacity_request(capacity_configuration: ConnectorCapacity=None):
    capacity_request = {}
    if capacity_configuration.auto_scaling:
        capacity_request['autoScaling'] = capacity_configuration.auto_scaling
    if capacity_configuration.provisioned_capacity:
        capacity_request['provisionedCapacity'] = capacity_configuration.provisioned_capacity
    return capacity_request


def entry_point(raw_config, kafka_client):
    print(raw_config)
    raw_plugin_config = raw_config["default_s3_plugin_configuration"]["value"]["connector_s3_plugin"]
    print(raw_plugin_config)
    plugin_config = PluginConfig(
        bucket_arn=raw_plugin_config["bucket_arn"],
        file_key=raw_plugin_config["file_key"],
        name=raw_plugin_config["name"]
    )

    plugin_details = get_plugin_if_exists(kafka_client, plugin_config.name)
    print(plugin_details)
    if not plugin_details:
        logger.error(f"Cannot Find Plugin with name {plugin_config.name}")
        return Response(success=False,failure_reason=f"Cannot find plugin with name {plugin_config.name}")

    logger.info(f"custom_plugin_response {plugin_details}")

    connector_config = connector_config_from_input_config(raw_config, plugin_details)
    print(connector_config)
    connector_action = check_connector_exists_with_config(kafka_client, connector_config)

    if connector_action["action"] == "CREATE":
        connector_response = create_connector(kafka_client, connector_config)
        logger.info(f"connector_response {connector_response}")
        return Response(success=True, connector_response=connector_response)
    elif connector_action["action"] == "UPDATE":
        connector_response = update_connector_capacity(kafka_client, connector_action["arn"], connector_action["version"], connector_config.capacity)
        logger.info(f"connector_response {connector_response}")
        return Response(success=True, connector_response=connector_response)
    elif connector_action["action"] == "RECREATE":
        delete_connector(kafka_client, connector_action["arn"], connector_action["version"])
        connector_response = create_connector(kafka_client, connector_config)
        logger.info(f"connector_response {connector_response}")
        return Response(success=True, connector_response=connector_response)
    else:
        logger.info(f"connector {connector_config.name} already exists")

if __name__ == "__main__":
    parser = generate_arg_parser()
    args = vars(parser.parse_args())
    config = json.loads(args["input"])
    logger.debug(f"given config {config}")
    kafka_client = get_kafka_client()
    entry_point(config, kafka_client)
