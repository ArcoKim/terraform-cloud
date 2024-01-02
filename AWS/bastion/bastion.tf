resource "aws_instance" "bastion" {
  ami                         = "ami-0ff1cd0b5d98708d1" // Amazon Linux 2 : ami-074413845c101fc4d
  associate_public_ip_address = true
  instance_type               = "t3.small"
  subnet_id                   = var.public-a
  disable_api_termination     = true
  key_name                    = aws_key_pair.keypair.key_name
  vpc_security_group_ids      = [aws_security_group.bastion.id]
  iam_instance_profile        = aws_iam_instance_profile.admin.name
  user_data                   = file("./bastion/userdata.sh")

  tags = {
    Name = "skills-bastion"
  }
}

resource "aws_security_group" "bastion" {
  name        = "bastion_sg"
  description = "Allow SSH traffic"
  vpc_id      = var.vpc

  ingress {
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
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

resource "aws_eip" "bastion" {
  instance = aws_instance.bastion.id
  domain   = "vpc"
}

resource "aws_key_pair" "keypair" {
  key_name   = "skills-key"
  public_key = file("~/.ssh/id_rsa.pub")
}

resource "aws_iam_role" "admin" {
  name = "AdminRole"

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

resource "aws_iam_role_policy_attachment" "admin" {
  role       = aws_iam_role.admin.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_iam_instance_profile" "admin" {
  name = "AdminRole"
  role = aws_iam_role.admin.name
}