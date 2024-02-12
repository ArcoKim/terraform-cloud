resource "aws_ecs_service" "skills" {
  name            = "skills-svc"
  cluster         = aws_ecs_cluster.skills.id
  task_definition = aws_ecs_task_definition.skills.arn
  desired_count   = 2

    network_configuration {
      subnets = [ var.private["a"], var.private["c"] ]
      security_groups = [ aws_security_group.ecs-svc.id ]
      assign_public_ip = false
    }

  load_balancer {
    target_group_arn = aws_lb_target_group.ecs-svc.arn
    container_name   = "app"
    container_port   = 80
  }
}

resource "aws_security_group" "ecs-svc" {
  name        = "ecs-svc-sg"
  description = "Allow HTTP traffic"
  vpc_id      = var.vpc

  ingress {
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    security_groups = [ aws_security_group.ecs-alb.id ]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_lb" "ecs" {
  name               = "skills-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [ aws_security_group.ecs-alb.id ]
  subnets            = [ var.public["a"], var.public["c"] ]
}

resource "aws_security_group" "ecs-alb" {
  name        = "alb-sg"
  description = "Allow HTTP traffic"
  vpc_id      = var.vpc

  ingress {
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = [ "0.0.0.0/0" ]
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

resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.ecs.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ecs-svc.arn
  }
}

resource "aws_lb_target_group" "ecs-svc" {
  name     = "ecs-svc-tg"
  port     = 80
  protocol = "HTTP"
  target_type = "ip"
  vpc_id   = var.vpc
}