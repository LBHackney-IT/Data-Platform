output "job_name" {
  value = aws_glue_job.xlsx_import.id
}

output "job_arn" {
  value = aws_glue_job.xlsx_import.arn
}
