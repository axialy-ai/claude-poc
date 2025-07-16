data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

resource "random_password" "db_password" {
  length  = 16
  special = true
}

resource "aws_db_parameter_group" "axialy_mysql" {
  family = "mysql8.0"
  name   = "${var.db_instance_identifier}-params"

  parameter {
    name  = "innodb_buffer_pool_size"
    value = "{DBInstanceClassMemory*3/4}"
  }

  parameter {
    name  = "max_connections"
    value = "100"
  }

  parameter {
    name  = "innodb_log_file_size"
    value = "134217728"
  }

  parameter {
    name  = "slow_query_log"
    value = "1"
  }

  parameter {
    name  = "long_query_time"
    value = "2"
  }

  tags = {
    Name = "Axialy MySQL Parameters"
  }
}

resource "aws_db_subnet_group" "axialy" {
  name       = "${var.db_instance_identifier}-subnet-group"
  subnet_ids = data.aws_subnets.default.ids

  tags = {
    Name = "Axialy DB subnet group"
  }
}

resource "aws_security_group" "axialy_rds" {
  name        = "${var.db_instance_identifier}-rds-sg"
  description = "Security group for Axialy RDS instance"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port   = 3306
    to_port     = 3306
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
    Name = "Axialy RDS Security Group"
  }
}

resource "aws_db_instance" "axialy" {
  identifier     = var.db_instance_identifier
  engine         = "mysql"
  engine_version = "8.0"
  instance_class = var.db_instance_class
  
  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.allocated_storage * 2
  storage_type          = "gp2"
  storage_encrypted     = true
  
  db_name  = "axialy_main"
  username = "axialy_admin"
  password = random_password.db_password.result
  
  vpc_security_group_ids = [aws_security_group.axialy_rds.id]
  db_subnet_group_name   = aws_db_subnet_group.axialy.name
  parameter_group_name   = aws_db_parameter_group.axialy_mysql.name
  
  backup_retention_period = 7
  backup_window          = "03:00-04:00"
  maintenance_window     = "sun:04:00-sun:05:00"
  
  skip_final_snapshot = true
  deletion_protection = false
  
  performance_insights_enabled = true
  monitoring_interval         = 60
  monitoring_role_arn        = aws_iam_role.rds_monitoring.arn
  
  enabled_cloudwatch_logs_exports = ["error", "general", "slowquery"]
  
  tags = {
    Name        = "Axialy Database"
    Environment = "production"
    Project     = "axialy-ai"
  }
}

resource "aws_iam_role" "rds_monitoring" {
  name = "${var.db_instance_identifier}-rds-monitoring-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "monitoring.rds.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "rds_monitoring" {
  role       = aws_iam_role.rds_monitoring.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

resource "aws_cloudwatch_log_group" "rds_error_log" {
  name              = "/aws/rds/instance/${var.db_instance_identifier}/error"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "rds_general_log" {
  name              = "/aws/rds/instance/${var.db_instance_identifier}/general"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "rds_slow_query_log" {
  name              = "/aws/rds/instance/${var.db_instance_identifier}/slowquery"
  retention_in_days = 7
}
