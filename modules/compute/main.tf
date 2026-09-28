data "aws_ssm_parameter" "al2023_ami" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

# =========================================================
# WEB TIER LAUNCH TEMPLATE
# =========================================================

resource "aws_launch_template" "web" {
  name_prefix   = "three-tier-web-"
  image_id      = data.aws_ssm_parameter.al2023_ami.value
  instance_type = var.web_instance_type

  update_default_version = true

  iam_instance_profile {
    name = var.web_instance_profile_name
  }

  vpc_security_group_ids = [var.web_ec2_sg_id]

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  credit_specification {
    cpu_credits = "standard"
  }

  user_data = base64encode(templatefile(
    "${path.module}/web-user-data.sh.tftpl",
    {
      app_alb_dns_name = var.app_alb_dns_name
    }
  ))

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "three-tier-web"
      Tier = "web"
    }
  }
}

# =========================================================
# APP TIER LAUNCH TEMPLATE
# =========================================================

resource "aws_launch_template" "app" {
  name_prefix   = "three-tier-app-"
  image_id      = data.aws_ssm_parameter.al2023_ami.value
  instance_type = var.app_instance_type

  update_default_version = true

  iam_instance_profile {
    name = var.app_instance_profile_name
  }

  vpc_security_group_ids = [var.app_ec2_sg_id]

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  credit_specification {
    cpu_credits = "standard"
  }

  user_data = base64encode(templatefile(
    "${path.module}/app-user-data.sh.tftpl",
    {
      db_endpoint    = var.db_endpoint
      rds_secret_arn = var.rds_secret_arn
    }
  ))

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "three-tier-app"
      Tier = "application"
    }
  }
}

# =========================================================
# WEB AUTO SCALING GROUP
# =========================================================

resource "aws_autoscaling_group" "web" {
  name = "three-tier-web-asg"

  min_size         = 2
  max_size         = 2
  desired_capacity = 2

  metrics_granularity = "1Minute"

  enabled_metrics = [
    "GroupDesiredCapacity",
    "GroupInServiceInstances",
    "GroupPendingInstances"
  ]

  vpc_zone_identifier = var.web_subnet_ids
  target_group_arns   = [var.web_target_group_arn]

  health_check_type         = "ELB"
  health_check_grace_period = 300

  launch_template {
    id      = aws_launch_template.web.id
    version = aws_launch_template.web.latest_version
  }

  instance_refresh {
    strategy = "Rolling"

    preferences {
      min_healthy_percentage = 50
      instance_warmup        = 120
    }
  }

  tag {
    key                 = "Name"
    value               = "three-tier-web"
    propagate_at_launch = true
  }

  tag {
    key                 = "Tier"
    value               = "web"
    propagate_at_launch = true
  }
}

# =========================================================
# APP AUTO SCALING GROUP
# =========================================================

resource "aws_autoscaling_group" "app" {
  name = "three-tier-app-asg"

   min_size         = 2
  max_size         = 2
  desired_capacity = 2

  metrics_granularity = "1Minute"

  enabled_metrics = [
    "GroupDesiredCapacity",
    "GroupInServiceInstances",
    "GroupPendingInstances"
  ]

  vpc_zone_identifier = var.app_subnet_ids
  target_group_arns   = [var.app_target_group_arn]

  health_check_type         = "ELB"
  health_check_grace_period = 300

  launch_template {
    id      = aws_launch_template.app.id
    version = aws_launch_template.app.latest_version
  }

  instance_refresh {
    strategy = "Rolling"

    preferences {
      min_healthy_percentage = 50
      instance_warmup        = 120
    }
  }

  tag {
    key                 = "Name"
    value               = "three-tier-app"
    propagate_at_launch = true
  }

  tag {
    key                 = "Tier"
    value               = "application"
    propagate_at_launch = true
  }
}