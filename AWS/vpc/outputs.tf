output "vpc" {
  value = aws_vpc.main.id
}

output "public" {
  value = {
    a = aws_subnet.public-a.id
    c = aws_subnet.public-c.id
  }
}

output "private" {
  value = {
    a = aws_subnet.private-a.id
    c = aws_subnet.private-c.id
  }
}