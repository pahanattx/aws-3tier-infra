resource "aws_lb" "web" {
  name               = "three-tier-web-alb"
  internal           = true
  load_balancer_type = "application"

  security_groups = [var.web_alb_sg_id]
  subnets         = var.web_subnet_ids

  enable_deletion_protection = false
  drop_invalid_header_fields = true

  tags = {
    Name = "three-tier-web-alb"
    Tier = "web"
  }
}

resource "aws_lb_target_group" "web" {
  name        = "three-tier-web-tg"
  port        = 80
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = var.vpc_id

  health_check {
    enabled             = true
    protocol            = "HTTP"
    path                = "/"
    matcher             = "200-399"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = {
    Name = "three-tier-web-tg"
    Tier = "web"
  }
}

resource "aws_lb_listener" "web" {
  load_balancer_arn = aws_lb.web.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web.arn
  }
}

resource "aws_lb" "app" {
  name               = "three-tier-app-alb"
  internal           = true
  load_balancer_type = "application"

  security_groups = [var.app_alb_sg_id]
  subnets         = var.app_subnet_ids

  enable_deletion_protection = false
  drop_invalid_header_fields = true

  tags = {
    Name = "three-tier-app-alb"
    Tier = "application"
  }
}

resource "aws_lb_target_group" "app" {
  name        = "three-tier-app-tg"
  port        = 4000
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = var.vpc_id

  health_check {
    enabled             = true
    protocol            = "HTTP"
    path                = "/health"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = {
    Name = "three-tier-app-tg"
    Tier = "application"
  }
}

resource "aws_lb_listener" "app" {
  load_balancer_arn = aws_lb.app.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}