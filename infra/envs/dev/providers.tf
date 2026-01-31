terraform {
  required_version = ">= 1.5.0"

  backend "s3" {
    bucket  = "pixology-terraform-state-sath"
    key     = "pixology/dev/terraform.tfstate"
    region  = "ap-south-1"
    encrypt = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "ap-south-1"
}
