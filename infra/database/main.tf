terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region     = var.region
  access_key = var.aws_access_key_id
  secret_key = var.aws_secret_access_key
}

data "aws_availability_zones" "available" {
  state = "available"
}

resource "random_password" "db_password" {
  length  = 16
  special = true
}

resource "aws_vpc" "axialy_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "axialy-vpc"
  }
}

resource "aws_internet_gateway" "axialy_igw" {
  vpc_id = aws_vpc.axialy_vpc.id

  tags = {
    Name = "axialy-igw"
  }
}

resource "aws_subnet" "axialy_public_subnet" {
  vpc_id                  = aws_vpc.axialy_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "axialy-public-subnet"
  }
}

resource "aws_subnet" "axialy_private_subnet_1" {
  vpc_id            = aws_vpc.axialy_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "axialy-private-subnet-1"
  }
}

resource "aws_subnet" "axialy_private_subnet_2" {
  vpc_id            = aws_vpc.axialy_vpc.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = data.aws_availability_zones.available.names[1]

  tags = {
    Name = "axialy-private-subnet-2"
  }
}

resource "aws_route_table" "axialy_public_rt" {
  vpc_id = aws_vpc.axialy_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.axialy_igw.id
  }

  tags = {
    Name = "axialy-public-rt"
  }
}

resource "aws_route_table_association" "axialy_public_rta" {
  subnet_id      = aws_subnet.axialy_public_subnet.id
  route_table_id = aws_route_table.axialy_public_rt.id
}

resource "aws_security_group" "axialy_rds_sg" {
  name        = "axialy-rds-sg"
  description = "Security group for Axialy RDS instance"
  vpc_id      = aws_vpc.axialy_vpc.id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.axialy_ec2_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "axialy-rds-sg"
  }
}

resource "aws_security_group" "axialy_ec2_sg" {
  name        = "axialy-ec2-sg"
  description = "Security group for Axialy EC2 instance"
  vpc_id      = aws_vpc.axialy_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
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
    Name = "axialy-ec2-sg"
  }
}

resource "aws_db_subnet_group" "axialy_db_subnet_group" {
  name       = "axialy-db-subnet-group"
  subnet_ids = [aws_subnet.axialy_private_subnet_1.id, aws_subnet.axialy_private_subnet_2.id]

  tags = {
    Name = "axialy-db-subnet-group"
  }
}

resource "aws_db_instance" "axialy_database" {
  identifier                = var.db_instance_identifier
  engine                    = "mysql"
  engine_version            = "8.0"
  instance_class            = var.instance_class
  allocated_storage         = var.allocated_storage
  storage_type              = "gp2"
  storage_encrypted         = true
  
  db_name  = "axialy"
  username = "axialy_admin"
  password = random_password.db_password.result
  
  vpc_security_group_ids = [aws_security_group.axialy_rds_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.axialy_db_subnet_group.name
  
  backup_retention_period = 7
  backup_window          = "03:00-04:00"
  maintenance_window     = "sun:04:00-sun:05:00"
  
  skip_final_snapshot = true
  deletion_protection = false
  
  tags = {
    Name = "axialy-database"
  }
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

resource "aws_instance" "database_setup" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t3.micro"
  key_name               = var.ec2_key_pair
  vpc_security_group_ids = [aws_security_group.axialy_ec2_sg.id]
  subnet_id              = aws_subnet.axialy_public_subnet.id

  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    yum install -y mysql
    
    mkdir -p /home/ec2-user/.axialy
    chown ec2-user:ec2-user /home/ec2-user/.axialy
    
    echo "Database setup instance ready"
  EOF

  tags = {
    Name = "axialy-database-setup"
  }
}

resource "aws_eip_association" "axialy_eip_assoc" {
  instance_id   = aws_instance.database_setup.id
  allocation_id = var.ec2_elastic_ip_allocation_id
}
