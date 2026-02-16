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

# create s3 bucket
resource "aws_s3_bucket" "my-bucket" {
  bucket = "mydemobuckentname1602"

  tags = {
    Enivronment = "Dev"
  }
}