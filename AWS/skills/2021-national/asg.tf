resource "aws_autoscaling_group" "webapp" {
  name                = "wsi-web-api-asg"
  desired_capacity    = 2
  min_size            = 2
  max_size            = 10
  vpc_zone_identifier = [aws_subnet.private-a.id, aws_subnet.private-b.id]
  target_group_arns   = [aws_lb_target_group.stable.arn]

  launch_template {
    id      = aws_launch_template.webapp.id
    version = "$Latest"
  }
}

resource "aws_autoscaling_policy" "webapp" {
  name                   = "web-asg-policy"
  autoscaling_group_name = aws_autoscaling_group.webapp.name

  policy_type = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 30.0
  }
}

resource "aws_launch_template" "webapp" {
  name          = "wsi-web-api-lt"
  image_id      = data.aws_ami.amazon-linux-2.id
  instance_type = local.instance_type
  key_name      = aws_key_pair.keypair.key_name
  iam_instance_profile {
    arn = aws_iam_instance_profile.webapp.arn
  }

  vpc_security_group_ids = [aws_security_group.webapp.id]
  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "wsi-web-api-asg"
    }
  }

  user_data = base64encode(<<EOF
    #!/bin/bash
    yum update -y
    yum install -y jq amazon-cloudwatch-agent
    aws s3 cp s3://${aws_s3_bucket.artifactory-s3.id}/app.py /home/ec2-user/app.py
    aws s3 cp s3://${aws_s3_bucket.config-s3.id}/config.json /opt/aws/amazon-cloudwatch-agent/bin/config.json
    pip3 install flask
    mkdir -p /var/log/app
    touch /var/log/app/app.log
    nohup python3 /home/ec2-user/app.py > /home/ec2-user/nohup.out 2>&1 &
    amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -s -c file:/opt/aws/amazon-cloudwatch-agent/bin/config.json
  EOF
  )
}

resource "aws_security_group" "webapp" {
  name        = "web_sg"
  description = "Allow HTTP traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion.id]
  }

  ingress {
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_iam_role" "webapp" {
  name = "WebappRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "s3_access" {
  role       = aws_iam_role.webapp.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}

resource "aws_iam_role_policy_attachment" "cloudwatch_access" {
  role       = aws_iam_role.webapp.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_instance_profile" "webapp" {
  name = "WebappRole"
  role = aws_iam_role.webapp.name
}