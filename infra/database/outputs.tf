output "db_host" {
  description = "RDS instance hostname"
  value       = aws_db_instance.axialy_database.address
}

output "db_port" {
  description = "RDS instance port"
  value       = aws_db_instance.axialy_database.port
}

output "db_user" {
  description = "RDS database username"
  value       = aws_db_instance.axialy_database.username
}

output "db_pass" {
  description = "RDS database password"
  value       = aws_db_instance.axialy_database.password
  sensitive   = true
}

output "db_instance_id" {
  description = "RDS instance identifier"
  value       = aws_db_instance.axialy_database.id
}

output "ec2_public_ip" {
  description = "EC2 instance public IP address"
  value       = aws_instance.database_setup.public_ip
}

output "ec2_instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.database_setup.id
}

output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.axialy_vpc.id
}

output "rds_security_group_id" {
  description = "RDS security group ID"
  value       = aws_security_group.axialy_rds_sg.id
}

output "ec2_security_group_id" {
  description = "EC2 security group ID"
  value       = aws_security_group.axialy_ec2_sg.id
}
