locals {
  broker = {
    container_name         = "broker"
    image_name             = "confluentinc/cp-kafka:5.4.0"
    port                   = 9092
    cpu                    = 256
    memory                 = 2048
    load_balancer_required = false
    environment_variables = [
      { name : "KAFKA_BROKER_ID", value : "1" },
      { name : "KAFKA_ZOOKEEPER_CONNECT", value : "zookeeper:2181" },
      { name : "KAFKA_LISTENER_SECURITY_PROTOCOL_MAP", value : "PLAINTEXT:PLAINTEXT,PLAINTEXT_HOST:PLAINTEXT" },
      { name : "KAFKA_ADVERTISED_LISTENERS", value : "PLAINTEXT://broker:29092,PLAINTEXT_HOST://localhost:9092" },
      { name : "KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR", value : "1" },
      { name : "KAFKA_GROUP_INITIAL_REBALANCE_DELAY_MS", value : "0" },
      { name : "KAFKA_HEAP_OPTS", value : "-Xms256m -Xmx256m" }
    ]
    mount_points = [
      { sourceVolume : "broker", containerPath : "/var/lib/kafka/data/", readOnly : false }
    ]
    volumes = ["broker"]
  }
  datahub_actions = {
    container_name         = "datahub-actions"
    image_name             = "acryldata/acryl-datahub-actions:head"
    port                   = 80
    cpu                    = 256
    memory                 = 2048
    load_balancer_required = false
    environment_variables = [
      { name : "GMS_HOST", value : "datahub-gms" },
      { name : "GMS_PORT", value : "8080" },
      { name : "KAFKA_BOOTSTRAP_SERVER", value : "broker:29092" },
      { name : "SCHEMA_REGISTRY_URL", value : "http://schema-registry:8081" },
      { name : "METADATA_AUDIT_EVENT_NAME", value : "MetadataAuditEvent_v4" },
      { name : "METADATA_CHANGE_LOG_VERSIONED_TOPIC_NAME", value : "MetadataChangeLog_Versioned_v1" },
      { name : "DATAHUB_SYSTEM_CLIENT_ID", value : "__datahub_system" },
      { name : "DATAHUB_SYSTEM_CLIENT_SECRET", value : random_password.password.result },
      { name : "KAFKA_PROPERTIES_SECURITY_PROTOCOL", value : "PLAINTEXT" }
    ]
    mount_points = []
    volumes      = []
  }
  datahub_frontend_react = {
    container_name         = "datahub-frontend-react"
    image_name             = "linkedin/datahub-frontend-react:head"
    port                   = 9002
    cpu                    = 256
    memory                 = 2048
    load_balancer_required = true
    environment_variables = [
      { name : "PORT", value : "80" },
      { name : "DATAHUB_GMS_HOST", value : "80" },
      { name : "DATAHUB_GMS_PORT", value : "datahub-gms" },
      { name : "DATAHUB_SECRET", value : random_password.password.result },
      { name : "DATAHUB_APP_VERSION", value : "1.0" },
      { name : "DATAHUB_PLAY_MEM_BUFFER_SIZE", value : "10MB" },
      { name : "JAVA_OPTS", value : "-Xms512m -Xmx512m -Dhttp.port=9002 -Dconfig.file=datahub-frontend/conf/application.conf -Djava.security.auth.login.config=datahub-frontend/conf/jaas.conf -Dlogback.configurationFile=datahub-frontend/conf/logback.xml -Dlogback.debug=false -Dpidfile.path=/dev/null" },
      { name : "KAFKA_BOOTSTRAP_SERVER", value : "broker:29092" },
      { name : "DATAHUB_TRACKING_TOPIC", value : "DataHubUsageEvent_v1" },
      { name : "ELASTIC_CLIENT_HOST", value : "elasticsearch" },
      { name : "ELASTIC_CLIENT_PORT", value : "9200" }
    ]
    mount_points = []
    volumes      = []
  }
  datahub_gms = {
    container_name         = "datahub-gms"
    image_name             = "linkedin/datahub-gms:head"
    port                   = 8080
    cpu                    = 256
    memory                 = 2048
    load_balancer_required = false
    environment_variables = [
      { name : "DATASET_ENABLE_SCSI", value : "false" },
      { name : "EBEAN_DATASOURCE_USERNAME", value : "datahub" },
      { name : "EBEAN_DATASOURCE_PASSWORD", value : "datahub" },
      { name : "EBEAN_DATASOURCE_HOST", value : "mysql:3306" },
      { name : "EBEAN_DATASOURCE_URL", value : "jdbc:mysql://mysql:3306/datahub?verifyServerCertificate", value : "false&useSSL", value : "true&useUnicode", value : "yes&characterEncoding", value : "UTF-8&enabledTLSProtocols", value : "TLSv1.2" },
      { name : "EBEAN_DATASOURCE_DRIVER", value : "com.mysql.jdbc.Driver" },
      { name : "KAFKA_BOOTSTRAP_SERVER", value : "broker:29092" },
      { name : "KAFKA_SCHEMAREGISTRY_URL", value : "http://schema-registry:8081" },
      { name : "ELASTICSEARCH_HOST", value : "elasticsearch" },
      { name : "ELASTICSEARCH_PORT", value : "9200" },
      { name : "NEO4J_HOST", value : "http://neo4j:7474" },
      { name : "NEO4J_URI", value : "bolt://neo4j" },
      { name : "NEO4J_USERNAME", value : "neo4j" },
      { name : "NEO4J_PASSWORD", value : "datahub" },
      { name : "JAVA_OPTS", value : "-Xms1g -Xmx1g" },
      { name : "GRAPH_SERVICE_IMPL", value : "neo4j" },
      { name : "ENTITY_REGISTRY_CONFIG_PATH", value : "/datahub/datahub-gms/resources/entity-registry.yml" },
      { name : "MAE_CONSUMER_ENABLED", value : "true" },
      { name : "MCE_CONSUMER_ENABLED", value : "true" },
      { name : "UI_INGESTION_ENABLED", value : "true" },
      { name : "UI_INGESTION_DEFAULT_CLI_VERSION", value : "0.8.26.6" }
    ]
    mount_points = []
    volumes      = []
  }
  zookeeper = {
    container_name         = "zookeeper"
    image_name             = "confluentinc/cp-zookeeper:5.4.0"
    port                   = 2181
    cpu                    = 256
    memory                 = 2048
    load_balancer_required = false
    environment_variables = [
      { name : "ZOOKEEPER_CLIENT_PORT", value : "2181" },
      { name : "ZOOKEEPER_TICK_TIME", value : "2000" },
    ]
    mount_points = [
      { sourceVolume : "zkdata", containerPath : "/var/opt/zookeeper", readOnly : false }
    ]
    volumes = ["zkdata"]
  }
  mysql_setup = {
    container_name         = "mysql-setup"
    image_name             = "acryldata/datahub-mysql-setup:head"
    port                   = 3306
    cpu                    = 256
    memory                 = 2048
    load_balancer_required = false
    environment_variables = [
      { name : "MYSQL_HOST", value : var.rds_properties.host },
      { name : "MYSQL_PORT", value : var.rds_properties.port },
      { name : "MYSQL_USERNAME", value : var.rds_properties.username },
      { name : "MYSQL_PASSWORD", value : var.rds_properties.password },
      { name : "DATAHUB_DB_NAME", value : var.rds_properties.db_name },
    ]
    mount_points = []
    volumes      = []
  }
  elasticsearch_setup = {
    container_name         = "elasticsearch-setup"
    image_name             = "linkedin/datahub-elasticsearch-setup:head"
    port                   = var.elasticsearch_properties.port
    cpu                    = 256
    memory                 = 2048
    load_balancer_required = false
    environment_variables = [
      { name : "ELASTICSEARCH_HOST", value : var.elasticsearch_properties.host },
      { name : "ELASTICSEARCH_PORT", value : var.elasticsearch_properties.port },
      { name : "ELASTICSEARCH_PROTOCOL", value : var.elasticsearch_properties.protocol },
      { name : "USE_AWS_ELASTICSEARCH", value : "true" }
    ]
    mount_points = []
    volumes      = []
  }
  kafka_setup = {
    container_name         = "kafka-setup"
    image_name             = "linkedin/datahub-kafka-setup:head"
    port                   = var.elasticsearch_properties.port
    cpu                    = 256
    memory                 = 2048
    load_balancer_required = false
    environment_variables = [
      { name : "KAFKA_ZOOKEEPER_CONNECT", value : var.kafka_properties.kafka_zookeeper_connect },
      { name : "KAFKA_BOOTSTRAP_SERVER", value : var.kafka_properties.kafka_bootstrap_server },
    ]
    mount_points = []
    volumes      = []
  }
  schema_registry = {
    container_name         = "schema-registry"
    image_name             = "confluentinc/cp-schema-registry:5.4.0"
    port                   = 8081
    cpu                    = 256
    memory                 = 2048
    load_balancer_required = false
    environment_variables = [
      { name : "SCHEMA_REGISTRY_HOST_NAME", value : var.schema_registry_properties.host_name },
      { name : "SCHEMA_REGISTRY_KAFKASTORE_CONNECTION_URL", value : var.schema_registry_properties.kafkastore_connection_url },
    ]
    mount_points = []
    volumes      = []
  }
}

resource "random_password" "password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}