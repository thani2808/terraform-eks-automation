terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.11.0"
    }
  }

  required_version = ">= 1.0"

  backend "s3" {
    bucket = "tf-backup-1505"
    key    = "state/terraform.tfstate"
    region = "ap-south-1"
  }
}

provider "aws" {
  region  = "ap-south-1"
  profile = "admin"
}