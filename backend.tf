terraform {
  backend "s3" {
    bucket = "tf-backup-1505"          # Make sure this bucket exists
    key    = "state/terraform.tfstate" # Path to your state file in the bucket
    region = "ap-south-1"              # Your AWS region (e.g., Mumbai)
  }
}