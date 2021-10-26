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

variable "map_public_ip" {
  default = true
}

variable "igw_name" {
  default = "csye6225-IGW"
}

variable "rt_name" {
  default = "csye6225-RT"
}

variable "app_pub_sg_name" {
  default = "application"
}

variable "app_pub_sg_desc" {
  default = "Application Security Group for EC2 WebApp"
}

variable "db_pub_sg_name" {
  default = "database"
}

variable "db_pub_sg_desc" {
  default = "Database Security Group for RDS Instance"
}

variable "bucket_domain" {
  default = "dev.ashwinkumarrk.me"
}

variable "kms_desc" {
  default = "This key is used to encrypt bucket objects"
}