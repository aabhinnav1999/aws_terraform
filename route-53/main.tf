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


resource "aws_route53_zone" "primary" {
  name = "devopsexample.com"
}