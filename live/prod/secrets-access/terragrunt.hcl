include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../../modules/secrets-access"
}

dependency "iam" {
  config_path = "../iam"
}

dependency "rds" {
  config_path = "../rds"
}

inputs = {
  app_role_name = dependency.iam.outputs.app_role_name
  rds_secret_arn = dependency.rds.outputs.master_user_secret_arn
}