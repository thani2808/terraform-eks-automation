# resource "aws_kms_key" "myeks_kms_key" {
#   description             = "KMS key for ekscl secrets encryption"
#   deletion_window_in_days = 7
#   key_usage               = "ENCRYPT_DECRYPT"
#   enable_key_rotation     = true

#   policy = jsonencode({
#     Version = "2012-10-17",
#     Statement = [
#       {
#         Sid    = "Enable IAM User Permissions",
#         Effect = "Allow",
#         Principal = {
#           AWS = "arn:aws:iam::430861662740:root"
#         },
#         Action   = "kms:*",
#         Resource = "*"
#       },
#       {
#         Sid    = "Allow use of the key",
#         Effect = "Allow",
#         Principal = {
#           AWS = "arn:aws:iam::430861662740:role/EKSClusterRole"
#         },
#         Action = [
#           "kms:Encrypt",
#           "kms:Decrypt",
#           "kms:ReEncrypt*",
#           "kms:GenerateDataKey*",
#           "kms:DescribeKey"
#         ],
#         Resource = "*"
#       }
#     ]
#   })

#   tags = {
#     Name = "${var.nodename}-${var.env}-ekscl-key"
#   }
# }

# resource "aws_kms_alias" "myeks_kms_key" {
#   name          = "alias/${var.nodename}-${var.env}-ekscl-key"
#   target_key_id = aws_kms_key.myeks_kms_key.id
# }

# resource "aws_iam_role" "EKSClusterRole" {
#   name = "my-EKSClusterRole"

#   assume_role_policy = jsonencode({
#     Version = "2012-10-17",
#     Statement = [
#       {
#         Effect = "Allow",
#         Principal = {
#           Service = "eks.amazonaws.com"
#         },
#         Action = "sts:AssumeRole"
#       }
#     ]
#   })
# }

# resource "aws_iam_role" "EKSNodeRole" {
#   name = "my-EKSNodeRole"

#   assume_role_policy = jsonencode({
#     Version = "2012-10-17",
#     Statement = [
#       {
#         Effect = "Allow",
#         Principal = {
#           Service = "ec2.amazonaws.com"
#         },
#         Action = "sts:AssumeRole"
#       }
#     ]
#   })
# }

# Replace all data.aws_iam_role references
# For example:
# role_arn = aws_iam_role.EKSClusterRole.arn
# node_role_arn = aws_iam_role.EKSNodeRole.arn

# The rest of your code can remain the same, but you should now reference the roles like:
# aws_iam_role.EKSClusterRole.arn
# aws_iam_role.EKSNodeRole.arn