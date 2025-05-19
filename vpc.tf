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
resource "aws_subnet" "public_subnet" {
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

resource "aws_instance" "bastion" {
  ami                         = var.aws_ami
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.public_subnet.id
  associate_public_ip_address = true
  key_name                    = aws_key_pair.sshkey.key_name
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
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = var.pri_route_name
  }
}

resource "aws_route_table_association" "private_assoc_1a" {
  subnet_id      = aws_subnet.private_subnet_1a.id
  route_table_id = aws_route_table.private_rt.id
}

resource "aws_route_table_association" "private_assoc_1b" {
  subnet_id      = aws_subnet.private_subnet_1b.id
  route_table_id = aws_route_table.private_rt.id
}

resource "aws_route_table_association" "private_assoc_db" {
  subnet_id      = aws_subnet.db_subnet.id
  route_table_id = aws_route_table.private_rt.id
}

# ------------------------
# IAM POLICY DOCUMENTS
# ------------------------

data "aws_iam_policy_document" "eks_cluster_assume_role_policy" {
  statement {
    effect = "Allow"

    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "eks_node_assume_role_policy" {
  statement {
    effect = "Allow"

    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

# ------------------------
# IAM ROLES AND POLICIES
# ------------------------

resource "aws_iam_role" "eks_cluster_role" {
  name = "${var.env}-eks-cluster-role"

  assume_role_policy = data.aws_iam_policy_document.eks_cluster_assume_role_policy.json
}

resource "aws_iam_role_policy_attachment" "eks_cluster_AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster_role.name
}

resource "aws_iam_role" "eks_node_role" {
  name = "${var.env}-eks-node-role"

  assume_role_policy = data.aws_iam_policy_document.eks_node_assume_role_policy.json
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
# VPC Endpoint for EC2
resource "aws_vpc_endpoint" "ec2" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.region}.ec2"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.private_subnet_1a.id, aws_subnet.private_subnet_1b.id]
  security_group_ids  = [aws_security_group.endpoint_sg.id]
  private_dns_enabled = true
}

# VPC Endpoint for STS (used by EKS for IAM)
resource "aws_vpc_endpoint" "sts" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.region}.sts"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.private_subnet_1a.id, aws_subnet.private_subnet_1b.id]
  security_group_ids  = [aws_security_group.endpoint_sg.id]
  private_dns_enabled = true
}

# VPC Endpoint for ECR API
resource "aws_vpc_endpoint" "ecr_api" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.region}.ecr.api"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.private_subnet_1a.id, aws_subnet.private_subnet_1b.id]
  security_group_ids  = [aws_security_group.endpoint_sg.id]
  private_dns_enabled = true
}

# VPC Endpoint for ECR Docker
resource "aws_vpc_endpoint" "ecr_dkr" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.region}.ecr.dkr"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.private_subnet_1a.id, aws_subnet.private_subnet_1b.id]
  security_group_ids  = [aws_security_group.endpoint_sg.id]
  private_dns_enabled = true
}

# VPC Endpoint for S3 (Gateway type)
# resource "aws_vpc_endpoint" "s3" {
#   vpc_id       = aws_vpc.main.id
#   service_name = "com.amazonaws.${var.region}.s3"
#   route_table_ids = [
#     aws_route_table.private_rt_1a.id,
#     aws_route_table.private_rt_1b.id
#   ]
#   vpc_endpoint_type = "Gateway"
# }

# ------------------------
# SSH KEY
# ------------------------
resource "tls_private_key" "ekscl" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "id_rsa" {
  key_name   = var.key_name
  public_key = tls_private_key.ekscl.public_key_openssh
}

output "private_key_pem" {
  value     = tls_private_key.ekscl.private_key_pem
  sensitive = true
}

# ------------------------
# EKS Load Balancer Controller IAM Policy
# ------------------------
resource "aws_iam_policy" "ekscl_EKS_LBC_policy" {
  name        = "${var.nodename}-${var.env}-EKS-LBC-pl"
  description = "IAM policy for EKS Load Balancer Controller"
  policy      = data.aws_iam_policy_document.eks_lbc_policy.json
}

data "aws_iam_policy_document" "eks_lbc_policy" {
  statement {
    effect = "Allow"
    actions = [
      "elasticloadbalancing:*",
      "ec2:Describe*",
      "ec2:CreateSecurityGroup",
      "ec2:CreateTags",
      "ec2:AuthorizeSecurityGroupIngress",
      "iam:CreateServiceLinkedRole",
      "cognito-idp:DescribeUserPoolClient",
      "waf-regional:GetWebACLForResource",
      "tag:GetResources",
      "waf:GetWebACL",
      "shield:GetSubscriptionState",
      "shield:DescribeProtection",
      "shield:CreateProtection"
    ]
    resources = ["*"]
  }
}

# ------------------------
# OUTPUTS
# ------------------------
output "eks_cluster_name" {
  value = aws_eks_cluster.main.name
}

output "eks_cluster_endpoint" {
  value = aws_eks_cluster.main.endpoint
}

output "eks_cluster_certificate_authority" {
  value = aws_eks_cluster.main.certificate_authority[0].data
}

output "node_group_role_arn" {
  value = aws_iam_role.eks_node_role.arn
}

output "bastion_public_ip" {
  value = aws_instance.bastion.public_ip
}