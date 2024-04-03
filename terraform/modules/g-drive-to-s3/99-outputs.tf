output "lambda_zip_sha256_hash" {
  description = "The SHA256 hash of the Lambda function ZIP archive."
  value       = filesha256(data.archive_file.lambda.output_path)
}
