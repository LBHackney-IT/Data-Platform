/* Different tag outputs 
*/
output "tags" {
  description = "Returns a map of all the tags, including custom tags"
  value       = local.tags_merged
}

output "tags_no_custom" {
  description = "Returns a map of all the standard tags, without custom tags"
  value       = local.tags
}
