variable "profile" {}
variable "region" {}

variable "vpc_cidr_block" {
  type        = string
  description = "CIDR for VPC"
}

variable "vpc_name" {
  default = "csye6225-VPC"
}