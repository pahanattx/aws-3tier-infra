include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../../modules/compute"
}

dependency "networking" {
  config_path = "../networking"
}

dependency "security" {
  config_path = "../security"
}

dependency "iam" {
  config_path = "../iam"
}

dependency "alb" {
  config_path = "../alb"
}

dependency "rds" {
  config_path = "../rds"
}


inputs = {
  web_subnet_ids = dependency.networking.outputs.web_subnet_ids
  app_subnet_ids = dependency.networking.outputs.app_subnet_ids

  web_ec2_sg_id = dependency.security.outputs.web_ec2_sg_id
  app_ec2_sg_id = dependency.security.outputs.app_ec2_sg_id

  web_instance_profile_name = dependency.iam.outputs.web_instance_profile_name
  app_instance_profile_name = dependency.iam.outputs.app_instance_profile_name

  web_target_group_arn = dependency.alb.outputs.web_target_group_arn
  app_target_group_arn = dependency.alb.outputs.app_target_group_arn
  app_alb_dns_name     = dependency.alb.outputs.app_alb_dns_name

  web_instance_type = "t3.micro"
  app_instance_type = "t3.micro"

db_endpoint    = dependency.rds.outputs.db_endpoint
rds_secret_arn = dependency.rds.outputs.master_user_secret_arn
}