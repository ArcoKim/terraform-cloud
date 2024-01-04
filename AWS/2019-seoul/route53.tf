resource "aws_route53_zone" "main" {
  name = "ws.local"

  vpc {
    vpc_id = aws_vpc.main.id
  }
}