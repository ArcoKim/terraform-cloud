resource "aws_lb" "web" {
  name               = "web-cc2021-ap-int"
  internal           = true
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = [aws_subnet.private-a.id, aws_subnet.private-b.id]
}

resource "aws_lb_target_group" "stable" {
  name     = "web-stable-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
  health_check {
    path = "/health"
  }
}

resource "aws_lb_target_group" "test" {
  name     = "web-test-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
  health_check {
    path = "/health"
  }
}

resource "aws_lb_listener" "web" {
  load_balancer_arn = aws_lb.web.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.stable.arn
  }
}

resource "aws_lb_listener_rule" "dev" {
  listener_arn = aws_lb_listener.web.arn
  priority = 1

  action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "Not found this WSI page"
      status_code  = "404"
    }
  }

  condition {
    path_pattern {
      values = [ "/swagger-ui.html" ]
    }
  }
}

resource "aws_lb_listener_rule" "test" {
  listener_arn = aws_lb_listener.web.arn
  priority = 2

  action {
    type = "forward"
    target_group_arn = aws_lb_target_group.test.arn
  }

  condition {
    query_string {
      key = "test"
      value = "true"
    }
  }
}

resource "aws_security_group" "alb" {
  name        = "alb_sg"
  description = "Allow HTTP traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = [aws_vpc.main.cidr_block]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}