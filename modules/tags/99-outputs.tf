output "values" {
  description = "Returns a map of all the tags, including custom tags"
  value       = local.tags_merged
}

output "values_no_custom" {
  description = "Returns a map of all the standard tags, without custom tags"
  value       = local.tags
}
