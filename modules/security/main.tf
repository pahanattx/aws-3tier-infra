data "aws_ec2_managed_prefix_list" "cloudfront" {
  name = "com.amazonaws.global.cloudfront.origin-facing"
}

# --------------------------------------------------
# Security Groups
# --------------------------------------------------

resource "aws_security_group" "web_alb" {
  name        = "3tier-web-alb-sg"
  description = "Security group for private Web ALB"
  vpc_id      = var.vpc_id

  tags = {
    Name = "3tier-web-alb-sg"
  }
}

resource "aws_security_group" "web_ec2" {
  name        = "3tier-web-ec2-sg"
  description = "Security group for Web tier EC2 instances"
  vpc_id      = var.vpc_id

  tags = {
    Name = "3tier-web-ec2-sg"
  }
}

resource "aws_security_group" "app_alb" {
  name        = "3tier-app-alb-sg"
  description = "Security group for internal App ALB"
  vpc_id      = var.vpc_id

  tags = {
    Name = "3tier-app-alb-sg"
  }
}

resource "aws_security_group" "app_ec2" {
  name        = "3tier-app-ec2-sg"
  description = "Security group for App tier EC2 instances"
  vpc_id      = var.vpc_id

  tags = {
    Name = "3tier-app-ec2-sg"
  }
}

resource "aws_security_group" "rds" {
  name        = "3tier-rds-sg"
  description = "Security group for MySQL RDS"
  vpc_id      = var.vpc_id

  tags = {
    Name = "3tier-rds-sg"
  }
}

resource "aws_security_group" "vpc_endpoints" {
  name        = "3tier-vpce-sg"
  description = "Security group for interface VPC endpoints"
  vpc_id      = var.vpc_id

  tags = {
    Name = "3tier-vpce-sg"
  }
}

# --------------------------------------------------
# Inbound Rules
# --------------------------------------------------

# CloudFront -> Web ALB
resource "aws_vpc_security_group_ingress_rule" "web_alb_from_cloudfront" {
  security_group_id = aws_security_group.web_alb.id
  prefix_list_id    = data.aws_ec2_managed_prefix_list.cloudfront.id

  ip_protocol = "tcp"
  from_port   = 80
  to_port     = 80

  description = "HTTP from CloudFront origin-facing servers"
}

# Web ALB -> Web EC2
resource "aws_vpc_security_group_ingress_rule" "web_ec2_from_web_alb" {
  security_group_id            = aws_security_group.web_ec2.id
  referenced_security_group_id = aws_security_group.web_alb.id

  ip_protocol = "tcp"
  from_port   = 80
  to_port     = 80

  description = "HTTP from Web ALB"
}

# Web EC2 -> Internal App ALB
resource "aws_vpc_security_group_ingress_rule" "app_alb_from_web" {
  security_group_id            = aws_security_group.app_alb.id
  referenced_security_group_id = aws_security_group.web_ec2.id

  ip_protocol = "tcp"
  from_port   = 80
  to_port     = 80

  description = "HTTP from Web tier"
}

# Internal App ALB -> App EC2
resource "aws_vpc_security_group_ingress_rule" "app_ec2_from_app_alb" {
  security_group_id            = aws_security_group.app_ec2.id
  referenced_security_group_id = aws_security_group.app_alb.id

  ip_protocol = "tcp"
  from_port   = 4000
  to_port     = 4000

  description = "Node.js application traffic from App ALB"
}

# App EC2 -> RDS
resource "aws_vpc_security_group_ingress_rule" "rds_from_app" {
  security_group_id            = aws_security_group.rds.id
  referenced_security_group_id = aws_security_group.app_ec2.id

  ip_protocol = "tcp"
  from_port   = 3306
  to_port     = 3306

  description = "MySQL from App tier"
}

# Web EC2 -> VPC Endpoints
resource "aws_vpc_security_group_ingress_rule" "vpce_from_web" {
  security_group_id            = aws_security_group.vpc_endpoints.id
  referenced_security_group_id = aws_security_group.web_ec2.id

  ip_protocol = "tcp"
  from_port   = 443
  to_port     = 443

  description = "HTTPS from Web tier"
}

# App EC2 -> VPC Endpoints
resource "aws_vpc_security_group_ingress_rule" "vpce_from_app" {
  security_group_id            = aws_security_group.vpc_endpoints.id
  referenced_security_group_id = aws_security_group.app_ec2.id

  ip_protocol = "tcp"
  from_port   = 443
  to_port     = 443

  description = "HTTPS from App tier"
}

# --------------------------------------------------
# Outbound Rules
# --------------------------------------------------

# Web ALB -> Web EC2
resource "aws_vpc_security_group_egress_rule" "web_alb_to_web" {
  security_group_id            = aws_security_group.web_alb.id
  referenced_security_group_id = aws_security_group.web_ec2.id

  ip_protocol = "tcp"
  from_port   = 80
  to_port     = 80
}

# Web EC2 -> App ALB
resource "aws_vpc_security_group_egress_rule" "web_to_app_alb" {
  security_group_id            = aws_security_group.web_ec2.id
  referenced_security_group_id = aws_security_group.app_alb.id

  ip_protocol = "tcp"
  from_port   = 80
  to_port     = 80
}

# Web EC2 HTTPS outbound for SSM/package access
resource "aws_vpc_security_group_egress_rule" "web_https" {
  security_group_id = aws_security_group.web_ec2.id
  cidr_ipv4         = "0.0.0.0/0"

  ip_protocol = "tcp"
  from_port   = 443
  to_port     = 443
}

# App ALB -> App EC2
resource "aws_vpc_security_group_egress_rule" "app_alb_to_app" {
  security_group_id            = aws_security_group.app_alb.id
  referenced_security_group_id = aws_security_group.app_ec2.id

  ip_protocol = "tcp"
  from_port   = 4000
  to_port     = 4000
}

# App EC2 -> RDS
resource "aws_vpc_security_group_egress_rule" "app_to_rds" {
  security_group_id            = aws_security_group.app_ec2.id
  referenced_security_group_id = aws_security_group.rds.id

  ip_protocol = "tcp"
  from_port   = 3306
  to_port     = 3306
}

# App EC2 HTTPS outbound for SSM/package access
resource "aws_vpc_security_group_egress_rule" "app_https" {
  security_group_id = aws_security_group.app_ec2.id
  cidr_ipv4         = "0.0.0.0/0"

  ip_protocol = "tcp"
  from_port   = 443
  to_port     = 443
}