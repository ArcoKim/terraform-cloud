resource "aws_ecs_task_definition" "skills" {
  family = "skills-td"
  requires_compatibilities = ["FARGATE"]
  network_mode = "awsvpc"
  cpu = "1024"
  memory = "2048"

  container_definitions = jsonencode([
    {
      name      = "app"
      image     = "nginx"
      essential = true
      portMappings = [{
        containerPort = 80
      }]
    }
  ])
}