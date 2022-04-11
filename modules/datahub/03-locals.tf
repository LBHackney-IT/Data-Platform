locals {
  datahub_frontend_react = {
    container_name          = "datahub-frontend-react"
    image_name              = "linkedin/datahub-frontend-react"
    image_tag               = "latest"
    port                    = 9002
    cpu                     = 256
    memory                  = 2048
    load_balancer_required  = true
    standalone_onetime_task = false
    environment_variables = [
      { name : "PORT", value : "9002" },
      { name : "DATAHUB_GMS_HOST", value : aws_alb.datahub_gms.dns_name },
      { name : "DATAHUB_GMS_PORT", value : "8080" },
      { name : "DATAHUB_SECRET", value : random_password.datahub_secret.result },
      { name : "DATAHUB_APP_VERSION", value : "1.0" },
      { name : "DATAHUB_PLAY_MEM_BUFFER_SIZE", value : "10MB" },
      { name : "JAVA_OPTS", value : "-Xms2048m -Xmx2048m -Dhttp.port=9002 -Dconfig.file=datahub-frontend/conf/application.conf -Djava.security.auth.login.config=datahub-frontend/conf/jaas.conf -Dlogback.configurationFile=datahub-frontend/conf/logback.xml -Dlogback.debug=false -Dpidfile.path=/dev/null" },
      { name : "KAFKA_BOOTSTRAP_SERVER", value : var.kafka_properties.kafka_bootstrap_server },
      { name : "KAFKA_PROPERTIES_SECURITY_PROTOCOL", value : "SSL" },
      { name : "DATAHUB_TRACKING_TOPIC", value : "DataHubUsageEvent_v1" },
      { name : "ELASTIC_CLIENT_HOST", value : aws_elasticsearch_domain.es.endpoint },
      { name : "ELASTIC_CLIENT_PORT", value : "80" }
    ]
    port_mappings = [
      { containerPort : 9002, hostPort : 9002 }
    ]
    mount_points = []
    volumes      = []
  }
  datahub_gms = {
    container_name          = "datahub-gms"
    image_name              = "linkedin/datahub-gms"
    image_tag               = "latest"
    port                    = 8080
    cpu                     = 512
    memory                  = 4096
    load_balancer_required  = true
    standalone_onetime_task = false
    environment_variables = [
      { name : "DATASET_ENABLE_SCSI", value : "false" },
      { name : "EBEAN_DATASOURCE_USERNAME", value : aws_db_instance.datahub.username },
      { name : "EBEAN_DATASOURCE_PASSWORD", value : aws_db_instance.datahub.password },
      { name : "EBEAN_DATASOURCE_HOST", value : aws_db_instance.datahub.endpoint },
      { name : "EBEAN_DATASOURCE_URL", value : "jdbc:mysql://${aws_db_instance.datahub.endpoint}/${aws_db_instance.datahub.identifier}" },
      { name : "EBEAN_DATASOURCE_DRIVER", value : "com.mysql.jdbc.Driver" },
      { name : "KAFKA_BOOTSTRAP_SERVER", value : var.kafka_properties.kafka_bootstrap_server },
      { name : "KAFKA_SCHEMAREGISTRY_URL", value : var.schema_registry_properties.schema_registry_url },
      { name : "SPRING_KAFKA_PROPERTIES_SECURITY_PROTOCOL", value : "SSL" },
      { name : "ELASTICSEARCH_HOST", value : aws_elasticsearch_domain.es.endpoint },
      { name : "ELASTICSEARCH_PORT", value : "80" },
      { name : "NEO4J_HOST", value : "http://${aws_alb.datahub_neo4j.dns_name}:${local.neo4j.port}" },
      { name : "NEO4J_URI", value : "bolt://${aws_alb.datahub_neo4j.dns_name}" },
      { name : "NEO4J_USERNAME", value : "neo4j" },
      { name : "NEO4J_PASSWORD", value : random_password.datahub_secret.result },
      { name : "JAVA_OPTS", value : "-Xms1g -Xmx1g" },
      { name : "GRAPH_SERVICE_IMPL", value : "neo4j" },
      { name : "ENTITY_REGISTRY_CONFIG_PATH", value : "/datahub/datahub-gms/resources/entity-registry.yml" },
      { name : "MAE_CONSUMER_ENABLED", value : "true" },
      { name : "MCE_CONSUMER_ENABLED", value : "true" },
      { name : "UI_INGESTION_ENABLED", value : "false" },
      { name : "UI_INGESTION_DEFAULT_CLI_VERSION", value : "0.8.26.6" }
    ]
    port_mappings = [
      { containerPort : 8080, hostPort : 8080 }
    ]
    mount_points = []
    volumes      = []
  }
  datahub_mae_consumer = {
    container_name          = "datahub-mae-consumer"
    image_name              = "linkedin/datahub-mae-consumer"
    image_tag               = "latest"
    port                    = 9090
    cpu                     = 512
    memory                  = 4096
    load_balancer_required  = false
    standalone_onetime_task = false
    environment_variables = [
      { name : "MAE_CONSUMER_ENABLED", value : "true" },
      { name : "PE_CONSUMER_ENABLED", value : "true" },
      { name : "KAFKA_BOOTSTRAP_SERVER", value : var.kafka_properties.kafka_bootstrap_server },
      { name : "KAFKA_SCHEMAREGISTRY_URL", value : var.schema_registry_properties.schema_registry_url },
      { name : "SPRING_KAFKA_PROPERTIES_SECURITY_PROTOCOL", value : "SSL" },
      { name : "ELASTICSEARCH_HOST", value : aws_elasticsearch_domain.es.endpoint },
      { name : "ELASTICSEARCH_PORT", value : "80" },
      { name : "NEO4J_HOST", value : "http://${aws_alb.datahub_neo4j.dns_name}:${local.neo4j.port}" },
      { name : "NEO4J_URI", value : "bolt://${aws_alb.datahub_neo4j.dns_name}" },
      { name : "NEO4J_USERNAME", value : "neo4j" },
      { name : "NEO4J_PASSWORD", value : random_password.datahub_secret.result },
      { name : "GMS_HOST", value : aws_alb.datahub_gms.dns_name },
      { name : "GMS_PORT", value : "8080" },
      { name : "GRAPH_SERVICE_IMPL", value : "neo4j" },
      { name : "ENTITY_REGISTRY_CONFIG_PATH", value : "/datahub/datahub-mae-consumer/resources/entity-registry.yml" },
    ]
    port_mappings = [
      { containerPort : 9090, hostPort : 9090 }
    ]
    mount_points = []
    volumes      = []
  }
  datahub_mce_consumer = {
    container_name          = "datahub-mce-consumer"
    image_name              = "linkedin/datahub-mce-consumer"
    image_tag               = "latest"
    port                    = 9090
    cpu                     = 512
    memory                  = 4096
    load_balancer_required  = false
    standalone_onetime_task = false
    environment_variables = [
      { name : "MCE_CONSUMER_ENABLED", value : "true" },
      { name : "KAFKA_BOOTSTRAP_SERVER", value : var.kafka_properties.kafka_bootstrap_server },
      { name : "KAFKA_SCHEMAREGISTRY_URL", value : var.schema_registry_properties.schema_registry_url },
      { name : "SPRING_KAFKA_PROPERTIES_SECURITY_PROTOCOL", value : "SSL" },
      { name : "GMS_HOST", value : aws_alb.datahub_gms.dns_name },
      { name : "GMS_PORT", value : "8080" },
    ]
    port_mappings = [
      { containerPort : 9090, hostPort : 9090 }
    ]
    mount_points = []
    volumes      = []
  }
  mysql_setup = {
    container_name          = "mysql-setup"
    image_name              = "acryldata/datahub-mysql-setup"
    image_tag               = "head"
    port                    = 3306
    cpu                     = 256
    memory                  = 2048
    load_balancer_required  = false
    standalone_onetime_task = false
    environment_variables = [
      { name : "MYSQL_HOST", value : aws_db_instance.datahub.address },
      { name : "MYSQL_PORT", value : aws_db_instance.datahub.port },
      { name : "MYSQL_USERNAME", value : aws_db_instance.datahub.username },
      { name : "MYSQL_PASSWORD", value : aws_db_instance.datahub.password },
      { name : "DATAHUB_DB_NAME", value : aws_db_instance.datahub.identifier },
    ]
    port_mappings = []
    mount_points  = []
    volumes       = []
  }
  elasticsearch_setup = {
    container_name          = "elasticsearch-setup"
    image_name              = "linkedin/datahub-elasticsearch-setup"
    image_tag               = "latest"
    port                    = 443
    cpu                     = 256
    memory                  = 2048
    load_balancer_required  = false
    standalone_onetime_task = false
    environment_variables = [
      { name : "ELASTICSEARCH_HOST", value : aws_elasticsearch_domain.es.endpoint },
      { name : "ELASTICSEARCH_PORT", value : "443" },
      { name : "ELASTICSEARCH_USE_SSL", value : "true" },
      { name : "USE_AWS_ELASTICSEARCH", value : "true" }
    ]
    port_mappings = []
    mount_points  = []
    volumes       = []
  }
  kafka_setup = {
    container_name          = "kafka-setup"
    image_name              = "linkedin/datahub-kafka-setup"
    image_tag               = "head"
    port                    = 443
    cpu                     = 256
    memory                  = 2048
    load_balancer_required  = false
    standalone_onetime_task = false
    environment_variables = [
      { name : "KAFKA_ZOOKEEPER_CONNECT", value : var.kafka_properties.kafka_zookeeper_connect },
      { name : "KAFKA_BOOTSTRAP_SERVER", value : var.kafka_properties.kafka_bootstrap_server },
      # This must be "ssl" in lower case. The kafka-setup container overrides the default SSL properties when "SSL" is provided.
      # To get around this we set this to lower case, the defaults are then not overridden and the container can connect to kafka using SSL correctly
      # Kafka-setup container problem code: https://github.com/datahub-project/datahub/blob/master/docker/kafka-setup/kafka-setup.sh#L14-L21
      { name : "KAFKA_PROPERTIES_SECURITY_PROTOCOL", value : "ssl" },
      { name : "PLATFORM_EVENT_TOPIC_NAME", value : "PlatformEvent_v1" }
    ]
    port_mappings = []
    mount_points  = []
    volumes       = []
  }
  neo4j = {
    container_name          = "neo4j"
    image_name              = "neo4j"
    image_tag               = "4.0.6"
    port                    = 7474
    cpu                     = 256
    memory                  = 2048
    load_balancer_required  = true
    standalone_onetime_task = false
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