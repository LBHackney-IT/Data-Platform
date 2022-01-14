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


def create_custom_plugin(bucket_arn: str, file_key: str, version: str) -> PluginResponse:
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
        name="hackney-data-platform"
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
    log_group: str
    log_group_enabled: bool
    firehose_delivery_stream: str
    firehose_delivery_stream_enabled: bool
    s3_bucket: str
    s3_bucket_enabled: bool
    s3_prefix: str


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
        connector_configuration,
        cluster_config,
        connect_version,
        log_delivery_config,
        service_execution_role_arn,
        plugin_response,
        worker_configuration,
        capacity
):
    client = boto3.client("kafkaconnect")
    response = client.create_connector(
        capacity={
            'autoScaling': capacity.auto_scaling,
            'provisionedCapacity': capacity.provisioned_capacity
        },
        connectorConfiguration=connector_configuration.config,
        connectorName=connector_name,
        connectorDescription=connector_description,
        kafkaCluster={
            'apacheKafkaCluster': {
                'bootstrapServers': cluster_config.bootstreap_servers,
                'vpc': {
                    'securityGroups': cluster_config.vpc_security_groups,
                    'subnets': cluster_config.vpc_subnets
                }
            }
        },
        kafkaClusterClientAuthentication={
            'authenticationType': 'IAM'
        },
        kafkaClusterEncryptionInTransit={
            'encryptionType': 'PLAINTEXT'
        },
        kafkaConnectVersion=connect_version,
        logDelivery={
            'workerLogDelivery': {
                'cloudWatchLogs': {
                    'enabled': log_delivery_config.log_group_enabled,
                    'logGroup': log_delivery_config.log_group
                },
                'firehose': {
                    'deliveryStream': log_delivery_config.firehose_delivery_stream,
                    'enabled': log_delivery_config.firehose_delivery_stream_enabled
                },
                's3': {
                    'bucket': log_delivery_config.s3_bucket,
                    'enabled': log_delivery_config.s3_bucket_enabled,
                    'prefix': log_delivery_config.s3_bucket_prefix
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
        config["bucket_arn"],
        config["file_key"],
        config["version"]
    )
    logger.debug(f"custom_plugin_response {plugin_response}")

    connector_response = create_connector(
        config["connector_name"],
        "setting up kafka connector for hackney data platform",
        config["connector_configuration"],
        config["cluster_config"],
        config["connect_version"],
        config["log_delivery_config"],
        config["service_execution_role_arn"],
        config["plugin_response"],
        config["worker_configuration"],
        config["capacity"]
    )
    logger.debug(f"connector_response {connector_response}")

