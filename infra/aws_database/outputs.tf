output "db_host" {
  description = "RDS instance hostname"
  value       = aws_db_instance.axialy.address
}

output "db_port" {
  description = "RDS instance port"
  value       = aws_db_instance.axialy.port
}

output "db_user" {
  description = "Database username"
  value       = aws_db_instance.axialy.username
}

output "db_pass" {
  description = "Database password"
  value       = random_password.db_password.result
  sensitive   = true
}

output "db_instance_id" {
  description = "RDS instance identifier"
  value       = aws_db_instance.axialy.id
}

output "db_endpoint" {
  description = "RDS instance endpoint"
  value       = aws_db_instance.axialy.endpoint
}

output "db_arn" {
  description = "RDS instance ARN"
  value       = aws_db_instance.axialy.arn
}

output "security_group_id" {
  description = "Security group ID for RDS instance"
  value       = aws_security_group.axialy_rds.id
}

output "parameter_group_name" {
  description = "DB parameter group name"
  value       = aws_db_parameter_group.axialy_mysql.name
}

output "subnet_group_name" {
  description = "DB subnet group name"
  value       = aws_db_subnet_group.axialy.name
}
