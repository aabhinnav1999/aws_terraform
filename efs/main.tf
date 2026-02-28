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

# create efs file system
resource "aws_efs_file_system" "demo" {
    creation_token = "my-efs-file-system"
    performance_mode = "generalPurpose"

    tags = {
        Name = "my-efs-file-system"
    }
}