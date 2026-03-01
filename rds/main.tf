terraform {
    required_providers {
      aws ={
        source = "hashicorp/aws"
        version = "~> 6.0"
            }
    }
}

provider "aws" {
    region = "eu-west-1"
}

resource "aws_security_group" "mysql-sg" {
    ingress  {
        to_port = "3306"
        from_port = "3306"
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        to_port = "22"
        from_port = "22"
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        from_port = "8000"
        to_port = "8000"
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        to_port = "80"
        from_port = "80"
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        to_port = 0
        from_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
    
    tags = {
      "Name" = "rds-sg"
    }
}

resource "aws_db_instance" "mysql-db" {
    db_name = "test_mysql_db"
    allocated_storage = 20
    instance_class = "db.t3.micro"
    engine = "mysql"
    engine_version = "8.0.39"
    vpc_security_group_ids = [ aws_security_group.mysql-sg.id ]
    identifier = "demomysql"         
    publicly_accessible = true
    skip_final_snapshot = true
    username = var.username
    password = var.password

    tags = {
        "Name" = "demomysql"
    }
  
}