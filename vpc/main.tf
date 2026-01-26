terraform {
  required_providers {
    aws = {
        source = "hashicorp/aws"
        version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "eu-west-1"
}

# create vpc
resource "aws_vpc" "main" {
  cidr_block = "172.16.0.0/16"

    tags = {
        Name = "my-vpc"
    }
}