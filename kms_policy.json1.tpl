v{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "Allow administration of the key",
      "Effect": "Allow",
      "Principal": {
        "AWS": [
          "${aws_account_id}:root",
          %{ for admin in key_administrators ~}
          "${admin}"%{ if !last } , %{ endif }
          %{ endfor }
        ]
      },
      "Action": "kms:*",
      "Resource": "*"
    },
    {
      "Sid": "Allow use of the key",
      "Effect": "Allow",
      "Principal": {
        "AWS": [
          %{ for user in key_users ~}
          "${user}"%{ if !last } , %{ endif }
          %{ endfor }
        ]
      },
      "Action": [
        "kms:Encrypt",
        "kms:Decrypt",
        "kms:GenerateDataKey*",
        "kms:DescribeKey"
      ],
      "Resource": "*"
    }
  ]
}