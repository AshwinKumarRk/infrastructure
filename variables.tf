#provider
variable "profile" {}
variable "region" {}

#vpc
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

#subnets
variable "subnet_az_cidr" {
  description = "CIDR for Subnets"
}

variable "subnet_az" {
  description = "AZ for Subnets"
}

variable "subnet_name" {
  default = "csye6225-Subnet"
}

variable "map_public_ip" {
  default = true
}

#Internet Gateway
variable "igw_name" {
  default = "csye6225-IGW"
}

#Route Table
variable "rt_name" {
  default = "csye6225-RT"
}

#Security Groups
variable "app_sg_name" {
  default = "application"
}

variable "app_sg_desc" {
  default = "Application Security Group for EC2 WebApp"
}

variable "db_sg_name" {
  default = "database"
}

variable "db_sg_desc" {
  default = "Database Security Group for RDS Instance"
}

#s3 bucket
variable "bucket_domain" {
  default = "prod.ashwinkumarrk.me"
}

variable "kms_desc" {
  default = "This key is used to encrypt bucket objects"
}

#RDS Instance

variable "db_engine" {
  default = "mysql"
}

variable "db_version" {
  default = "8.0"
}

variable "dbp_name" {
  default = "rds-pg"
}

variable "dbp_family" {
  default = "mysql8.0"
}

variable "db_iclass" {
  default = "db.t3.micro"
}

variable "db_name" {}
variable "db_user" {}
variable "db_pass" {}
variable "db_id" {}
variable "db_rr_id" {}
variable "accountID" {}

variable "db_param_gp" {
  default = "default.mysql8.0"
}

#AMI
variable "owner_id" {}

#EC2 Instance
variable "key" {}
variable "instance" {
  default = "t2.micro"
}
variable "delete_onterm" {
  default = true
}
variable "vsize" {
  default = 20
}

variable "vtype" {
  default = "gp2"
}