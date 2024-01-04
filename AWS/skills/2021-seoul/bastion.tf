resource "aws_instance" "bastion" {
  ami                         = local.ami
  associate_public_ip_address = true
  instance_type               = local.instance_type
  subnet_id                   = aws_subnet.public-a.id
  disable_api_termination     = true
  key_name                    = aws_key_pair.keypair.key_name
  vpc_security_group_ids      = [aws_security_group.bastion.id]
  user_data                   = file("${local.filepath}/bastion.sh")

  tags = {
    Name = "bastion-skills-ap"
  }
}

resource "aws_security_group" "bastion" {
  name        = "bastion_sg"
  description = "Allow SSH traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port        = 37722
    to_port          = 37722
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