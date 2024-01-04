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
  ttl     = 60

  alias {
    name                   = aws_lb.web.dns_name
    zone_id                = aws_lb.web.zone_id
    evaluate_target_health = true
  }
}