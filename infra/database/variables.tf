variable "aws_access_key_id" {
  description = "AWS access key ID"
  type        = string
  sensitive   = true
}

variable "aws_secret_access_key" {
  description = "AWS secret access key"
  type        = string
  sensitive   = true
}

variable "db_instance_identifier" {
  description = "RDS instance identifier"
  type        = string
}

variable "region" {
  description = "AWS region where resources will be created"
  type        = string
  default     = "us-west-2"
}

variable "instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "allocated_storage" {
  description = "Allocated storage for RDS instance in GB"
  type        = string
  default     = "20"
}

variable "admin_default_email" {
  description = "Default email for admin user"
  type        = string
  sensitive   = true
}

variable "admin_default_password" {
  description = "Default password for admin user"
  type        = string
  sensitive   = true
}

variable "admin_default_user" {
  description = "Default username for admin user"
  type        = string
  sensitive   = true
}

variable "ec2_key_pair" {
  description = "EC2 key pair name for SSH access"
  type        = string
}

variable "ec2_ssh_private_key" {
  description = "EC2 SSH private key content"
  type        = string
  sensitive   = true
}

variable "ec2_elastic_ip_allocation_id" {
  description = "Elastic IP allocation ID for EC2 instance"
  type        = string
}
