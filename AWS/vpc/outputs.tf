output "vpc" {
  value = aws_vpc.main.id
}

output "public-a" {
  value = aws_subnet.public-a.id
}