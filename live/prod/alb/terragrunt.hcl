include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../../modules/alb"
}

dependency "networking" {
  config_path = "../networking"
}

dependency "security" {
  config_path = "../security"
}

inputs = {
  vpc_id         = dependency.networking.outputs.vpc_id
  web_subnet_ids = dependency.networking.outputs.web_subnet_ids
  app_subnet_ids = dependency.networking.outputs.app_subnet_ids

  web_alb_sg_id = dependency.security.outputs.web_alb_sg_id
  app_alb_sg_id = dependency.security.outputs.app_alb_sg_id
}