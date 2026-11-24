variable "name" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "public_subnet_ids" {
  type = list(string)
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "alb_sg_id" {
  type = string
}

variable "app_sg_id" {
  type = string
}

variable "instance_profile_name" {
  type = string
}

variable "user_data" {
  description = "Plain-text cloud-init / bash script run at first boot"
  type        = string
}

variable "app_port" {
  type    = number
  default = 80
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}

variable "min_size" {
  type    = number
  default = 2
}

variable "max_size" {
  type    = number
  default = 4
}

variable "desired_capacity" {
  type    = number
  default = 2
}

variable "cpu_target" {
  description = "Target average CPU % for the scaling policy"
  type        = number
  default     = 50
}

variable "tags" {
  type    = map(string)
  default = {}
}
