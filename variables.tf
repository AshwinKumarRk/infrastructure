variable "profile" {}
variable "region" {}

variable "vpc_cidr_block" {
  type        = string
  description = "CIDR for VPC"
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