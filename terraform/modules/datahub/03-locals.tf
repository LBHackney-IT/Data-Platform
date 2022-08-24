locals {
  datahub_version = "v0.8.32"
  datahub_frontend_react = {
    container_name          = "datahub-frontend-react"
    image_name              = "linkedin/datahub-frontend-react"
    image_tag               = local.datahub_version
    port                    = 9002
    cpu                     = 2048
    memory                  = 8192
    load_balancer_required  = true
    standalone_onetime_task = false
    environment_variables = [
      { name : "PORT", value : "9002" },
      { name : "DATAHUB_GMS_HOST", value : aws_alb.datahub_gms.dns_name },
      { name : "DATAHUB_GMS_PORT", value : "8080" },
      { name : "DATAHUB_APP_VERSION", value : "1.0" },
      { name : "DATAHUB_PLAY_MEM_BUFFER_SIZE", value : "10MB" },
      { name : "JAVA_OPTS", value : "-Xms8g -Xmx8g -Dhttp.port=9002 -Dconfig.file=datahub-frontend/conf/application.conf -Djava.security.auth.login.config=datahub-frontend/conf/jaas.conf -Dlogback.configurationFile=datahub-frontend/conf/logback.xml -Dlogback.debug=false -Dpidfile.path=/dev/null" },
      { name : "KAFKA_BOOTSTRAP_SERVER", value : var.kafka_properties.kafka_bootstrap_server },
      { name : "SPRING_KAFKA_PROPERTIES_SECURITY_PROTOCOL", value : "SSL" },
      { name : "DATAHUB_TRACKING_TOPIC", value : "DataHubUsageEvent_v1" },
      { name : "ELASTIC_CLIENT_HOST", value : aws_elasticsearch_domain.es.endpoint },
      { name : "ELASTIC_CLIENT_PORT", value : "443" },
      { name : "AUTH_OIDC_ENABLED", value : var.is_live_environment },
      { name : "AUTH_OIDC_DISCOVERY_URI", value : "https://accounts.google.com/.well-known/openid-configuration" },
      { name : "AUTH_OIDC_BASE_URL", value : var.datahub_url },
      { name : "AUTH_OIDC_SCOPE", value : "openid profile email" },
      { name : "AUTH_OIDC_USER_NAME_CLAIM", value : "email" },
      { name : "AUTH_OIDC_USER_NAME_CLAIM_REGEX", value : "([^@]+)" },
      { name : "DATAHUB_ANALYTICS_ENABLED", value : "false" },
      { name : "AUTH_JAAS_ENABLED", value : "false" }
    ]
    secrets = [
      { name : "DATAHUB_SECRET", valueFrom : aws_ssm_parameter.datahub_password.arn },
      { name : "AUTH_OIDC_CLIENT_ID", valueFrom : data.aws_ssm_parameter.datahub_google_client_id.arn },
      { name : "AUTH_OIDC_CLIENT_SECRET", valueFrom : data.aws_ssm_parameter.datahub_google_client_secret.arn },
    ]
    port_mappings = [
      { containerPort : 9002, hostPort : 9002, protocol : "tcp" }
    ]
    mount_points = []
    volumes      = []
  }
  datahub_gms = {
    container_name          = "datahub-gms"
    image_name              = "linkedin/datahub-gms"
    image_tag               = local.datahub_version
    port                    = 8080
    cpu                     = 2048
    memory                  = 8192
    load_balancer_required  = true
    standalone_onetime_task = false
    environment_variables = [
      { name : "DATASET_ENABLE_SCSI", value : "false" },
      { name : "EBEAN_DATASOURCE_USERNAME", value : aws_db_instance.datahub.username },
      { name : "EBEAN_DATASOURCE_HOST", value : aws_db_instance.datahub.endpoint },
      { name : "EBEAN_DATASOURCE_URL", value : "jdbc:mysql://${aws_db_instance.datahub.endpoint}/${aws_db_instance.datahub.identifier}?verifyServerCertificate=false&useSSL=true&useUnicode=yes&characterEncoding=UTF-8" },
      { name : "EBEAN_DATASOURCE_DRIVER", value : "com.mysql.jdbc.Driver" },
      { name : "KAFKA_BOOTSTRAP_SERVER", value : var.kafka_properties.kafka_bootstrap_server },
      { name : "KAFKA_SCHEMAREGISTRY_URL", value : var.schema_registry_properties.schema_registry_url },
      { name : "SPRING_KAFKA_PROPERTIES_SECURITY_PROTOCOL", value : "SSL" },
      { name : "ELASTICSEARCH_HOST", value : aws_elasticsearch_domain.es.endpoint },
      { name : "ELASTICSEARCH_PORT", value : "443" },
      { name : "ELASTICSEARCH_USE_SSL", value : "true" },
      { name : "ELASTICSEARCH_SSL_PROTOCOL", value : "TLSv1.2" },
      { name : "GRAPH_SERVICE_IMPL", value : "elasticsearch" },
      { name : "PE_CONSUMER_ENABLED", value : "true" },
      { name : "JAVA_OPTS", value : "-Xms8g -Xmx8g" },
      { name : "ENTITY_REGISTRY_CONFIG_PATH", value : "/datahub/datahub-gms/resources/entity-registry.yml" },
      { name : "MAE_CONSUMER_ENABLED", value : "true" },
      { name : "MCE_CONSUMER_ENABLED", value : "true" },
      { name : "UI_INGESTION_ENABLED", value : "true" },
      { name : "UI_INGESTION_DEFAULT_CLI_VERSION", value : "0.8.26.6" },
    ]
    secrets = [
      { name : "EBEAN_DATASOURCE_PASSWORD", valueFrom : aws_ssm_parameter.datahub_rds_password.arn },
    ]
    port_mappings = [
      { containerPort : 8080, hostPort : 8080, protocol : "tcp" }
    ]
    mount_points = []
    volumes      = []
  }
  datahub_mae_consumer = {
    container_name          = "datahub-mae-consumer"
    image_name              = "linkedin/datahub-mae-consumer"
    image_tag               = local.datahub_version
    port                    = 9090
    cpu                     = 2048
    memory                  = 8192
    load_balancer_required  = false
    standalone_onetime_task = false
    environment_variables = [
      { name : "MAE_CONSUMER_ENABLED", value : "true" },
      { name : "PE_CONSUMER_ENABLED", value : "true" },
      { name : "KAFKA_BOOTSTRAP_SERVER", value : var.kafka_properties.kafka_bootstrap_server },
      { name : "KAFKA_SCHEMAREGISTRY_URL", value : var.schema_registry_properties.schema_registry_url },
      { name : "SPRING_KAFKA_PROPERTIES_SECURITY_PROTOCOL", value : "SSL" },
      { name : "ELASTICSEARCH_HOST", value : aws_elasticsearch_domain.es.endpoint },
      { name : "ELASTICSEARCH_PORT", value : "443" },
      { name : "ELASTICSEARCH_USE_SSL", value : "true" },
      { name : "ELASTICSEARCH_SSL_PROTOCOL", value : "TLSv1.2" },
      { name : "GMS_HOST", value : aws_alb.datahub_gms.dns_name },
      { name : "GMS_PORT", value : "8080" },
      { name : "GRAPH_SERVICE_IMPL", value : "elasticsearch" },
      { name : "ENTITY_REGISTRY_CONFIG_PATH", value : "/datahub/datahub-mae-consumer/resources/entity-registry.yml" },
    ]
    secrets = []
    port_mappings = [
      { containerPort : 9090, hostPort : 9090, protocol : "tcp" }
    ]
    mount_points = []
    volumes      = []
  }
  datahub_mce_consumer = {
    container_name          = "datahub-mce-consumer"
    image_name              = "linkedin/datahub-mce-consumer"
    image_tag               = local.datahub_version
    port                    = 9090
    cpu                     = 2048
    memory                  = 8192
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
    secrets = []
    port_mappings = [
      { containerPort : 9090, hostPort : 9090, protocol : "tcp" }
    ]
    mount_points = []
    volumes      = []
  }
  datahub_actions = {
    container_name          = "datahub-actions"
    image_name              = "acryldata/acryl-datahub-actions"
    image_tag               = "head"
    port                    = 80
    cpu                     = 2048
    memory                  = 8192
    standalone_onetime_task = false
    load_balancer_required  = false
    environment_variables = [
      { name : "GMS_HOST", value : aws_alb.datahub_gms.dns_name },
      { name : "GMS_PORT", value : "8080" },
      { name : "KAFKA_BOOTSTRAP_SERVER", value : var.kafka_properties.kafka_bootstrap_server },
      { name : "SCHEMA_REGISTRY_URL", value : var.schema_registry_properties.schema_registry_url },
      { name : "METADATA_AUDIT_EVENT_NAME", value : "MetadataAuditEvent_v4" },
      { name : "METADATA_CHANGE_LOG_VERSIONED_TOPIC_NAME", value : "MetadataChangeLog_Versioned_v1" },
      { name : "DATAHUB_SYSTEM_CLIENT_ID", value : "__datahub_system" },
      { name : "KAFKA_PROPERTIES_SECURITY_PROTOCOL", value : "SSL" },
      { name : "AWS_DEFAULT_REGION", value : data.aws_region.current.name },
      { name : "AWS_ROLE", value : aws_iam_role.datahub_role.arn },
      { name : "GLUE_EXTRACT_TRANSFORMS", value : "false" },
      { name : "GMS_URL", value : "http://${aws_alb.datahub_gms.dns_name}:8080" }
    ]
    secrets = [
      { name : "DATAHUB_SYSTEM_CLIENT_SECRET", valueFrom : aws_ssm_parameter.datahub_password.arn },
      { name : "AWS_ACCESS_KEY_ID", valueFrom : aws_ssm_parameter.datahub_aws_access_key_id.arn },
      { name : "AWS_SECRET_ACCESS_KEY", valueFrom : aws_ssm_parameter.datahub_aws_secret_access_key.arn },
    ]
    port_mappings = []
    mount_points  = []
    volumes       = []
  }
  mysql_setup = {
    container_name          = "mysql-setup"
    image_name              = "acryldata/datahub-mysql-setup"
    image_tag               = local.datahub_version
    port                    = 3306
    cpu                     = 256
    memory                  = 2048
    load_balancer_required  = false
    standalone_onetime_task = true
    environment_variables = [
      { name : "MYSQL_HOST", value : aws_db_instance.datahub.address },
      { name : "MYSQL_PORT", value : aws_db_instance.datahub.port },
      { name : "MYSQL_USERNAME", value : aws_db_instance.datahub.username },
      { name : "DATAHUB_DB_NAME", value : aws_db_instance.datahub.identifier },
    ]
    secrets = [
      { name : "MYSQL_PASSWORD", valueFrom : aws_ssm_parameter.datahub_rds_password.arn },
    ]
    port_mappings = []
    mount_points  = []
    volumes       = []
  }
  elasticsearch_setup = {
    container_name          = "elasticsearch-setup"
    image_name              = "linkedin/datahub-elasticsearch-setup"
    image_tag               = local.datahub_version
    port                    = 443
    cpu                     = 256
    memory                  = 2048
    load_balancer_required  = false
    standalone_onetime_task = true
    environment_variables = [
      { name : "ELASTICSEARCH_HOST", value : aws_elasticsearch_domain.es.endpoint },
      { name : "ELASTICSEARCH_PORT", value : "443" },
      { name : "ELASTICSEARCH_USE_SSL", value : "true" },
      { name : "ELASTICSEARCH_SSL_PROTOCOL", value : "TLSv1.2" },
      { name : "USE_AWS_ELASTICSEARCH", value : "true" },
    ]
    secrets       = []
    port_mappings = []
    mount_points  = []
    volumes       = []
  }
  kafka_setup = {
    container_name          = "kafka-setup"
    image_name              = "linkedin/datahub-kafka-setup"
    image_tag               = local.datahub_version
    port                    = 443
    cpu                     = 256
    memory                  = 2048
    load_balancer_required  = false
    standalone_onetime_task = true
    environment_variables = [
      { name : "KAFKA_ZOOKEEPER_CONNECT", value : var.kafka_properties.kafka_zookeeper_connect },
      { name : "KAFKA_BOOTSTRAP_SERVER", value : var.kafka_properties.kafka_bootstrap_server },
      # This must be "ssl" in lower case. The kafka-setup container overrides the default SSL properties when "SSL" is provided.
      # To get around this we set this to lower case, the defaults are then not overridden and the container can connect to kafka using SSL correctly
      # Kafka-setup container problem code: https://github.com/datahub-project/datahub/blob/master/docker/kafka-setup/kafka-setup.sh#L14-L21
      { name : "KAFKA_PROPERTIES_SECURITY_PROTOCOL", value : "ssl" },
      { name : "PLATFORM_EVENT_TOPIC_NAME", value : "PlatformEvent_v1" }
    ]
    secrets       = []
    port_mappings = []
    mount_points  = []
    volumes       = []
  }
}
