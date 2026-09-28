output "vpc_origin_id" {
  value = aws_cloudfront_vpc_origin.web.id
}

output "vpc_origin_arn" {
  value = aws_cloudfront_vpc_origin.web.arn
}

output "distribution_id" {
  value = aws_cloudfront_distribution.web.id
}

output "distribution_domain_name" {
  value = aws_cloudfront_distribution.web.domain_name
}

output "distribution_status" {
  value = aws_cloudfront_distribution.web.status
}