output "web_alb_sg_id" {
  value = aws_security_group.web_alb.id
}

output "web_ec2_sg_id" {
  value = aws_security_group.web_ec2.id
}

output "app_alb_sg_id" {
  value = aws_security_group.app_alb.id
}

output "app_ec2_sg_id" {
  value = aws_security_group.app_ec2.id
}

output "rds_sg_id" {
  value = aws_security_group.rds.id
}

output "vpc_endpoints_sg_id" {
  value = aws_security_group.vpc_endpoints.id
}