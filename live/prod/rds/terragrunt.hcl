include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../../modules/rds"
}

dependency "networking" {
  config_path = "../networking"
}

dependency "security" {
  config_path = "../security"
}

inputs = {
  db_subnet_ids         = dependency.networking.outputs.db_subnet_ids
  rds_security_group_id = dependency.security.outputs.rds_sg_id

  db_identifier   = "three-tier-prod-mysql"
  master_username = "dbadmin"
  instance_class  = "db.t4g.micro"
}