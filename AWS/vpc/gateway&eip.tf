resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "skills-igw"
  }
}

resource "aws_eip" "eip-a" {
  domain = "vpc"

  tags = {
    Name = "skills-eip-a"
  }
}

resource "aws_eip" "eip-c" {
  domain = "vpc"

  tags = {
    Name = "skills-eip-c"
  }
}

resource "aws_nat_gateway" "nat-a" {
  allocation_id = aws_eip.eip-a.id
  subnet_id     = aws_subnet.public-a.id

  tags = {
    Name = "skills-nat-a"
  }

  depends_on = [aws_internet_gateway.igw]
}

resource "aws_nat_gateway" "nat-c" {
  allocation_id = aws_eip.eip-c.id
  subnet_id     = aws_subnet.public-c.id

  tags = {
    Name = "skills-nat-c"
  }

  depends_on = [aws_internet_gateway.igw]
}