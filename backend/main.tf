terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }
  required_version = ">= 1.3.1"
}

provider "aws" {
  region = "eu-west-2"  # Replace with your desired region
}


module "s3" {
  source = "./s3"
}
