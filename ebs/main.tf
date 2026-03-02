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

# create ec2 instance
resource "aws_instance" "example" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  key_name               = var.key_name
  vpc_security_group_ids = var.security_group_ids
  availability_zone = var.availability_zone

  tags = {
    Name = "my-web-server"
  }
}

# create ebs volume
resource "aws_ebs_volume" "example" {
  availability_zone = "eu-west-1a"
  size              = 10

  tags = {
    Name = "my-ebs-volume"
  }
}

# attach ebs volume to ec2 instance
resource "aws_volume_attachment" "example" {
  device_name = "/dev/sdf"
  volume_id   = aws_ebs_volume.example.id
  instance_id = aws_instance.example.id
}