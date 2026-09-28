include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../../modules/security"
}

dependency "networking" {
  config_path = "../networking"
}

inputs = {
  vpc_id = dependency.networking.outputs.vpc_id
}