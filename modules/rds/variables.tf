variable "db_subnet_ids" {
  type = list(string)
}

variable "rds_security_group_id" {
  type = string
}

variable "db_identifier" {
  type = string
}

variable "master_username" {
  type = string
}

variable "instance_class" {
  type = string
}