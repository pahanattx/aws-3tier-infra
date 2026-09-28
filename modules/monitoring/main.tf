resource "aws_cloudwatch_dashboard" "teamops" {
  dashboard_name = "three-tier-teamops-observability"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "text"
        x      = 0
        y      = 0
        width  = 24
        height = 2

        properties = {
          markdown = "# TeamOps 3-Tier AWS Observability\nWeb, Application, Load Balancer and RDS health"
        }
      },

      {
        type   = "metric"
        x      = 0
        y      = 2
        width  = 12
        height = 6

        properties = {
          title   = "Auto Scaling - In-Service vs Desired"
          region  = "us-east-1"
          period  = 60
          stat    = "Average"
          view    = "timeSeries"

          metrics = [
            [
              "AWS/AutoScaling",
              "GroupInServiceInstances",
              "AutoScalingGroupName",
              var.web_asg_name,
              {
                label = "Web In-Service"
              }
            ],
            [
              ".",
              "GroupDesiredCapacity",
              ".",
              var.web_asg_name,
              {
                label = "Web Desired"
              }
            ],
            [
              ".",
              "GroupInServiceInstances",
              ".",
              var.app_asg_name,
              {
                label = "App In-Service"
              }
            ],
            [
              ".",
              "GroupDesiredCapacity",
              ".",
              var.app_asg_name,
              {
                label = "App Desired"
              }
            ]
          ]
        }
      },

      {
        type   = "metric"
        x      = 12
        y      = 2
        width  = 12
        height = 6

        properties = {
          title   = "ALB Healthy Targets"
          region  = "us-east-1"
          period  = 60
          stat    = "Average"
          view    = "timeSeries"

          metrics = [
            [
              "AWS/ApplicationELB",
              "HealthyHostCount",
              "TargetGroup",
              var.web_target_group_arn_suffix,
              "LoadBalancer",
              var.web_alb_arn_suffix,
              {
                label = "Web Healthy Targets"
              }
            ],
            [
              "AWS/ApplicationELB",
              "HealthyHostCount",
              "TargetGroup",
              var.app_target_group_arn_suffix,
              "LoadBalancer",
              var.app_alb_arn_suffix,
              {
                label = "App Healthy Targets"
              }
            ]
          ]
        }
      },

      {
        type   = "metric"
        x      = 0
        y      = 8
        width  = 12
        height = 6

        properties = {
          title   = "ALB Target Response Time"
          region  = "us-east-1"
          period  = 60
          stat    = "Average"
          view    = "timeSeries"

          metrics = [
            [
              "AWS/ApplicationELB",
              "TargetResponseTime",
              "LoadBalancer",
              var.web_alb_arn_suffix,
              {
                label = "Web Target Response Time"
              }
            ],
            [
              "AWS/ApplicationELB",
              "TargetResponseTime",
              "LoadBalancer",
              var.app_alb_arn_suffix,
              {
                label = "App Target Response Time"
              }
            ]
          ]
        }
      },

      {
        type   = "metric"
        x      = 12
        y      = 8
        width  = 12
        height = 6

        properties = {
          title   = "RDS CPU Utilization"
          region  = "us-east-1"
          period  = 60
          stat    = "Average"
          view    = "timeSeries"

          metrics = [
            [
              "AWS/RDS",
              "CPUUtilization",
              "DBInstanceIdentifier",
              var.db_instance_id
            ]
          ]

          yAxis = {
            left = {
              min = 0
              max = 100
            }
          }
        }
      },

      {
        type   = "metric"
        x      = 0
        y      = 14
        width  = 12
        height = 6

        properties = {
          title   = "RDS Database Connections"
          region  = "us-east-1"
          period  = 60
          stat    = "Average"
          view    = "timeSeries"

          metrics = [
            [
              "AWS/RDS",
              "DatabaseConnections",
              "DBInstanceIdentifier",
              var.db_instance_id
            ]
          ]
        }
      },

      {
        type   = "metric"
        x      = 12
        y      = 14
        width  = 12
        height = 6

        properties = {
          title   = "RDS Free Storage Space"
          region  = "us-east-1"
          period  = 60
          stat    = "Average"
          view    = "timeSeries"

          metrics = [
            [
              "AWS/RDS",
              "FreeStorageSpace",
              "DBInstanceIdentifier",
              var.db_instance_id
            ]
          ]
        }
      }
    ]
  })
}

   
# =========================================================
# CLOUDWATCH ALARMS
# =========================================================

resource "aws_cloudwatch_metric_alarm" "web_unhealthy_targets" {
  alarm_name        = "three-tier-web-unhealthy-targets"
  alarm_description = "Detects unhealthy targets in the Web tier target group."

  namespace   = "AWS/ApplicationELB"
  metric_name = "UnHealthyHostCount"
  statistic   = "Maximum"

  period              = 60
  evaluation_periods  = 2
  datapoints_to_alarm = 2

  threshold           = 1
  comparison_operator = "GreaterThanOrEqualToThreshold"

  dimensions = {
    LoadBalancer = var.web_alb_arn_suffix
    TargetGroup  = var.web_target_group_arn_suffix
  }

  treat_missing_data = "notBreaching"
}

resource "aws_cloudwatch_metric_alarm" "app_unhealthy_targets" {
  alarm_name        = "three-tier-app-unhealthy-targets"
  alarm_description = "Detects unhealthy targets in the Application tier target group."

  namespace   = "AWS/ApplicationELB"
  metric_name = "UnHealthyHostCount"
  statistic   = "Maximum"

  period              = 60
  evaluation_periods  = 2
  datapoints_to_alarm = 2

  threshold           = 1
  comparison_operator = "GreaterThanOrEqualToThreshold"

  dimensions = {
    LoadBalancer = var.app_alb_arn_suffix
    TargetGroup  = var.app_target_group_arn_suffix
  }

  treat_missing_data = "notBreaching"
}

resource "aws_cloudwatch_metric_alarm" "rds_high_cpu" {
  alarm_name        = "three-tier-rds-high-cpu"
  alarm_description = "Detects sustained high CPU utilization on the TeamOps RDS instance."

  namespace   = "AWS/RDS"
  metric_name = "CPUUtilization"
  statistic   = "Average"

  period              = 300
  evaluation_periods  = 2
  datapoints_to_alarm = 2

  threshold           = 80
  comparison_operator = "GreaterThanOrEqualToThreshold"

  dimensions = {
    DBInstanceIdentifier = var.db_instance_id
  }

  treat_missing_data = "notBreaching"
}

resource "aws_cloudwatch_metric_alarm" "rds_low_free_storage" {
  alarm_name        = "three-tier-rds-low-free-storage"
  alarm_description = "Detects when TeamOps RDS free storage falls below 5 GiB."

  namespace   = "AWS/RDS"
  metric_name = "FreeStorageSpace"
  statistic   = "Average"

  period              = 300
  evaluation_periods  = 2
  datapoints_to_alarm = 2

  threshold           = 5368709120
  comparison_operator = "LessThanThreshold"

  dimensions = {
    DBInstanceIdentifier = var.db_instance_id
  }

  treat_missing_data = "notBreaching"
}