include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../../modules/monitoring"
}

dependency "compute" {
  config_path = "../compute"
}

dependency "alb" {
  config_path = "../alb"
}

dependency "rds" {
  config_path = "../rds"
}

inputs = {
  web_asg_name = dependency.compute.outputs.web_asg_name
  app_asg_name = dependency.compute.outputs.app_asg_name

  web_alb_arn_suffix          = dependency.alb.outputs.web_alb_arn_suffix
  web_target_group_arn_suffix = dependency.alb.outputs.web_target_group_arn_suffix

  app_alb_arn_suffix          = dependency.alb.outputs.app_alb_arn_suffix
  app_target_group_arn_suffix = dependency.alb.outputs.app_target_group_arn_suffix

  db_instance_id = dependency.rds.outputs.db_instance_identifier
}