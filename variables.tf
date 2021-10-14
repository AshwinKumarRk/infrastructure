variable "profile" {}
variable "region" {}

variable "vpc_cidr_block" {
  type        = string
  description = "CIDR for VPC"
}

variable "dns_hostnames" {
  default = true
}

variable "dns_support" {
  default = true
}

variable "classiclink" {
  default = true
}

variable "assign_ipv6" {
  default = false
}

variable "vpc_name" {
  default = "csye6225-VPC"
}

variable "subnet_az_cidr" {
  description = "CIDR for Subnets"
}

variable "subnet_name" {
  default = "csye6225-Subnet"
}

variable "igw_name" {
  default = "csye6225-IGW"
}

variable "rt_name" {
  default = "csye6225-RT"
}