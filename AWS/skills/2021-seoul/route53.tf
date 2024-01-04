resource "aws_route53_zone" "main" {
  name = "ws.local"

  vpc {
    vpc_id = aws_vpc.main.id
  }
}

resource "aws_route53_record" "web" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "web.ws.local"
  type    = "CNAME"
  ttl = 300
  records = [ aws_lb.web.dns_name ]
}