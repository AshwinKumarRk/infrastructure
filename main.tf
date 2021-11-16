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
  vpc_id = aws_vpc.main.id
  name   = "application"

  # allow SSH port
  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    //security_groups = ["${aws_security_group.loadBalancer.id}"]
  }

  # allow HTTP port
  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.lb_sg.id]
  }

  # allow port 3000
  ingress {
    from_port       = 3000
    to_port         = 3000
    protocol        = "tcp"
    security_groups = [aws_security_group.lb_sg.id]
  }

  # allow outbound traffic 
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "application"
  }
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
        sse_algorithm = "aws:kms"
      }
    }
  }
}

#Block public access for S3 bucket
resource "aws_s3_bucket_public_access_block" "s3_pub_accblk" {
  bucket             = aws_s3_bucket.bucket.id
  ignore_public_acls = true
}

#Create RDS Parameter Group
resource "aws_db_parameter_group" "db_pg" {
  name   = var.dbp_name
  family = var.dbp_family
}

#Create RDS Subnet Group
resource "aws_db_subnet_group" "db_sntg" {
  name       = "main"
  subnet_ids = aws_subnet.subnet.*.id
  tags = {
    Name = "My DB subnet group"
  }
}

#Create RDS Instance
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

#Fetch AMI data
data "aws_ami" "ami" {
  most_recent = true
  owners      = [var.owner_id]
}

#Create EC2 Instance
// resource "aws_instance" "ec2_instance" {
//   ami                         = data.aws_ami.ami.id
//   instance_type               = var.instance
//   vpc_security_group_ids      = [aws_security_group.app_sg.id]
//   subnet_id                   = aws_subnet.subnet[1].id
//   key_name                    = var.key
//   iam_instance_profile        = aws_iam_instance_profile.ec2_profile.name
//   associate_public_ip_address = true
//   root_block_device {
//     delete_on_termination = true
//     volume_size           = var.vsize
//     volume_type           = var.vtype
//   }
//   tags = {
//     Name = "webappv1"
//   }
//   #Runs following script on instance boot
//   user_data = <<-EOF
//         #!/bin/bash
//         sleep 30
//         sudo apt-get update
//         sleep 30
//         sudo apt-get install unzip
//         sudo apt install sl
//         mkdir -p /home/ubuntu/webapp/
//         sudo chown -R ubuntu:ubuntu /home/ubuntu/webapp
//         sudo echo DB_NAME="${var.db_name}"  >> /home/ubuntu/webapp/.env
//         sudo echo DB_USER="${aws_db_instance.db_instance.username}" >> /home/ubuntu/webapp/.env
//         sudo echo DB_PASS= "${aws_db_instance.db_instance.password}" >> /home/ubuntu/webapp/.env
//         sudo echo DB_HOST= "${aws_db_instance.db_instance.address}" | sed s/:3306//g  >> /home/ubuntu/webapp/.env
//         sudo echo S3_BUCKET= "${aws_s3_bucket.bucket.bucket}" >> /home/ubuntu/webapp/.env
//         EOF
// }


#Create IAM Role
resource "aws_iam_role" "EC2-CSYE6225" {
  name = "EC2-CSYE6225"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
    {
        "Action": "sts:AssumeRole",
        "Principal": {
        "Service": "ec2.amazonaws.com"
        },
        "Effect": "Allow",
        "Sid": ""
    }
    ]
}
EOF
}

#Create IAM Policy
resource "aws_iam_policy" "WebAppS3" {
  name   = "WebAppS3"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
      {
          "Effect": "Allow",
          "Action": [
              "s3:PutObject",
              "s3:GetObject",
              "s3:DeleteObject",
              "s3:PutObjectAcl"
          ],
          "Resource": [
              "arn:aws:s3:::${aws_s3_bucket.bucket.bucket}",
              "arn:aws:s3:::${aws_s3_bucket.bucket.bucket}/*"
          ]
      }
  ]
}
EOF
}

#Attach WebAppS3 policy to EC2-CSYE6225 IAM Role
resource "aws_iam_role_policy_attachment" "Attach_WebAppS3_to_EC2-CSYE6225" {
  role       = aws_iam_role.EC2-CSYE6225.name
  policy_arn = aws_iam_policy.WebAppS3.arn
}

