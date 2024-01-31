resource "aws_instance" "bastion" {
  ami                         = data.aws_ami.amazon-linux-2.id
  associate_public_ip_address = true
  instance_type               = local.instance_type
  subnet_id                   = aws_subnet.public-a.id
  disable_api_termination     = true
  key_name                    = aws_key_pair.keypair.key_name
  vpc_security_group_ids      = [aws_security_group.bastion.id]
  iam_instance_profile        = aws_iam_instance_profile.admin.name
  user_data                   = <<EOF
    #!/bin/bash
    yum update -y
    yum remove -y awscli
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    ./aws/install
    yum install -y docker git jq
    systemctl start docker
    systemctl enable docker
    usermod -a -G docker ec2-user
    curl -O https://s3.us-west-2.amazonaws.com/amazon-eks/1.28.3/2023-11-14/bin/linux/amd64/kubectl
    chmod +x ./kubectl
    HOME=/home/ec2-user
    mkdir -p $HOME/bin && cp ./kubectl $HOME/bin/kubectl && echo "export PATH=$PATH:$HOME/bin" >> ~/.bash_profile
    source ~/.bash_profile
    kubectl completion bash | tee /etc/bash_completion.d/kubectl > /dev/null
    curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
    chmod 700 get_helm.sh
    ./get_helm.sh
    curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
    mv /tmp/eksctl /usr/local/bin
    echo "export CLUSTER_NAME=${aws_eks_cluster.skills.name}" >> ~/.bashrc
    echo "export AWS_DEFAULT_REGION=${local.region}" >> ~/.bashrc
    echo "export AWS_ACCOUNT_ID=${data.aws_caller_identity.current.account_id}" >> ~/.bashrc
    source ~/.bashrc
    aws eks update-kubeconfig --name "${aws_eks_cluster.skills.name}"
    git clone https://github.com/ahmetb/kubectx /opt/kubectx
    ln -s /opt/kubectx/kubectx /usr/local/bin/kubectx
    ln -s /opt/kubectx/kubens /usr/local/bin/kubens
    curl --silent --location "https://github.com/derailed/k9s/releases/download/v0.27.4/k9s_Linux_amd64.tar.gz" | tar xz -C /tmp
    cp /tmp/k9s /usr/local/bin
    cp /tmp/k9s /usr/bin
    aws s3 cp s3://${aws_s3_bucket.config.id}/ $HOME --recursive
    chown -R ec2-user:ec2-user $HOME/app && chown -R ec2-user:ec2-user $HOME/k8s
    chmod +x $HOME/app/match/match && chmod +x $HOME/app/stress/stress
    aws ecr get-login-password --region ${local.region} | docker login --username AWS --password-stdin ${data.aws_caller_identity.current.account_id}.dkr.ecr.${local.region}.amazonaws.com
    docker build -t ${aws_ecr_repository.match.repository_url}:latest $HOME/app/match
    docker build -t ${aws_ecr_repository.stress.repository_url}:latest $HOME/app/stress
    docker push ${aws_ecr_repository.match.repository_url}:latest
    docker push ${aws_ecr_repository.stress.repository_url}:latest
  EOF

  tags = {
    Name = "skills-bastion"
  }

  depends_on = [ 
    aws_eks_access_entry.admin-allow,
    aws_eks_access_policy_association.admin-allow
  ]
}

resource "aws_security_group" "bastion" {
  name        = "bastion-sg"
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