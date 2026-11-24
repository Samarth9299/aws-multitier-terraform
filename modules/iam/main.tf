# Least-privilege role for the app instances:
# - SSM core permissions (Session Manager access instead of SSH keys)
# - read-only access to ONE S3 prefix for app config
# Nothing else.

data "aws_iam_policy_document" "assume_ec2" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "app" {
  name               = "${var.name}-app-role"
  assume_role_policy = data.aws_iam_policy_document.assume_ec2.json
  tags               = var.tags
}

resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.app.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_s3_bucket" "config" {
  bucket_prefix = "${var.name}-config-"
  force_destroy = true
  tags          = var.tags
}

resource "aws_s3_bucket_public_access_block" "config" {
  bucket                  = aws_s3_bucket.config.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

data "aws_iam_policy_document" "read_config" {
  statement {
    sid       = "ReadAppConfigOnly"
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.config.arn}/app/*"]
  }
}

resource "aws_iam_role_policy" "read_config" {
  name   = "read-app-config"
  role   = aws_iam_role.app.id
  policy = data.aws_iam_policy_document.read_config.json
}

resource "aws_iam_instance_profile" "app" {
  name = "${var.name}-app-profile"
  role = aws_iam_role.app.name
}
