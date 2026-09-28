variable "web_subnet_ids" {
  type = list(string)
}

variable "app_subnet_ids" {
  type = list(string)
}

variable "web_ec2_sg_id" {
  type = string
}

variable "app_ec2_sg_id" {
  type = string
}

variable "web_instance_profile_name" {
  type = string
}

variable "app_instance_profile_name" {
  type = string
}

variable "web_target_group_arn" {
  type = string
}

variable "app_target_group_arn" {
  type = string
}

variable "app_alb_dns_name" {
  type = string
}

variable "web_instance_type" {
  type = string
}

variable "app_instance_type" {
  type = string
}

variable "db_endpoint" {
  type = string
}

variable "rds_secret_arn" {
  type = string
}