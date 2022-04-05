locals {
  datahub_actions = {
    container_name         = "datahub-actions"
    image_name             = "acryldata/acryl-datahub-actions"
    image_tag              = "head"
    port                   = 80
    cpu                    = 256
    memory                 = 2048
    load_balancer_required = false
    environment_variables = [
      { name : "GMS_HOST", value : aws_alb.datahub_gms.dns_name },
      { name : "GMS_PORT", value : "8080" },
      { name : "KAFKA_BOOTSTRAP_SERVER", value : var.kafka_properties.kafka_bootstrap_server },
      { name : "SCHEMA_REGISTRY_URL", value : var.schema_registry_properties.schema_registry_url },
      { name : "METADATA_AUDIT_EVENT_NAME", value : "MetadataAuditEvent_v4" },
      { name : "METADATA_CHANGE_LOG_VERSIONED_TOPIC_NAME", value : "MetadataChangeLog_Versioned_v1" },
      { name : "DATAHUB_SYSTEM_CLIENT_ID", value : "__datahub_system" },
      { name : "DATAHUB_SYSTEM_CLIENT_SECRET", value : random_password.datahub_secret.result },
      { name : "KAFKA_PROPERTIES_SECURITY_PROTOCOL", value : "SSL" }
    ]
    port_mappings = []
    mount_points  = []
    volumes       = []
  }
  datahub_frontend_react = {
    container_name         = "datahub-frontend-react"
    image_name             = "linkedin/datahub-frontend-react"
    image_tag              = "latest"
    port                   = 9002
    cpu                    = 256
    memory                 = 2048
    load_balancer_required = true
    environment_variables = [
      { name : "PORT", value : "9002" },
      { name : "DATAHUB_GMS_HOST", value : aws_alb.datahub_gms.dns_name },
      { name : "DATAHUB_GMS_PORT", value : "8080" },
      { name : "DATAHUB_SECRET", value : random_password.datahub_secret.result },
      { name : "DATAHUB_APP_VERSION", value : "1.0" },
      { name : "DATAHUB_PLAY_MEM_BUFFER_SIZE", value : "10MB" },
      { name : "JAVA_OPTS", value : "-Xms2048m -Xmx2048m -Dhttp.port=9002 -Dconfig.file=datahub-frontend/conf/application.conf -Djava.security.auth.login.config=datahub-frontend/conf/jaas.conf -Dlogback.configurationFile=datahub-frontend/conf/logback.xml -Dlogback.debug=false -Dpidfile.path=/dev/null" },
      { name : "KAFKA_BOOTSTRAP_SERVER", value : var.kafka_properties.kafka_bootstrap_server },
      { name : "DATAHUB_TRACKING_TOPIC", value : "DataHubUsageEvent_v1" },
      { name : "ELASTIC_CLIENT_HOST", value : "elasticsearch" },
      { name : "ELASTIC_CLIENT_PORT", value : "9200" }
    ]
    port_mappings = [
      { containerPort : 9002, hostPort : 9002 }
    ]
    mount_points = []
    volumes      = []
  }
  datahub_gms = {
    container_name         = "datahub-gms"
    image_name             = "linkedin/datahub-gms"
    image_tag              = "latest"
    port                   = 8080
    cpu                    = 256
    memory                 = 2048
    load_balancer_required = true
    environment_variables = [
      { name : "DATASET_ENABLE_SCSI", value : "false" },
      { name : "EBEAN_DATASOURCE_USERNAME", value : aws_db_instance.datahub.username },
      { name : "EBEAN_DATASOURCE_PASSWORD", value : aws_db_instance.datahub.password },
      { name : "EBEAN_DATASOURCE_HOST", value : aws_db_instance.datahub.endpoint },
      { name : "EBEAN_DATASOURCE_URL", value : "jdbc:mysql://${aws_db_instance.datahub.endpoint}/${aws_db_instance.datahub.name}?verifyServerCertificate", value : "false&useSSL", value : "true&useUnicode", value : "yes&characterEncoding", value : "UTF-8&enabledTLSProtocols", value : "TLSv1.2" },
      { name : "EBEAN_DATASOURCE_DRIVER", value : "com.mysql.jdbc.Driver" },
      { name : "KAFKA_BOOTSTRAP_SERVER", value : var.kafka_properties.kafka_bootstrap_server },
      { name : "KAFKA_SCHEMAREGISTRY_URL", value : var.schema_registry_properties.schema_registry_url },
      { name : "ELASTICSEARCH_HOST", value : "elasticsearch" },
      { name : "ELASTICSEARCH_PORT", value : "9200" },
      { name : "NEO4J_HOST", value : "http://${aws_alb.datahub_neo4j.dns_name}:7474" },
      { name : "NEO4J_URI", value : "bolt://${aws_alb.datahub_neo4j.dns_name}" },
      { name : "NEO4J_USERNAME", value : "neo4j" },
      { name : "NEO4J_PASSWORD", value : random_password.datahub_secret.result },
      { name : "JAVA_OPTS", value : "-Xms1g -Xmx1g" },
      { name : "GRAPH_SERVICE_IMPL", value : "neo4j" },
      { name : "ENTITY_REGISTRY_CONFIG_PATH", value : "/datahub/datahub-gms/resources/entity-registry.yml" },
      { name : "MAE_CONSUMER_ENABLED", value : "false" },
      { name : "MCE_CONSUMER_ENABLED", value : "false" },
      { name : "UI_INGESTION_ENABLED", value : "true" },
      { name : "UI_INGESTION_DEFAULT_CLI_VERSION", value : "0.8.26.6" }
    ]
    port_mappings = [
      { containerPort : 8080, hostPort : 8080 }
    ]
    mount_points = []
    volumes      = []
  }
  mysql_setup = {
    container_name         = "mysql-setup"
    image_name             = "acryldata/datahub-mysql-setup"
    image_tag              = "latest"
    port                   = 3306
    cpu                    = 256
    memory                 = 2048
    load_balancer_required = false
    environment_variables = [
      { name : "MYSQL_HOST", value : aws_db_instance.datahub.address },
      { name : "MYSQL_PORT", value : aws_db_instance.datahub.port },
      { name : "MYSQL_USERNAME", value : aws_db_instance.datahub.username },
      { name : "MYSQL_PASSWORD", value : aws_db_instance.datahub.password },
      { name : "DATAHUB_DB_NAME", value : aws_db_instance.datahub.name },
    ]
    port_mappings = []
    mount_points  = []
    volumes       = []
  }
  elasticsearch_setup = {
    container_name         = "elasticsearch-setup"
    image_name             = "linkedin/datahub-elasticsearch-setup"
    image_tag              = "latest"
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
    port_mappings = []
    mount_points  = []
    volumes       = []
  }
  kafka_setup = {
    container_name         = "kafka-setup"
    image_name             = "linkedin/datahub-kafka-setup"
    image_tag              = "latest"
    port                   = var.elasticsearch_properties.port
    cpu                    = 256
    memory                 = 2048
    load_balancer_required = false
    environment_variables = [
      { name : "KAFKA_ZOOKEEPER_CONNECT", value : var.kafka_properties.kafka_zookeeper_connect },
      { name : "KAFKA_BOOTSTRAP_SERVER", value : var.kafka_properties.kafka_bootstrap_server },
    ]
    port_mappings = []
    mount_points  = []
    volumes       = []
  }
  neo4j = {
    container_name         = "neo4j"
    image_name             = "neo4j"
    image_tag              = "4.0.6"
    port                   = 7474
    cpu                    = 256
    memory                 = 2048
    load_balancer_required = true
    environment_variables = [
      { name : "NEO4J_AUTH", value : "neo4j/datahub" },
      { name : "NEO4J_dbms_default__database", value : "graph.db" },
      { name : "NEO4J_dbms_allow__upgrade", value : "true" },
    ]
    mount_points = [
      { sourceVolume : "neo4jdata", containerPath : "/data", readOnly : false }
    ]
    port_mappings = [
      { containerPort : 7474, hostPort : 7474 },
      { containerPort : 7687, hostPort : 7687 }
    ]
    volumes = ["neo4jdata"]
  }
}

resource "random_password" "datahub_secret" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}