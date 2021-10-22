output "crawler_name" {
  value = aws_glue_crawler.crawler == null ? null : aws_glue_crawler.crawler[0].name
}