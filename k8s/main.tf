terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

provider "aws" {
  region = "eu-west-1"
}

resource "aws_vpc" "example" {
  cidr_block = "172.16.0.0/16"

  tags = {
    Name = "k8s-vpc"
  }
}

# create public subnet
resource "aws_subnet" "public-1" {
  vpc_id            = aws_vpc.example.id
  cidr_block        = "172.16.1.0/24"
  availability_zone = "eu-west-1a"
  tags = {
    Name = "k8s-subnet-1"
  }
  map_public_ip_on_launch = true
}

resource "aws_subnet" "public-2" {
  vpc_id            = aws_vpc.example.id
  cidr_block        = "172.16.2.0/24"
  availability_zone = "eu-west-1b"
  tags = {
    Name = "k8s-subnet-2"
  }
  map_public_ip_on_launch = true
}

resource "aws_subnet" "public-3" {
  vpc_id            = aws_vpc.example.id
  cidr_block        = "172.16.3.0/24"
  availability_zone = "eu-west-1c"
  tags = {
    Name = "k8s-subnet-3"
  }
  map_public_ip_on_launch = true
}

# create internet gateway
resource "aws_internet_gateway" "example" {
  vpc_id = aws_vpc.example.id

  tags = {
    Name = "k8s-igw"
  }
}

# create public route table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.example.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.example.id
  }
}


# associate route table with public subnet
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public-1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public-2" {
  subnet_id      = aws_subnet.public-2.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public-3" {
  subnet_id      = aws_subnet.public-3.id
  route_table_id = aws_route_table.public.id
}

resource "aws_security_group" "k8s_master_sg" {
  name        = "k8s-master-sg"
  description = "Security group for Kubernetes master nodes"
  vpc_id      = aws_vpc.example.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.example.cidr_block]
    description = "Allow Kubernetes API server access from within the VPC"
  }

  ingress {
    from_port   = 2379
    to_port     = 2380
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.example.cidr_block]
    description = "Allow etcd server client API access from within the VPC"
  }

  ingress {
    from_port   = 10250
    to_port     = 10250
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.example.cidr_block]
    description = "Allow kubelet API access from within the VPC"
  }

  ingress {
    from_port   = 10257
    to_port     = 10257
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.example.cidr_block]
    description = "Allow kube-controller-manager access from within the VPC"
  }

  ingress {
    from_port   = 10259
    to_port     = 10259
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.example.cidr_block]
    description = "Allow kube-scheduler access from within the VPC"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "k8s-master-sg"
  }
}

variable "availability_zones" {
  type    = list(string)
  default = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
}

locals {
  master_names = ["k8s-master-leader", "k8s-master-2", "k8s-master-3"]
}

locals {
  subnet_ids = [
    aws_subnet.public-1.id,
    aws_subnet.public-2.id,
    aws_subnet.public-3.id,
  ]
}

# Randomly shuffle the names so the "leader" label lands on a random AZ/instance
resource "random_shuffle" "master_name_assignment" {
  input        = local.master_names
  result_count = 3
}

# Build a map keyed by AZ index so each master gets a fixed AZ + a shuffled name
locals {
  masters = {
    for idx, az in var.availability_zones :
    idx => {
      az     = az
      subnet = local.subnet_ids[idx]
      name   = random_shuffle.master_name_assignment.result[idx]
    }
  }
}


resource "aws_instance" "k8s_master" {

  for_each = local.masters

  ami                    = var.ami_id
  instance_type          = var.master_instance_type
  key_name               = var.key_name
  subnet_id              = each.value.subnet
  vpc_security_group_ids = [aws_security_group.k8s_master_sg.id]
  availability_zone      = each.value.az

  tags = {
    Name = each.value.name
    Role = each.value.name == "k8s-master-leader" ? "leader" : "master"
  }

  root_block_device {
    volume_size = 10
    volume_type = "gp3"
  }

  connection {
    type        = "ssh"
    user        = var.ssh_user
    private_key = file(var.private_key_path)
    host        = self.public_ip
    timeout     = "3m"
  }

  # copy the local script to the instance
  provisioner "file" {
    source      = "k8s_script.sh"
    destination = "/tmp/k8s_script.sh"
  }

  # make it executable and run it
  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/k8s_script.sh",
      "sudo /tmp/k8s_script.sh",
    ]
  }
}

resource "aws_instance" "nginx" {

  ami                    = var.ami_id
  instance_type          = "t3.micro"
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.k8s_master_sg.id]
  subnet_id              = aws_subnet.public-1.id

  tags = {
    Name = "Nginx-Server"
  }

  root_block_device {
    volume_size = 10
    volume_type = "gp3"
  }

}