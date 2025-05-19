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
    sudo yum install -y python3
    sudo dnf install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm
    sudo systemctl enable amazon-ssm-agent
    sudo systemctl start amazon-ssm-agent
  EOF

  tags = {
    Name = "my-bastion-host"
  }
}