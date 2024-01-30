resource "aws_instance" "bastion" {
  ami                         = data.aws_ami.amazon-linux-2.id
  associate_public_ip_address = true
  instance_type               = local.instance_type
  subnet_id                   = aws_subnet.public-a.id
  disable_api_termination     = true
  key_name                    = aws_key_pair.keypair.key_name
  vpc_security_group_ids      = [aws_security_group.bastion.id]
  iam_instance_profile        = aws_iam_instance_profile.admin.name
  user_data                   = file("${local.filepath}/userdata.sh")

  tags = {
    Name = "skills-bastion"
  }

  connection {
    type = "ssh"
    user = "ec2-user"
    private_key = file("~/.ssh/id_rsa")
    host = self.public_ip
  }

  provisioner "file" {
    source = "${local.filepath}/match/"
    destination = "/home/ec2-user/match"
  }

  provisioner "file" {
    source = "${local.filepath}/stress/"
    destination = "/home/ec2-user/stress"
  }

  provisioner "remote-exec" {
    inline = [ 
      "aws ecr get-login-password --region ${local.region} | docker login --username AWS --password-stdin ${data.aws_caller_identity.current.account_id}.dkr.ecr.${local.region}.amazonaws.com",
      "docker build -t ${aws_ecr_repository.match.repository_url}:latest /home/ec2-user/match",
      "docker build -t ${aws_ecr_repository.stress.repository_url}:latest /home/ec2-user/stress",
      "docker push ${aws_ecr_repository.match.repository_url}:latest",
      "docker push ${aws_ecr_repository.stress.repository_url}:latest"
    ]
  }

  depends_on = [aws_eks_cluster.skills]
}

resource "aws_security_group" "bastion" {
  name        = "bastion_sg"
  description = "Allow SSH traffic"
  vpc_id      = aws_vpc.main.id

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