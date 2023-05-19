terraform {
  required_version = ">= 1.1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.2"
    }
  }

  backend "s3" {
    key     = "tfstate"
    region  = "eu-west-1"
    encrypt = true
  }
}

provider "aws" {
  region      = "eu-west-1"
  max_retries = 10
}