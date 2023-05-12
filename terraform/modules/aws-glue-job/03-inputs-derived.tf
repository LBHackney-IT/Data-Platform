locals {
  job_name_identifier = replace(lower(var.job_name), "/[^a-zA-Z0-9]+/", "-")
}