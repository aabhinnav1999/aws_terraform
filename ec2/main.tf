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
  # profile = "ec2-profile"
}

# create ec2 instance
# resource "aws_instance" "example" {
#   ami                    = var.ami_id
#   instance_type          = var.instance_type
#   key_name               = var.key_name
#   vpc_security_group_ids = var.security_group_ids

#   tags = {
#     Name = "my-web-server"
#   }

#   root_block_device {
#     volume_size = 20
#     volume_type = "gp3"
#   }

# provisioner "file" {
#   source      = "docker.sh"
#   destination = "/tmp/docker.sh"

#   connection {
#     type        = "ssh"
#     user        = "ubuntu"
#     private_key = file(var.private_key_path)
#     host        = self.public_ip  
# }
# }

# provisioner "remote-exec" {
#   inline = [
#     "chmod +x /tmp/docker.sh",
#     "sudo /tmp/docker.sh"
#   ]

#   connection {
#     type        = "ssh"
#     user        = "ubuntu"
#     private_key = file(var.private_key_path)
#     host        = self.public_ip
#   } 
# }
# }

# output "public_ip" {
#   value = aws_instance.example.public_ip
# }

# create efs
# resource "aws_efs_file_system" "example" {
#   creation_token = "my-ec2-token"
#   performance_mode = "generalPurpose"

#   tags = {
#     Name = "my-ec2-efs"
#   }
# }

# create multiple ec2 instances
resource "aws_instance" "example_multiple" {

  count                  = 90
  ami                    = var.ami_id
  instance_type          = var.instance_type
  key_name               = var.key_name
  vpc_security_group_ids = var.security_group_ids

  tags = {
    Name = "my-server-${format("%02d", count.index + 1)}"
  }

  root_block_device {
    volume_size = 8
    volume_type = "gp3"
  }
}