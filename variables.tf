# ------------------------------
# AWS Provider Configuration Variables
# ------------------------------
variable "aws_account_id" {
  description = "AWS account ID where resources will be created"
  type        = string
}

variable "region" {
  description = "AWS region where resources will be deployed"
  type        = string
  default     = "ap-south-1"
}

# ------------------------------
# Networking Configuration Variables
# ------------------------------
variable "vpc_cidr" {
  description = "CIDR block of your VPC (e.g., 10.0.0.0/16)"
  type        = string
  default     = "10.15.0.0/16"
}

variable "vpc_name" {
  description = "Name tag for the VPC"
  type        = string
}

variable "web_sub_cidr" {
  description = "CIDR block for the public web subnet"
  type        = string
  default     = "10.15.2.0/24"
}

variable "web_sub_name" {
  description = "Name tag for the public web subnet"
  type        = string
}

variable "app_sub_cidr_1a" {
  description = "CIDR block for the application subnet in AZ 1a"
  type        = string
}

variable "app_sub_cidr_1b" {
  description = "CIDR block for the application subnet in AZ 1b"
  type        = string
}

variable "app_sub_name_1a" {
  description = "Name tag for the application subnet in AZ 1a"
  type        = string
}

variable "app_sub_name_1b" {
  description = "Name tag for the application subnet in AZ 1b"
  type        = string
}

variable "db_sub_cidr" {
  description = "CIDR block for the database subnet"
  type        = string
}

variable "db_sub_name" {
  description = "Name tag for the database subnet"
  type        = string
}

variable "availability_zone1a" {
  description = "First availability zone"
  type        = string
  default     = "ap-south-1a"
}

variable "availability_zone1b" {
  description = "Second availability zone"
  type        = string
}

variable "pub_route_name" {
  description = "Name tag for the public route table"
  type        = string
}

variable "pri_route_name" {
  description = "Name tag for the private route table"
  type        = string
}

variable "my_igw_name" {
  description = "Name tag for the Internet Gateway"
  type        = string
}

variable "vpc_route_cidr" {
  description = "CIDR block for routing within the VPC"
  type        = string
}

# variable "elastic_ip_name" {
#   description = "Name tag for the Elastic IP address"
#   type        = string
# }

# variable "my_natgw_name" {
#   description = "Name tag for the NAT Gateway"
#   type        = string
# }

# variable "natgw_cidr" {
#   description = "CIDR block allowed to access the NAT Gateway (usually VPC CIDR or specific)"
#   type        = string
# }

# ------------------------------
# EC2 Configuration Variables
# ------------------------------
variable "aws_ami" {
  description = "AMI ID to use for EC2 instances"
  type        = string
  default     = "ami-078c1149d8ad719a7"
}

variable "key_name" {
  description = "Name of the existing AWS Key Pair to use for SSH"
  type        = string
  default     = "your-keypair-name"
}

variable "nodename" {
  description = "Name for nodes or instances"
  type        = string
}

# ------------------------------
# EKS Configuration Variables
# ------------------------------
variable "eks_cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "eks_nodegroup_name" {
  description = "Name of the EKS node group"
  type        = string
}

# ------------------------------
# IAM & Access Control Variables
# ------------------------------
variable "env" {
  description = "Environment tag (e.g., dev, staging, prod)"
  type        = string
}

# variable "key_administrators" {
#   description = "List of IAM ARNs with full KMS key administration access"
#   type        = list(string)
# }

# variable "key_users" {
#   description = "List of IAM ARNs (e.g., EKS roles) with permission to use the KMS key"
#   type        = list(string)
# }

variable "admin_cidr" {
  description = "Admin public IP range for SSH access"
  type        = string
}

# variable "env" {
#   description = "Environment name (e.g., dev, prod)"
#   type        = string
# }

variable "public_key_path" {
  description = "Path to the public key file"
  type        = string
}

# variable "ami_id" {
#   description = "AMI ID for the bastion host"
#   type        = string
# }

# variable "key_name" {
#   description = "SSH Key pair name"
#   type        = string
# }

# variable "admin_cidr" {
#   description = "Admin IP CIDR for SSH access"
#   type        = string
# }


# variable "key_administrators" {
#   default = "arn:aws:iam::430861662740:root"
# }

# variable "key_users" {
#   default = "arn:aws:iam::430861662740:role/EKSClusterRole"
# }