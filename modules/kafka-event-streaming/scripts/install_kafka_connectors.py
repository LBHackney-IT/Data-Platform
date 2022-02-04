import argparse
from dataclasses import dataclass
from typing import Dict, List
import logging
import time

import boto3
import botocore
import json

logging.basicConfig()
logger = logging.getLogger(__name__)


def generate_arg_parser():
    parser = argparse.ArgumentParser()
    parser.add_argument("--input", help="expected input from terraform")
    return parser


@dataclass
class PluginResponse:
    name: str
    state: str
    arn: str
    revision: str


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
    auto_scaling: Dict[str, str]
    provisioned_capacity: Dict[str, str]


@dataclass
class ConnectorResponse:
    name: str
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
    plugin: PluginResponse
    capacity: ConnectorCapacity
    worker_configuration: WorkerConfiguration or None

def check_connector_exists_with_config(connector_config: ConnectorConfiguration):
    client = boto3.client("kafkaconnect")
    response = client.list_connectors(
        connectorNamePrefix=connector_config.name,
        maxResults=100,
    )
    print(response)
    connectors = response['connectors']
    if len(connectors) == 0:
        print("Needs Creating")
        return {"action": "CREATE"}

    connectorArn = connectors[0]["connectorArn"]
    description = client.describe_connector(
        connectorArn=connectorArn
    )

# these checks dont work
    if description["connectorDescription"] == connector_config.description:
        print("Needs Recreation because of description")
        return {"action": "RECREATE", "arn": description["connectorArn"], "version": description["currentVersion"]}
    if description["kafkaConnectVersion"] == connector_config.kafka_connect_version:
        print("Needs Recreation because of version")
        return {"action": "RECREATE", "arn": description["connectorArn"], "version": description["currentVersion"]}
    if description["connectorConfiguration"] == connector_config.configuration:
        print("Needs Recreation because of config")
        return {"action": "RECREATE", "arn": description["connectorArn"], "version": description["currentVersion"]}


    if  description["capacity"]["autoScaling"] == connector_config.capacity.auto_scaling \
    or description["capacity"]["provisionedCapacity"] == connector_config.capacity.provisioned_capacity:
        print("Needs Updating")
        return {"action": "UPDATE", "arn": description["connectorArn"], "version": description["currentVersion"] }

    return {"action": "None"}
def update_connector(connectorArn:str, currentVersion:str, capacityConfig:ConnectorCapacity):
    client = boto3.client("kafkaconnect")
    response = client.update_connector(
        capacity=get_capacity_request(capacityConfig),
        connectorArn=connectorArn,
        currentVersion=currentVersion
    )
    logger.info(f"update_connector response {response}")

def delete_connector(connectorArn:str, currentVersion:str):
    client = boto3.client("kafkaconnect")
    response = client.delete_connector(
        connectorArn=connectorArn,
        currentVersion=currentVersion
    )
    state = "DELETING"
    logger.info(f"delete_connector response {response}")
    while state == "DELETING":
        time.sleep(5)
        state = "DELETED" if len(client.list_connectors(
            connectorNamePrefix=connector_config.name,
            maxResults=100,
        )['connectors']) == 0 else "DELETING"





def get_plugin_if_exists(name: str):
    client = boto3.client("kafkaconnect")
    response = client.list_custom_plugins(
        maxResults=100,
    )
    plugins = response['customPlugins']
    return next((PluginResponse(
        name=plugin["name"],
        state=plugin["customPluginState"],
        arn=plugin["customPluginArn"],
        revision=plugin["latestRevision"]["revision"]
    ) for plugin in plugins if plugin["name"] == name), None)

def create_custom_plugin(config: PluginConfig) -> PluginResponse:
    client = boto3.client("kafkaconnect")
    response = client.create_custom_plugin(
        contentType="ZIP",
        description="kafka connect plugin for hackney data platform",
        location={
            "s3Location": {
                "bucketArn": config["bucket_arn"],
                "fileKey": config["file_key"],
            }
        },
        name=config["name"]
    )

    return PluginResponse(
        name=response["name"],
        state=response["customPluginState"],
        arn=response["customPluginArn"],
        revision=response["revision"]
    )

def get_capacity_request(connector_config: ConnectorCapacity):
    capacity = {}
    if connector_config.capacity.auto_scaling:
        capacity['autoScaling'] = connector_config.capacity.auto_scaling
    if connector_config.capacity.provisioned_capacity:
        capacity['provisionedCapacity'] = connector_config.capacity.provisioned_capacity
    return capacity

