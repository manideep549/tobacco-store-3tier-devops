
output "backend_ip" {
  value = aws_instance.backend.public_ip
}

output "db_endpoint" {
  value = aws_db_instance.mysql.endpoint
}
