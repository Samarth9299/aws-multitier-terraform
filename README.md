# AWS Multi-Tier Infrastructure with Terraform

Reproducible AWS environment built from **modular Terraform**: a VPC with public and private subnets across two Availability Zones, an Internet Gateway and NAT Gateway, an Application Load Balancer, and an **Auto Scaling Group** of Nginx web servers in private subnets with **least-privilege IAM**. Terraform state is stored remotely in **S3 with DynamoDB locking**.

One `terraform apply` builds the whole environment in a few minutes, identically every time.

[![terraform-checks](https://github.com/Samarth9299/aws-multitier-terraform/actions/workflows/terraform.yml/badge.svg)](https://github.com/Samarth9299/aws-multitier-terraform/actions/workflows/terraform.yml)

## Architecture

```
                    Internet
                       │
                 ┌─────▼─────┐
                 │    IGW    │
                 └─────┬─────┘
   VPC 10.0.0.0/16     │
  ┌────────────────────┼──────────────────────────────┐
  │  Public subnets    │   (10.0.0.0/24, 10.0.1.0/24) │
  │   ┌────────────────▼───────────────┐   ┌───────┐  │
  │   │  Application Load Balancer :80 │   │  NAT  │  │
  │   └────────────────┬───────────────┘   └───▲───┘  │
  │  Private subnets   │  (10.0.10.0/24, 10.0.11.0/24)│
  │   ┌────────────────▼───────────────┐       │      │
  │   │ Auto Scaling Group (2-4 x EC2) │───────┘      │
  │   │ Nginx, Amazon Linux 2023       │  outbound    │
  │   └────────────────────────────────┘  via NAT     │
  └───────────────────────────────────────────────────┘

  Remote state:  S3 bucket (versioned, encrypted)  +  DynamoDB lock table
```

## What it demonstrates

| Area | Implementation |
|---|---|
| Infrastructure as Code | Reusable modules: `vpc`, `security`, `iam`, `compute` |
| Networking | 2 public + 2 private subnets, route tables, IGW, NAT Gateway |
| High availability | ALB across 2 AZs, ASG with ELB health checks and rolling instance refresh |
| Scaling | Target-tracking policy keeps average CPU around 50% (2–4 instances) |
| Security | App instances accept traffic **only from the ALB security group**, no SSH port open (access via SSM Session Manager), IMDSv2 required, IAM role limited to SSM + read-only on one S3 prefix |
| State management | S3 backend with versioning, encryption, public-access block, DynamoDB state locking |
| CI | GitHub Actions runs `terraform fmt`, `terraform validate` and ShellCheck on every push |

## Repository layout

```
bootstrap/          # one-time: S3 state bucket + DynamoDB lock table
envs/dev/           # the environment: wires the modules together
modules/
  vpc/              # VPC, subnets, IGW, NAT, route tables
  security/         # ALB + app security groups
  iam/              # least-privilege EC2 role + instance profile
  compute/          # ALB, target group, launch template, ASG, scaling policy
scripts/
  user_data.sh      # first-boot script: installs Nginx, writes /health
  deploy.sh         # init + validate + plan + apply (or --destroy)
  check_lb.sh       # shows requests being spread across instances
```

## Prerequisites

- AWS account and an IAM user/role with permission to create VPC, EC2, ELB, IAM, S3 and DynamoDB resources
- [AWS CLI](https://docs.aws.amazon.com/cli/) configured (`aws configure`)
- [Terraform](https://developer.hashicorp.com/terraform/install) 1.5 or newer

## How to run

### 1. Create the remote-state backend (once)

```bash
cd bootstrap
terraform init
terraform apply
terraform output
```

### 2. Configure the environment

```bash
cd ../envs/dev
cp backend.hcl.example backend.hcl            # paste bucket + table names from step 1
cp terraform.tfvars.example terraform.tfvars  # optional: change region, sizes, allowed IP
```

### 3. Deploy

```bash
cd ../..
./scripts/deploy.sh
```

Open the printed `app_url`. Refresh a few times, or run `./scripts/check_lb.sh`, to see different instance IDs answering.

### 4. Destroy (important – avoids charges)

```bash
./scripts/deploy.sh --destroy
```

The state bucket in `bootstrap/` is protected from deletion on purpose. To remove it too, set `force_destroy = true` in `bootstrap/main.tf`, apply, then run `terraform destroy` in `bootstrap/`.

## Cost note

The **NAT Gateway** and **ALB** are billed per hour, even on the free tier (roughly US$1–2 per day together in ap-south-1). Destroy the environment when you are done testing.

## Things I would add next

- HTTPS listener with an ACM certificate and HTTP→HTTPS redirect
- One NAT Gateway per AZ for production-grade availability
- RDS in the private subnets for a full three-tier app
- CloudWatch alarms + SNS notifications
