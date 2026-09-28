data "aws_vpc" "main" {
  cidr_block = var.vpc_cidr
}

data "aws_subnet" "web_a" {
  vpc_id     = data.aws_vpc.main.id
  cidr_block = var.web_subnet_a_cidr
}

data "aws_subnet" "web_b" {
  vpc_id     = data.aws_vpc.main.id
  cidr_block = var.web_subnet_b_cidr
}

data "aws_lb" "web" {
  name = var.web_alb_name
}

data "aws_lb_listener" "web_http" {
  load_balancer_arn = data.aws_lb.web.arn
  port              = 80
}

resource "aws_security_group" "vpc_link" {
  name        = "three-tier-api-vpc-link-sg"
  description = "API Gateway VPC Link to private Web ALB"
  vpc_id      = data.aws_vpc.main.id

  tags = {
    Name = "three-tier-api-vpc-link-sg"
    Tier = "edge"
  }
}

resource "aws_vpc_security_group_egress_rule" "vpc_link_to_web_alb" {
  security_group_id            = aws_security_group.vpc_link.id
  referenced_security_group_id = one(data.aws_lb.web.security_groups)

  ip_protocol = "tcp"
  from_port   = 80
  to_port     = 80

  description = "Allow VPC Link to private Web ALB on HTTP"
}

resource "aws_vpc_security_group_ingress_rule" "web_alb_from_vpc_link" {
  security_group_id            = one(data.aws_lb.web.security_groups)
  referenced_security_group_id = aws_security_group.vpc_link.id

  ip_protocol = "tcp"
  from_port   = 80
  to_port     = 80

  description = "Allow API Gateway VPC Link to private Web ALB"
}

resource "aws_apigatewayv2_vpc_link" "web" {
  name = "three-tier-web-vpc-link"

  security_group_ids = [
    aws_security_group.vpc_link.id
  ]

  subnet_ids = [
    data.aws_subnet.web_a.id,
    data.aws_subnet.web_b.id
  ]

  tags = {
    Name = "three-tier-web-vpc-link"
    Tier = "edge"
  }
}

resource "aws_apigatewayv2_api" "web" {
  name          = "three-tier-teamops-http-api"
  protocol_type = "HTTP"

  tags = {
    Name = "three-tier-teamops-http-api"
    Tier = "edge"
  }
}

resource "aws_apigatewayv2_integration" "web" {
  api_id = aws_apigatewayv2_api.web.id

  integration_type   = "HTTP_PROXY"
  integration_method = "ANY"
  integration_uri    = data.aws_lb_listener.web_http.arn

  connection_type = "VPC_LINK"
  connection_id   = aws_apigatewayv2_vpc_link.web.id

  payload_format_version = "1.0"
  timeout_milliseconds   = 30000

  request_parameters = {
    "overwrite:path" = "$request.path"
  }
}

resource "aws_apigatewayv2_route" "default" {
  api_id    = aws_apigatewayv2_api.web.id
  route_key = "$default"
  target    = "integrations/${aws_apigatewayv2_integration.web.id}"
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.web.id
  name        = "$default"
  auto_deploy = true

  tags = {
    Name = "three-tier-teamops-default-stage"
    Tier = "edge"
  }
}