#Attach CloudWatch Agent policy to EC2-CSYE6225 IAM Role
resource "aws_iam_role_policy_attachment" "Attach_CWAgent_to_EC2-CSYE6225" {
  role       = aws_iam_role.EC2-CSYE6225.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

#Attach SSM Managed Instance Core policy to EC2-CSYE6225 IAM Role
resource "aws_iam_role_policy_attachment" "Attach_SSM_to_EC2-CSYE6225" {
  role       = aws_iam_role.EC2-CSYE6225.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

#Attach IAM Role to EC2
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "ec2_profile"
  role = aws_iam_role.EC2-CSYE6225.name
}

#Create ASG Launch Configuration for ASG
resource "aws_launch_configuration" "asg_launch_config" {
  name                        = "asg_launch_config"
  image_id                    = data.aws_ami.ami.id
  instance_type               = "t2.micro"
  key_name                    = var.key
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.ec2_profile.name
  security_groups             = [aws_security_group.app_sg.id]
  user_data                   = <<-EOF
      #!/bin/bash
      sleep 30
      sudo apt-get update
      sleep 30
      sudo apt-get install unzip
      sudo apt install sl
      mkdir -p /home/ubuntu/webapp/
      sudo chown -R ubuntu:ubuntu /home/ubuntu/webapp
      sudo echo DB_NAME="${var.db_name}"  >> /home/ubuntu/webapp/.env
      sudo echo DB_USER="${aws_db_instance.db_instance.username}" >> /home/ubuntu/webapp/.env
      sudo echo DB_PASS= "${aws_db_instance.db_instance.password}" >> /home/ubuntu/webapp/.env
      sudo echo DB_HOST= "${aws_db_instance.db_instance.address}" | sed s/:3306//g  >> /home/ubuntu/webapp/.env
      sudo echo S3_BUCKET= "${aws_s3_bucket.bucket.bucket}" >> /home/ubuntu/webapp/.env
      sudo touch check.txt
        EOF
}

#Create Auto Scaling Group
resource "aws_autoscaling_group" "asg" {
  name                 = "asg"
  desired_capacity     = 3
  max_size             = 5
  min_size             = 3
  default_cooldown     = 60
  launch_configuration = aws_launch_configuration.asg_launch_config.name
  vpc_zone_identifier  = [aws_subnet.subnet[1].id]
  target_group_arns    = [aws_lb_target_group.lb_target_grp.arn]
  tag {
    key                 = "Name"
    value               = "webappv1"
    propagate_at_launch = true
  }
}

#ASG Policy to Scale Up by one instance
resource "aws_autoscaling_policy" "ASG_Scale_Up_Policy" {
  name                   = "ASG_Scale_Up_Policy"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 60
  autoscaling_group_name = aws_autoscaling_group.asg.name
}

#ASG Policy to Scale Down by one instance
resource "aws_autoscaling_policy" "ASG_Scale_Down_Policy" {
  name                   = "ASG_Scale_Down_Policy"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 60
  autoscaling_group_name = aws_autoscaling_group.asg.name
}

#ASG Security Group for Load Balancer
resource "aws_security_group" "lb_sg" {
  name   = "Application Load Balancer Security Group"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name        = "Application Load Balancer Security Group"
    Environment = var.profile
  }
}

#Load Balancer to Manage ASG Instances
resource "aws_lb" "load_balancer" {
  name               = "Application-Load-Balancer"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb_sg.id]
  subnets            = aws_subnet.subnet.*.id
  tags = {
    Environment = var.profile
    Name        = "Application-Load-Balancer"
  }
}

#Load Balancer Target Group for Endpoint
resource "aws_lb_target_group" "lb_target_grp" {
  name     = "ALB-Target-Group"
  port     = "3000"
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
}

#Load Balancer to listen to HTTP Traffic
resource "aws_lb_listener" "lb_listener" {
  load_balancer_arn = aws_lb.load_balancer.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.lb_target_grp.arn
  }
}

#Cloudwatch Alarm for Scale Down on Low Usage
resource "aws_cloudwatch_metric_alarm" "CPU_Usage_Low" {
  alarm_name          = "CPU-Usage-Low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "60"
  statistic           = "Average"
  threshold           = "3"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.asg.name
  }

  alarm_description = "Scales down if CPU Usage below 3%"
  alarm_actions     = [aws_autoscaling_policy.ASG_Scale_Down_Policy.arn]
}

#Cloudwatch Alarm for Scale Up on High Usage
resource "aws_cloudwatch_metric_alarm" "CPU_Usage_High" {
  alarm_name          = "CPU-Usage-High"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "60"
  statistic           = "Average"
  threshold           = "5"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.asg.name
  }

  alarm_description = "Scales up if CPU Usage above 5%"
  alarm_actions     = [aws_autoscaling_policy.ASG_Scale_Up_Policy.arn]
}