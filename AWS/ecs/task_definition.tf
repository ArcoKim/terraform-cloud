data "aws_caller_identity" "current" {}

resource "aws_ecs_task_definition" "skills" {
  family = "skills-td"
  requires_compatibilities = ["FARGATE"]
  network_mode = "awsvpc"
  cpu = "1024"
  memory = "2048"

  container_definitions = jsonencode([
    {
      name      = "app"
      image     = "${data.aws_caller_identity.current.account_id}.dkr.ecr.ap-northeast-2.amazonaws.com/ecs-app"
      essential = true
      portMappings = [
        {
          containerPort = 3000
          hostPort      = 3000
        }
      ]
      healthCheck = {
        command = [
            "CMD-SHELL",
            "curl -f http://localhost:3000/health || exit 1"
        ]
      }
    }
  ])

  proxy_configuration {
    type           = "APPMESH"
    container_name = "envoy"
    properties = {
      AppPorts         = "3000"
      EgressIgnoredIPs = "169.254.170.2,169.254.169.254"
      IgnoredUID       = "1337"
      ProxyEgressPort  = 15001
      ProxyIngressPort = 15000
    }
  }
}