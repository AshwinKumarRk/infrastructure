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

  count                   = length(var.subnet_az_cidr)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = element(var.subnet_az_cidr, count.index)
  map_public_ip_on_launch = var.map_public_ip
  availability_zone       = element(var.subnet_az, count.index)

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

  timeouts {
    create = "3m"
    delete = "3m"
  }
  tags = {
    Name = var.rt_name
  }
}

//Create route table association
resource "aws_route_table_association" "rta" {
  count          = length(var.subnet_az_cidr)
  subnet_id      = element(aws_subnet.subnet.*.id, count.index)
  route_table_id = aws_route_table.rt.id
}

//Create Application Security Group
resource "aws_security_group" "app_sg" {
  name        = var.app_sg_name
  description = var.app_sg_desc
  vpc_id      = aws_vpc.main.id
}

//Add http SG rule
resource "aws_security_group_rule" "http" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.app_sg.id
}

//Add https SG rule
resource "aws_security_group_rule" "https" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.app_sg.id
}

//Add ssh SG rule
resource "aws_security_group_rule" "ssh" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.app_sg.id
}

//Add localhost SG rule
resource "aws_security_group_rule" "localhost" {
  type              = "ingress"
  from_port         = 3000
  to_port           = 3000
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.app_sg.id
}

resource "aws_security_group_rule" "outbound" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.app_sg.id
}

#Create database security group
resource "aws_security_group" "db_sg" {
  name        = var.db_sg_name
  description = var.db_sg_desc
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.app_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#Create random string to use for unique bucket name creation
resource "random_string" "random" {
  length  = 8
  lower   = true
  special = false
  number  = false
  upper   = false
}

#kms key for s3 bucket default encryption
resource "aws_kms_key" "mykey" {
  description             = var.kms_desc
  deletion_window_in_days = 7
}

#Create s3 bucket
resource "aws_s3_bucket" "bucket" {
  bucket        = "${random_string.random.id}.${var.bucket_domain}"
  acl           = "private"
  force_destroy = true

  lifecycle_rule {
    id      = "log"
    enabled = true

    prefix = "log/"

    tags = {
      rule      = "log"
      autoclean = "true"
    }

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = aws_kms_key.mykey.arn
        sse_algorithm     = "aws:kms"
      }
    }
  }
}

resource "aws_s3_bucket_public_access_block" "s3_pab" {
  bucket             = aws_s3_bucket.bucket.id
  ignore_public_acls = true
}

resource "aws_db_parameter_group" "db_pg" {
  name   = var.dbp_name
  family = var.dbp_family
}

resource "aws_db_subnet_group" "db_sntg" {
  name       = "main"
  subnet_ids = aws_subnet.subnet.*.id
  tags = {
    Name = "My DB subnet group"
  }
}

resource "aws_db_instance" "db_instance" {
  allocated_storage      = 10
  engine                 = var.db_engine
  instance_class         = var.db_iclass
  name                   = var.db_name
  username               = var.db_user
  password               = var.db_pass
  identifier             = var.db_id
  parameter_group_name   = aws_db_parameter_group.db_pg.id
  multi_az               = false
  db_subnet_group_name   = aws_db_subnet_group.db_sntg.name
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  skip_final_snapshot    = true
}
