import argparse
from dataclasses import dataclass
from typing import Dict, List
import logging

import boto3
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


def create_custom_plugin(bucket_arn: str, file_key: str, version: str, name: str) -> PluginResponse:
    client = boto3.client("kafkaconnect")
    response = client.create_custom_plugin(
        contentType="ZIP",
        description="kafka connect plugin for hackney data platform",
        location={
            "s3Location": {
                "bucketArn": bucket_arn,
                "fileKey": file_key,
                "objectVersion": version
            }
        },
        name=name
    )
    return PluginResponse(
        name=response["name"],
        state=response["customPluginState"],
        arn=response["customPluginArn"],
        revision=response["revision"]
    )


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
    log_group: str or None
    log_group_enabled: bool or None
    firehose_delivery_stream: str or None
    firehose_delivery_stream_enabled: bool or None
    s3_bucket: str or None
    s3_bucket_enabled: bool or None
    s3_prefix: str or None


@dataclass
class ClusterConfig:
    bootstrap_servers: str
    vpc_security_groups: List[str]
    vpc_subnets: List[str]


@dataclass
class ConnectorConfiguration:
    config: Dict[str, str]


@dataclass
class ConnectorCapacity:
    auto_scaling: Dict[str, str]
    provisioned_capacity: Dict[str, str]


@dataclass
class ConnectorResponse:
    name: str
    arn: str
    state: str


def create_connector(
        connector_name,
        connector_description,
        connector_configuration: ConnectorConfiguration,
        cluster_config: ClusterConfig,
        connect_version,
        log_delivery_config: LogDeliveryConfiguration,
        service_execution_role_arn,
        plugin_response: PluginResponse,
        capacity: ConnectorCapacity,
        worker_configuration: WorkerConfiguration = None
):
    client = boto3.client("kafkaconnect")
    response = client.create_connector(
        capacity=capacity,
        connectorConfiguration=connector_configuration,
        connectorName=connector_name,
        connectorDescription=connector_description,
        kafkaCluster={
            'apacheKafkaCluster': {
                'bootstrapServers': cluster_config.bootstrap_servers,
                'vpc': {
                    'securityGroups': cluster_config.vpc_security_groups,
                    'subnets': cluster_config.vpc_subnets
                }
            }
        },
        # kafkaClusterClientAuthentication={
        #     'authenticationType': 'IAM'
        # },
        kafkaClusterEncryptionInTransit={
            'encryptionType': 'PLAINTEXT'
        },
        kafkaConnectVersion=connect_version,
        logDelivery={
            'workerLogDelivery': {
                'cloudWatchLogs': {
                    'enabled': log_delivery_config.log_group_enabled,
                    'logGroup': log_delivery_config.log_group
                }
            }
        },
        plugins=[
            {
                plugin_response.name: {
                    'customPluginArn': plugin_response.arn,
                    'revision': plugin_response.revision
                }
            },
        ],
        serviceExecutionRoleArn=service_execution_role_arn,
        workerConfiguration={
            'revision': worker_configuration.revision,
            'workerConfigurationArn': worker_configuration.arn
        }
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

    plugin_response = create_custom_plugin(
        config["connector_s3_plugin"]["bucket_arn"],
        config["connector_s3_plugin"]["file_key"],
        config["connector_s3_plugin"]["version"],
        config["connector_s3_plugin"]["name"]
    )
    logger.debug(f"custom_plugin_response {plugin_response}")

    connector_response = create_connector(
        config["tenure_connector_name"],
        "setting up kafka connector for hackney data platform",
        config["default_s3_plugin_configuration"]["connector_configuration"],
        config["cluster_config"],
        config["default_s3_plugin_configuration"]["connect_version"],
        config["default_s3_plugin_configuration"]["connector_log_delivery_config"],
        config["default_s3_plugin_configuration"]["service_execution_role_arn"],
        plugin_response,
        config["default_s3_plugin_configuration"]["capacity"],
        config["worker_configuration"]
    )
    logger.debug(f"connector_response {connector_response}")
