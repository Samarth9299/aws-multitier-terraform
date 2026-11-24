output "app_url" {
  description = "Open this in a browser (takes 2-3 minutes after apply for instances to pass health checks)"
  value       = "http://${module.compute.alb_dns_name}"
}

output "vpc_id" {
  value = module.vpc.vpc_id
}

output "public_subnet_ids" {
  value = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  value = module.vpc.private_subnet_ids
}

output "asg_name" {
  value = module.compute.asg_name
}

output "config_bucket" {
  value = module.iam.config_bucket
}
