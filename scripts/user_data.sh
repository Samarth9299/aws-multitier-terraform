#!/bin/bash
# First-boot script for the app instances (Amazon Linux 2023).
# Installs Nginx and serves a page that shows which instance answered,
# so you can watch the load balancer spread traffic across the ASG.
set -euo pipefail

dnf install -y nginx

# IMDSv2: get a session token first, then read instance metadata
TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" \
  -H "X-aws-ec2-metadata-token-ttl-seconds: 300")
meta() {
  curl -s -H "X-aws-ec2-metadata-token: $TOKEN" \
    "http://169.254.169.254/latest/meta-data/$1"
}
INSTANCE_ID=$(meta instance-id)
AZ=$(meta placement/availability-zone)
PRIVATE_IP=$(meta local-ipv4)

cat > /usr/share/nginx/html/index.html <<HTML
<!doctype html>
<html>
<head><meta charset="utf-8"><title>${project_name}</title></head>
<body style="font-family: sans-serif; margin: 40px;">
  <h1>${project_name}</h1>
  <p>Served by <b>$INSTANCE_ID</b> in <b>$AZ</b> ($PRIVATE_IP)</p>
  <p>Provisioned with Terraform: VPC, public/private subnets, NAT Gateway,
     ALB, Auto Scaling Group, least-privilege IAM.</p>
</body>
</html>
HTML

# Health-check endpoint used by the ALB target group
echo "ok" > /usr/share/nginx/html/health

systemctl enable --now nginx
