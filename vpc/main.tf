terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "eu-west-1"
}

# create vpc
resource "aws_vpc" "demo" {
  cidr_block = "172.16.0.0/16"

  tags = {
    Name = "demo-vpc"
  }
}

# create public subnet
resource "aws_subnet" "public" {
  vpc_id            = aws_vpc.demo.id
  cidr_block        = "172.16.1.0/24"
  availability_zone = "eu-west-1a"
  tags = {
    Name = "public-subnet"
  }
  map_public_ip_on_launch = true
}

# create private subnet
resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.demo.id
  cidr_block        = "172.16.2.0/24"
  availability_zone = "eu-west-1b"
  tags = {
    Name = "private-subnet"
  }
} 

# create internet gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.demo.id

  tags = {
    Name = "demo-igw"
  }
}

# create route table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.demo.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
}

# associate route table with public subnet
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# create a security group for public instance
resource "aws_security_group" "public_instance_sg" {
  name        = "public-instance-sg"
  description = "Security group for public instance"
  vpc_id      = aws_vpc.demo.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# create ec2 instance in public subnet
resource "aws_instance" "public_instance" {
  ami           = "ami-03446a3af42c5e74e"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.public.id
  key_name = "eu-west-1-kp"
  vpc_security_group_ids = [aws_security_group.public_instance_sg.id]

  tags = {
    Name = "public-instance"
  }
}

# output 
output "ec2_public_ip" {
  value = aws_instance.public_instance.public_ip
}