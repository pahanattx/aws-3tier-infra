include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../../modules/api-gateway"
}

inputs = {
  vpc_cidr          = "10.30.0.0/16"
  web_subnet_a_cidr = "10.30.10.0/24"
  web_subnet_b_cidr = "10.30.11.0/24"
  web_alb_name      = "three-tier-web-alb"
}
