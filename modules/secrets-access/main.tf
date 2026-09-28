resource "aws_iam_role_policy" "rds_secret_access" {
  name = "three-tier-rds-secret-access"
  role = var.app_role_name

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = var.rds_secret_arn
      }
    ]
  })
}