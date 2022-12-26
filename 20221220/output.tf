output "public_ip_address" {
  value = aws_instance.app-ec2.public_ip
}