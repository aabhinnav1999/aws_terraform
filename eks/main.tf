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

# create vpc
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "${var.NAME}-vpc"
  }

}

resource "aws_subnet" "public-1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "eu-west-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.NAME}-public-subnet-1"
  }
}

resource "aws_subnet" "public-2" {
  vpc_id                  = aws_vpc.main.id
  availability_zone       = "eu-west-1b"
  cidr_block              = "10.0.2.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.NAME}-public-subnet-2"
  }
}

resource "aws_subnet" "public-3" {
  vpc_id                  = aws_vpc.main.id
  availability_zone       = "eu-west-1c"
  cidr_block              = "10.0.3.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.NAME}-public-subnet-3"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.NAME}-igw"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "${var.NAME}-public-route-table"
  }
}


resource "aws_route_table_association" "public-1" {
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


# create eks cluster
resource "aws_eks_cluster" "demo" {
  name = "${var.NAME}-cluster"

  access_config {
    authentication_mode = "API"
  }

  role_arn = var.eks_cluster_role_arn

  vpc_config {
    subnet_ids = [aws_subnet.public-1.id, aws_subnet.public-2.id, aws_subnet.public-3.id]
  }

  tags = {
    Name = "${var.NAME}-cluster"
  }

  # eks auto mode configuration

  # bootstrap_self_managed_addons = false

  # compute_config {
  #   enabled       = true
  #   node_pools    = ["general-purpose", "system"]
  #   node_role_arn = var.auto_mode_node_role_arn
  # }

  # # Auto Mode: required to go with compute_config
  # kubernetes_network_config {
  #   elastic_load_balancing {
  #     enabled = true
  #   }
  # }

  # # Auto Mode: required to go with compute_config
  # storage_config {
  #   block_storage {
  #     enabled = true
  #   }
  # }

}


resource "aws_eks_node_group" "demo-1" {
  cluster_name    = aws_eks_cluster.demo.name
  node_group_name = "${var.NAME}-node-group"
  node_role_arn   = var.node_group_role_arn
  subnet_ids      = [aws_subnet.public-1.id, aws_subnet.public-2.id, aws_subnet.public-3.id]
  instance_types  = ["t3.micro"] # optional, default is "t3.medium"

  remote_access {
    ec2_ssh_key               = var.worker_nodes_key
  }

  labels = {
    environment = "dev",
  }

  scaling_config {
    desired_size = 2
    max_size     = 5
    min_size     = 1
  }

  update_config {
    max_unavailable = 1
  }
}

# resource "aws_eks_node_group" "demo-2" {
#   cluster_name    = aws_eks_cluster.demo.name
#   node_group_name = "${var.NAME}-node-group-2"
#   node_role_arn   = var.node_group_role_arn
#   subnet_ids      = [aws_subnet.public-1.id, aws_subnet.public-2.id, aws_subnet.public-3.id]
#   instance_types  = ["t2.micro"]

#   labels = {
#     family      = "t2.micro",
#     environment = "dev",
#     app         = "ecommerce"
#   }

#   scaling_config {
#     desired_size = 1
#     max_size     = 5
#     min_size     = 1
#   }

# }

# resource "aws_eks_node_group" "demo-3" {
#   cluster_name    = aws_eks_cluster.demo.name
#   node_group_name = "${var.NAME}-node-group-3"
#   node_role_arn   = var.node_group_role_arn
#   subnet_ids      = [aws_subnet.public-1.id, aws_subnet.public-2.id, aws_subnet.public-3.id]
#   instance_types  = ["t2.small"]

#   labels = {
#     family      = "t2.small",
#     environment = "dev",
#     app         = "booking"
#   }

#   scaling_config {
#     desired_size = 1
#     max_size     = 5
#     min_size     = 1
#   }

# }

resource "aws_eks_access_entry" "access_1" {
  cluster_name  = aws_eks_cluster.demo.name
  principal_arn = var.access_entry_1
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "access_policy_association_1" {
  cluster_name  = aws_eks_cluster.demo.name
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  principal_arn = var.access_entry_1

  access_scope {
    type = "cluster"
  }
}

resource "aws_eks_access_entry" "access_2" {
  cluster_name  = aws_eks_cluster.demo.name
  principal_arn = var.access_entry_2
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "access_policy_association_2" {
  cluster_name  = aws_eks_cluster.demo.name
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  principal_arn = var.access_entry_2

  access_scope {
    type = "cluster"
  }
}

# resource "aws_eks_addon" "pod_identity_agent" {
#   cluster_name = aws_eks_cluster.demo.name
#   addon_name   = "eks-pod-identity-agent"
# }

# data "aws_iam_policy_document" "pod_identity_trust" {
#   statement {
#     effect  = "Allow"
#     actions = ["sts:AssumeRole", "sts:TagSession"]

#     principals {
#       type        = "Service"
#       identifiers = ["pods.eks.amazonaws.com"]
#     }
#   }
# }

# resource "aws_eks_addon" "efs_csi_driver" {
#   cluster_name = aws_eks_cluster.demo.name
#   addon_name   = "aws-efs-csi-driver"

#   depends_on = [aws_eks_pod_identity_association.efs_csi_association]

# }


# resource "aws_iam_role" "efs_csi_pod_identity_role" {
#   name               = "tf-efs-csi-driver-role"
#   assume_role_policy = data.aws_iam_policy_document.pod_identity_trust.json
# }

# resource "aws_iam_role_policy_attachment" "efs_csi_pod_identity_policy_attachment" {
#   role       = aws_iam_role.efs_csi_pod_identity_role.name
#   policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEFSCSIDriverPolicy"
# }

# resource "aws_eks_pod_identity_association" "efs_csi_association" {
#   cluster_name    = aws_eks_cluster.demo.name
#   namespace       = "kube-system"
#   service_account = "efs-csi-controller-sa"
#   role_arn        = aws_iam_role.efs_csi_pod_identity_role.arn

#   depends_on = [aws_eks_addon.pod_identity_agent]
# }

# resource "aws_eks_addon" "ebs_csi_driver" {
#   cluster_name = aws_eks_cluster.demo.name
#   addon_name   = "aws-ebs-csi-driver"

#   depends_on = [aws_eks_pod_identity_association.ebs_csi_association]

# }

# resource "aws_iam_role" "ebs_csi_pod_identity_role" {
#   name               = "tf-ebs-csi-driver-role"
#   assume_role_policy = data.aws_iam_policy_document.pod_identity_trust.json
# }

# resource "aws_iam_role_policy_attachment" "ebs_csi_pod_identity_policy_attachment" {
#   role       = aws_iam_role.ebs_csi_pod_identity_role.name
#   policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
# }

# resource "aws_eks_pod_identity_association" "ebs_csi_association" {
#   cluster_name    = aws_eks_cluster.demo.name
#   namespace       = "kube-system"
#   service_account = "ebs-csi-controller-sa"
#   role_arn        = aws_iam_role.ebs_csi_pod_identity_role.arn

#   depends_on = [aws_eks_addon.pod_identity_agent]
# }