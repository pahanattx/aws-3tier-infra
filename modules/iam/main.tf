data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

# -------------------------
# Web Tier IAM Role
# -------------------------

resource "aws_iam_role" "web_ec2" {
  name               = "3tier-web-ec2-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json
}

resource "aws_iam_role_policy_attachment" "web_ssm" {
  role       = aws_iam_role.web_ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "web_ec2" {
  name = "3tier-web-ec2-profile"
  role = aws_iam_role.web_ec2.name
}

# -------------------------
# App Tier IAM Role
# -------------------------

resource "aws_iam_role" "app_ec2" {
  name               = "3tier-app-ec2-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json
}

resource "aws_iam_role_policy_attachment" "app_ssm" {
  role       = aws_iam_role.app_ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "app_ec2" {
  name = "3tier-app-ec2-profile"
  role = aws_iam_role.app_ec2.name
}