include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../../modules/networking"
}

inputs = {
  vpc_cidr = "10.30.0.0/16"

  az_a = "us-east-1a"
  az_b = "us-east-1b"

  public_a_cidr = "10.30.0.0/24"
  public_b_cidr = "10.30.1.0/24"

  web_a_cidr = "10.30.10.0/24"
  web_b_cidr = "10.30.11.0/24"

  app_a_cidr = "10.30.20.0/24"
  app_b_cidr = "10.30.21.0/24"

  db_a_cidr = "10.30.30.0/24"
  db_b_cidr = "10.30.31.0/24"
}