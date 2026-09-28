variable "vpc_id" {
  type = string
}

variable "web_subnet_ids" {
  type = list(string)
}

variable "app_subnet_ids" {
  type = list(string)
}

variable "web_alb_sg_id" {
  type = string
}

variable "app_alb_sg_id" {
  type = string
}