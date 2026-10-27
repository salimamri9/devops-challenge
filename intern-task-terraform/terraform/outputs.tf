output "public_ip" {
  description = "public ip of the instance"
  value       = aws_instance.app.public_ip
}

output "app_port" {
  description = "port the app listens on"
  value       = local.app_port
}
