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

resource "aws_vpc" "example" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "tf-vpc"
  }
}

# create public subnets
resource "aws_subnet" "public_subnet_1" {
  vpc_id                  = aws_vpc.example.id
  availability_zone       = "eu-west-1a"
  cidr_block              = "10.0.0.0/20"
  map_public_ip_on_launch = false

  tags = {
    Name = "tf-subnet-public1-eu-west-1a"
  }
}

resource "aws_subnet" "public_subnet_2" {
  vpc_id                  = aws_vpc.example.id
  availability_zone       = "eu-west-1b"
  cidr_block              = "10.0.16.0/20"
  map_public_ip_on_launch = false

  tags = {
    Name = "tf-subnet-public2-eu-west-1b"
  }
}

resource "aws_subnet" "public_subnet_3" {
  vpc_id                  = aws_vpc.example.id
  availability_zone       = "eu-west-1c"
  cidr_block              = "10.0.32.0/20"
  map_public_ip_on_launch = false

  tags = {
    Name = "tf-subnet-public3-eu-west-1c"
  }
}

# create private subnets
resource "aws_subnet" "private_subnet_1" {

  vpc_id            = aws_vpc.example.id
  availability_zone = "eu-west-1a"
  cidr_block        = "10.0.128.0/20"

  tags = {
    Name = "tf-subnet-private1-eu-west-1a"
  }
}

resource "aws_subnet" "private_subnet_2" {
  vpc_id            = aws_vpc.example.id
  availability_zone = "eu-west-1b"
  cidr_block        = "10.0.144.0/20"

  tags = {
    Name = "tf-subnet-private2-eu-west-1b"
  }
}

resource "aws_subnet" "private_subnet_3" {
  vpc_id            = aws_vpc.example.id
  availability_zone = "eu-west-1c"
  cidr_block        = "10.0.160.0/20"

  tags = {
    Name = "tf-subnet-private3-eu-west-1c"
  }
}
