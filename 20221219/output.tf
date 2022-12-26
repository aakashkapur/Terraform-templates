output "public_subnet_ids" {
    value = aws_subnet.project_public_subnet[*].id
}

output "vpc_id" {
  value = aws_vpc.project_vpc.id
}