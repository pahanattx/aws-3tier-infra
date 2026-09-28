output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnet_ids" {
  value = [
    aws_subnet.public_a.id,
    aws_subnet.public_b.id
  ]
}

output "web_subnet_ids" {
  value = [
    aws_subnet.web_a.id,
    aws_subnet.web_b.id
  ]
}

output "app_subnet_ids" {
  value = [
    aws_subnet.app_a.id,
    aws_subnet.app_b.id
  ]
}

output "db_subnet_ids" {
  value = [
    aws_subnet.db_a.id,
    aws_subnet.db_b.id
  ]
}

output "nat_gateway_ids" {
  value = [
    aws_nat_gateway.nat_a.id,
    aws_nat_gateway.nat_b.id
  ]
}