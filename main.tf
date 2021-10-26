//Create a VPC
resource "aws_vpc" "main" {
  cidr_block                       = var.vpc_cidr_block
  enable_dns_hostnames             = var.dns_hostnames
  enable_dns_support               = var.dns_support
  enable_classiclink_dns_support   = var.classiclink
  assign_generated_ipv6_cidr_block = var.assign_ipv6
  tags = {
    "Name" = var.vpc_name
  }
}

//Create subnets
resource "aws_subnet" "subnet" {
  depends_on = [aws_vpc.main]

  for_each = var.subnet_az_cidr

  cidr_block              = each.value
  vpc_id                  = aws_vpc.main.id
  availability_zone       = each.key
  map_public_ip_on_launch = var.map_public_ip

  tags = {
    Name = var.subnet_name
  }
}

//Create internet gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = var.igw_name
  }
}

//Create route table
resource "aws_route_table" "rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = var.rt_name
  }
}

//Create route table association
resource "aws_route_table_association" "rta" {
  for_each = aws_subnet.subnet

  subnet_id      = each.value.id
  route_table_id = aws_route_table.rt.id
}

//Create Security Group
resource "aws_security_group" "app_pub_sg" {
  name        = "application"
  description = "Allow application access"
  vpc_id      = aws_vpc.main.id
}

resource "aws_security_group_rule" "http" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.app_pub_sg.id
}

resource "aws_security_group_rule" "https" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.app_pub_sg.id
}

resource "aws_security_group_rule" "ssh" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.app_pub_sg.id
}

resource "aws_security_group_rule" "localhost" {
  type              = "ingress"
  from_port         = 3000
  to_port           = 3000
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.app_pub_sg.id
}

resource "aws_security_group_rule" "outbound" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.app_pub_sg.id
}
