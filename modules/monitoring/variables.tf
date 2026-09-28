variable "web_asg_name" {
  type = string
}

variable "app_asg_name" {
  type = string
}

variable "web_alb_arn_suffix" {
  type = string
}

variable "web_target_group_arn_suffix" {
  type = string
}

variable "app_alb_arn_suffix" {
  type = string
}

variable "app_target_group_arn_suffix" {
  type = string
}

variable "db_instance_id" {
  type = string
}