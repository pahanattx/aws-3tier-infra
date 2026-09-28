output "ssm_endpoint_id" {
  value = aws_vpc_endpoint.ssm.id
}

output "ssmmessages_endpoint_id" {
  value = aws_vpc_endpoint.ssmmessages.id
}