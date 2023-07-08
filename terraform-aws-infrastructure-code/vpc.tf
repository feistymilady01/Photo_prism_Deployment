# Create VPC

resource "aws_vpc" "g19capstone_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Name = "g19capstone_vpc"
  }
}

#  Create Public Subnet-1

resource "aws_subnet" "gp19-public-subnet-1" {
  vpc_id                  = aws_vpc.g19capstone_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1a"

  tags = {
    Name = "gp19-public-subnet-1"
  }
}

#  Create Public Subnet-1

resource "aws_subnet" "gp19-public-subnet-2" {
  vpc_id                  = aws_vpc.g19capstone_vpc.id
  cidr_block              = "10.0.2.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1b"

  tags = {
    Name = "gp19-public-subnet-2"
  }
}

# Create Private Subnet-1

resource "aws_subnet" "gp19-private-subnet-1" {
  vpc_id                  = aws_vpc.g19capstone_vpc.id
  cidr_block              = "10.0.4.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = false
  tags = {
    Name = "gp19-private-subnet-1"
  }
}

# Create Private Subnet-2

resource "aws_subnet" "gp19-private-subnet-2" {
  vpc_id                  = aws_vpc.g19capstone_vpc.id
  cidr_block              = "10.0.5.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = false
  tags = {
    Name = "gp19-private-subnet-2"
  }
}

# Create Internet Gateway

resource "aws_internet_gateway" "g19capstone_igw" {
  vpc_id = aws_vpc.g19capstone_vpc.id

  tags = {
    Name = "g19capstone_igw"
  }
}

# Create public Route Table

resource "aws_route_table" "g19capstone_public_rt" {
  vpc_id = aws_vpc.g19capstone_vpc.id

  route {
    cidr_block  = "0.0.0.0/0"
    gateway_id  = aws_internet_gateway.g19capstone_igw.id
  }

  tags = {
    Name = "g19capstone_public_rt"
  }
}

# Create Route Table for private sub 1

resource "aws_route_table" "gp19-private-rt-1" {
  vpc_id = aws_vpc.g19capstone_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.gp19capstone-nat-1.id
  }

  tags = {
    Name = "gp19-private-rt-1"
  }
}

# Create Route Table for private sub 2

resource "aws_route_table" "gp19-private-rt-2" {
  vpc_id = aws_vpc.g19capstone_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.gp19capstone-nat-2.id
  }

  tags = {
    Name = "gp19-private-rt-2"
  }
}

# Associate public subnet 1 with public route table

resource "aws_route_table_association" "gp19-public-subnet-1-association" {
  subnet_id      = aws_subnet.gp19-public-subnet-1.id
  route_table_id = aws_route_table.g19capstone_public_rt.id
}

# Associate public subnet 2 with public route table

resource "aws_route_table_association" "gp19-public-subnet-2-association" {
  subnet_id      = aws_subnet.gp19-public-subnet-2.id
  route_table_id = aws_route_table.g19capstone_public_rt.id
}

# Associate private subnet 1 with private route table 1

resource "aws_route_table_association" "priv-sub1-association" {
  subnet_id      = aws_subnet.gp19-private-subnet-1.id
  route_table_id = aws_route_table.gp19-private-rt-1.id
}

# Associate private subnet 2 with private route table 2

resource "aws_route_table_association" "priv-sub2-association" {
  subnet_id      = aws_subnet.gp19-private-subnet-2.id
  route_table_id = aws_route_table.gp19-private-rt-2.id
}


# Create an Elastic IP for NAT Gateway 1

resource "aws_eip" "gp19-eip-1" {
  domain     = "vpc"
  depends_on = [aws_internet_gateway.g19capstone_igw]
  tags = {
    Name = "gp19-eip-1"
  }
}



# Create an Elastic IP for NAT Gateway 2

resource "aws_eip" "gp19-eip-2" {
  domain     = "vpc"
  depends_on = [aws_internet_gateway.g19capstone_igw]
  tags = {
    Name = "gp19-eip-2"
  }
}


# Create NAT Gateway 1

resource "aws_nat_gateway" "gp19capstone-nat-1" {
  allocation_id = aws_eip.gp19-eip-1.id
  subnet_id     = aws_subnet.gp19-public-subnet-1.id

  tags = {
    Name = "gp19capstone-nat-1"
  }
  depends_on = [aws_internet_gateway.g19capstone_igw]
}



# Create a NAT Gateway 2

resource "aws_nat_gateway" "gp19capstone-nat-2" {
  allocation_id = aws_eip.gp19-eip-2.id
  subnet_id     = aws_subnet.gp19-public-subnet-2.id

  tags = {
    Name = "gp19capstone-nat-2"
  }
  depends_on = [aws_internet_gateway.g19capstone_igw]
}

# Create a Network ACL for VPC

resource "aws_network_acl" "g19capstone_network_acl" {
  vpc_id     = aws_vpc.g19capstone_vpc.id
  subnet_ids = [aws_subnet.gp19-public-subnet-1.id, aws_subnet.gp19-public-subnet-2.id]

  ingress {
    rule_no     = 100
    protocol    = "-1"
    action      = "allow"
    cidr_block  = "0.0.0.0/0"
    from_port   = 0
    to_port     = 0
  }

  egress {
    rule_no     = 100
    protocol    = "-1"
    action      = "allow"
    cidr_block  = "0.0.0.0/0"
    from_port   = 0
    to_port     = 0
  }
}