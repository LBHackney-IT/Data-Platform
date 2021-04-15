locals {
  environment_long = lookup({Dev="development", Stg="staging", Prod="production"}, var.environment, "unknown")
}
