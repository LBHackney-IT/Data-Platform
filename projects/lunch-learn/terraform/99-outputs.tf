# We make any output files clear by adding them to the 99-outputs.tf, meaning anyone can quickly check if they're consuming your module
output "values" {
  description = "Some value that we want to output, potentially to access from other Terraform modules"
  value       = module.tags.values
}
