# --- IAM Role and Instance Profile for SSM ---
resource "aws_iam_role" "ssm_role" {
  name = "SSM-Role-EC2"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "ec2.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ssm_policy_attach" {
  role       = aws_iam_role.ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ssm_instance_profile" {
  name = "SSM-Role-EC2"
  role = aws_iam_role.ssm_role.name
}

# --- EC2 Bastion Host ---
resource "aws_instance" "bastion_host" {
  ami                    = var.aws_ami
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.private_subnet_1a.id
  iam_instance_profile   = aws_iam_instance_profile.ssm_instance_profile.name
  vpc_security_group_ids = [aws_security_group.bastion_sg.id]
  key_name               = aws_key_pair.id_rsa.key_name

  user_data = <<-EOF
    #!/bin/bash
    set -e

    # Install dependencies
    sudo yum update -y
    sudo yum install -y python3 curl unzip

    # Install AWS CLI v2
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    sudo ./aws/install

    # Install kubectl
    curl -o kubectl https://s3.us-west-2.amazonaws.com/amazon-eks/1.28.2/2023-11-17/bin/linux/amd64/kubectl
    chmod +x ./kubectl
    sudo mv ./kubectl /usr/local/bin/

    # Install Helm
    curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

    # Configure kubeconfig for EKS
    aws eks update-kubeconfig --region ap-south-1 --name poc-eks-cluster

    # Wait for Kubernetes API
    for i in {1..30}; do
      if kubectl version --short; then break; fi
      echo "Waiting for Kubernetes API..." && sleep 10
    done

    # Deploy Helm chart (example: ingress-nginx)
    helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
    helm repo update
    helm install my-nginx ingress-nginx/ingress-nginx --namespace ingress-nginx --create-namespace
  EOF

  # user_data = <<-EOF
  #   #!/bin/bash
  #   sudo yum install -y python3
  #   sudo dnf install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm
  #   sudo systemctl enable amazon-ssm-agent
  #   sudo systemctl start amazon-ssm-agent
  # EOF

  tags = {
    Name = "my-bastion-host"
  }
}