variable "vpc_cidr" {
  type        = string
  description = "Existing TeamOps VPC CIDR"
  default     = "10.30.0.0/16"
}

variable "web_subnet_a_cidr" {
  type        = string
  description = "Existing private Web subnet A CIDR"
  default     = "10.30.10.0/24"
}

variable "web_subnet_b_cidr" {
  type        = string
  description = "Existing private Web subnet B CIDR"
  default     = "10.30.11.0/24"
}

variable "web_alb_name" {
  type        = string
  description = "Existing private Web ALB name"
  default     = "three-tier-web-alb"
}
