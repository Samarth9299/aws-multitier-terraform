variable "name" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "app_port" {
  description = "Port the app instances listen on"
  type        = number
  default     = 80
}

variable "allowed_http_cidr" {
  description = "Who may reach the load balancer (use your own IP/32 to restrict)"
  type        = string
  default     = "0.0.0.0/0"
}

variable "tags" {
  type    = map(string)
  default = {}
}
