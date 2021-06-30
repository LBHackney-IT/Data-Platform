resource "aws_kms_key" "secrets_manager_key" {
  tags = module.tags.values

  description             = "${local.identifier_prefix}-secrets-manager-key"
  deletion_window_in_days = 10
  enable_key_rotation     = true
}

resource "random_pet" "name" {
  keepers = {
    # Generate a new pet name each time we the kms key id
    kms_key_id = aws_kms_key.sheets_credentials.id
  }
}
resource "aws_kms_alias" "key_alias" {
  name          = lower("alias/${local.identifier_prefix}-secrets-manager")
  target_key_id = aws_kms_key.secrets_manager_key.key_id
}

resource "aws_secretsmanager_secret" "sheets_credentials_housing" {
  tags = module.tags.values

  // Random pet name is added here, encase you destroy the secret. Secrets will linger for around 6-7 days encase
  // recovery is required, and you will be unable to create with the same name.
  name = "${local.identifier_prefix}-sheets-credential-housing-${random_pet.name.id}"

  # Read the kms key id "through" the random_pet resource to ensure that
  # both will change together.
  kms_key_id = random_pet.name.keepers.kms_key_id
}

resource "aws_secretsmanager_secret_version" "housing_json_credentials_secret_version" {
  count         = terraform.workspace == "default" ? 1 : 0
  secret_id     = aws_secretsmanager_secret.sheets_credentials_housing.id
  secret_binary = google_service_account_key.housing_json_credentials[0].private_key
}

resource "aws_secretsmanager_secret" "redshift_cluster_parking_credentials" {
  tags = module.tags.values

  name        = "${local.identifier_prefix}-parking/redshift-cluster-parking-user"
  description = "Credentials for the redshift cluster parking user "
  kms_key_id  = aws_kms_key.secrets_manager_key.id
}
