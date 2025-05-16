{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "Allow administration of the key",
      "Effect": "Allow",
      "Principal": {
        "AWS": [
          %{ for admin in key_administrators }
            "${admin}"%{ if admin != key_administrators[key_administrators.length - 1] },%{ endif }
          %{ endfor }
        ]
      },
      "Action": [
        "kms:*"
      ],
      "Resource": "*"
    },
    {
      "Sid": "Allow use of the key",
      "Effect": "Allow",
      "Principal": {
        "AWS":
        [
          %{ for user in key_users }
            "${user}"%{ if user != key_users[key_users.length - 1] },%{ endif }
          %{ endfor }
        ]
      },
      "Action": [
        "kms:Encrypt",
        "kms:Decrypt",
        "kms:ReEncrypt*",
        "kms:GenerateDataKey*",
        "kms:DescribeKey"
      ],
      "Resource": "*"
    }
  ]
}