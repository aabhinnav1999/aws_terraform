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

# create IAM Role
resource "aws_iam_role" "demo_role" {
  name = "tf-role"
  
  # create a simple s3 list buckets policy
  assume_role_policy = jsonencode({
    vrersion = "2012-10-17"
    statement = [
        {
            sid = "ListBuckets01"
            effect = "Allow"
            action = "s3:ListAllMyBuckets"
            resource = "*"
        }
  ]
  })
  
}