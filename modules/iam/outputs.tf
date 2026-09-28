output "web_instance_profile_name" {
  value = aws_iam_instance_profile.web_ec2.name
}

output "app_instance_profile_name" {
  value = aws_iam_instance_profile.app_ec2.name
}

output "web_role_name" {
  value = aws_iam_role.web_ec2.name
}

output "app_role_name" {
  value = aws_iam_role.app_ec2.name
}