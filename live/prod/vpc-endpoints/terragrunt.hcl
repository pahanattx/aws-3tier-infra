include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../../modules/vpc-endpoints"
}

dependency "networking" {
  config_path = "../networking"
}

dependency "security" {
  config_path = "../security"
}

inputs = {
  vpc_id            = dependency.networking.outputs.vpc_id
  subnet_ids        = dependency.networking.outputs.app_subnet_ids
  security_group_id = dependency.security.outputs.vpc_endpoints_sg_id
  aws_region        = "us-east-1"
}