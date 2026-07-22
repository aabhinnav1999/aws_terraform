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
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "${var.NAME}-vpc"
  }

}

resource "aws_subnet" "public-1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "eu-west-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.NAME}-public-subnet-1"
  }
}

resource "aws_subnet" "public-2" {
  vpc_id                  = aws_vpc.main.id
  availability_zone       = "eu-west-1b"
  cidr_block              = "10.0.2.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.NAME}-public-subnet-2"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.NAME}-igw"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "${var.NAME}-public-route-table"
  }
}

resource "aws_route_table_association" "public-1" {
  subnet_id      = aws_subnet.public-1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public-2" {
  subnet_id      = aws_subnet.public-2.id
  route_table_id = aws_route_table.public.id
}

resource "aws_security_group" "eks" {
  name        = "${var.NAME}-sg"
  description = "Security group for EKS cluster"
  vpc_id      = aws_vpc.main.id

  tags = {
    "Name" = "${var.NAME}-sg"
  }

  ingress {
    from_port   = 443
    to_port     = 443
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

# create eks cluster
resource "aws_eks_cluster" "demo" {
  name = "${var.NAME}-cluster"

  access_config {
    authentication_mode = "API"
  }

  role_arn = var.eks_cluster_role_arn

  vpc_config {
    subnet_ids = [aws_subnet.public-1.id, aws_subnet.public-2.id]
  }

  tags = {
    Name = "${var.NAME}-cluster"
  }
}


resource "aws_eks_node_group" "demo" {
  cluster_name    = aws_eks_cluster.demo.name
  node_group_name = "${var.NAME}-node-group"
  node_role_arn   = var.node_group_role_arn
  subnet_ids      = [aws_subnet.public-1.id, aws_subnet.public-2.id]
  instance_types  = ["t3.small"] # optional, default is "t3.medium"

  scaling_config {
    desired_size = 2
    max_size     = 5
    min_size     = 2
  }

  update_config {
    max_unavailable = 1
  }
}

resource "aws_eks_access_entry" "access_1" {
  cluster_name      = aws_eks_cluster.demo.name
  principal_arn     = var.access_entry_1
  type              = "STANDARD"
}

resource "aws_eks_access_policy_association" "access_policy_association_1" {
  cluster_name  = aws_eks_cluster.demo.name
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  principal_arn = var.access_entry_1

  access_scope {
    type       = "cluster"
  }
}

resource "aws_eks_access_entry" "access_2" {
  cluster_name      = aws_eks_cluster.demo.name
  principal_arn     = var.access_entry_2
  type              = "STANDARD"
}

resource "aws_eks_access_policy_association" "access_policy_association_2" {
  cluster_name  = aws_eks_cluster.demo.name
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  principal_arn = var.access_entry_2

  access_scope {
    type       = "cluster"
  }
}