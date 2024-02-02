output "vpc" {
  value = aws_vpc.main.id
}

output "public-a" {
  value = aws_subnet.public-a.id
}

output "public-c" {
  value = aws_subnet.public-c.id
}

output "private-a" {
  value = aws_subnet.private-a.id
}

output "private-c" {
  value = aws_subnet.private-c.id
}