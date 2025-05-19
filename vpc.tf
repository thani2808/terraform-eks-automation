# Cleaned Terraform code with duplicates removed and structure preserved

# ------------------------
# VPC
# ------------------------
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = var.vpc_name
  }
}

# ------------------------
# SUBNETS
# ------------------------
resource "aws_subnet" "public_subnet_1a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.web_sub_cidr
  availability_zone       = var.availability_zone1a
  map_public_ip_on_launch = true

  tags = {
    Name = var.web_sub_name
  }
}

resource "aws_subnet" "private_subnet_1a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.app_sub_cidr_1a
  availability_zone       = var.availability_zone1a
  map_public_ip_on_launch = false

  tags = {
    Name = var.app_sub_name_1a
  }
}

resource "aws_subnet" "private_subnet_1b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.app_sub_cidr_1b
  availability_zone       = var.availability_zone1b
  map_public_ip_on_launch = false

  tags = {
    Name = var.app_sub_name_1b
  }
}

resource "aws_subnet" "db_subnet" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.db_sub_cidr
  availability_zone       = var.availability_zone1a
  map_public_ip_on_launch = false

  tags = {
    Name = var.db_sub_name
  }
}

# ------------------------
# BASTION HOST
# ------------------------
resource "aws_instance" "bastion" {
  ami                         = var.aws_ami
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.public_subnet_1a.id
  associate_public_ip_address = true
  key_name                    = aws_key_pair.id_rsa.key_name
  vpc_security_group_ids      = [aws_security_group.bastion_sg.id]

  tags = {
    Name = "${var.env}-bastion-host"
  }
}

# ------------------------
# INTERNET GATEWAY
# ------------------------
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.env}-igw"
  }
}

# ------------------------
# ROUTE TABLES
# ------------------------
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "${var.env}-public-rt"
  }
}

resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public_subnet_1a.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table" "private_rt_1a" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.env}-private-rt-1a"
  }
}

resource "aws_route" "private_nat_route_1a" {
  route_table_id         = aws_route_table.private_rt_1a.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat_gw.id
}

resource "aws_route_table_association" "private_1a" {
  subnet_id      = aws_subnet.private_subnet_1a.id
  route_table_id = aws_route_table.private_rt_1a.id
}

resource "aws_route_table_association" "private_1b" {
  subnet_id      = aws_subnet.private_subnet_1b.id
  route_table_id = aws_route_table.private_rt_1a.id
}

resource "aws_route_table_association" "private_db" {
  subnet_id      = aws_subnet.db_subnet.id
  route_table_id = aws_route_table.private_rt_1a.id
}

# ------------------------
# NAT GATEWAY
# ------------------------
resource "aws_eip" "nat_eip" {
  tags = {
    Name = "nat-eip"
  }
}

resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_subnet_1a.id
  depends_on    = [aws_internet_gateway.igw]

  tags = {
    Name = "nat-gw"
  }
}

resource "aws_key_pair" "id_rsa" {
  key_name   = "id_rsa"
  public_key = file("~/.ssh/id_rsa.pub")
}

# ------------------------
# IAM ROLES AND POLICIES
# ------------------------
data "aws_iam_policy_document" "eks_cluster_assume_role_policy" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "eks_cluster_role" {
  name               = "${var.env}-eks-cluster-role"
  assume_role_policy = data.aws_iam_policy_document.eks_cluster_assume_role_policy.json
}

resource "aws_iam_role_policy_attachment" "eks_cluster_AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster_role.name
}

# Node Role
resource "aws_iam_role" "eks_node_role" {
  name = "${var.env}-eks-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eks_node_AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_node_role.name
}

resource "aws_iam_role_policy_attachment" "eks_node_AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_node_role.name
}

resource "aws_iam_role_policy_attachment" "eks_node_AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_node_role.name
}

# ------------------------
# EKS CLUSTER
# ------------------------
resource "aws_eks_cluster" "main" {
  name     = "${var.env}-eks-cluster"
  role_arn = aws_iam_role.eks_cluster_role.arn

  vpc_config {
    subnet_ids = [
      aws_subnet.private_subnet_1a.id,
      aws_subnet.private_subnet_1b.id
    ]
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_AmazonEKSClusterPolicy
  ]
}

# ------------------------
# EKS NODE GROUP
# ------------------------
resource "aws_eks_node_group" "eks_nodes" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${var.env}-node-group"
  node_role_arn   = aws_iam_role.eks_node_role.arn

  subnet_ids = [
    aws_subnet.private_subnet_1a.id,
    aws_subnet.private_subnet_1b.id
  ]

  scaling_config {
    desired_size = 2
    max_size     = 3
    min_size     = 1
  }

  instance_types = ["t3.medium"]
  ami_type       = "AL2_x86_64"

  remote_access {
    ec2_ssh_key               = aws_key_pair.id_rsa.key_name
    source_security_group_ids = [aws_security_group.private_instance_sg.id]
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_node_AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.eks_node_AmazonEC2ContainerRegistryReadOnly,
    aws_iam_role_policy_attachment.eks_node_AmazonEKS_CNI_Policy,
    aws_eks_cluster.main
  ]

  tags = {
    Name = "${var.env}-eks-node-group"
  }
}

# ------------------------
# VPC ENDPOINTS
# ------------------------
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${var.region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_route_table.private_rt_1a.id]

  tags = {
    Name = "${var.env}-s3-endpoint"
  }
}

resource "aws_vpc_endpoint" "dynamodb" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${var.region}.dynamodb"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_route_table.private_rt_1a.id]

  tags = {
    Name = "${var.env}-dynamodb-endpoint"
  }
}

# ------------------------
# S3 BUCKET
# ------------------------
resource "aws_s3_bucket" "cluster_logs" {
  bucket        = "${var.env}-eks-logs-${random_id.bucket_suffix.hex}"
  force_destroy = true

  tags = {
    Name        = "${var.env}-eks-logs"
    Environment = var.env
  }
}

resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# Optional: bucket policy or lifecycle rules can be added here

# ------------------------
# OUTPUTS
# ------------------------
output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnet_id" {
  value = aws_subnet.public_subnet_1a.id
}

output "private_subnet_ids" {
  value = [
    aws_subnet.private_subnet_1a.id,
    aws_subnet.private_subnet_1b.id
  ]
}

output "db_subnet_id" {
  value = aws_subnet.db_subnet.id
}

output "eks_cluster_name" {
  value = aws_eks_cluster.main.name
}

output "eks_node_group_name" {
  value = aws_eks_node_group.eks_nodes.node_group_name
}

output "s3_logs_bucket" {
  value = aws_s3_bucket.cluster_logs.bucket
}

output "vpc_endpoint_s3_id" {
  value = aws_vpc_endpoint.s3.id
}

output "vpc_endpoint_dynamodb_id" {
  value = aws_vpc_endpoint.dynamodb.id
}