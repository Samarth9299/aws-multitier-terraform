terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Remote state in S3 with DynamoDB locking.
  # Values come from backend.hcl:  terraform init -backend-config=backend.hcl
  backend "s3" {}
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = local.tags
  }
}

locals {
  name = "${var.project}-${var.environment}"
  tags = {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
  }

  user_data = templatefile("${path.module}/../../scripts/user_data.sh", { project_name = "${var.project}-${var.environment}" })
}

module "vpc" {
  source   = "../../modules/vpc"
  name     = local.name
  vpc_cidr = var.vpc_cidr
  az_count = var.az_count
  tags     = local.tags
}

module "security" {
  source            = "../../modules/security"
  name              = local.name
  vpc_id            = module.vpc.vpc_id
  app_port          = 80
  allowed_http_cidr = var.allowed_http_cidr
  tags              = local.tags
}

module "iam" {
  source = "../../modules/iam"
  name   = local.name
  tags   = local.tags
}

module "compute" {
  source                = "../../modules/compute"
  name                  = local.name
  vpc_id                = module.vpc.vpc_id
  public_subnet_ids     = module.vpc.public_subnet_ids
  private_subnet_ids    = module.vpc.private_subnet_ids
  alb_sg_id             = module.security.alb_sg_id
  app_sg_id             = module.security.app_sg_id
  instance_profile_name = module.iam.instance_profile_name
  instance_type         = var.instance_type
  min_size              = var.min_size
  max_size              = var.max_size
  desired_capacity      = var.desired_capacity
  user_data             = local.user_data
  tags                  = local.tags
}
