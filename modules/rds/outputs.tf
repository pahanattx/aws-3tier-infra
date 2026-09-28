output "db_instance_id" {
  value = aws_db_instance.main.id
}

output "db_endpoint" {
  value = aws_db_instance.main.address
}

output "db_port" {
  value = aws_db_instance.main.port
}

output "master_user_secret_arn" {
  value = aws_db_instance.main.master_user_secret[0].secret_arn
}

output "db_subnet_group_name" {
  value = aws_db_subnet_group.main.name
}

output "db_instance_identifier" {
  value = aws_db_instance.main.identifier
}