def create_connector(connector_config: ConnectorConfiguration):
    client = boto3.client("kafkaconnect")

    response = client.create_connector(
        capacity=get_capacity_request(connector_config),
        connectorConfiguration=connector_config.configuration,
        connectorName=connector_config.name,
        connectorDescription=connector_config.description,
        kafkaCluster={
            'apacheKafkaCluster': {
                'bootstrapServers': connector_config.cluster_config.bootstrap_servers,
                'vpc': {
                    'securityGroups': connector_config.cluster_config.vpc_security_groups,
                    'subnets': connector_config.cluster_config.vpc_subnets
                }
            }
        },
        kafkaClusterClientAuthentication={
            'authenticationType': 'NONE'
        },
        kafkaClusterEncryptionInTransit={
            'encryptionType': 'TLS'
        },
        kafkaConnectVersion=connector_config.kafka_connect_version,
        logDelivery={
            'workerLogDelivery': {
                'cloudWatchLogs': {
                    'enabled': connector_config.log_delivery.log_group_enabled,
                    'logGroup': connector_config.log_delivery.log_group
                }
            }
        },
        plugins=[
            {
                'customPlugin': {
                    'customPluginArn': plugin_response.arn,
                    'revision': plugin_response.revision
                }
            },
        ],
        serviceExecutionRoleArn=connector_config.service_execution_role_arn
    )
    return ConnectorResponse(
        name=response["connectorName"],
        arn=response["connectorArn"],
        state=response["connectorState"]
    )

if __name__ == "__main__":
    parser = generate_arg_parser()
    args = vars(parser.parse_args())
    config = json.loads(args["input"])
    logger.debug(f"given config {config}")

    plugin_config:PluginConfig = config["default_s3_plugin_configuration"]["value"]["connector_s3_plugin"]

    plugin_response = get_plugin_if_exists(plugin_config["name"]) or create_custom_plugin(plugin_config)
    logger.info(f"custom_plugin_response {plugin_response}")

    cluster_config_tf = config["cluster_config"]["value"]
    cluster_config = ClusterConfig(
        bootstrap_servers=cluster_config_tf["bootstrap_brokers_tls"],
        vpc_security_groups=cluster_config_tf["vpc_security_groups"],
        vpc_subnets=cluster_config_tf["vpc_subnets"]
    )
    log_delivery_tf = config["default_s3_plugin_configuration"]["value"]["connector_log_delivery_config"]
    log_delivery = LogDeliveryConfiguration(
        log_group=log_delivery_tf.get("log_group"),
        log_group_enabled=log_delivery_tf.get("log_group_enabled")
    )

    connector_capacity_tf = config["default_s3_plugin_configuration"]["value"]["capacity"]
    connector_capacity = ConnectorCapacity(
        auto_scaling=connector_capacity_tf.get("auto_scaling"),
        provisioned_capacity=connector_capacity_tf.get("provisioned_capacity")
    )

    connector_config = ConnectorConfiguration(
        name=config["tenure_connector_name"]["value"],
        description="Kafka connector to write tenure changes to S3",
        configuration=config["default_s3_plugin_configuration"]["value"]["connector_configuration"],
        cluster_config=cluster_config,
        kafka_connect_version=config["default_s3_plugin_configuration"]["value"]["connect_version"],
        log_delivery=log_delivery,
        service_execution_role_arn=config["default_s3_plugin_configuration"]["value"]["service_execution_role_arn"],
        plugin=plugin_response,
        capacity=connector_capacity,
        worker_configuration=config.get("worker_configuration", {}).get("value", None)
    )

    connector_action = check_connector_exists_with_config(connector_config)

    if connector_action["action"] == "CREATE":
        connector_response = create_connector(connector_config)
        logger.info(f"connector_response {connector_response}")
    elif connector_action["action"] == "UPDATE":
        update_connector(connector_action["arn"], connector_action["version"], connector_config.capacity)
    elif connector_action["action"] == "RECREATE":
        delete_connector(connector_action["arn"], connector_action["version"])
        connector_response = create_connector(connector_config)
        logger.info(f"connector_response {connector_response}")
    else:
        logger.info(f"connector {connector_config.name} already exists")
