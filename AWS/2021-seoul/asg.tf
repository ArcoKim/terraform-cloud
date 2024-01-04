resource "aws_launch_template" "web" {
  name = "web_asg_lt"
  image_id = local.ami
  instance_type = local.instance_type
  key_name = aws_key_pair.keypair.key_name

  vpc_security_group_ids = [ aws_security_group.web.id ]
  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "web-skills-ap-stable"
    }
  }

  user_data = filebase64("${path.module}/web.sh")
}

resource "aws_security_group" "web" {
  name        = "web_sg"
  description = "Allow HTTP traffic"
  vpc_id      = aws_vpc.main.id

  ingress = [
		{
			from_port        = 22
			to_port          = 22
			protocol         = "tcp"
			security_groups = [ aws_security_group.bastion.id ]
		},
		{
			from_port        = 80
			to_port          = 80
			protocol         = "tcp"
			security_groups = [ aws_security_group.alb.id ]
		}
	]

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_iam_role" "s3" {
  name = "S3ReadRole"

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

resource "aws_iam_role_policy_attachment" "s3" {
  role       = aws_iam_role.s3.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}

resource "aws_iam_instance_profile" "s3" {
  name = "S3ReadRole"
  role = aws_iam_role.s3.name
}