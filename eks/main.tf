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

# create eks cluster
resource "aws_eks_cluster" "demo" {
  name = "tf-eks-cluster"

  access_config {
    authentication_mode = "API"
  }

  role_arn = var.eks_cluster_role_arn

  vpc_config {
    subnet_ids = var.subnets
  }

  tags = {
    Name = "tf-eks-cluster"
  }
}


resource "aws_eks_node_group" "demo" {
  cluster_name    = aws_eks_cluster.demo.name
  node_group_name = "tf-node-group"
  node_role_arn   = var.node_group_role_arn
  subnet_ids      = var.subnets    
  instance_types = ["t2.micro"] # optional, default is "t3.medium"

  scaling_config {
    desired_size = 1
    max_size     = 3
    min_size     = 1
  }

  update_config {
    max_unavailable = 1
  }
}