include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../../modules/cloudfront"
}

dependency "alb" {
  config_path = "../alb"
}

inputs = {
  web_alb_arn      = dependency.alb.outputs.web_alb_arn
  web_alb_dns_name = dependency.alb.outputs.web_alb_dns_name
}